// ============================================================================
// sync-scadenze-golia/index.ts
// Supabase Edge Function - Aggiorna le Scadenze autisti dagli export del portale Golia salvati nella
// stessa cartella Google Drive dei km (GOLIA_DRIVE_FOLDER_ID):
//   "Scadenza_patenti_*.csv"            COGNOME;NOME;PATENTE_NUMERO;DATA_SCADENZA
//   "Scadenze_CQC_*.csv"                COGNOME;NOME;CQC_NUMERO;DATA_SCADENZA
//   "Scadenze_carte_conducente_*.csv"   Autista;Carta;Filiale;Scadenza_Carta
// Per ogni tipo legge il file piu' recente; righe senza data di scadenza ignorate (documenti vecchi).
// Scrive tramite la funzione SQL scadenze_autisti_aggiorna (v46): aggiorna o crea, senza doppioni.
// Chi puo' lanciarla: il cron (x-cron-secret = SYNC_CRON_SECRET) o un admin del gestionale.
// body {"prova": true} = legge e conta, ma NON scrive.
// ============================================================================

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function risposta(corpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(corpo), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}

async function ottieniAccessTokenGoogle(): Promise<string> {
  const credJson = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
  if (!credJson) throw new Error("Variabile GOOGLE_SERVICE_ACCOUNT_JSON non impostata");
  const cred = JSON.parse(credJson);

  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: cred.client_email,
    scope: "https://www.googleapis.com/auth/drive.readonly",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const base64url = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const unsigned = `${base64url(header)}.${base64url(payload)}`;

  const pem = cred.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${signatureB64}`,
    }),
  });

  if (!res.ok) throw new Error(`Autenticazione Google fallita: ${res.status} ${await res.text()}`);
  const data = await res.json();
  return data.access_token;
}

interface FileDrive { id: string; name: string; modifiedTime: string; mimeType: string; }

async function elencaExport(folderId: string, token: string): Promise<FileDrive[]> {
  const url = new URL("https://www.googleapis.com/drive/v3/files");
  url.searchParams.set("q", `'${folderId}' in parents and trashed = false and name contains 'Scadenz'`);
  url.searchParams.set("orderBy", "modifiedTime desc");
  url.searchParams.set("pageSize", "50");
  url.searchParams.set("fields", "files(id,name,modifiedTime,mimeType)");
  url.searchParams.set("supportsAllDrives", "true");
  url.searchParams.set("includeItemsFromAllDrives", "true");
  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`Elenco cartella Drive fallito: ${res.status} ${await res.text()}`);
  return (await res.json()).files ?? [];
}

async function scaricaTestoFile(file: FileDrive, token: string): Promise<string> {
  // Se Drive ha convertito il file in formato Google, va esportato:
  //  - Foglio Google   -> CSV
  //  - Documento Google -> testo semplice
  let url = `https://www.googleapis.com/drive/v3/files/${file.id}?alt=media&supportsAllDrives=true`;
  if (file.mimeType === "application/vnd.google-apps.spreadsheet") {
    url = `https://www.googleapis.com/drive/v3/files/${file.id}/export?mimeType=text/csv`;
  } else if (file.mimeType === "application/vnd.google-apps.document") {
    url = `https://www.googleapis.com/drive/v3/files/${file.id}/export?mimeType=text/plain`;
  }

  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`Download di "${file.name}" fallito: ${res.status} ${await res.text()}`);
  return await res.text();
}

// ----------------------------------------------------------------------------
// Lettura dei CSV
// ----------------------------------------------------------------------------
type Categoria = "PATENTE" | "CQC" | "CARTA";
const categoriaDi = (nome: string): Categoria | null =>
  /patent/i.test(nome) ? "PATENTE" : /cqc/i.test(nome) ? "CQC" : /cart/i.test(nome) ? "CARTA" : null;

function dataIso(v: string): string | null {
  const s = (v || "").replace(/"/g, "").trim();
  let m = s.match(/^(\d{2})\/(\d{2})\/(\d{4})/); if (m) return `${m[3]}-${m[2]}-${m[1]}`;
  m = s.match(/^(\d{4})-(\d{2})-(\d{2})/); if (m) return `${m[1]}-${m[2]}-${m[3]}`;
  return null;
}

function leggiCsv(testo: string, cat: Categoria): Record<string, string>[] {
  const righe = testo.replace(/^\uFEFF/, "").split(/\r?\n/).filter((r) => r.trim() !== "");
  if (righe.length < 2) return [];
  const sep = righe[0].includes(";") ? ";" : ",";
  const pulisci = (x: string) => (x ?? "").replace(/^"|"$/g, "").trim();
  const out: Record<string, string>[] = [];
  for (const r of righe.slice(1)) {
    const c = r.split(sep).map(pulisci);
    if (cat === "CARTA") {
      const scad = dataIso(c[3]);
      if (c[0] && scad) out.push({ nominativo: c[0], categoria: cat, numero: c[1] || "", scadenza: scad });
    } else {
      const scad = dataIso(c[3]);
      if ((c[0] || c[1]) && scad) out.push({ cognome: c[0], nome: c[1], categoria: cat, numero: c[2] || "", scadenza: scad });
    }
  }
  return out;
}

async function chiChiama(req: Request): Promise<string | null> {
  const cronSecret = Deno.env.get("SYNC_CRON_SECRET");
  const hdrCron = req.headers.get("x-cron-secret");
  if (cronSecret && hdrCron && hdrCron === cronSecret) return "cron";

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!token) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const clienteUtente = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data: u, error } = await clienteUtente.auth.getUser(token);
  if (error || !u?.user) return null;

  const { data: admin, error: errAdmin } = await clienteUtente.rpc("is_admin");
  if (errAdmin || admin !== true) return null;

  return `admin ${u.user.email ?? u.user.id}`;
}

// ----------------------------------------------------------------------------
// Handler principale
// ----------------------------------------------------------------------------
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return risposta({ successo: false, errore: "Usa POST" }, 405);
  const chi = await chiChiama(req);
  if (!chi) return risposta({ successo: false, errore: "Non autorizzato" }, 401);

  let prova = false;
  try { prova = (await req.json())?.prova === true; } catch { /* body vuoto */ }

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const scriviLog = async (esito: string, dettaglio: Record<string, unknown>) => {
    if (prova) return;
    const { error } = await supabase.from("sync_golia_log").insert({ esito, lanciata_da: chi, dettaglio: { tipo: "scadenze", ...dettaglio } });
    if (error) console.error("Log non scritto:", error.message);
  };

  try {
    const folderId = Deno.env.get("GOLIA_DRIVE_FOLDER_ID");
    if (!folderId) throw new Error("Variabile GOLIA_DRIVE_FOLDER_ID non impostata");
    const token = await ottieniAccessTokenGoogle();
    const tutti = await elencaExport(folderId, token);

    // per ogni tipo, il file piu' recente
    const scelti = new Map<Categoria, FileDrive>();
    for (const f of tutti) { const c = categoriaDi(f.name); if (c && !scelti.has(c)) scelti.set(c, f); }
    if (scelti.size === 0) {
      const det = { nota: "Nessun export Scadenze (patenti, CQC, carte) nella cartella Golia" };
      await scriviLog("nessun_file", det);
      return risposta({ successo: true, prova, ...det });
    }

    const righe: Record<string, string>[] = [];
    const fileLetti: { nome: string; modificato: string; righe: number }[] = [];
    for (const [cat, f] of scelti) {
      const r = leggiCsv(await scaricaTestoFile(f, token), cat);
      righe.push(...r);
      fileLetti.push({ nome: f.name, modificato: f.modifiedTime, righe: r.length });
    }

    let esito: Record<string, unknown> = { righe_lette: righe.length };
    if (!prova) {
      const { data, error } = await supabase.rpc("scadenze_autisti_aggiorna", { p_righe: righe, p_fonte: "Golia" });
      if (error) throw new Error(`Aggiornamento scadenze fallito: ${error.message}`);
      esito = { ...esito, ...(data as Record<string, unknown>) };
    }
    const det = { file_letti: fileLetti, ...esito };
    await scriviLog("ok", det);
    return risposta({ successo: true, prova, lanciata_da: chi, ...det });
  } catch (err) {
    await scriviLog("errore", { errore: String(err) });
    return risposta({ successo: false, errore: String(err) }, 500);
  }
});

// ============================================================================
// promemoria-fogli-viaggio/index.ts  (Supabase Edge Function)
// Ogni mattina: fogli di viaggio "inviati all'autista" con servizio finito ieri o prima e non ancora compilati.
//  - all'autista (e al secondo autista): notifica nell'app (tabella notifiche) + push sul telefono,
//    tramite la funzione del sito /api/invia-notifica (la stessa dei turni), con la chiave di servizio;
//  - dal 2o giorno di ritardo: avviso all'ufficio nella campanella del gestionale;
//  - al massimo un promemoria al giorno per foglio e per persona; solo servizi finiti negli ultimi 30 giorni.
// Chi puo' lanciarla: il cron (x-cron-secret = SYNC_CRON_SECRET) o un admin del gestionale.
// body {"prova": true} = conta e mostra, senza inviare niente.
// ============================================================================
import { createClient } from "npm:@supabase/supabase-js@2";

const SITO = "https://amministrazione-deangelisbus-v2.pages.dev";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const risposta = (corpo: unknown, status = 200) =>
  new Response(JSON.stringify(corpo), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });

// data di oggi in Italia (AAAA-MM-GG)
const oggiItalia = () => new Intl.DateTimeFormat("sv-SE", { timeZone: "Europe/Rome" }).format(new Date());
const itD = (iso: string) => iso.split("-").reverse().join("/");
const giorniTra = (da: string, a: string) => Math.round((Date.parse(a + "T12:00:00Z") - Date.parse(da + "T12:00:00Z")) / 86400000);

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return risposta({ successo: false, errore: "Usa POST" }, 405);

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // autorizzazione: cron con segreto, oppure amministratore collegato
  const segreto = Deno.env.get("SYNC_CRON_SECRET");
  let chi: string | null = null;
  if (segreto && req.headers.get("x-cron-secret") === segreto) chi = "cron";
  else {
    const token = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
    if (token) {
      const utente = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: `Bearer ${token}` } } });
      const { data } = await utente.rpc("is_admin_gestionale");
      if (data === true) chi = "admin";
    }
  }
  if (!chi) return risposta({ successo: false, errore: "Non autorizzato" }, 401);

  let prova = false;
  try { prova = (await req.json())?.prova === true; } catch { /* body vuoto */ }

  try {
    const oggi = oggiItalia();
    const inizioOggi = `${oggi}T00:00:00+02:00`;
    const { data: fogli, error } = await supabase.from("fogli_viaggio")
      .select("id, numero, oggetto, data_partenza, data_rientro, autista_id, secondo_autista_id, stato")
      .eq("stato", "inviato_autista").lt("data_partenza", oggi);
    if (error) throw new Error(`Lettura fogli: ${error.message}`);

    // solo i servizi finiti negli ultimi 30 giorni: quelli piu' vecchi sono casi da sistemare in ufficio
    const MAX_GIORNI = 30;
    const daRicordare = (fogli || []).filter((f) => {
      const fine = f.data_rientro || f.data_partenza;
      return fine < oggi && giorniTra(fine, oggi) <= MAX_GIORNI;
    });
    const vecchi = (fogli || []).filter((f) => giorniTra(f.data_rientro || f.data_partenza, oggi) > MAX_GIORNI)
      .map((f) => `${f.numero || ''} ${f.oggetto || ''} (${itD(f.data_rientro || f.data_partenza)})`.trim());
    const idAutisti = [...new Set(daRicordare.flatMap((f) => [f.autista_id, f.secondo_autista_id]).filter(Boolean))];
    const { data: autisti } = idAutisti.length
      ? await supabase.from("autisti").select("id, user_id, fcm_token, cognome, nome").in("id", idAutisti)
      : { data: [] as any[] };
    const perId = new Map((autisti || []).map((a: any) => [a.id, a]));

    // promemoria gia' mandati oggi (per non insistere)
    const { data: giaOggi } = daRicordare.length
      ? await supabase.from("notifiche").select("riferimento_id, destinatario_user_id, destinatario_tipo, tipo_evento")
          .in("tipo_evento", ["promemoria_foglio", "foglio_in_ritardo"]).gte("created_at", inizioOggi)
          .in("riferimento_id", daRicordare.map((f) => f.id))
      : { data: [] as any[] };
    const gia = (rif: string, dest: string | null, tipo: string) =>
      (giaOggi || []).some((n: any) => n.riferimento_id === rif && n.tipo_evento === tipo && (dest ? n.destinatario_user_id === dest : n.destinatario_tipo === "admin"));

    const esito = { fogli_da_ricordare: daRicordare.length, fogli_oltre_30_giorni_ignorati: vecchi, notifiche_autisti: 0, push_inviate: 0, push_senza_telefono: 0, push_errori: 0, avvisi_ufficio: 0, dettagli: [] as string[] };

    for (const f of daRicordare) {
      const fine = f.data_rientro || f.data_partenza;
      const ritardo = giorniTra(fine, oggi);
      const nomeFoglio = `${f.numero || ""}${f.oggetto ? " – " + f.oggetto : ""}`.trim();
      for (const aid of [f.autista_id, f.secondo_autista_id].filter(Boolean)) {
        const a: any = perId.get(aid);
        if (!a?.user_id || gia(f.id, a.user_id, "promemoria_foglio")) continue;
        const titolo = "📝 Foglio di viaggio da compilare";
        const messaggio = `Ricordati di compilare il foglio di viaggio ${nomeFoglio} del ${itD(fine)}: km, orari e spese.`;
        esito.dettagli.push(`${a.cognome} ${a.nome || ""}: ${nomeFoglio} (${ritardo} gg)`);
        if (prova) continue;
        const { error: e1 } = await supabase.from("notifiche").insert({
          destinatario_tipo: "autista", destinatario_user_id: a.user_id, titolo, messaggio, icona: "📝",
          url_redirect: `/fogli-viaggio/${f.id}/modifica`, tipo_evento: "promemoria_foglio",
          riferimento_id: f.id, riferimento_tipo: "foglio_viaggio",
        });
        if (!e1) esito.notifiche_autisti++;
        if (!a.fcm_token) { esito.push_senza_telefono++; continue; }
        try {
          // stessa funzione del sito usata per i turni: /api/invia-notifica, chiamata interna con la chiave di servizio
          const r = await fetch(`${SITO}/api/invia-notifica`, {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}` },
            body: JSON.stringify({ autista_ids: [a.id], titolo, messaggio,
              data: { tipo_evento: "promemoria_foglio", riferimento_id: f.id, url: `/fogli-viaggio/${f.id}/modifica` } }),
          });
          const j = await r.json().catch(() => ({}));
          if (r.ok && (j.notifiche_inviate || 0) > 0) esito.push_inviate++; else esito.push_errori++;
        } catch { esito.push_errori++; }
      }
      // dal secondo giorno: avviso all'ufficio
      if (ritardo >= 2 && !gia(f.id, null, "foglio_in_ritardo")) {
        const nomi = [f.autista_id, f.secondo_autista_id].filter(Boolean).map((x) => { const a: any = perId.get(x); return a ? `${a.cognome} ${a.nome || ""}`.trim() : ""; }).filter(Boolean).join(", ");
        if (!prova) {
          const { error: e2 } = await supabase.from("notifiche").insert({
            destinatario_tipo: "admin", titolo: "⏰ Foglio di viaggio non compilato",
            messaggio: `${nomeFoglio} (servizio finito il ${itD(fine)}, ${ritardo} giorni fa) non e' ancora stato compilato da ${nomi || "l'autista"}.`,
            icona: "⏰", url_redirect: `/fogli-viaggio/${f.id}`, tipo_evento: "foglio_in_ritardo",
            riferimento_id: f.id, riferimento_tipo: "foglio_viaggio",
          });
          if (!e2) esito.avvisi_ufficio++;
        } else esito.avvisi_ufficio++;
      }
    }
    return risposta({ successo: true, prova, lanciata_da: chi, oggi, ...esito });
  } catch (err) {
    return risposta({ successo: false, errore: String(err) }, 500);
  }
});

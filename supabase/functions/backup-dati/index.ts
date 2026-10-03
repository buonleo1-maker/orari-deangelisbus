// Supabase Edge Function "backup-dati": backup completo del database del gestionale e ripristino.
// Azioni (POST JSON):
//   esegui      { tipo }                       -> copia tutte le tabelle in un file .json.gz nello spazio privato "backup"
//   link        { id }                         -> link temporaneo (1 ora) per scaricare un backup
//   tabelle     { id }                         -> elenco tabelle e righe di un backup
//   consulta    { id, tabella }                -> righe di una tabella com'era alla data del backup
//   ripristina  { id, tabella, chiavi? }       -> rimette le righe (tutte o solo quelle indicate); prima fa un backup di sicurezza
//   elenco-pc   {}  + header x-backup-key       -> elenco dei file con link, per scaricarli sul PC/chiavetta (menu Strumenti)
// Accesso: amministratori del gestionale (login) oppure chiavi segrete del Vault (cron notturno / menu Strumenti).
import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cron-secret, x-backup-key',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });
const env = (k: string) => Deno.env.get(k) ?? '';
const BUCKET = 'backup';
const GIORNI_TENUTI = 30;

type Backup = { versione: number; creato_il: string; struttura?: string; tabelle: Record<string, { chiave: string[]; righe: Record<string, unknown>[] }> };

async function comprimi(testo: string): Promise<Uint8Array> {
  const s = new Blob([testo]).stream().pipeThrough(new CompressionStream('gzip'));
  return new Uint8Array(await new Response(s).arrayBuffer());
}
async function decomprimi(dati: Blob): Promise<string> {
  const s = dati.stream().pipeThrough(new DecompressionStream('gzip'));
  return await new Response(s).text();
}

async function leggiTabella(db: SupabaseClient, t: string): Promise<Record<string, unknown>[]> {
  const out: Record<string, unknown>[] = [];
  for (let da = 0; ; da += 1000) {
    const { data, error } = await db.from(t).select('*').range(da, da + 999);
    if (error) throw new Error(`${t}: ${error.message}`);
    out.push(...(data ?? []));
    if (!data || data.length < 1000) return out;
  }
}

async function eseguiBackup(db: SupabaseClient, tipo: string, note?: string) {
  const inizio = Date.now();
  const { data: elenco, error } = await db.rpc('backup_tabelle');
  if (error) throw new Error(`Elenco tabelle: ${error.message}`);
  const backup: Backup = { versione: 1, creato_il: new Date().toISOString(), tabelle: {} };
  const conteggi: Record<string, number> = {};
  for (const r of (elenco ?? []) as { tabella: string; chiave: string[] }[]) {
    const righe = await leggiTabella(db, r.tabella);
    backup.tabelle[r.tabella] = { chiave: r.chiave ?? [], righe };
    conteggi[r.tabella] = righe.length;
  }
  const { data: struttura } = await db.rpc('backup_schema');
  if (typeof struttura === 'string') backup.struttura = struttura;
  const file = await comprimi(JSON.stringify(backup));
  const d = new Date(); const p2 = (n: number) => String(n).padStart(2, '0');
  const percorso = `${d.getUTCFullYear()}/${p2(d.getUTCMonth() + 1)}/backup-${d.getUTCFullYear()}-${p2(d.getUTCMonth() + 1)}-${p2(d.getUTCDate())}-${p2(d.getUTCHours())}${p2(d.getUTCMinutes())}-${tipo}.json.gz`;
  const up = await db.storage.from(BUCKET).upload(percorso, file, { contentType: 'application/gzip', upsert: true });
  if (up.error) throw new Error(`Salvataggio file: ${up.error.message}`);
  let percorsoStruttura: string | null = null;
  if (backup.struttura) {
    percorsoStruttura = percorso.replace(/backup-([^/]+)\.json\.gz$/, 'struttura-$1.sql');
    const us = await db.storage.from(BUCKET).upload(percorsoStruttura, new Blob([backup.struttura], { type: 'text/plain' }), { contentType: 'text/plain; charset=utf-8', upsert: true });
    if (us.error) percorsoStruttura = null;
  }
  const { data: reg } = await db.from('backup_registro').insert({
    tipo, percorso, percorso_struttura: percorsoStruttura, dimensione: file.length, tabelle: conteggi, durata_ms: Date.now() - inizio, note: note ?? null,
  }).select().single();
  await pulisci(db);
  return reg;
}

/** Tiene le copie degli ultimi 30 giorni e, per i mesi precedenti, la prima copia di ogni mese. */
async function pulisci(db: SupabaseClient) {
  const limite = new Date(Date.now() - GIORNI_TENUTI * 86400000).toISOString();
  const { data } = await db.from('backup_registro').select('id, creato_il, percorso, percorso_struttura').eq('esito', 'ok').lt('creato_il', limite).order('creato_il');
  const tenutiMese = new Set<string>(); const via: { id: number; percorso: string; percorso_struttura: string | null }[] = [];
  for (const r of (data ?? []) as { id: number; creato_il: string; percorso: string; percorso_struttura: string | null }[]) {
    const mese = r.creato_il.slice(0, 7);
    if (!tenutiMese.has(mese)) { tenutiMese.add(mese); continue; }
    via.push(r);
  }
  if (via.length) {
    await db.storage.from(BUCKET).remove(via.flatMap((v) => [v.percorso, v.percorso_struttura]).filter(Boolean) as string[]);
    await db.from('backup_registro').delete().in('id', via.map((v) => v.id));
  }
}

async function caricaBackup(db: SupabaseClient, id: number): Promise<Backup> {
  const { data: reg } = await db.from('backup_registro').select('percorso').eq('id', id).single();
  if (!reg?.percorso) throw new Error('Backup non trovato');
  const { data, error } = await db.storage.from(BUCKET).download(reg.percorso);
  if (error || !data) throw new Error(`Lettura file: ${error?.message}`);
  return JSON.parse(await decomprimi(data)) as Backup;
}

async function gestisci(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ errore: 'Metodo non consentito' }, 405);
  let corpo: Record<string, unknown> = {};
  try { corpo = await req.json(); } catch { /* corpo vuoto */ }
  const azione = String(corpo.azione ?? '');
  const db = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false } });

  // chi chiama?
  const cron = req.headers.get('x-cron-secret');
  const chiavePc = req.headers.get('x-backup-key');
  let autorizzato = false;
  if (cron) autorizzato = (await db.rpc('backup_verifica_chiave', { p_nome: 'backup_cron_secret', p_valore: cron })).data === true;
  else if (chiavePc) autorizzato = (await db.rpc('backup_verifica_chiave', { p_nome: 'backup_download_key', p_valore: chiavePc })).data === true;
  else {
    const utente = createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } }, auth: { persistSession: false },
    });
    autorizzato = (await utente.rpc('is_admin_gestionale')).data === true;
  }
  if (!autorizzato) return json({ errore: 'Accesso riservato agli amministratori del gestionale.' }, 403);
  if (chiavePc && azione !== 'elenco-pc') return json({ errore: 'Con la chiave del PC si possono solo scaricare le copie.' }, 403);
  if (cron && azione !== 'esegui') return json({ errore: 'Azione non consentita' }, 403);

  try {
    if (azione === 'esegui') {
      const tipo = ['automatico', 'manuale', 'sicurezza'].includes(String(corpo.tipo)) ? String(corpo.tipo) : 'manuale';
      try { return json({ ok: true, backup: await eseguiBackup(db, tipo, corpo.note ? String(corpo.note) : undefined) }); }
      catch (e) {
        await db.from('backup_registro').insert({ tipo, esito: 'errore', errore: (e as Error).message });
        return json({ errore: (e as Error).message }, 500);
      }
    }
    if (azione === 'link') {
      const { data: reg } = await db.from('backup_registro').select('percorso, percorso_struttura').eq('id', Number(corpo.id)).single();
      const quale = corpo.struttura ? reg?.percorso_struttura : reg?.percorso;
      if (!quale) throw new Error('File non disponibile per questa copia');
      const { data, error } = await db.storage.from(BUCKET).createSignedUrl(quale, 3600, { download: true });
      if (error) throw error;
      return json({ url: data.signedUrl });
    }
    if (azione === 'tabelle') {
      const b = await caricaBackup(db, Number(corpo.id));
      return json({ creato_il: b.creato_il, tabelle: Object.entries(b.tabelle).map(([t, v]) => ({ tabella: t, righe: v.righe.length, chiave: v.chiave })) });
    }
    if (azione === 'consulta') {
      const b = await caricaBackup(db, Number(corpo.id)); const t = b.tabelle[String(corpo.tabella)];
      if (!t) throw new Error('Tabella non presente in questo backup');
      return json({ chiave: t.chiave, righe: t.righe });
    }
    if (azione === 'ripristina') {
      const b = await caricaBackup(db, Number(corpo.id)); const nome = String(corpo.tabella); const t = b.tabelle[nome];
      if (!t) throw new Error('Tabella non presente in questo backup');
      if (!t.chiave.length) throw new Error('La tabella non ha una chiave primaria: ripristino automatico non possibile');
      const chiavi = Array.isArray(corpo.chiavi) ? (corpo.chiavi as string[]) : null;
      const firma = (r: Record<string, unknown>) => t.chiave.map((k) => String(r[k])).join('|');
      const righe = chiavi ? t.righe.filter((r) => chiavi.includes(firma(r))) : t.righe;
      if (!righe.length) throw new Error('Nessuna riga da ripristinare');
      const sicurezza = await eseguiBackup(db, 'sicurezza', `Prima del ripristino di ${righe.length} righe di ${nome} dal backup del ${b.creato_il.slice(0, 10)}`);
      for (let i = 0; i < righe.length; i += 500) {
        const { error } = await db.from(nome).upsert(righe.slice(i, i + 500), { onConflict: t.chiave.join(',') });
        if (error) throw new Error(`Ripristino interrotto (${i} righe rimesse): ${error.message}`);
      }
      return json({ ok: true, ripristinate: righe.length, backup_sicurezza: sicurezza?.id });
    }
    if (azione === 'elenco-pc') {
      const { data } = await db.from('backup_registro').select('id, creato_il, tipo, percorso, percorso_struttura, dimensione').eq('esito', 'ok').order('creato_il', { ascending: false });
      const out = [];
      for (const r of (data ?? []) as { id: number; creato_il: string; tipo: string; percorso: string; percorso_struttura: string | null; dimensione: number }[]) {
        const { data: s } = await db.storage.from(BUCKET).createSignedUrl(r.percorso, 3600, { download: true });
        let struttura: { file: string; url?: string } | null = null;
        if (r.percorso_struttura) {
          const { data: ss } = await db.storage.from(BUCKET).createSignedUrl(r.percorso_struttura, 3600, { download: true });
          struttura = { file: r.percorso_struttura.split('/').pop() ?? '', url: ss?.signedUrl };
        }
        out.push({ ...r, file: r.percorso.split('/').pop(), url: s?.signedUrl, struttura });
      }
      return json({ copie: out });
    }
    return json({ errore: 'Azione sconosciuta' }, 400);
  } catch (e) {
    return json({ errore: (e as Error).message }, 500);
  }
}

if (typeof Deno !== 'undefined') Deno.serve(gestisci);

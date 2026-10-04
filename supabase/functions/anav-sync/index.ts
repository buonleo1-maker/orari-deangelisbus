// Supabase Edge Function "anav-sync": circolari e news ANAV nel gestionale.
//   aggiorna  {}        -> legge dal sito ANAV i dati pubblici (numero, data, titolo, link) e salva le novita'
//   riassunto { id }    -> riassume con l'AI il PDF della circolare caricato nello spazio privato "anav"
// Accesso: amministratori del gestionale (login) oppure cron notturno (chiave backup_cron_secret del Vault).
// Il testo delle circolari resta nell'area riservata ANAV: qui si salvano solo i dati pubblici.
import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-cron-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });
const env = (k: string) => Deno.env.get(k) ?? '';
const BASE = 'https://anav.it';
const MESI: Record<string, number> = { gennaio: 1, febbraio: 2, marzo: 3, aprile: 4, maggio: 5, giugno: 6, luglio: 7, agosto: 8, settembre: 9, ottobre: 10, novembre: 11, dicembre: 12 };

export type Doc = { chiave: string; tipo: 'circolare' | 'news'; numero: string | null; protocollo: string | null; data: string | null; titolo: string; link: string | null };

const entita = (s: string) => s
  .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#0?39;|&apos;|&#8217;|&rsquo;/g, "'")
  .replace(/&#8211;|&ndash;/g, '-').replace(/&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"').replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)));
const pulisci = (s: string) => entita(s.replace(/<!\[CDATA\[|\]\]>/g, '').replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();
const dataIt = (g: string, m: string, a: string) => {
  const mm = MESI[m.toLowerCase()]; if (!mm) return null;
  return `${a}-${String(mm).padStart(2, '0')}-${String(Number(g)).padStart(2, '0')}`;
};
const dataRss = (s: string) => { const d = new Date(s); return isNaN(d.getTime()) ? null : d.toISOString().slice(0, 10); };
const slug = (u: string) => u.replace(/\/+$/, '').split('/').pop() ?? u;

const RE_CIRC = /Circolare n\.?\s*(\d+)\s*\/\s*(\d{4})\s+del\s+(\d{1,2})\s+([A-Za-z\u00c0-\u00ff]+)\s+(\d{4})\s*(.*)/i;

/** Circolari dal feed RSS (titolo, link, data); il numero si cerca nel titolo o nella descrizione. */
export function circolariDaRss(xml: string): Doc[] {
  const out: Doc[] = [];
  for (const it of xml.split(/<item[\s>]/).slice(1)) {
    const titolo = pulisci((/<title>([\s\S]*?)<\/title>/.exec(it) ?? [])[1] ?? '');
    const link = pulisci((/<link>([\s\S]*?)<\/link>/.exec(it) ?? [])[1] ?? '') || null;
    const desc = pulisci((/<description>([\s\S]*?)<\/description>/.exec(it) ?? [])[1] ?? '');
    const data = dataRss(pulisci((/<pubDate>([\s\S]*?)<\/pubDate>/.exec(it) ?? [])[1] ?? ''));
    if (!titolo) continue;
    const m = RE_CIRC.exec(titolo) ?? RE_CIRC.exec(desc);
    const numero = m ? `${m[1]}/${m[2]}` : null;
    const t = m && RE_CIRC.exec(titolo) ? (m[6] || titolo) : titolo;
    const prot = /Prot\.?\s*n\.?\s*([\w/.-]+)/i.exec(desc);
    out.push({ chiave: numero ? `circolare-${m![1]}-${m![2]}` : `circolare-${slug(link ?? titolo)}`, tipo: 'circolare', numero,
      protocollo: prot ? prot[1] : null, data: m ? dataIt(m[3], m[4], m[5]) ?? data : data, titolo: t.trim(), link });
  }
  return out;
}

/** Circolari da una pagina HTML del sito (riga "Circolare n. 184/2026 del 02 Ottobre 2026 TITOLO"). */
export function circolariDaHtml(html: string): Doc[] {
  const prot = new Map<string, string>();
  for (const m of html.matchAll(/Prot\.?\s*n\.?\s*(\d+)\/([\w/.-]+)/gi)) prot.set(m[1], `${m[1]}/${m[2]}`);
  const testo = entita(html.replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ').replace(/<\/(h\d|p|div|li|a|span|section|article)>|<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, ' '));
  const out = new Map<string, Doc>();
  for (const riga of testo.split('\n').map((r) => r.replace(/\s+/g, ' ').trim()).filter(Boolean)) {
    const m = RE_CIRC.exec(riga); if (!m || !m[6]) continue;
    const chiave = `circolare-${m[1]}-${m[2]}`;
    if (out.has(chiave)) continue;
    out.set(chiave, { chiave, tipo: 'circolare', numero: `${m[1]}/${m[2]}`, protocollo: prot.get(m[1]) ?? null,
      data: dataIt(m[3], m[4], m[5]), titolo: m[6].replace(/\s*Contenuto che richiede il login.*$/i, '').trim(), link: `${BASE}/categoria-documenti/circolari-anav/` });
  }
  return [...out.values()];
}

/** News dal feed RSS. */
export function newsDaRss(xml: string): Doc[] {
  const out: Doc[] = [];
  for (const it of xml.split(/<item[\s>]/).slice(1)) {
    const titolo = pulisci((/<title>([\s\S]*?)<\/title>/.exec(it) ?? [])[1] ?? '');
    const link = pulisci((/<link>([\s\S]*?)<\/link>/.exec(it) ?? [])[1] ?? '');
    if (!titolo || !link) continue;
    out.push({ chiave: `news-${slug(link)}`, tipo: 'news', numero: null, protocollo: null,
      data: dataRss(pulisci((/<pubDate>([\s\S]*?)<\/pubDate>/.exec(it) ?? [])[1] ?? '')), titolo, link });
  }
  return out;
}

/** News da una pagina HTML: collegamenti /news/... con il loro titolo e la data vicina. */
export function newsDaHtml(html: string): Doc[] {
  const out = new Map<string, Doc>();
  for (const m of html.matchAll(/<a[^>]+href="(https?:\/\/(?:www\.)?anav\.it\/news\/[^"#?]+)"[^>]*>([\s\S]*?)<\/a>/gi)) {
    const titolo = pulisci(m[2]); if (titolo.length < 8) continue;
    const chiave = `news-${slug(m[1])}`; if (out.has(chiave)) continue;
    const dopo = pulisci(html.slice(m.index ?? 0, (m.index ?? 0) + 1500));
    const d = /(\d{1,2})\s+([A-Za-z\u00c0-\u00ff]+)\s+(\d{4})/.exec(dopo);
    out.set(chiave, { chiave, tipo: 'news', numero: null, protocollo: null, data: d ? dataIt(d[1], d[2], d[3]) : null, titolo, link: m[1] });
  }
  return [...out.values()];
}

async function scarica(url: string): Promise<string | null> {
  try {
    const r = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 (compatible; GestionaleDeAngelisBus/1.0; associato ANAV)', Accept: 'text/html,application/rss+xml,application/xml' } });
    return r.ok ? await r.text() : null;
  } catch { return null; }
}

async function aggiorna(db: SupabaseClient) {
  const dettagli: string[] = []; const tutti = new Map<string, Doc>();
  const aggiungi = (fonte: string, l: Doc[]) => { dettagli.push(`${fonte}: ${l.length}`); for (const d of l) if (!tutti.has(d.chiave)) tutti.set(d.chiave, d); };
  // circolari: feed, poi pagina dell'archivio, poi home page
  let x = await scarica(`${BASE}/categoria-documenti/circolari-anav/feed/`);
  let c = x && x.includes('<item') ? circolariDaRss(x) : [];
  aggiungi('feed circolari', c);
  for (const pagina of [`${BASE}/categoria-documenti/circolari-anav/`, `${BASE}/`]) {
    const h = await scarica(pagina); if (h) aggiungi(`pagina ${pagina.replace(BASE, '') || '/'} (circolari)`, circolariDaHtml(h));
  }
  // news: feed, poi pagina delle news
  x = await scarica(`${BASE}/category/news/feed/`);
  aggiungi('feed news', x && x.includes('<item') ? newsDaRss(x) : []);
  const hn = await scarica(`${BASE}/category/news/`); if (hn) aggiungi('pagina news', newsDaHtml(hn));

  const elenco = [...tutti.values()];
  let nuovi = 0;
  if (elenco.length) {
    const { data: esistenti } = await db.from('anav_documenti').select('chiave').in('chiave', elenco.map((d) => d.chiave));
    const gia = new Set((esistenti ?? []).map((e: { chiave: string }) => e.chiave));
    const daInserire = elenco.filter((d) => !gia.has(d.chiave));
    if (daInserire.length) {
      const { error } = await db.from('anav_documenti').insert(daInserire);
      if (error) throw new Error(error.message);
    }
    nuovi = daInserire.length;
  }
  const esito = elenco.length ? 'ok' : 'nessun dato letto dal sito';
  await db.from('anav_sync_log').insert({ nuovi, trovati: elenco.length, esito, dettagli: dettagli.join(' | ') });
  return { nuovi, trovati: elenco.length, esito, dettagli };
}

async function riassunto(db: SupabaseClient, id: number) {
  const chiaveAi = env('ANTHROPIC_API_KEY');
  if (!chiaveAi) throw new Error('Manca il segreto ANTHROPIC_API_KEY su Supabase (Edge Functions > Secrets).');
  const { data: d } = await db.from('anav_documenti').select('*').eq('id', id).single();
  if (!d?.pdf_percorso) throw new Error('Carica prima il PDF della circolare.');
  const { data: f, error } = await db.storage.from('anav').download(d.pdf_percorso);
  if (error || !f) throw new Error(`Lettura PDF: ${error?.message}`);
  const bytes = new Uint8Array(await f.arrayBuffer()); let bin = '';
  for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'x-api-key': chiaveAi, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001', max_tokens: 700,
      system: 'Sei l\'assistente amministrativo di De Angelis Bus S.r.l., impresa di trasporto pubblico locale (TPL) e noleggio autobus con conducente (NCC) a Grottole (MT). Leggi la circolare ANAV allegata e rispondi SOLO con un oggetto JSON valido, senza testo prima o dopo, con le chiavi: "sintesi" (massimo 2 frasi), "cosa_fare" (elenco di massimo 4 azioni concrete per l\'azienda, vuoto se nessuna), "scadenza" (la data entro cui agire, formato AAAA-MM-GG, oppure null), "riguarda_noi" ("si", "forse" o "no"). Scrivi in italiano semplice.',
      messages: [{ role: 'user', content: [
        { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: btoa(bin) } },
        { type: 'text', text: `Circolare: ${d.numero ?? ''} ${d.titolo}` },
      ] }],
    }),
  });
  const out = await r.json();
  if (!r.ok) throw new Error(out?.error?.message ?? `Errore AI ${r.status}`);
  const testo = (out.content ?? []).map((b: { text?: string }) => b.text ?? '').join('').replace(/```json|```/g, '').trim();
  let j: { sintesi?: string; cosa_fare?: string[]; scadenza?: string | null; riguarda_noi?: string };
  try { j = JSON.parse(testo); } catch { j = { sintesi: testo }; }
  const righe = [j.sintesi ?? '', ...(j.cosa_fare?.length ? ['Cosa fare:', ...j.cosa_fare.map((a) => `- ${a}`)] : []),
    j.scadenza ? `Entro: ${j.scadenza}` : '', j.riguarda_noi ? `Ci riguarda: ${j.riguarda_noi}` : ''].filter(Boolean);
  const testoFinale = righe.join('\n');
  await db.from('anav_documenti').update({ riassunto: testoFinale, riassunto_il: new Date().toISOString() }).eq('id', id);
  return { riassunto: testoFinale, scadenza: j.scadenza && /^\d{4}-\d{2}-\d{2}$/.test(j.scadenza) ? j.scadenza : null };
}

async function gestisci(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ errore: 'Metodo non consentito' }, 405);
  let corpo: Record<string, unknown> = {};
  try { corpo = await req.json(); } catch { /* vuoto */ }
  const db = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false } });
  const cron = req.headers.get('x-cron-secret');
  let ok = false;
  if (cron) ok = (await db.rpc('backup_verifica_chiave', { p_nome: 'backup_cron_secret', p_valore: cron })).data === true && corpo.azione === 'aggiorna';
  else {
    const u = createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } }, auth: { persistSession: false } });
    ok = (await u.rpc('is_admin_gestionale')).data === true;
  }
  if (!ok) return json({ errore: 'Accesso riservato agli amministratori del gestionale.' }, 403);
  try {
    if (corpo.azione === 'aggiorna') return json(await aggiorna(db));
    if (corpo.azione === 'riassunto') return json(await riassunto(db, Number(corpo.id)));
    return json({ errore: 'Azione sconosciuta' }, 400);
  } catch (e) { return json({ errore: (e as Error).message }, 500); }
}

if (typeof Deno !== 'undefined') Deno.serve(gestisci);

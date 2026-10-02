// Supabase Edge Function "invia-notifica": notifiche push dell'app Orari Deangelisbus.
// Azioni (POST JSON):
//   { azione: "chiave" }                         -> chiave pubblica VAPID (per l'app, nessun login)
//   { azione: "invia", titolo, testo, url?, novita_id? } -> invia a tutti gli iscritti (solo admin del gestionale)
// Segreti richiesti: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT (es. mailto:info@deangelisbus.it).
// Web Push implementato con WebCrypto (RFC 8291 aes128gcm + RFC 8292 VAPID): nessuna libreria esterna.
import { createClient } from 'npm:@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (dati: unknown, status = 200) =>
  new Response(JSON.stringify(dati), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

// ---------- utilita' ----------
const te = new TextEncoder();
export function b64uEnc(b: Uint8Array): string {
  let s = ''; for (const x of b) s += String.fromCharCode(x);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
export function b64uDec(s: string): Uint8Array {
  const p = s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4);
  const bin = atob(p); const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}
function unisci(...parti: Uint8Array[]): Uint8Array {
  const out = new Uint8Array(parti.reduce((n, p) => n + p.length, 0)); let o = 0;
  for (const p of parti) { out.set(p, o); o += p.length; }
  return out;
}
async function hmac(chiave: Uint8Array, dati: Uint8Array): Promise<Uint8Array> {
  const k = await crypto.subtle.importKey('raw', chiave, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return new Uint8Array(await crypto.subtle.sign('HMAC', k, dati));
}

// ---------- VAPID (RFC 8292) ----------
export async function importaChiavePrivata(pubB64: string, privB64: string): Promise<CryptoKey> {
  const pub = b64uDec(pubB64);
  const jwk = { kty: 'EC', crv: 'P-256', x: b64uEnc(pub.slice(1, 33)), y: b64uEnc(pub.slice(33, 65)), d: privB64, ext: true };
  return await crypto.subtle.importKey('jwk', jwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
}
export async function intestazioneVapid(endpoint: string, pubB64: string, priv: CryptoKey, subject: string): Promise<string> {
  const aud = new URL(endpoint).origin;
  const testa = b64uEnc(te.encode(JSON.stringify({ typ: 'JWT', alg: 'ES256' })));
  const corpo = b64uEnc(te.encode(JSON.stringify({ aud, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub: subject })));
  const firma = new Uint8Array(await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, priv, te.encode(`${testa}.${corpo}`)));
  return `vapid t=${testa}.${corpo}.${b64uEnc(firma)}, k=${pubB64}`;
}

// ---------- cifratura del messaggio (RFC 8291, aes128gcm) ----------
export async function cifra(messaggio: Uint8Array, p256dhB64: string, authB64: string): Promise<Uint8Array> {
  const uaPub = b64uDec(p256dhB64); const authSecret = b64uDec(authB64);
  const as = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']) as CryptoKeyPair;
  const asPub = new Uint8Array(await crypto.subtle.exportKey('raw', as.publicKey));
  const uaKey = await crypto.subtle.importKey('raw', uaPub, { name: 'ECDH', namedCurve: 'P-256' }, false, []);
  const ecdh = new Uint8Array(await crypto.subtle.deriveBits({ name: 'ECDH', public: uaKey }, as.privateKey, 256));
  const prkKey = await hmac(authSecret, ecdh);
  const ikm = await hmac(prkKey, unisci(te.encode('WebPush: info\0'), uaPub, asPub, new Uint8Array([1])));
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const prk = await hmac(salt, ikm);
  const cek = (await hmac(prk, unisci(te.encode('Content-Encoding: aes128gcm\0'), new Uint8Array([1])))).slice(0, 16);
  const nonce = (await hmac(prk, unisci(te.encode('Content-Encoding: nonce\0'), new Uint8Array([1])))).slice(0, 12);
  const k = await crypto.subtle.importKey('raw', cek, 'AES-GCM', false, ['encrypt']);
  const cifrato = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, k, unisci(messaggio, new Uint8Array([2]))));
  const rs = new Uint8Array([0, 0, 16, 0]); // 4096
  return unisci(salt, rs, new Uint8Array([asPub.length]), asPub, cifrato);
}

export async function inviaUna(sub: { endpoint: string; p256dh: string; auth: string }, messaggio: Uint8Array,
  vapid: { pub: string; priv: CryptoKey; subject: string }): Promise<number> {
  const corpo = await cifra(messaggio, sub.p256dh, sub.auth);
  const r = await fetch(sub.endpoint, {
    method: 'POST',
    headers: {
      Authorization: await intestazioneVapid(sub.endpoint, vapid.pub, vapid.priv, vapid.subject),
      'Content-Encoding': 'aes128gcm', 'Content-Type': 'application/octet-stream', TTL: '86400', Urgency: 'high',
    },
    body: corpo,
  });
  await r.body?.cancel();
  return r.status;
}

// ---------- servizio ----------
async function gestisci(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ errore: 'Metodo non consentito' }, 405);
  const env = (k: string) => Deno.env.get(k) ?? '';
  let dati: Record<string, unknown> = {};
  try { dati = await req.json(); } catch { return json({ errore: 'Richiesta non valida' }, 400); }

  if (dati.azione === 'chiave') return json({ chiave: env('VAPID_PUBLIC_KEY') });

  if (dati.azione === 'invia') {
    // solo gli amministratori del gestionale possono inviare
    const utente = createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } }, auth: { persistSession: false },
    });
    const { data: admin } = await utente.rpc('is_admin_gestionale');
    if (admin !== true) return json({ errore: 'Solo gli amministratori del gestionale possono inviare notifiche.' }, 403);

    const titolo = String(dati.titolo ?? '').trim().slice(0, 80);
    const testo = String(dati.testo ?? '').trim().slice(0, 240);
    if (!titolo) return json({ errore: 'Manca il titolo della notifica.' }, 400);
    const novitaId = dati.novita_id ? Number(dati.novita_id) : null;
    const url = String(dati.url ?? './?apri=novita');

    const servizio = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false } });
    const { data: iscritti, error } = await servizio.from('push_iscrizioni').select('endpoint, p256dh, auth');
    if (error) return json({ errore: error.message }, 500);

    const vapid = { pub: env('VAPID_PUBLIC_KEY'), priv: await importaChiavePrivata(env('VAPID_PUBLIC_KEY'), env('VAPID_PRIVATE_KEY')), subject: env('VAPID_SUBJECT') || 'mailto:info@deangelisbus.it' };
    const messaggio = te.encode(JSON.stringify({ title: titolo, body: testo, url, tag: novitaId ? `novita-${novitaId}` : `avviso-${Date.now()}` }));

    let inviate = 0, errori = 0; const scadute: string[] = [];
    const lista = iscritti ?? [];
    for (let i = 0; i < lista.length; i += 25) {
      const esiti = await Promise.all(lista.slice(i, i + 25).map(async (s) => {
        try { return { s, st: await inviaUna(s, messaggio, vapid) }; } catch { return { s, st: 0 }; }
      }));
      for (const { s, st } of esiti) {
        if (st >= 200 && st < 300) inviate++;
        else { errori++; if (st === 404 || st === 410) scadute.push(s.endpoint); }
      }
    }
    if (scadute.length) await servizio.from('push_iscrizioni').delete().in('endpoint', scadute);
    if (inviate) await servizio.from('push_iscrizioni').update({ ultimo_invio: new Date().toISOString() }).gte('creato_il', '1970-01-01');
    if (novitaId) await servizio.from('orari_novita').update({ notificata_il: new Date().toISOString() }).eq('id', novitaId);
    await servizio.from('push_invii').insert({ titolo, testo, url, novita_id: novitaId, destinatari: lista.length, inviate, errori, rimosse: scadute.length });
    return json({ destinatari: lista.length, inviate, errori, rimosse: scadute.length });
  }

  return json({ errore: 'Azione sconosciuta' }, 400);
}

if (typeof Deno !== 'undefined') Deno.serve(gestisci);

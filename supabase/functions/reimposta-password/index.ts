// Supabase Edge Function "reimposta-password": un amministratore del gestionale imposta una NUOVA password
// per l'account di un dipendente (quando l'ha persa e non puo' usare il link via email).
// Richiesta: { autista_id, password }  ->  { ok: true, email }
// Accesso: solo utenti amministratori del gestionale (is_admin_gestionale), con il loro login.
// v2 (21/11/2026): chiavi nuove (sb_secret per il database, sb_publishable per l'utente), con
// ripiego sulle Legacy. "Enforce JWT verification" DISATTIVATA (il controllo e' nel codice).
import { createClient } from 'npm:@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });
const env = (k: string) => Deno.env.get(k) ?? '';
const chiaviNuove = (k: string): string[] => {
  try { return Object.values(JSON.parse(env(k) || '{}')).filter((v): v is string => typeof v === 'string' && v.length > 0); }
  catch { return []; }
};
const CHIAVE_DB = chiaviNuove('SUPABASE_SECRET_KEYS')[0] || env('SUPABASE_SERVICE_ROLE_KEY');
const CHIAVE_PUBBLICA = chiaviNuove('SUPABASE_PUBLISHABLE_KEYS')[0] || env('SUPABASE_ANON_KEY');

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ errore: 'Metodo non consentito' }, 405);
  try {
    // 1) chi chiede deve essere amministratore del gestionale
    const auth = req.headers.get('Authorization') ?? '';
    if (!/^Bearer\s+ey/i.test(auth)) return json({ errore: 'Solo gli amministratori del gestionale possono reimpostare le password.' }, 403);
    const utente = createClient(env('SUPABASE_URL'), CHIAVE_PUBBLICA, {
      global: { headers: { Authorization: auth } }, auth: { persistSession: false },
    });
    const { data: admin } = await utente.rpc('is_admin_gestionale');
    if (admin !== true) return json({ errore: 'Solo gli amministratori del gestionale possono reimpostare le password.' }, 403);

    // 2) dati della richiesta
    const { autista_id, password } = await req.json().catch(() => ({}));
    if (!autista_id) return json({ errore: 'Dipendente non indicato.' }, 400);
    if (!password || String(password).length < 6) return json({ errore: 'La password deve avere almeno 6 caratteri.' }, 400);

    // 3) account collegato al dipendente
    const db = createClient(env('SUPABASE_URL'), CHIAVE_DB, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: dip, error: e1 } = await db.from('autisti').select('id, nome, cognome, email, user_id').eq('id', autista_id).single();
    if (e1 || !dip) return json({ errore: 'Dipendente non trovato.' }, 404);
    if (!dip.user_id) return json({ errore: 'Questo dipendente non ha un account per l\'app: crealo dalla scheda (Crea account).' }, 400);

    // 4) nuova password
    const { error: e2 } = await db.auth.admin.updateUserById(dip.user_id, { password: String(password) });
    if (e2) return json({ errore: `Password non cambiata: ${e2.message}` }, 500);
    return json({ ok: true, email: dip.email, nome: `${dip.nome ?? ''} ${dip.cognome ?? ''}`.trim() });
  } catch (e) {
    return json({ errore: (e as Error).message }, 500);
  }
});

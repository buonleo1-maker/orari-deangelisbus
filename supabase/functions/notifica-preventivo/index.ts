// Edge Function: notifica-preventivo
// Chiamata dai trigger del database su INSERT in:
//   - richieste_preventivo  -> email "Preventivo app: ..."
//   - segnalazioni_app      -> email "Segnalazione app: ..."
//   - prenotazioni_auto     -> email "Prenotazione auto: ..." + notifica sul telefono degli amministratori (v59)
// Invia un'email all'ufficio (SMTP Aruba, porta 465 SSL).
//
// Secrets (Edge Functions > Secrets):
//   SMTP_HOST=smtps.aruba.it   SMTP_PORT=465
//   SMTP_USER=info@deangelisbus.it   SMTP_PASS=<password della casella>
//   EMAIL_TO=info@deangelisbus.it,tiziana@deangelisbus.it
//   WEBHOOK_SECRET=<stessa parola usata nei trigger>
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY sono già disponibili automaticamente.
// Notifiche push (facoltativi): PUSH_URL (predefinito: funzione /api/invia-notifica del gestionale)
//   e PUSH_SERVICE_KEY (predefinito: SUPABASE_SERVICE_ROLE_KEY; deve coincidere con SUPABASE_SERVICE_KEY su Cloudflare).

import nodemailer from 'npm:nodemailer@6.9.14';
import { createClient } from 'npm:@supabase/supabase-js@2';

const TIPI_PREVENTIVO: Record<string, string> = {
  trasferimento: 'Trasferimento', noleggio: 'Noleggio con autista', gita: 'Gita / viaggio di gruppo', altro: 'Altro',
};
const TIPI_SEGNALAZIONE: Record<string, string> = {
  suggerimento: 'Suggerimento / feedback', reclamo: 'Reclamo', segnalazione: 'Segnalazione', complimento: 'Complimento',
};

const SERVIZI_AUTO: Record<string, string> = {
  ultimo_miglio: 'Ultimo miglio (dal bus alla destinazione)', visita_medica: 'Accompagnamento visita medica',
};
const PUSH_URL_PREDEFINITO = 'https://amministrazione-deangelisbus-v2.pages.dev/api/invia-notifica';

/** Notifica sul telefono a tutti gli amministratori del gestionale che hanno l'app con le notifiche attive. */
async function notificaAmministratori(titolo: string, messaggio: string, dati: Record<string, string>) {
  const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: admin, error } = await sb.from('autisti').select('id')
    .or('ruolo.in.(admin,amministratore),and(accesso_amministratore.is.true,attivo.is.true)')
    .not('fcm_token', 'is', null);
  if (error) return { ok: false, errore: `lettura amministratori: ${error.message}` };
  const ids = (admin ?? []).map((a: { id: string }) => a.id);
  if (!ids.length) return { ok: false, errore: 'nessun amministratore con le notifiche attive' };
  const chiave = Deno.env.get('PUSH_SERVICE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const r = await fetch(Deno.env.get('PUSH_URL') ?? PUSH_URL_PREDEFINITO, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${chiave}` },
    body: JSON.stringify({ autista_ids: ids, titolo, messaggio, data: dati }),
  });
  const testo = await r.text();
  return { ok: r.ok, stato: r.status, risposta: testo.slice(0, 300) };
}

const esc = (v: unknown) => String(v ?? '').replace(/[&<>"']/g, (c) =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
const dataIt = (d: string | null) => (d ? d.split('-').reverse().join('/') : '—');
const ora = (t: string | null) => (t ? t.slice(0, 5) : '');
const quando = (iso: string) => new Date(iso).toLocaleString('it-IT', { timeZone: 'Europe/Rome' });

function tabellaHtml(titolo: string, sotto: string, righe: [string, unknown][], azione?: { href: string; testo: string }) {
  return `
  <div style="font-family:Arial,sans-serif;max-width:600px">
    <h2 style="color:#020a5d;margin:0 0 4px">${esc(titolo)}</h2>
    <p style="color:#5b6b7b;margin:0 0 16px">${esc(sotto)}</p>
    <table style="border-collapse:collapse;width:100%">
      ${righe.map(([k, v]) => `<tr><td style="padding:8px;border-bottom:1px solid #d6dde4;color:#5b6b7b;width:130px;vertical-align:top">${esc(k)}</td><td style="padding:8px;border-bottom:1px solid #d6dde4;font-weight:bold;white-space:pre-wrap">${esc(v)}</td></tr>`).join('')}
    </table>
    <p style="color:#5b6b7b;font-size:12px;margin-top:16px">Messaggio automatico dell'app Orari Deangelisbus S.r.l. – orari.deangelisbus.it</p>
    ${azione ? `<p style="margin-top:16px"><a href="${esc(azione.href)}" style="background:#ffc628;color:#020a5d;padding:10px 16px;border-radius:6px;text-decoration:none;font-weight:bold">${esc(azione.testo)}</a></p>` : ''}
  </div>`;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Metodo non consentito', { status: 405 });
  if (req.headers.get('x-webhook-secret') !== Deno.env.get('WEBHOOK_SECRET')) {
    return new Response('Non autorizzato', { status: 401 });
  }
  const payload = await req.json().catch(() => null);
  const r = payload?.record;
  if (!r || payload?.type !== 'INSERT') return new Response('Nessun dato', { status: 400 });
  const tabella: string = payload?.table ?? 'richieste_preventivo';

  let oggetto: string, html: string, testo: string, replyTo: string | undefined;

  let push: { titolo: string; messaggio: string } | null = null;

  if (tabella === 'prenotazioni_auto') {
    const cliente = [r.nome, r.cognome].filter(Boolean).join(' ');
    const visita = r.servizio === 'visita_medica';
    const righe: [string, unknown][] = [
      ['Servizio', SERVIZI_AUTO[r.servizio] ?? r.servizio],
      ['Data', dataIt(r.data)],
      [visita ? 'Ora appuntamento' : 'Arrivo del bus', ora(r.ora) || '—'],
      [visita ? 'Partenza (casa)' : 'Fermata di arrivo', r.partenza],
      [visita ? 'Ospedale / studio' : 'Destinazione', r.destinazione],
    ];
    if (!visita) righe.push(['Corsa del bus', r.corsa ?? '—'], ['Bagagli', r.bagagli ?? '—']);
    if (visita) righe.push(["L'autista aspetta", r.attesa ? 'Sì, attende e riporta a casa' : 'No']);
    righe.push(
      ['Ritorno', r.ritorno ? `Sì${r.ora_ritorno ? `, verso le ${ora(r.ora_ritorno)}` : ''}` : 'No'],
      ['Persone', r.passeggeri],
      ['Esigenze', r.esigenze ?? '—'],
      ['Note', r.note ?? '—'],
      ['Prenotato da', cliente],
      ['Telefono', r.telefono],
      ['Email', r.email ?? '—'],
    );
    if (r.per_altri) righe.push(['Passeggero', `${r.passeggero_nome ?? '—'}${r.passeggero_telefono ? ` – tel. ${r.passeggero_telefono}` : ''}`]);
    oggetto = `Prenotazione auto: ${SERVIZI_AUTO[r.servizio] ?? r.servizio} – ${dataIt(r.data)} ${ora(r.ora)} – ${cliente}`;
    html = tabellaHtml(`Nuova prenotazione auto n. ${r.id}`, `Inviata dall'app Orari il ${quando(r.creata_il)}`, righe,
      { href: `tel:${String(r.telefono).replace(/\s/g, '')}`, testo: 'Chiama il cliente' });
    testo = righe.map(([k, v]) => `${k}: ${v}`).join('\n') + '\n\nMessaggio automatico dell\'app Orari Deangelisbus S.r.l.';
    replyTo = r.email || undefined;
    push = {
      titolo: visita ? 'Nuova prenotazione: visita medica' : 'Nuova prenotazione: ultimo miglio',
      messaggio: `${dataIt(r.data)} ${ora(r.ora)} – ${r.partenza} → ${r.destinazione} – ${cliente}`.slice(0, 200),
    };
  } else if (tabella === 'segnalazioni_app') {
    const righe: [string, unknown][] = [
      ['Tipo', TIPI_SEGNALAZIONE[r.tipo] ?? r.tipo],
      ['Linea', r.linea_id ?? '—'],
      ['Quando', `${dataIt(r.data_evento)} ${ora(r.ora_evento)}`.trim()],
      ['Dove', r.luogo ?? '—'],
      ['Messaggio', r.messaggio],
      ['Nome', r.nome ?? '— (anonimo)'],
      ['Telefono', r.telefono ?? '—'],
      ['Email', r.email ?? '—'],
    ];
    oggetto = `Segnalazione app: ${TIPI_SEGNALAZIONE[r.tipo] ?? r.tipo}${r.linea_id ? ` – ${r.linea_id}` : ''}`;
    html = tabellaHtml(`Nuova segnalazione n. ${r.id}`, `Inviata dall'app Orari il ${quando(r.creata_il)}`, righe,
      r.telefono ? { href: `tel:${String(r.telefono).replace(/\s/g, '')}`, testo: 'Chiama il cliente' } : undefined);
    testo = righe.map(([k, v]) => `${k}: ${v}`).join('\n') + '\n\nMessaggio automatico dell\'app Orari Deangelisbus S.r.l.';
    replyTo = r.email || undefined;
  } else {
    const cliente = [r.nome, r.cognome].filter(Boolean).join(' ');
    const righe: [string, unknown][] = [
      ['Nome e cognome', cliente],
      ['Azienda', r.azienda ?? '—'],
      ['Telefono', r.telefono],
      ['Email', r.email ?? '—'],
      ['Data di partenza', `${dataIt(r.data_andata)} ${ora(r.ora_andata)}`.trim()],
      ['Data di rientro', r.data_ritorno ? `${dataIt(r.data_ritorno)} ${ora(r.ora_ritorno)}`.trim() : '—'],
      ['Luogo di partenza', r.partenza],
      ['Luogo di destinazione', r.destinazione],
      ['Partecipanti', r.passeggeri ?? '—'],
      ['Itinerario', r.itinerario ?? '—'],
      ['Ulteriori informazioni', r.note ?? '—'],
    ];
    if (r.tipo) righe.unshift(['Servizio', TIPI_PREVENTIVO[r.tipo] ?? r.tipo]);
    oggetto = `Preventivo app: ${r.partenza} → ${r.destinazione} (${dataIt(r.data_andata)}) – ${cliente}${r.azienda ? `, ${r.azienda}` : ''}`;
    html = tabellaHtml(`Nuova richiesta di preventivo n. ${r.id}`, `Inviata dall'app Orari il ${quando(r.creata_il)}`, righe,
      { href: `tel:${String(r.telefono).replace(/\s/g, '')}`, testo: 'Chiama il cliente' });
    testo = righe.map(([k, v]) => `${k}: ${v}`).join('\n') + '\n\nMessaggio automatico dell\'app Orari Deangelisbus S.r.l.';
    replyTo = r.email || undefined;
  }

  const transport = nodemailer.createTransport({
    host: Deno.env.get('SMTP_HOST') ?? 'smtps.aruba.it',
    port: Number(Deno.env.get('SMTP_PORT') ?? 465),
    secure: true,
    auth: { user: Deno.env.get('SMTP_USER')!, pass: Deno.env.get('SMTP_PASS')! },
  });
  let esitoSmtp: Record<string, unknown> = {};
  try {
    const info = await transport.sendMail({
      from: `"App Orari Deangelisbus" <${Deno.env.get('SMTP_USER')}>`,
      to: Deno.env.get('EMAIL_TO') ?? Deno.env.get('SMTP_USER'),
      replyTo: replyTo ?? Deno.env.get('SMTP_USER'), subject: oggetto, text: testo, html,
    });
    // risposta del server di posta: utile per capire dove finisce il messaggio
    esitoSmtp = { accettati: info.accepted, rifiutati: info.rejected, risposta: info.response, id: info.messageId };
    console.log('Email inviata', tabella, r.id, JSON.stringify(esitoSmtp));
  } catch (e) {
    console.error('Invio email fallito:', e);
    esitoSmtp = { errore_email: String(e) };
    // per le prenotazioni si prova comunque la notifica sul telefono
    if (!push) return new Response(JSON.stringify({ ok: false, errore: String(e) }), { status: 500 });
  }

  const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const nomeTabella = tabella === 'segnalazioni_app' ? 'segnalazioni_app' : tabella === 'prenotazioni_auto' ? 'prenotazioni_auto' : 'richieste_preventivo';
  const aggiornamento: Record<string, string> = {};
  if (!esitoSmtp.errore_email) aggiornamento.email_inviata_il = new Date().toISOString();

  let esitoPush: Record<string, unknown> | null = null;
  if (push) {
    try {
      esitoPush = await notificaAmministratori(push.titolo, push.messaggio, { tipo: 'prenotazione_auto', id: String(r.id), url: '/admin/app-orari/prenotazioni-auto' });
      if (esitoPush.ok) aggiornamento.push_inviata_il = new Date().toISOString();
      console.log('Notifica amministratori', r.id, JSON.stringify(esitoPush));
    } catch (e) {
      esitoPush = { ok: false, errore: String(e) };
      console.error('Notifica amministratori fallita:', e);
    }
  }
  if (Object.keys(aggiornamento).length) await sb.from(nomeTabella).update(aggiornamento).eq('id', r.id);

  return new Response(JSON.stringify({ ok: true, tabella, ...esitoSmtp, ...(esitoPush ? { push: esitoPush } : {}) }), { headers: { 'Content-Type': 'application/json' } });
});

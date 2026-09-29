// Edge Function: notifica-preventivo
// Chiamata dai trigger del database su INSERT in:
//   - richieste_preventivo  -> email "Preventivo app: ..."
//   - segnalazioni_app      -> email "Segnalazione app: ..."
// Invia un'email all'ufficio (SMTP Aruba, porta 465 SSL).
//
// Secrets (Edge Functions > Secrets):
//   SMTP_HOST=smtps.aruba.it   SMTP_PORT=465
//   SMTP_USER=info@deangelisbus.it   SMTP_PASS=<password della casella>
//   EMAIL_TO=info@deangelisbus.it,tiziana@deangelisbus.it
//   WEBHOOK_SECRET=<stessa parola usata nei trigger>
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY sono già disponibili automaticamente.

import nodemailer from 'npm:nodemailer@6.9.14';
import { createClient } from 'npm:@supabase/supabase-js@2';

const TIPI_PREVENTIVO: Record<string, string> = {
  trasferimento: 'Trasferimento', noleggio: 'Noleggio con autista', gita: 'Gita / viaggio di gruppo', altro: 'Altro',
};
const TIPI_SEGNALAZIONE: Record<string, string> = {
  suggerimento: 'Suggerimento / feedback', reclamo: 'Reclamo', segnalazione: 'Segnalazione', complimento: 'Complimento',
};

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

  if (tabella === 'segnalazioni_app') {
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
    return new Response(JSON.stringify({ ok: false, errore: String(e) }), { status: 500 });
  }

  const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const nomeTabella = tabella === 'segnalazioni_app' ? 'segnalazioni_app' : 'richieste_preventivo';
  await sb.from(nomeTabella).update({ email_inviata_il: new Date().toISOString() }).eq('id', r.id);

  return new Response(JSON.stringify({ ok: true, tabella, ...esitoSmtp }), { headers: { 'Content-Type': 'application/json' } });
});

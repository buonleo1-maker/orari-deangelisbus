// Edge Function: notifica-preventivo
// Chiamata dal Database Webhook su INSERT in richieste_preventivo.
// Invia un'email all'ufficio con i dettagli della richiesta (SMTP Aruba, porta 465 SSL).
//
// Secrets richiesti (Edge Functions > Secrets):
//   SMTP_HOST=smtps.aruba.it   SMTP_PORT=465
//   SMTP_USER=info@deangelisbus.it   SMTP_PASS=<password della casella>
//   EMAIL_TO=info@deangelisbus.it   (più indirizzi separati da virgola)
//   WEBHOOK_SECRET=<stringa casuale, uguale all'header del webhook>
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY sono già disponibili automaticamente.

import nodemailer from 'npm:nodemailer@6.9.14';
import { createClient } from 'npm:@supabase/supabase-js@2';

const TIPI: Record<string, string> = {
  trasferimento: 'Trasferimento', noleggio: 'Noleggio con autista', gita: 'Gita / viaggio di gruppo', altro: 'Altro',
};

const esc = (v: unknown) => String(v ?? '').replace(/[&<>"']/g, (c) =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));

const dataIt = (d: string | null) => (d ? d.split('-').reverse().join('/') : '—');
const ora = (t: string | null) => (t ? t.slice(0, 5) : '');

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Metodo non consentito', { status: 405 });
  if (req.headers.get('x-webhook-secret') !== Deno.env.get('WEBHOOK_SECRET')) {
    return new Response('Non autorizzato', { status: 401 });
  }

  const payload = await req.json().catch(() => null);
  const r = payload?.record;
  if (!r || payload?.type !== 'INSERT') return new Response('Nessuna richiesta', { status: 400 });

  const righe: [string, string][] = [
    ['Servizio', TIPI[r.tipo] ?? r.tipo],
    ['Partenza', r.partenza],
    ['Destinazione', r.destinazione],
    ['Andata', `${dataIt(r.data_andata)} ${ora(r.ora_andata)}`.trim()],
    ['Ritorno', r.ritorno ? `${dataIt(r.data_ritorno)} ${ora(r.ora_ritorno)}`.trim() : 'Solo andata'],
    ['Passeggeri', r.passeggeri ?? '—'],
    ['Nome', r.nome],
    ['Telefono', r.telefono],
    ['Email', r.email ?? '—'],
    ['Note', r.note ?? '—'],
  ];

  const html = `
  <div style="font-family:Arial,sans-serif;max-width:600px">
    <h2 style="color:#152538;margin:0 0 4px">Nuova richiesta di preventivo n. ${esc(r.id)}</h2>
    <p style="color:#5b6b7b;margin:0 0 16px">Inviata dall'app Orari De Angelis Bus il ${esc(new Date(r.creata_il).toLocaleString('it-IT', { timeZone: 'Europe/Rome' }))}</p>
    <table style="border-collapse:collapse;width:100%">
      ${righe.map(([k, v]) => `<tr><td style="padding:8px;border-bottom:1px solid #d6dde4;color:#5b6b7b;width:130px;vertical-align:top">${esc(k)}</td><td style="padding:8px;border-bottom:1px solid #d6dde4;font-weight:bold;white-space:pre-wrap">${esc(v)}</td></tr>`).join('')}
    </table>
    <p style="margin-top:16px"><a href="tel:${esc(String(r.telefono).replace(/\s/g, ''))}" style="background:#ffc628;color:#152538;padding:10px 16px;border-radius:6px;text-decoration:none;font-weight:bold">Chiama il cliente</a></p>
  </div>`;
  const testo = righe.map(([k, v]) => `${k}: ${v}`).join('\n');

  const transport = nodemailer.createTransport({
    host: Deno.env.get('SMTP_HOST') ?? 'smtps.aruba.it',
    port: Number(Deno.env.get('SMTP_PORT') ?? 465),
    secure: true,
    auth: { user: Deno.env.get('SMTP_USER')!, pass: Deno.env.get('SMTP_PASS')! },
  });

  try {
    await transport.sendMail({
      from: `"App Orari De Angelis Bus" <${Deno.env.get('SMTP_USER')}>`,
      to: Deno.env.get('EMAIL_TO') ?? Deno.env.get('SMTP_USER'),
      replyTo: r.email || undefined,
      subject: `Preventivo app: ${TIPI[r.tipo] ?? r.tipo} ${r.partenza} → ${r.destinazione} (${dataIt(r.data_andata)})`,
      text: testo,
      html,
    });
  } catch (e) {
    console.error('Invio email fallito:', e);
    return new Response(JSON.stringify({ ok: false, errore: String(e) }), { status: 500 });
  }

  // segna la richiesta come notificata
  const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  await sb.from('richieste_preventivo').update({ email_inviata_il: new Date().toISOString() }).eq('id', r.id);

  return new Response(JSON.stringify({ ok: true }), { headers: { 'Content-Type': 'application/json' } });
});

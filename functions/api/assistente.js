// Cloudflare Pages Function: /api/assistente
// Assistente virtuale dell'app Deangelisbus S.r.l. (Insieme in viaggio).
//
// DUE MOTORI, scelti in automatico:
//  1) GRATUITO (predefinito): Cloudflare Workers AI, modello Llama 3.3 70B.
//     Serve il collegamento "Workers AI" nelle impostazioni del progetto Pages
//     (Settings > Bindings > Add > Workers AI, nome variabile: AI).
//     Quota gratuita: 10.000 "neuroni" al giorno (circa 30-40 domande).
//  2) CLAUDE HAIKU (a pagamento, piu' preciso): basta aggiungere il segreto
//     ANTHROPIC_API_KEY (Settings > Variables and Secrets). Se c'e', si usa questo.
// Nessuna chiave arriva mai all'app.

const MODELLO = 'claude-haiku-4-5-20251001';
const MODELLO_GRATUITO = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
const MAX_MESSAGGI = 12;
const MAX_CARATTERI_MSG = 800;
const MAX_CONTESTO = 70000;

const GUIDA = `Sei l'assistente virtuale dell'app "Deangelisbus S.r.l. – Insieme in viaggio" di Deangelisbus S.r.l. (Grottole, MT, Basilicata).
Rispondi in italiano, in modo breve, chiaro e cordiale (massimo 6-8 righe), come parleresti a un passeggero anche anziano.

COSA FA L'APP (per spiegarne l'uso):
- Home: messaggio di benvenuto, riquadro "Prossimo bus" dalla fermata preferita, card "Richiedi un preventivo" (noleggio con conducente), card "Le nostre biglietterie" (biglietteria online Cotrab e biglietterie a terra), card "Viaggi di gruppo" (agenzia Ridola Viaggi), Novità ed eventi, menu dei servizi, card "Scrivici" (reclami, segnalazioni e consigli), link al sito e al parco macchine.
- Scheda "Partenze": sceglie/cambia la fermata preferita e mostra i prossimi bus di oggi o domani.
- Scheda "Da - a": scegli fermata di partenza e di arrivo e il giorno, mostra i bus diretti con durata e prezzo della corsa semplice.
- Scheda "Mappa": fermate sulla mappa, toccando una fermata si vedono le partenze.
- Scheda "Info": contatti, biglietti, preventivo, aggiornamento orari, installazione dell'app.
- "Le mie fermate": aprire una fermata e toccare "Salva tra le mie fermate" (stellina); in Home compaiono fino a 4 fermate salvate con il prossimo bus. Per toglierla si tocca di nuovo la stellina.
- "Fermate vicino a me" (in Home, sotto il prossimo bus): con il permesso alla posizione mostra le 6 fermate piu' vicine con distanza e prossimo bus. Se il permesso e' stato negato si riattiva dalle impostazioni del telefono (Posizione).
- "Condividi questo orario": aprire una corsa e toccare il pulsante verde; manda via WhatsApp/SMS un messaggio con linea, giorno, partenza, arrivo e link all'app.
- "Passa l'app a un amico" (in Home e Info): mostra un QR code da far inquadrare con la fotocamera, oppure invia il link.
- "Scopri il territorio" e "In giro con noi" (galleria foto con presentazione e musica) sono in Home.
- Menu servizi in Home: trasporto extraurbano (linee Cotrab da Grottole), scolastici, urbani, trasporto disabili Matera (su prenotazione), navetta Matera - Aeroporto di Bari (a mesi alterni), linea Matera - Policoro.
- Installare l'app: da Chrome menu (tre puntini) > "Installa app" o "Aggiungi a schermata Home"; su iPhone Condividi > "Aggiungi alla schermata Home".
- Gli orari preceduti da "~" o "circa" sono stimati: consiglia di essere alla fermata qualche minuto prima.
- Biglietti linee Cotrab: online su biglietteria.cotrab.it o app Cotrab; biglietterie a terra: Deangelisbus S.r.l. (sede di Via Arcioni 6, Grottole), Tabaccheria Faniello Antonio (Miglionico), Bar Tabaccheria Speranza Francesco (Grottole); a bordo con sovrapprezzo. Navetta aeroporto Bari: biglietti solo online su marozzivt.it.
- Preventivi noleggio: modulo "Richiedi un preventivo", risposta di solito entro 48 ore, preventivo non vincolante.

CONTATTI: tel. 0835 758126 (lun-ven 8:30-13:30 e 15:30-19:00), info@deangelisbus.it, preventivi commerciale@deangelisbus.it, sito www.deangelisbus.it.

REGOLE:
- Per orari, fermate e prezzi usa SOLO i dati in "DATI ORARI" qui sotto. Se un'informazione non c'è, dillo con franchezza e suggerisci di chiamare lo 0835 758126. Non inventare mai orari, prezzi o fermate.
- Considera giorno e ora attuali indicati nei dati quando parli di "prossimo bus".
- Non puoi prenotare, vendere biglietti o modificare niente: indica la sezione dell'app o il contatto giusto.
- Se la domanda non riguarda i servizi Deangelisbus o l'uso dell'app, rispondi gentilmente che puoi aiutare solo su questi argomenti.
- Non chiedere e non ripetere dati personali.`;

export async function onRequestPost({ request, env }) {
  if (!env.ANTHROPIC_API_KEY && !env.AI) return json({ errore: 'Assistente non configurato' }, 503);

  let corpo;
  try { corpo = await request.json(); } catch { return json({ errore: 'Richiesta non valida' }, 400); }

  const messaggi = Array.isArray(corpo?.messaggi) ? corpo.messaggi.slice(-MAX_MESSAGGI) : [];
  const contesto = typeof corpo?.contesto === 'string' ? corpo.contesto.slice(0, MAX_CONTESTO) : '';
  const adesso = typeof corpo?.adesso === 'string' ? corpo.adesso.slice(0, 120) : '';
  const puliti = messaggi
    .filter((m) => m && (m.ruolo === 'utente' || m.ruolo === 'assistente') && typeof m.testo === 'string' && m.testo.trim())
    .map((m) => ({ role: m.ruolo === 'utente' ? 'user' : 'assistant', content: m.testo.slice(0, MAX_CARATTERI_MSG) }));
  if (!puliti.length || puliti[puliti.length - 1].role !== 'user') return json({ errore: 'Nessuna domanda' }, 400);

  // --- motore gratuito: Cloudflare Workers AI ---
  if (!env.ANTHROPIC_API_KEY) {
    try {
      const out = await env.AI.run(MODELLO_GRATUITO, {
        messages: [
          { role: 'system', content: `${GUIDA}\n\nDATI ORARI (aggiornati):\n${contesto}\n\n${adesso}` },
          ...puliti,
        ],
        max_tokens: 500,
        temperature: 0.2,
      });
      const testo = (out?.response ?? '').trim();
      return json({ risposta: testo || 'Non sono riuscito a rispondere: riprova o chiama lo 0835 758126.' });
    } catch (e) {
      console.error('Errore Workers AI', e);
      return json({ risposta: 'Per oggi l\'assistente ha esaurito le risposte disponibili. Riprova domani oppure chiama lo 0835 758126: gli orari restano consultabili nell\'app.' });
    }
  }

  // --- motore Claude Haiku ---
  const risposta = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: MODELLO,
      max_tokens: 500,
      system: [
        { type: 'text', text: GUIDA },
        { type: 'text', text: `DATI ORARI (aggiornati):\n${contesto}`, cache_control: { type: 'ephemeral' } },
        { type: 'text', text: adesso || 'Ora attuale non disponibile.' },
      ],
      messages: puliti,
    }),
  });

  if (!risposta.ok) {
    console.error('Errore Anthropic', risposta.status, await risposta.text());
    return json({ errore: 'Servizio momentaneamente non disponibile' }, 502);
  }
  const dati = await risposta.json();
  const testo = (dati.content ?? []).filter((b) => b.type === 'text').map((b) => b.text).join('\n').trim();
  return json({ risposta: testo || 'Non sono riuscito a rispondere: riprova o chiama lo 0835 758126.' });
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { 'content-type': 'application/json; charset=utf-8' } });
}

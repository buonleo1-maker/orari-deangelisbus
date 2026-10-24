# Prenotazione auto e minivan (v59) – app Orari

Nuovo servizio nell'app: **"Prenota auto o minivan"**, con due scelte:
- **Dal bus a destinazione** (ultimo miglio): fermata di arrivo, corsa, destinazione, persone, bagagli, ritorno;
- **Visita medica**: indirizzo di casa, ospedale o studio, ora dell'appuntamento, attesa dell'autista, ritorno,
  esigenze (carrozzina…), possibilità di prenotare per un familiare.

Il cliente lo trova in Home (riquadro "Ti portiamo dove il bus non arriva") e in Informazioni.
A ogni prenotazione: **email all'ufficio** e **notifica sul telefono degli amministratori**;
nel gestionale la si gestisce dalla nuova pagina **App Orari → Prenotazioni auto** (pacchetto del gestionale).

## File in questo pacchetto

| File | Cosa fa |
|---|---|
| `sql/orari_deangelisbus_v59_prenotazioni_auto.sql` | NUOVO – tabella `prenotazioni_auto`, permessi, avviso automatico |
| `supabase/functions/notifica-preventivo/index.ts` | aggiornata: email delle prenotazioni + notifica agli amministratori |
| `notifica-preventivo-codice.txt` | lo stesso codice della funzione, in un file di testo facile da aprire |
| `src/screens/PrenotaAuto.tsx` | NUOVO – il modulo di prenotazione |
| `src/components/CardPrenotaAuto.tsx` | NUOVO – il riquadro in Home |
| `src/App.tsx`, `src/lib/data.ts`, `src/screens/Home.tsx`, `src/screens/Info.tsx`, `src/styles.css` | collegamenti e stili |

## Passo 1 – Database

1. Supabase > **SQL Editor** > **New query**.
2. Incolla il contenuto di `sql\orari_deangelisbus_v59_prenotazioni_auto.sql` e premi **Run**.
3. In fondo deve comparire "prenotazioni_auto pronta".
   Lo script copia da solo la parola segreta già usata per le email dei preventivi.

## Passo 2 – Aggiorna la funzione delle email

1. Supabase > **Edge Functions** > `notifica-preventivo` > scheda **Code** (o "Edit").
2. Apri `notifica-preventivo-codice.txt` con un doppio clic, **Ctrl+A**, **Ctrl+C**.
3. Nell'editor di Supabase cancella tutto e premi **Ctrl+V**, poi **Deploy**.

Le email dei preventivi e delle segnalazioni continuano a funzionare come prima.

## Passo 3 – Pubblica l'app

1. Menu Strumenti, voce **2 – Aggiorna tutto**.
2. Estrai questo zip in `C:\DEANGELISBUS\orari-deangelisbus`, sostituendo i file.
3. Voce **4 – Pubblica l'app Orari**.
4. Voce **3 – Salva tutto su GitHub**.

## Passo 4 – Prova

1. Installa prima il pacchetto del gestionale (pagina Prenotazioni auto).
2. Dall'app invia una prenotazione di prova (con il tuo nome e la scritta PROVA nelle note).
3. Controlla che arrivino l'**email** e la **notifica sul telefono**, e che la prenotazione compaia nel gestionale.
4. Eliminala dal gestionale.

## Se la notifica sul telefono non arriva

- La ricevono solo gli amministratori che hanno l'**app degli autisti** sul telefono con le notifiche attive
  (sono gli stessi che ricevono le notifiche dei turni).
- In Supabase > Edge Functions > `notifica-preventivo` > **Logs** cerca "Notifica amministratori":
  - "nessun amministratore con le notifiche attive" → apri l'app autisti sul telefono e consenti le notifiche;
  - stato 403 → la chiave di servizio di Supabase non coincide con quella impostata su Cloudflare:
    in Supabase > Edge Functions > **Secrets** aggiungi `PUSH_SERVICE_KEY` con lo stesso valore della variabile
    `SUPABASE_SERVICE_KEY` del progetto Cloudflare `amministrazione-deangelisbus-v2`.

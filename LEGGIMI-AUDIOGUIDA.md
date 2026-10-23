# Audioguida GPS – bus panoramico dei Sassi (v56)

Il passeggero apre l'audioguida, sceglie la lingua (italiano, inglese, tedesco, francese, spagnolo) e tocca **Avvia**.
Quando il bus arriva vicino a un luogo, il racconto parte da solo. Le tappe si possono anche toccare per ascoltarle subito.

## File in questo pacchetto

| File | Cosa fa |
|---|---|
| `sql/orari_deangelisbus_v56_audioguida.sql` | NUOVO – tabella `audioguida_tappe` con le 7 tappe in 5 lingue, spazio per i file audio |
| `src/lib/audioguida.ts` | NUOVO – lingue, testi dei pulsanti, lettore vocale |
| `src/screens/Audioguida.tsx` | NUOVO – la schermata dell'audioguida |
| `src/components/CardAudioguida.tsx` | NUOVO – il riquadro "Audioguida dei Sassi" |
| `src/App.tsx` | collegamento della schermata e del link `?apri=audioguida` |
| `src/lib/types.ts`, `src/lib/data.ts` | lettura della nuova tabella |
| `src/screens/Home.tsx`, `src/screens/Territorio.tsx` | riquadro audioguida in Home e in "Scopri il territorio" |
| `src/styles.css` | stili dell'audioguida (in fondo al file) |
| `stampa/qr-audioguida.png` | QR code da mettere sul bus: apre direttamente l'audioguida |

## Passo 1 – Copia i file

1. Dal menu Strumenti fai la voce **2 – Aggiorna tutto**.
2. Estrai questo zip dentro `C:\DEANGELISBUS\orari-deangelisbus`.
3. Quando Windows chiede, scegli **Sostituisci i file nella destinazione**.

## Passo 2 – Prepara il database

1. Apri Supabase > **SQL Editor** > **New query**.
2. Apri `sql\orari_deangelisbus_v56_audioguida.sql` con il Blocco note, copia tutto e incollalo.
3. Premi **Run**. In fondo deve comparire l'elenco delle 7 tappe.

## Passo 3 – Controlla le coordinate (importante)

Le coordinate delle tappe sono **approssimative**. Vanno controllate una per una:

1. Su Google Maps tieni premuto (o tasto destro) sul punto della strada dove deve partire il racconto: in alto compaiono le coordinate, per esempio `40.6638, 16.6094`.
2. In Supabase apri **Table Editor** > `audioguida_tappe` e correggi `lat` (primo numero) e `lon` (secondo numero).
3. `raggio_m` è la distanza in metri a cui parte il racconto: 150 va bene in città. Se due luoghi sono vicini, abbassalo a 80–100.

Le tappe con `lat` e `lon` vuoti ("Da vergogna nazionale…" e "Matera e il cinema") non hanno un punto: partono subito dopo la tappa che le precede nell'ordine.

I testi si correggono nello stesso modo, nelle colonne `testo_it`, `testo_en`, `testo_de`, `testo_fr`, `testo_es`. La modifica arriva sui telefoni senza ripubblicare l'app.

## Passo 4 – Pubblica e prova

1. Menu Strumenti, voce **4 – Pubblica l'app Orari**.
2. Sul telefono apri **Chrome** all'indirizzo `https://orari.deangelisbus.it/?apri=audioguida`.
3. Scegli la lingua e tocca **Avvia l'audioguida**: senti "Audioguida attiva".
4. Lontano da Matera, prova toccando le tappe nell'elenco. A Matera, sul bus, verifica che ogni racconto parta nel punto giusto.
5. Se tutto va bene: voce **3 – Salva tutto su GitHub**.

## Passo 5 – App Android (Play Store)

Sul PC con Android Studio:

```powershell
cd C:\DEANGELISBUS\orari-deangelisbus
npm.cmd run build
npx.cmd cap sync android
npx.cmd cap open android
```

Poi prova sul telefono con il tasto Play verde, come al solito.

## Cose da sapere

- **Voce**: l'audioguida usa la voce del telefono. In Chrome funziona bene. Dentro l'app Android alcuni telefoni non hanno la lettura vocale: in quel caso il racconto compare scritto. Il passo successivo è registrare i file audio con voce AI: basta caricarli nel bucket `audioguida` di Supabase Storage e scrivere il nome del file nelle colonne `audio_it`, `audio_en`… (per esempio `panoramico-matera/0-it.mp3`). L'app li usa da sola al posto della voce del telefono.
- **Schermo acceso**: mentre l'audioguida è attiva l'app tiene lo schermo acceso. Se il passeggero esce per fare foto, al ritorno ritrova l'audioguida com'era.
- **QR code**: `stampa\qr-audioguida.png` va stampato e messo sul bus panoramico, con la scritta "Audioguida gratuita – 5 lingue".
- **Gestionale**: la pagina per gestire le tappe nel gestionale arriverà con il prossimo pacchetto; nel frattempo si usa il Table Editor di Supabase.

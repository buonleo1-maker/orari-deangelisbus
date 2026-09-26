# Orari De Angelis Bus

App pubblica con linee, fermate, orari e tariffe dei servizi De Angelis Bus.
React + TypeScript + Vite, dati su Supabase (tabelle `orari_*`), app Android con Capacitor.

L'app funziona anche senza Internet: include una copia degli orari (`src/data/snapshot.json`)
e salva sul telefono l'ultima versione scaricata da Supabase.

## 1. Preparare il database (una volta sola)

In Supabase > SQL Editor esegui, in quest'ordine:

1. `sql/orari_deangelisbus_setup.sql`
2. `sql/orari_deangelisbus_v2_servizi.sql`
3. `sql/orari_deangelisbus_v3_nuovi_servizi.sql`
4. `sql/orari_deangelisbus_v4_colori_preventivi.sql`

## Logo

Il marchio è già incluso in `src\assets\` (versione bianca e blu, ricavate da logo.jpg).
Icone e schermata di avvio Android si generano da `assets\logo.png` (marchio bianco su sfondo trasparente).

## Richieste di preventivo

Le richieste inviate dall'app finiscono nella tabella `richieste_preventivo` su Supabase
(Table Editor). L'app può solo inserirle: nessuno può leggerle dall'app.
Il link all'informativa privacy è in `src/screens/Preventivo.tsx`: controlla che punti alla pagina giusta del sito.

## 2. Provare l'app sul PC

Su Windows/PowerShell usa `npm.cmd` e `npx.cmd` (oppure `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`).

```powershell
cd C:\DEANGELISBUS\orari-deangelisbus
copy .env.example .env        # poi apri .env e incolla la "anon public key" di Supabase
npm.cmd install
npm.cmd run dev               # apri l'indirizzo che compare (es. http://localhost:5173)
```

Nel browser premi F12 e attiva la vista smartphone per vederla come sul telefono.

## 3. Creare l'app Android

Serve Android Studio installato (include Java e SDK Android).

```powershell
npm.cmd run build
npx.cmd cap add android       # solo la prima volta: crea la cartella android\
npx.cmd cap sync android
npx.cmd cap open android      # apre il progetto in Android Studio
```

In Android Studio:

1. Aspetta che finisca "Gradle sync".
2. Per provarla: collega il telefono con il debug USB attivo e premi il tasto Play verde.
3. Per il Play Store: menu **Build > Generate Signed App Bundle or APK > Android App Bundle**,
   crea una nuova chiave (keystore) e **conservala con cura insieme alla password**:
   senza quella non potrai più pubblicare aggiornamenti.
4. Il file `.aab` finisce in `android\app\release\`.

Icone e schermata di avvio: `npx.cmd @capacitor/assets generate --android --iconBackgroundColor "#020a5d" --iconBackgroundColorDark "#020a5d" --splashBackgroundColor "#020a5d" --splashBackgroundColorDark "#020a5d"`.

Ad ogni modifica del codice: `npm.cmd run build` e poi `npx.cmd cap sync android`.
Per cambiare solo gli orari **non serve** ripubblicare l'app: basta modificare le tabelle su Supabase.

## 4. Pubblicare sul Play Store

1. Account Google Play Console come organizzazione De Angelis Bus S.R.L. (serve il numero D-U-N-S).
2. Crea l'app "Orari De Angelis Bus", categoria Viaggi e informazioni locali, gratuita.
3. Compila: privacy policy (pagina sul sito), sicurezza dei dati (l'app non raccoglie dati personali),
   classificazione dei contenuti, pubblico di destinazione.
4. Carica icona 512x512, grafica in evidenza 1024x500 e almeno 2 screenshot del telefono.
5. Carica il file `.aab` in un rilascio (prima "Test interno", poi "Produzione").

## 5. Versione web (PWA installabile)

La stessa app si può pubblicare come sito, come il gestionale:

```powershell
npm.cmd run build
npx.cmd wrangler pages deploy dist --project-name=orari-deangelisbus --branch=main
```

Indirizzo pubblico: https://orari.deangelisbus.it (dominio personalizzato del progetto Pages, record CNAME `orari` -> `orari-deangelisbus.pages.dev`).
La cartella `stampa/` contiene QR code e locandina A4.

## Note

- Mappa: usa le mappe OpenStreetMap. Per un uso intenso in produzione conviene un fornitore
  di mappe con chiave (es. MapTiler, piano gratuito) al posto di `tile.openstreetmap.org` in `src/screens/Mappa.tsx`.
- Le fermate senza coordinate compaiono negli orari ma non sulla mappa.
- Gli orari con `~` o "circa" sono quelli con `minuti` vuoto nel database (stimati dai km).

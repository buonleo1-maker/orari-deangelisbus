# Lavorare da qualsiasi PC (casa, ufficio) + chiavetta USB

Tutto il codice sta su **GitHub** (privato). Ogni PC ne ha una copia; la chiavetta USB e' solo una **copia di sicurezza**.

| Cosa | Dove sta | Come si aggiorna |
|---|---|---|
| App Orari (codice) | GitHub `orari-deangelisbus`, ramo **main** | menu voci 2 / 3 |
| Gestionale (codice) | GitHub `deangelisbus-gestionale`, ramo **master** | menu voci 2 / 3 |
| Dati (orari, preventivi, novita', noleggi...) | Supabase (online) | sempre aggiornati, da qualsiasi PC |
| Siti online | Cloudflare Pages | menu voci 4 / 5 |
| Password SMTP, chiavi segrete | Supabase > Edge Functions > Secrets, Cloudflare | non stanno sui PC |
| File `.env` (chiave pubblica Supabase) | solo sui PC, mai su GitHub | lo crea la voce 1 |

## Cartelle standard (uguali su tutti i PC)

- App Orari: `C:\DEANGELISBUS\orari-deangelisbus`
- Gestionale: `C:\DEANGELISBUS\2-SORGENTE-APP\2-SORGENTE-APP` (l'app da compilare e' nella sottocartella `2-SORGENTE-APP`)

## Su un PC nuovo (una volta sola)

1. Installa **Git** (git-scm.com) e **Node.js LTS** (nodejs.org).
2. In PowerShell:
   ```
   mkdir C:\DEANGELISBUS -ErrorAction SilentlyContinue
   git clone https://github.com/buonleo1-maker/orari-deangelisbus.git C:\DEANGELISBUS\orari-deangelisbus
   ```
3. Apri `C:\DEANGELISBUS\orari-deangelisbus\strumenti` e fai doppio clic su **DeAngelisBus-Strumenti.bat**.
4. Scegli **1** (prima installazione), poi **8** (collegamento sul Desktop).

## Ogni giorno, su qualsiasi PC

1. **Inizio**: voce **2 - Aggiorna tutto**
2. lavori...
3. **Fine**: voce **3 - Salva tutto su GitHub** (sempre, prima di cambiare PC)

Per pubblicare: voce **4** (app Orari) o **5** (gestionale). Il menu controlla da solo che il `.env` sia giusto
prima di pubblicare, cosi' non si rischia di mettere online un sito senza chiavi.

Copia di sicurezza: voce **6** (chiavetta USB, cartella `DEANGELISBUS-COPIA`).

## Regole d'oro

- Mai lavorare direttamente sulla chiavetta: e' solo un backup.
- Sempre **Aggiorna** prima di iniziare e **Salva** prima di cambiare PC.
- L'app Android (Android Studio) va compilata solo sul PC dove e' installato Android Studio.

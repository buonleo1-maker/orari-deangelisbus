-- =====================================================
-- ORARI DE ANGELIS BUS / GESTIONALE – v18: sezione "Manuali e operatività" del gestionale.
-- Documenti in markdown, letti da tutti gli utenti collegati, modificabili solo dagli admin.
-- I documenti iniziali vengono inseriti solo se non esistono ancora (rieseguibile senza sovrascrivere).
-- =====================================================
create table if not exists manuali (
  id bigint generated always as identity primary key,
  slug text unique not null,
  titolo text not null check (char_length(titolo) between 2 and 120),
  categoria text not null default 'manuale' check (categoria in ('manuale','operativita')),
  contenuto text not null default '',
  ordine int not null default 0,
  aggiornato_il timestamptz not null default now(),
  aggiornato_da text
);
alter table manuali enable row level security;
drop policy if exists "lettura utenti" on manuali;
create policy "lettura utenti" on manuali for select to authenticated using (true);
drop policy if exists "admin gestiscono" on manuali;
create policy "admin gestiscono" on manuali for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant select, insert, update, delete on manuali to authenticated;





insert into manuali (slug, titolo, categoria, ordine, contenuto) values ('manuale-gestionale', 'Manuale del Gestionale', 'manuale', 1, $md$# Manuale del Gestionale Deangelisbus

Versione 5.0 — Ottobre 2026. Unisce il Manuale Utente v4.1 (giugno 2026) e il Manuale Amministratore v2.2 (maggio 2026), aggiornati con i moduli arrivati dopo: Noleggi, Scadenzario, Gestione ferie, sincronizzazioni automatiche, pagine App Orari e questa sezione Manuali.

## 1. Introduzione

DEANGELISBUS è il sistema gestionale web di De Angelis Bus S.r.l. per il trasporto pubblico locale (TPL) e il noleggio con conducente (NCC). È composto da due applicazioni, usabili da qualsiasi browser o installabili come app sul telefono.

| Applicazione | A chi serve | Indirizzo |
| --- | --- | --- |
| Gestionale (amministrazione) | Amministrazione e responsabili | amministrazione-deangelisbus-v2.pages.dev |
| App Autista | Autisti, ottimizzata per smartphone | deangelisbussrl-app.pages.dev (vedi il Manuale App Autisti) |
| Login | Email e password; le credenziali degli autisti si creano dalla sezione Autisti | — |

**Installare il gestionale sul telefono.** Android: Chrome → tre puntini → **Aggiungi a schermata Home**. iPhone: Safari → **Condividi** → **Aggiungi alla schermata Home**. Usare sempre l'indirizzo principale: gli indirizzi con un codice davanti (es. `abc123.amministrazione-…`) restano fermi a una vecchia versione.

**Permessi.** Le funzioni di modifica sono riservate agli utenti **amministratori**; chi non ha quel ruolo vede le pagine ma non può salvare.

## 2. Dashboard e navigazione

La dashboard è la schermata principale; il menu laterale porta a tutte le sezioni.

| Statistica | Significato |
| --- | --- |
| Da verificare | Fogli di viaggio compilati dall'autista che attendono la verifica |
| Fogli mese | Fogli di viaggio creati nel mese |
| Fatturato mese | Somma dei totali servizio dei fogli del mese |
| Manutenzioni | Manutenzioni dei veicoli in scadenza nei prossimi 30 giorni |
| Preventivi attivi | Preventivi inviati in attesa di risposta |

**Ricerca globale**

1. Scrivi almeno 2 caratteri nella barra di ricerca sotto l'intestazione.
2. I risultati compaiono subito: autisti, veicoli, committenti, fogli di viaggio, preventivi.
3. Clicca un risultato per aprire la pagina; **X** cancella la ricerca.

La ricerca trova cognome dell'autista, targa, nome del committente, numero del foglio o del preventivo e oggetto del servizio.

**Aree del menu**

| Area | Sezioni |
| --- | --- |
| Autisti e turni | Autisti, Presenze, Richieste, Report autista, Calendario turni, Carica turni, Turni TPL, Turni ricorrenti, Planning turni, Riposi, Gestione ferie, Scadenze autisti |
| Veicoli e operatività | Veicoli, Rifornimenti, Carichi serbatoio, Manutenzioni, Anomalie, Report veicolo, Fogli di viaggio, Archivio |
| Commerciale | Committenti, Preventivi, Fatture proforma, Feedback clienti, Biglietti, Report incassi, Noleggi |
| Amministrazione | Scadenzario, Report ed export, Statistiche, Impostazioni |
| Comunicazioni | Chat, notifiche agli autisti |
| App Orari | Linee e orari, Novità, Notifiche, Richieste preventivo, Segnalazioni, Territorio, Foto, Fermate |
| Manuali e operatività | Manuali e procedure operative |

## 3. Turni

### 3.1 Calendario turni

1. Menu → **Calendario turni** → scegli la settimana con le frecce.
2. Clicca la cella autista × giorno per assegnare un turno.
3. Scegli il tipo: **TPL**, **NCC**, **Assenza** o **Vuoto**.
4. Scegli il turno dal catalogo oppure inserisci orari personalizzati.
5. Salva: la **presenza** viene creata in automatico (il tipo TPL/NCC/assenza deriva dalla descrizione del turno).

I turni "Vuoto" (Disposizione, Garage, Scuole) non generano presenza e non compaiono nel report autista.

### 3.2 Caricare i turni della settimana da file

1. La Titolare prepara i turni in Word e li salva in **PDF** (2 pagine A4 orizzontali; la seconda pagina senza intestazione).
2. Menu → **Carica turni** → carica il PDF. Il PDF deve avere il **testo selezionabile**: immagini, foto e screenshot vengono rifiutati.
3. Controlla l'anteprima: verifica che i nomi degli autisti siano abbinati correttamente.
4. **Importa**: i turni vengono salvati senza cancellare le presenze dei giorni passati, e ogni autista riceve la notifica del turno assegnato.

### 3.3 Turni TPL e turni ricorrenti

- **Turni TPL**: archivio dei turni ufficiali con codice, linee servite, km e frequenza.
- **Turni ricorrenti**: catalogo dei turni con orari fissi (es. "1 NAVETTA/1 TURNO" = 04:00–15:00). Creando un turno con la stessa descrizione gli orari si compilano da soli; i turni nuovi vengono aggiunti al catalogo in automatico.

### 3.4 Planning turni (archivio settimanale)

1. Menu → **Planning turni** → **Archivia settimana**: si propone la settimana corrente; il sistema recupera i turni dal Calendario → **Archivia**.
2. Clicca una settimana archiviata per vederla; **Stampa / PDF** genera il prospetto aziendale (A3 orizzontale, autisti in righe e giorni in colonne).
3. **Invia in chat**: il planning arriva a tutti gli autisti come messaggio con link, con notifica push; dal telefono si apre una tabella ottimizzata.
4. Il planning evidenzia in rosso gli autisti con riposo insufficiente.

### 3.5 Riposi e conformità (Reg. CE 561/2006)

Menu → **Riposi e conformità**: elenco degli autisti con avvisi sul riposo giornaliero e settimanale. Tra un turno e l'altro servono almeno 11 ore consecutive di riposo; il sistema segnala le violazioni. Gran parte del servizio TPL rientra nell'esenzione prevista dal regolamento (art. 3a) e viene trattata di conseguenza.

## 4. Presenze, richieste e ferie

### 4.1 Presenze

1. Menu → **Presenze** → scegli mese e autista.
2. Per ogni giorno la griglia mostra **Programmato** (dal turno) ed **Effettivo** (inserito dall'autista; se modificato appare in arancione con la matita).
3. Clicca una cella per cambiare lo stato o inserire gli orari effettivi. Stati: Presente, Assente, Ferie, Malattia, Infortunio, Permesso, Festivo, Riposo. Lo stato della presenza è **provvisoria** finché non viene confermata.

Tipi: TPL (T), NCC (N), riposo/ferie/malattia senza tipo. Se un autista ha riposo programmato ma viene creato un foglio di viaggio NCC per lo stesso giorno, la presenza diventa NCC in automatico. I veicoli usati e i km vengono registrati insieme alla presenza.

### 4.2 Richieste di ferie e permessi

1. Menu → **Richieste**: le richieste in attesa hanno il badge arancione.
2. Apri la richiesta → **Approva** o **Rifiuta**, con nota facoltativa.
3. L'autista riceve subito la notifica.

### 4.3 Gestione ferie

1. Menu → **Gestione ferie** → scegli l'autista.
2. La dotazione annua segue il livello CCNL (fasce di 31/32 giorni); i saldi iniziali sono caricati come rettifiche; il calcolo vale anche su più anni.
3. Per il primo semestre 2026 fanno fede le schede cartacee; dal luglio 2026 fa fede il gestionale.

## 5. Fogli di viaggio (NCC)

### 5.1 Ciclo di vita

| Stato | Significato |
| --- | --- |
| Bozza | Creato ma non inviato: lo vede e lo modifica solo l'amministrazione |
| Inviato autista | Visibile all'autista, che lo compila a fine servizio |
| Compilato autista | L'autista ha inserito orari e spese: va verificato |
| Verificato | Dati controllati, pronto per l'archiviazione |
| Archiviato | Chiuso definitivamente, solo consultazione |

### 5.2 Creare un foglio

1. Menu → **Fogli di viaggio** → **Nuovo foglio**.
2. Oggetto del servizio (es. "Gita scolastica Roma"), committente dall'anagrafica (i dati fiscali si compilano da soli) o dati manuali, date di partenza e rientro.
3. Autista principale e veicolo.
4. **Programma giorni**: ogni giornata con data, orari e destinazione (obbligatori prima dell'invio).
5. Totale servizio (importo da fatturare).
6. **Salva come bozza** oppure **Invia all'autista** (l'autista riceve la notifica).

### 5.3 Verificare un foglio compilato

1. Dashboard → contatore **Da verificare** → apri il foglio.
2. Controlla km effettivi, orari e spese con le foto degli scontrini.
3. **Analizza AI** (viola): valutazione automatica di orari anomali, km incoerenti e spese fuori norma (OK / DA VERIFICARE / ATTENZIONE).
4. **Note e comunicazioni**: chiarimenti con l'autista, che riceve la notifica.
5. **Verifica** per approvare; facoltativo **Richiedi feedback** al committente; **Archivia** per chiudere. Un foglio chiuso si può riaprire con **Riapri**.

### 5.4 Duplicare un foglio

Nella riga del foglio clicca l'icona copia: nasce una nuova bozza con prefisso "COPIA - "; cambia date e dettagli. Utile per committenti abituali con gli stessi percorsi.

### 5.5 Fogli di viaggio dal CRM

I fogli di viaggio del CRM vtenext vengono sincronizzati nel gestionale in sola lettura (solo i dati di testata). In caso di differenze vale il CRM.

## 6. Veicoli e operatività

- **Manutenzioni**: Menu → Veicoli → Manutenzioni → **Nuova manutenzione**: veicolo, tipo (tagliando, revisione, assicurazione, bollo, tachigrafo…), data intervento, scadenza, km, costo, officina. Colori: verde oltre 90 giorni, arancione sotto 30, rosso scaduta.
- **Rifornimenti**: registro carburante con calcolo km/litro per veicolo e report mensile, filtri ed export CSV.
- **Carichi serbatoio**: registro dei carichi del serbatoio del deposito.
- **Anomalie veicoli**: segnalazioni degli autisti con urgenza bassa/media/alta; con urgenza alta arriva subito una notifica.
- **Report veicolo**: scegli veicolo e periodo (mese, anno, tutto): rifornimenti, litri, km, media km/l, costi di manutenzione, viaggi NCC; **Analizza AI** sui consumi; **Export CSV**.
- **Km da Golia**: le letture dei km arrivano ogni giorno dagli export del portale Golia (cartella Drive "Golia – Export").
- Veicoli, rifornimenti, carichi serbatoio e manutenzioni del CRM vtenext si sincronizzano ogni notte.

## 7. Autisti

**Creare un autista**

1. Menu → **Autisti** → **Nuovo autista**: nome, cognome, email (valida e univoca: serve per login e notifiche), telefono.
2. Spunta **Crea account**: la password viene generata in automatico.
3. Annota la password e comunicala all'autista: dopo non è più recuperabile.

**Scadenze documenti**: Menu → **Scadenze autisti** → **Nuovo documento**: autista, tipo (patente, CQC, carta tachigrafica, visita medica…), numero, rilascio, scadenza. I documenti in scadenza entro 30 giorni compaiono in dashboard.

**Report mensile autista**: Menu → **Report autista** → autista e mese → giorni lavorati, ore effettive, tipo giornate, indennità di trasferta → **Export Excel** per il consulente del lavoro.

## 8. Commerciale

### 8.1 Flusso completo

| Passo | Cosa si fa |
| --- | --- |
| 1 Anagrafica | Creare il committente con tutti i dati fiscali |
| 2 Preventivo | Creare il preventivo (manuale o con AI) e inviarlo via email con PDF |
| 3 Accettazione | Il cliente accetta online dal link, oppure l'accettazione si registra a mano |
| 4 Foglio di viaggio | Convertire il preventivo in foglio con un clic, assegnare autista e veicolo |
| 5 Esecuzione | Inviare il foglio all'autista, che lo compila a fine servizio |
| 6 Verifica | Verificare il foglio, anche con Analizza AI |
| 7 Feedback | Chiedere la valutazione al cliente |
| 8 Fatturazione | Convertire il preventivo in fattura proforma |

### 8.2 Committenti

Menu → **Committenti** → **Nuovo cliente**: denominazione, P.IVA, codice fiscale, SDI/PEC, indirizzo, email, telefono, referente. Inserire sempre l'email: serve per preventivi, proforma e feedback.

### 8.3 Preventivi

1. Menu → **Preventivi** → **Nuovo preventivo**.
2. Manuale: committente, oggetto, tratta, tipo veicolo, voci di costo. Oppure **Genera con AI**: descrivi il servizio a parole (es. "Gita scolastica Roma 2 giorni 50 studenti pullman GT partenza Matera 10 giugno") e l'AI compila oggetto, tratta, veicolo e una stima dell'importo, da verificare sempre.
3. **Calendario giorni**: ogni giornata con data, partenza, arrivo, veicolo.
4. Salva e clicca l'aeroplano: il PDF viene generato e inviato al cliente, che può accettare o rifiutare dal link.
5. Accettazione manuale: icona utente-spunta → email e metodo. Rifiuto: X rossa. Un preventivo senza risposta dopo la validità va messo in "Scaduto"; i rifiutati restano in archivio e si possono duplicare con prezzi aggiornati.
6. Dal preventivo accettato: icona mappa verde → **foglio di viaggio** precompilato; icona documento viola → **fattura proforma** con i dati fiscali del committente.

### 8.4 Fatture proforma

Menu → **Fatture proforma** → apri la fattura → modifica se serve → **Stampa/PDF**. La proforma si crea dal preventivo, così mantiene gli importi concordati. La fattura elettronica resta sul software contabile esterno.

### 8.5 Feedback clienti

1. Sul foglio verificato o archiviato clicca **Richiedi feedback** (serve l'email del committente).
2. Il cliente valuta servizio e autista con le stelle, senza login.
3. Menu → **Feedback clienti**: valutazioni, medie e statistiche; **Rispondi al cliente** pubblica una risposta.

### 8.6 Biglietti TPL e incassi

Gli autisti registrano le vendite per comune e tipo di biglietto; **Report incassi** riepiloga per linea.

### 8.7 Noleggi

1. Menu → **Noleggi**: archivio dei noleggi dal 2022 (oltre 3.400) con ricerca e filtri.
2. **Sincronizza da Drive** importa le modifiche fatte nei file Excel "SCHEDA NOLEGGI": in caso di differenze vince sempre l'Excel.
3. Le richieste di preventivo arrivate dall'app Orari diventano noleggi con **Crea noleggio** (pagina Richieste preventivo).

## 9. Scadenzario

1. Menu → **Scadenzario** → nuova scadenza: categoria (fiscale, gara, assicurazione, contratto, altro), data, giorni di preavviso, eventuale ricorrenza, responsabile.
2. Le scadenze in arrivo vengono segnalate ogni giorno in automatico.
3. A cosa fatta, aggiorna lo stato.

## 10. Comunicazioni

**Chat**

1. Seleziona l'autista dall'elenco a sinistra e scrivi.
2. Messaggi **urgenti** in rosso con badge URGENTE; **Broadcast** per scrivere a tutti gli autisti insieme; cestino per eliminare un messaggio.
3. I link nei messaggi sono cliccabili (per esempio il planning).

**Notifiche push agli autisti**: ogni messaggio, turno assegnato, foglio di viaggio e risposta a una richiesta genera una notifica sul telefono dell'autista, anche ad app chiusa. Ogni autista riceve le notifiche su un solo telefono: l'ultimo da cui ha fatto l'accesso.

## 11. Report, export e impostazioni

- **Report autista**: export in Excel separati per autista, **PRESENZE1** (tutti gli autisti in un file) e **CSV consulente**. Il calcolo delle indennità TPL/NCC usa gli orari effettivi se inseriti, altrimenti quelli programmati.
- **Report ed export**: report con filtri ed Excel multi-foglio; **Statistiche** con grafici.
- **Backup mensile**: 5 CSV via email (presenze, fogli di viaggio, biglietti, manutenzioni, rifornimenti); l'indirizzo si imposta in Impostazioni.
- **Impostazioni**: email del backup, indennità di trasferta, rimborso km, credenziali degli autisti.

## 12. Assistente AI

Il pulsante **Assistente** in basso a destra risponde in italiano usando i dati reali del database.

| Per | Scrivi |
| --- | --- |
| Autista | Il cognome esatto come in anagrafica (es. "Armandi") |
| Veicolo | Il nome esatto come in anagrafica (es. "Mercedes Sprinter") |
| Data | GG/MM o GG/MM/AAAA |
| Mese | "maggio 2026" o "maggio" |

Esempi: "Quanti km ha il bus Mercedes?", "Armandi il 01/05 lavorava?", "Rossi era in ferie il 15 maggio?", "Come si duplica un foglio?". Nelle pagine ci sono anche **Analizza AI** (fogli di viaggio e consumi dei veicoli) e **Genera con AI** (preventivi).

## 13. App Orari e Manuali

- **App Orari**: le otto pagine (Linee e orari, Novità app, Notifiche app, Richieste preventivo, Segnalazioni app, Territorio: cosa mangiare, Foto: in giro con noi, Fermate: posizione) sono descritte nel **Manuale App Orari**.
- **Manuali e operatività**: questa sezione. Gli amministratori possono modificare i manuali (**Modifica**, con anteprima) e aggiungere procedure operative (**Nuovo documento**); **Stampa / PDF** stampa il documento aperto.

## 14. Sincronizzazioni automatiche

| Cosa | Da dove | Quando |
| --- | --- | --- |
| Veicoli, rifornimenti, carichi serbatoio, manutenzioni | CRM vtenext | Ogni notte |
| Fogli di viaggio | CRM vtenext | Su richiesta, solo le modifiche |
| Noleggi | File Excel su Google Drive | Pulsante Sincronizza da Drive |
| Km dei veicoli | Export di Golia nella cartella Drive "Golia – Export" | Ogni giorno |
| Avvisi dello Scadenzario | Scadenze inserite | Ogni giorno |

## 15. Problemi frequenti

| Problema | Soluzione |
| --- | --- |
| Pagina bianca dopo il login | Ctrl+Shift+R; se persiste, Esci, chiudi il browser e riapri |
| Sul telefono mancano le pagine nuove | Usa l'icona creata dall'indirizzo principale; elimina le icone vecchie; cancella i dati dell'app e riaccedi |
| Notifiche agli autisti non arrivano | L'autista deve toccare il banner "Abilita notifiche"; su iPhone l'app va installata dalla schermata Home con Safari |
| L'autista non vede il foglio | Il foglio deve essere "Inviato autista": in bozza lo vede solo l'amministrazione |
| L'autista non può modificare il foglio | I fogli compilati, verificati o archiviati sono bloccati: usa **Riapri** |
| Il preventivo non arriva al cliente | Controlla l'email in anagrafica e la cartella spam del cliente |
| Il PDF del preventivo non si apre | Il browser blocca i popup: abilitali per il dominio del gestionale |
| L'assistente non trova l'autista | Cognome esatto, attenzione ai cognomi composti (es. "De Angelis") |
| Errore "null value" | Mancano campi obbligatori (con asterisco) |
| Il caricamento turni rifiuta il file | Il PDF deve avere il testo selezionabile, non essere una scansione o una foto |
| Upload foto scontrino fallisce | Controlla la connessione; foto JPG/PNG sotto i 5 MB |
| Il gestionale non salva | L'utente non è amministratore |

## 16. Requisiti tecnici

| Voce | Dettaglio |
| --- | --- |
| Browser | Chrome 90 o superiore consigliato; Firefox, Safari, Edge recenti |
| Smartphone | Android 8 o superiore con Chrome; iPhone iOS 14 o superiore con Safari |
| Connessione | Necessaria per tutte le funzioni |
| Tecnologia | React + TypeScript + Vite, database Supabase (PostgreSQL), Cloudflare Pages, notifiche Firebase, email Resend, assistente Claude (Anthropic), app Android con Capacitor |

Aggiornamenti e pubblicazione si fanno dal **menu Strumenti**: sempre voce 2 all'inizio, voce 3 alla fine, e voce 2 prima della voce 5 (pubblica il gestionale).

## 17. Backup e ripristino

Tutti i dati del gestionale (turni, presenze, ferie, autisti, veicoli, noleggi, preventivi, fogli di viaggio, scadenze, orari dell'app e ogni altra tabella) vengono copiati **ogni notte** in un file compresso, in uno spazio privato visibile solo agli amministratori. Si conservano le copie degli **ultimi 30 giorni** e **una copia per ogni mese, per sempre**. Le tabelle nuove entrano nel backup da sole.

**Pagina Backup e ripristino**

1. In alto il riquadro **verde** indica la data dell'ultimo backup, quanti record contiene e quante copie sono conservate. Se diventa **giallo**, l'ultimo backup ha più di un giorno: premere **Fai un backup adesso** e avvisare chi segue la parte tecnica.
2. **Fai un backup adesso**: copia immediata, utile prima di un'operazione importante (per esempio un caricamento grosso di dati).
3. **Scarica**: salva sul computer il file della copia.
4. **Consulta**: si sceglie una tabella e si vedono i dati **com'erano in quella data**, con la ricerca e il pulsante **Scarica per Excel**. Consultare non modifica niente.

**Ripristinare dati cancellati o modificati per errore**

1. Apri la copia di una data in cui i dati erano giusti → **Consulta** → scegli la tabella.
2. Cerca i record, spunta quelli da recuperare → **Ripristina selezionati**. In alternativa **Ripristina tutta la tabella** (chiede di scrivere RIPRISTINA).
3. I record vengono riportati com'erano in quella data; gli altri dati non vengono toccati e i record creati dopo restano.
4. **Prima di ogni ripristino il sistema salva da solo un backup di sicurezza**: se il ripristino non era quello giusto, si torna indietro ripristinando da quella copia.

**Copie in nostro possesso, fuori da internet**

Il menu Strumenti scarica le copie sul PC e sulla chiavetta, nella cartella **BACKUP-DATABASE**: in automatico con la voce 2 (Aggiorna tutto) e quando si apre il menu dalla chiavetta, oppure a mano con la voce **9**. La prima volta su ogni postazione la voce 9 chiede la chiave dei backup, che si legge su Supabase (SQL Editor) con: `select decrypted_secret from vault.decrypted_secrets where name = 'backup_download_key';`

I file sono in formato aperto (JSON compresso): anche senza il gestionale si possono aprire e i dati restano leggibili. Insieme a ogni copia viene salvata anche la **struttura del database** (file `struttura-….sql`), che serve a ricostruirlo da zero (capitolo 18). Le foto (galleria, scontrini) sono conservate a parte nello spazio file e non fanno parte di questo backup.

## 18. Cosa fare in caso di emergenza

I dati non vivono sul PC né sulla chiavetta: stanno nel database su internet (Supabase), con una copia completa ogni notte. Ogni copia contiene **tutti i dati** e anche la **struttura del database** (tabelle, funzioni, regole di accesso), e viene scaricata anche su PC e chiavetta nella cartella **BACKUP-DATABASE** (file `.json.gz` con i dati e file `struttura-….sql` con la struttura).

| Dove sta | Cosa |
| --- | --- |
| Supabase (database) | Tutti i dati, sempre aggiornati |
| Supabase (spazio privato "backup") | Copie complete: ultimi 30 giorni e una per mese, per sempre |
| PC e chiavetta, cartella BACKUP-DATABASE | Le stesse copie, scaricate dal menu Strumenti |
| GitHub | Il codice del gestionale e dell'app Orari |
| Cloudflare | Gestionale e app pubblicati online |

### 18.1 Si rompe un PC

Gestionale e app continuano a funzionare online e nessun dato è perso.

1. Su un PC nuovo installa **Git** e **Node.js**.
2. Avvia il menu Strumenti dalla chiavetta (oppure scaricandolo da GitHub) e usa la **voce 1 – Prima installazione**: riscarica gestionale e app Orari. Le chiavi del database si leggono su Supabase → Project Settings → API.
3. Per pubblicare: `npx.cmd wrangler login` (Cloudflare) e `npx.cmd supabase login` (Supabase).
4. **Voce 9** con la chiave dei backup: il PC nuovo riscarica tutte le copie.

### 18.2 Si perde la chiavetta

Non si perdono dati, ma la chiavetta contiene le copie del database e la chiave per scaricarle: va resa inutile.

1. Su Supabase, SQL Editor, cambia la chiave dei backup:

```sql
select vault.update_secret((select id from vault.secrets where name = 'backup_download_key'), encode(extensions.gen_random_bytes(24), 'hex'));
select decrypted_secret from vault.decrypted_secrets where name = 'backup_download_key';
```

2. Sul PC cancella `BACKUP-DATABASE\chiave-backup.txt` e rifai la **voce 9** con la chiave nuova.
3. Prepara una chiavetta nuova con la **voce 6**.

Per prevenire: cifrare la chiavetta con **BitLocker** (tasto destro sull'unità → Attiva BitLocker → password). Senza password chi la trova non legge niente.

### 18.3 Dati cancellati o modificati per errore

Pagina **Backup e ripristino** → copia di un giorno in cui i dati erano giusti → **Consulta** → tabella → spunta i record → **Ripristina selezionati** (vedi capitolo 17). Prima di ogni ripristino viene salvato un backup di sicurezza.

### 18.4 Il database su internet non è più disponibile

È il caso più improbabile (Supabase ha anche i suoi backup), ma le copie in nostro possesso bastano a ricostruire tutto:

1. Crea un nuovo progetto Supabase.
2. Nello SQL Editor esegui il file `struttura-….sql` più recente della cartella BACKUP-DATABASE: ricrea tabelle, funzioni e regole di accesso.
3. Carica i dati dal file `backup-….json.gz` della stessa data: è un'operazione tecnica, da fare con l'assistenza di chi segue il gestionale, ma il file contiene tutti i record di tutte le tabelle in formato aperto.
4. Aggiorna le chiavi del nuovo progetto nei file `.env` e su Cloudflare, poi ripubblica gestionale e app (voci 4 e 5).

### 18.5 Cose da custodire a parte

Alcune credenziali, per sicurezza, non stanno su GitHub. Conservarne una copia in un gestore di password o in un documento custodito:

- accesso a Supabase, Cloudflare, GitHub e Google (account aziendale);
- password della posta Aruba usata per le email automatiche (SMTP);
- chiavi delle notifiche (VAPID), eventuale chiave Anthropic, credenziali del service account Google per le sincronizzazioni;
- la chiave dei backup (si può sempre rileggere da Supabase);
- in futuro, la chiave di firma dell'app per il Play Store.
$md$)
on conflict (slug) do nothing;

insert into manuali (slug, titolo, categoria, ordine, contenuto) values ('manuale-app-autisti', 'Manuale App Autisti', 'manuale', 2, $md$# Manuale App Autisti

Versione 3.0 — Ottobre 2026. Unisce la Guida Autista v2.2 (maggio 2026) e la parte "Area Autista" del Manuale Utente v4.1 (giugno 2026).

## 1. Installa l'app sul telefono

**Importante:** installa l'app sulla schermata Home. Solo così ricevi le notifiche anche con il telefono in tasca, come WhatsApp.

**Opzione A — dal browser (Android e iPhone)**

Android (Samsung, Huawei, Xiaomi…):

1. Apri **Chrome** e vai su **deangelisbussrl-app.pages.dev**.
2. Tocca i **tre puntini** in alto a destra → **Aggiungi a schermata Home** → **Aggiungi**.

iPhone:

1. Apri **Safari** e vai su **deangelisbussrl-app.pages.dev**.
2. Tocca **Condividi** (quadrato con la freccia) → **Aggiungi alla schermata Home** → **Aggiungi**.

Su iPhone le notifiche funzionano solo con l'app aggiunta alla schermata Home da Safari.

**Opzione B — APK (solo Android)**

1. Ricevi il file dell'app dall'ufficio (WhatsApp o USB).
2. Impostazioni del telefono → Sicurezza → attiva **Installa app sconosciute**.
3. Apri il file e tocca **Installa**. Funziona come la versione dal browser, notifiche comprese.

## 2. Primo accesso e notifiche

1. Apri l'app dall'icona sulla schermata Home (non dal browser).
2. Inserisci email e password ricevute dall'ufficio → **Accedi**.
3. Se compare il banner **"Attiva notifiche"**, toccalo subito; quando il telefono chiede **"Consenti notifiche?"** tocca **Consenti**.

Si fa una volta sola. Le notifiche arrivano su **un solo telefono**: quello da cui hai fatto l'ultimo accesso.

## 3. La schermata principale

Mostra il **turno di oggi** con gli orari, i **prossimi turni** e i pulsanti per tutte le funzioni. Tocca un turno per vedere veicolo, orario e tipo di servizio.

**Turni sul calendario del telefono**: nel box verde **"Sincronizza turni con Google Calendar"**:

- **Apri in Google Calendar** → **Aggiungi calendario**: i turni si aggiornano da soli quando l'ufficio carica i nuovi;
- **Copia URL** → incollalo in Apple Calendar o Outlook come "Sottoscrivi calendario";
- **Scarica .ics** per importare i turni una sola volta.

## 4. Turni e planning

- **I miei turni**: calendario personale con tutti i turni assegnati.
- **Planning settimanale**: ogni settimana l'ufficio lo invia in chat. Tocca la notifica o apri la **Chat** → tocca il link nel messaggio → si apre la tabella con tutti gli autisti; scorri in orizzontale per vedere tutti i giorni.

## 5. Registra la presenza

1. Tocca il pulsante verde **Conferma presenza**.
2. Controlla l'orario mostrato.
3. Tocca **Conferma**: l'ufficio la vede subito.

## 6. Fogli di viaggio (NCC e noleggio)

**Trovare il foglio**: menu → **Fogli di viaggio**. Quelli **da compilare** hanno il bordo blu e il badge "Da compilare"; tocca il foglio o **Compila ora**.

**Compilare**

1. **Programma giorni**: per ogni giornata km iniziali e finali, ora di partenza e di arrivo effettive; se il percorso è cambiato, una nota sulla riga.
2. **Spese di viaggio**: aggiungi ogni spesa (pedaggi, parcheggi…) con descrizione, importo e se pagata con carta aziendale o in contanti; tocca la **fotocamera** per allegare la foto dello scontrino.
3. **Osservazioni autista**: eventuali note per l'ufficio.
4. Tocca **Invia all'ufficio**.

Una volta inviato, il foglio **non si può più modificare**: controlla bene prima. Ricevi una notifica quando l'ufficio lo approva o chiede una correzione.

**Note e comunicazioni**: in fondo al foglio puoi scrivere all'ufficio a proposito di quel servizio; l'ufficio riceve la notifica. I fogli già chiusi restano consultabili in sola lettura.

## 7. Altre funzioni

**Rifornimenti**

1. Menu → **Rifornimenti** → scegli il veicolo.
2. Inserisci litri, costo e distributore (anche con foto) → **Invia**. Il consumo km/litro si calcola da solo.

**Richiesta ferie e permessi**

1. Menu → **Richieste** → tipo: ferie, permesso o altra assenza.
2. Scegli le date, aggiungi una nota se serve → **Invia richiesta**.
3. Ricevi una notifica quando l'ufficio risponde.

**Biglietti TPL**: se lavori sulle linee, registra i biglietti venduti per comune e tipo; a fine turno inserisci il totale incassato per la quadratura.

**Segnala anomalia veicolo**

1. Dalla schermata principale tocca il pulsante rosso **Segnala anomalia veicolo**.
2. Scegli veicolo e tipo di problema (freni, luci, motore, pneumatici, sterzo, porte…).
3. Urgenza: **Bassa** (da verificare), **Media** (prima possibile), **Alta** (non partire!).
4. Descrivi il problema → **Invia segnalazione**. Con urgenza alta l'ufficio riceve subito una notifica: non effettuare il servizio senza autorizzazione.

**Chat con l'ufficio**: scrivi all'ufficio e ricevi una notifica per ogni risposta. I link nei messaggi sono cliccabili; puoi eliminare i tuoi messaggi con il cestino.

**Assistente**: il pulsante in basso a destra risponde alle domande sull'app, per esempio "Come registro la presenza?", "Come compilo il foglio di viaggio?", "Come chiedo le ferie?".

## 8. Le notifiche

Ricevi una notifica quando:

- l'ufficio carica i turni o invia il planning;
- ti viene assegnato un foglio di viaggio;
- il foglio compilato viene approvato o richiede correzioni;
- la richiesta di ferie o permesso viene approvata o rifiutata;
- arriva un messaggio in chat.

Tocca la notifica per aprire l'app direttamente nella sezione giusta.

## 9. Problemi comuni

| Problema | Cosa fare |
| --- | --- |
| Non ricevo le notifiche | Apri l'app dall'icona sulla schermata Home; Impostazioni → App → Chrome → Notifiche → attiva; esci dall'app e rientra; tocca il banner "Attiva notifiche" se compare. Se hai cambiato telefono, accedi da quello nuovo |
| Non riesco ad accedere | Controlla la connessione e email/password (attenzione alle maiuscole); per la password dimenticata contatta l'ufficio |
| Non vedo i miei turni | I turni vengono caricati ogni settimana; trascina la pagina verso il basso per aggiornare; se mancano ancora, contatta l'ufficio |
| Non vedo il foglio di viaggio | L'ufficio deve averlo inviato: se è ancora in bozza non lo vedi |
| L'app non si aggiorna | Chiudi e riapri l'app; se non basta: Impostazioni → App → deAngelisBus → Cancella cache; in ultimo disinstalla e reinstalla |
| La foto dello scontrino non si carica | Controlla la connessione; foto JPG/PNG sotto i 5 MB |

Per qualsiasi problema contatta l'ufficio — De Angelis Bus S.r.l., Grottole (MT).
$md$)
on conflict (slug) do nothing;

insert into manuali (slug, titolo, categoria, ordine, contenuto) values ('manuale-app-orari', 'Manuale App Orari', 'manuale', 3, $md$# Manuale App Orari Deangelisbus

## 1. Introduzione

L'app **Orari De Angelis Bus** ha due anime. È prima di tutto uno strumento **informativo**: orari, fermate e prossimi bus di tutte le corse esercitate da De Angelis Bus S.r.l., con biglietti, segnalazioni e assistente. Ma è anche una **vetrina del territorio** in cui viaggia: i Sassi di Matera, i borghi di Grottole, Miglionico e Montescaglioso, i loro monumenti, eventi, piatti tipici e ristoranti, le foto dei nostri viaggi, e l'invito a organizzare una gita con i nostri bus.

Così chi apre l'app per sapere quando passa il bus scopre anche cosa vedere e dove mangiare, e il turista che cerca un transfer trova un motivo in più per fermarsi. Tutti i contenuti che cambiano (orari, novità, foto, piatti, ristoranti, posizione delle fermate) si gestiscono dal **gestionale** o dal **database**, senza ripubblicare l'app.

Il manuale ha due parti: le sezioni 2–7 spiegano l'app dal lato del **passeggero**; le sezioni 8–12 spiegano come **gestirla** dal gestionale.

| Componente | A cosa serve | Dove si trova |
| --- | --- | --- |
| App web | L'app che usano i clienti, installabile dal QR code | https://orari.deangelisbus.it (Cloudflare Pages, progetto `orari-deangelisbus`) |
| App Android | Versione per il Play Store, oggi solo di prova | Pacchetto `it.deangelisbus.orari`, si compila con Android Studio |
| Gestionale | Pagine "App Orari" per linee, novità, notifiche, richieste, segnalazioni, territorio, foto, fermate | amministrazione-deangelisbus-v2 (Cloudflare Pages) |
| Database | Orari, fermate, richieste, segnalazioni, contenuti | Supabase, progetto `hmdpaypyljdgoehztbvi` |
| Codice sorgente | Copia di sicurezza e scambio tra PC | GitHub: `orari-deangelisbus` (ramo main) e `deangelisbus-gestionale` (ramo master) |
| Email automatiche | Avvisano l'ufficio di preventivi e segnalazioni | Funzione Supabase `notifica-preventivo` (posta Aruba) |

Tutti gli orari partono dal database: l'app li scarica all'apertura e ne tiene una copia sul telefono, così funziona anche senza rete.

## 2. Installazione per i passeggeri

Oggi l'app si installa dal **QR code** o dal link https://orari.deangelisbus.it: è gratuita, non serve registrarsi e pesa pochissimo.

**Su Android (Chrome)**

1. Inquadra il QR code con la fotocamera (locandina sui bus, oppure "Passa l'app a un amico" dal telefono di un altro utente) e tocca il link.
2. Si apre l'app nel browser. In fondo alla Home c'è il riquadro **"Installa l'app sul telefono"**: tocca **Installa**. In alternativa: menu di Chrome (tre puntini) → **Aggiungi a schermata Home**.
3. Sulla schermata del telefono compare l'icona **Orari**: da quel momento l'app si apre a tutto schermo come le altre.

**Su iPhone (Safari)**

1. Apri il link in **Safari**.
2. Tocca il pulsante **Condividi** (quadrato con la freccia) → **Aggiungi alla schermata Home** → **Aggiungi**.

**Aggiornamenti.** L'app web si aggiorna da sola: dopo ogni pubblicazione basta chiuderla e riaprirla (a volte due volte). Il riquadro "Installa l'app" sparisce da solo quando l'app è già installata.

**App Android (Play Store).** La versione nativa `it.deangelisbus.orari` esiste ed è provata con Android Studio, ma non è ancora pubblicata. Rispetto all'app web ha in più il pulsante **Esci** che chiude davvero l'app; in futuro le notifiche. Per la pubblicazione servono account sviluppatore aziendale (D-U-N-S), aggiornamento ad Android 16 (API 36), chiave di firma e informativa privacy.

**Locandina.** Per i bus e le fermate c'è la locandina A4 con il QR: `stampa\locandina-orari-A4.pdf` (il QR da solo: `stampa\qr-orari-deangelisbus.png`).

## 3. Primo avvio e Home

Al primo avvio conviene scegliere la **fermata principale**: da quel momento la Home mostra subito il prossimo bus da lì.

1. In Home tocca il riquadro blu **"Il tuo prossimo bus"** (o la scheda **Partenze** in basso).
2. Cerca la fermata per nome o paese e scegli **"Usa come mia fermata"**.
3. Il riquadro mostra l'orario del prossimo bus, i minuti che mancano e la destinazione.

**Ordine della Home, dall'alto in basso**

1. Eventuale **avviso di novità da leggere** (banner rosso o giallo).
2. Benvenuto e **prossimo bus** dalla fermata principale.
3. **Le mie fermate** (se ne hai salvate), **Fermate vicino a me** e l'invito ad attivare le notifiche.
4. **Novità ed eventi**.
5. **Menu dei servizi**: trasporto extraurbano, scolastici (Grottole, Miglionico, Montescaglioso), urbani, disabili Matera, navetta Matera – Aeroporto di Bari, linea Matera – Policoro, più le linee nuove create dal gestionale.
6. **Acquista biglietti e abbonamenti** (biglietteria Cotrab).
7. **Feedback, reclami e segnalazioni**.
8. **Scopri il territorio**.
9. **Noleggio con conducente** (richiesta preventivo).
10. **Viaggi di gruppo** con Ridola Viaggi.
11. **In giro con noi** (galleria foto), **I nostri bus**, **Visita il nostro sito**, **Passa l'app a un amico**, **Installa l'app**.

**Comandi sempre presenti**

- **Barra in basso**: Home, Partenze, Da – a, Mappa, Info.
- **"‹ Indietro"** in alto a sinistra in tutte le pagine interne; funziona anche il tasto indietro di Android.
- **Assistente** (pulsante rotondo in basso a destra).
- **Esci** in alto a destra in Home: nell'app Android chiude l'app; nell'app web installata prova a chiuderla e, se il telefono non lo consente, spiega come fare.
- Riaprendo l'app dopo almeno 30 secondi si torna sempre alla Home.

## 4. Consultare gli orari

Gli orari si trovano in quattro modi: per fermata, per servizio, da un posto a un altro, sulla mappa.

**Per fermata (Partenze)**

1. Scheda **Partenze** → scegli la fermata.
2. Il riquadro grande mostra il **prossimo bus** e tra quanti minuti passa; sotto, tutte le partenze di **Oggi** o **Domani**.
3. Tocca un orario per vedere la corsa completa.

**Per servizio (menu in Home)**

1. Tocca un servizio, per esempio **Trasporto pubblico extraurbano**, poi la linea.
2. In alto scegli la direzione (per gli scolastici: **Andata a scuola / Ritorno da scuola**) e il giorno (Oggi, Domani, i giorni successivi).
3. Ogni riga mostra partenza → arrivo, il percorso e i giorni in cui circola; negli scolastici anche **Secondaria, Primaria o Infanzia**.

**Da – a**: scegli fermata di partenza e di arrivo; l'app mostra le corse dirette del giorno con orari e, per le linee Cotrab, la tariffa.

**Mappa**: mostra le fermate con la posizione; tocca un segnaposto per aprire le partenze.

**Dettaglio corsa**: tutte le fermate con l'orario di passaggio, i giorni di circolazione e il pulsante **Condividi questo orario**.

**Come leggere gli orari**

| Simbolo o scritta | Significato |
| --- | --- |
| ~12:35 | Orario **stimato** in base ai chilometri: le fermate intermedie non hanno un orario ufficiale |
| solo giorni di scuola | La corsa non c'è nei giorni di vacanza scolastica e di sospensione |
| dal lunedì al sabato / tutti i giorni | Giorni in cui circola la corsa |
| Riquadro verde "effettuate da Deangelisbus" | Navetta Bari: mese in cui la svolgiamo noi |
| Riquadro giallo "effettuate da Autobus Tito" | Navetta Bari: stessi orari, mese svolto dall'altra azienda del consorzio |

**Navetta Matera – Aeroporto di Bari.** Sono le corse Cotrab 3 e 5, tutti i giorni festivi compresi: verso Bari alle 8:30 e 14:00, verso Matera alle 11:30 e 17:00. Le svolgiamo a mesi alterni con Autobus Tito; l'app le mostra tutti i mesi e indica chi effettua il servizio. Biglietti solo online su www.marozzivt.it.

## 5. Funzioni personali

Queste funzioni rendono l'app "propria": restano sul telefono dell'utente e non richiedono registrazione.

**Le mie fermate** (fino a 4, oltre alla fermata principale)

1. Apri una fermata (da Partenze, Mappa o Fermate vicino a me).
2. Tocca **"☆ Salva tra le mie fermate"**: diventa **"★ Fermata salvata"**.
3. In Home compare la sezione **Le mie fermate** con il prossimo bus di ognuna; per toglierla, tocca di nuovo la stellina.

**Fermate vicino a me**

1. In Home tocca **"Fermate vicino a me"**; la prima volta consenti l'accesso alla posizione.
2. Compaiono le **6 fermate più vicine** con distanza e prossimo bus; tocca una fermata per aprirla.
3. **"Aggiorna posizione"** in fondo, se ti sposti.

Se il permesso è stato negato: Impostazioni del telefono → Posizione → l'app (o Chrome) → Consenti. Funziona solo per le fermate che hanno la posizione sulla mappa (vedi 8.6).

**Condividi questo orario**

1. Apri una corsa e tocca il pulsante verde **"Condividi questo orario"**.
2. Scegli WhatsApp, SMS o email e il contatto: parte un messaggio con linea, giorno, partenza, arrivo e link all'app.

**Passa l'app a un amico** (in Home e in Info)

1. Tocca **"Passa l'app a un amico"**: compare il QR code a tutto schermo.
2. L'altra persona lo inquadra con la fotocamera e tocca il link.
3. Se non è presente, usa **"Oppure invia il link"**. Il QR funziona anche senza rete.

**Avvisi delle novità e notifiche**

- **Banner in Home**: quando c'è una novità non ancora letta compare in cima alla Home, **rosso** per le variazioni del servizio (scioperi, deviazioni), **giallo** per novità ed eventi. Toccandolo si apre la pagina Novità ed eventi, dove le nuove hanno l'etichetta **Nuova**; la ✕ lo chiude. La voce "Novità ed eventi" del menu mostra un **pallino rosso** con il numero di quelle da leggere.
- **Notifiche sul telefono**: in Home (una volta sola) e sempre in **Info** c'è il riquadro **"Avvisi sul telefono"**. Tocca **Attiva le notifiche** e poi **Consenti**: da quel momento scioperi, variazioni e novità importanti arrivano come notifica anche ad app chiusa; toccandola si apre la pagina Novità. Dallo stesso riquadro in Info si disattivano.
- Su **iPhone** le notifiche funzionano solo con l'app aggiunta alla schermata Home (iOS 16.4 o successivo). L'app Android di prova non le riceve ancora: arriveranno con il Play Store. Se sono state bloccate: Impostazioni del telefono → Notifiche → l'app o Chrome.

## 6. Servizi per il passeggero

Ogni servizio dell'app porta a un'azione concreta; quelli che inviano dati arrivano in ufficio per email e nel gestionale.

| Servizio | Cosa fa il passeggero | Dove arriva |
| --- | --- | --- |
| Acquista biglietti e abbonamenti | Apre la biglietteria online Cotrab (biglietteria.cotrab.it): paga con carta e ha il titolo sul telefono | Sito Cotrab |
| Richiedi un preventivo (Noleggio con conducente) | Compila il modulo, uguale a quello del sito | Email a info@ e tiziana@ + gestionale → Richieste preventivo |
| Feedback, reclami e segnalazioni | Sceglie il tipo, descrive, può restare anonimo | Email + gestionale → Segnalazioni app |
| Assistente | Fa domande in linguaggio naturale su orari, fermate, biglietti, uso dell'app | Risponde l'intelligenza artificiale |
| Novità ed eventi | Legge avvisi, eventi e variazioni del servizio | Gestite dal gestionale → Novità app |

**Richiesta preventivo, passo passo**

1. Home → **"Richiedi un preventivo"** (card blu del noleggio).
2. Campi obbligatori: Nome, Cognome, Telefono, Data partenza e rientro, Luogo partenza e destinazione, Email, consenso privacy. Facoltativi: Azienda, Ora partenza e rientro, Partecipanti, Itinerario, Ulteriori informazioni.
3. **Invia**: compare la conferma "risposta entro 48 ore, preventivo non vincolante". Se manca la rete, c'è il link per scrivere a commerciale@deangelisbus.it.

**Segnalazione, passo passo**

1. Home → **"Feedback, reclami e segnalazioni"**.
2. Scegli: Reclamo, Segnalazione, Suggerimento o Complimento; indica linea, data e ora se servono; descrivi.
3. Lascia nome e contatto per ricevere risposta, oppure invia **in forma anonima**.

**Assistente virtuale**

1. Tocca **Assistente** in basso a destra.
2. Scrivi la domanda o tocca un esempio ("Quando passa il prossimo bus?").
3. Si può continuare la conversazione; **"Nuova domanda"** ricomincia da capo, **"Chiudi"** torna alla pagina di prima.

L'assistente conosce tutti gli orari, le tariffe, le novità, i contenuti del territorio e le istruzioni d'uso dell'app. Con il motore gratuito risponde a circa 30–40 domande al giorno; poi avvisa e riprende il giorno dopo.

## 7. Territorio, galleria e viaggi di gruppo

È la parte dell'app che **promuove il territorio**: trasforma un orario in un invito a scoprire i paesi serviti, sostiene le attività locali (ristoranti, eventi, agenzia Ridola) e porta nuovi clienti al noleggio con le gite organizzate. Anche l'assistente virtuale conosce questi contenuti e li suggerisce a chi chiede.

**Scopri il territorio**

1. Home → card **"Scopri il territorio"**.
2. In alto i nomi dei paesi (Matera, Grottole, Miglionico, Montescaglioso): toccandoli si salta alla scheda.
3. Ogni scheda ha: cosa vedere, l'evento da non perdere, **Cosa mangiare** (piatti tipici e fino a 4 ristoranti con Chiama, Sito, Mappa), i pulsanti per gli orari dei bus e **"Organizza una gita con i nostri bus"** che apre il preventivo.

I testi su monumenti ed eventi sono nel codice dell'app (`src\lib\territorio.ts`): per cambiarli serve una nuova pubblicazione. Piatti e ristoranti invece si gestiscono dal gestionale (8.4).

**In giro con noi (galleria foto)**

1. Home → card **"In giro con noi"** (compare quando ci sono foto) o da Scopri il territorio.
2. Tocca una foto per vederla a tutto schermo, con didascalia e autore; frecce per scorrere.
3. **"▶ Guarda la presentazione"**: le foto scorrono da sole ogni 5 secondi con la musica di sottofondo; pulsanti per pausa, avanti/indietro, musica sì/no, chiudi.

Se la musica non si sente, controllare il volume multimediale del telefono.

**Viaggi di gruppo con Ridola Viaggi**

La card verde con il logo Ridola porta al sito ridolaviaggi.com, dove sono pubblicati i viaggi in programma. Non c'è nulla da gestire nell'app: i viaggi si aggiornano sul sito dell'agenzia.

## 8. Gestione dal gestionale

Nel menu del gestionale, sezione App Orari, ci sono otto pagine; ogni modifica salvata compare nell'app alla riapertura successiva, senza pubblicare nulla. Servono le credenziali di amministratore.

| Pagina del gestionale | Cosa gestisce | Effetto nell'app |
| --- | --- | --- |
| Linee e orari | Linee, percorsi con fermate e minuti, corse, sospensioni e periodi | Tutti gli orari, le linee e il menu dei servizi |
| Novità app | Novità, eventi, variazioni del servizio | Sezione Novità ed eventi e banner "da leggere" in Home |
| Notifiche app | Notifiche push ai telefoni iscritti, storico invii | Notifica sul telefono, anche ad app chiusa |
| Richieste preventivo | Richieste arrivate dal modulo noleggio | Nessuno (lavoro d'ufficio) |
| Segnalazioni app | Reclami, segnalazioni, suggerimenti, complimenti | Nessuno (lavoro d'ufficio) |
| Territorio: cosa mangiare | Piatti tipici e ristoranti per paese | Riquadro Cosa mangiare in Scopri il territorio |
| Foto: in giro con noi | Foto della galleria e musica della presentazione | Card e galleria In giro con noi |
| Fermate: posizione | Posizione sulla mappa di ogni fermata | Mappa e Fermate vicino a me |

### 8.1 Richieste preventivo

1. Apri **Richieste preventivo**: l'elenco si aggiorna da solo quando arriva una richiesta (arriva anche l'email "Preventivo app: …").
2. Filtra per **stato** e per tipo.
3. Apri la richiesta: **Chiama**, **Email** (risposta precompilata), note interne visibili solo all'ufficio, cambio stato.
4. **Crea noleggio**: apre il modulo Noleggi già compilato con committente, itinerario, date e note; la richiesta resta collegata al noleggio.
5. **Elimina** solo per richieste di prova o spam.

### 8.2 Segnalazioni app

1. Apri **Segnalazioni app** (arriva anche l'email "Segnalazione app: …").
2. Filtra per tipo e stato; leggi linea, data e descrizione.
3. Se il passeggero ha lasciato i contatti: **Chiama** o **Rispondi via email**. Annota l'esito nelle note interne e chiudi la segnalazione.

### 8.3 Novità app

1. Apri **Novità app** → **Nuova notizia**.
2. Scegli il **tipo**: Novità, Evento (con data) o Variazione del servizio (per scioperi, deviazioni, sospensioni).
3. Scrivi titolo e testo e compila gli altri campi proposti (per gli eventi la data). Attenzione alla data **"visibile dal"**: se è nel futuro la novità compare solo da quel giorno.
4. Salva. Per toglierla prima: **nascondi** o elimina.

### 8.4 Territorio: cosa mangiare

1. Apri **Territorio: cosa mangiare**: le voci sono divise per paese, in Piatti tipici e Ristoranti.
2. **Aggiungi piatto**: nome e una o due righe di descrizione.
3. **Aggiungi ristorante**: nome, descrizione breve, indirizzo, telefono, sito; l'app ne mostra al massimo 4 per paese.
4. Usa **Ordine** (1 = primo) per decidere la sequenza; l'occhio nasconde una voce senza cancellarla (per esempio un locale chiuso per la stagione).

### 8.5 Foto: in giro con noi

1. Apri **Foto: in giro con noi** → **Scegli foto**: si possono selezionare molte foto insieme, dal PC o dal telefono.
2. Le foto vengono rimpicciolite in automatico (lato lungo 1600 pixel); il nome del file diventa la didascalia: correggila e premi **Salva** sotto la foto.
3. **Autore**: preimpostato "Deangelisbus"; **Ordine** per la sequenza; occhio per nascondere, cestino per eliminare.
4. **Musica di sottofondo**: carica un file **MP3**, ascoltalo, sostituiscilo o toglilo. Solo musica libera da diritti (Audio Library di YouTube, Pixabay Music) o con licenza.

Usare solo foto proprie o con il permesso dell'autore; evitare foto con clienti riconoscibili senza il loro consenso.

### 8.6 Fermate: posizione

1. Apri **Fermate: posizione**. A sinistra l'elenco con il filtro **Senza posizione** (icona rossa) o **Tutte**; a destra la mappa, con le fermate già posizionate come puntini grigi.
2. Scegli una fermata: la mappa si sposta sul suo paese.
3. Dal PC: **clicca sulla mappa** nel punto esatto (casella **Satellite** per riconoscere piazze e pensiline); trascina il segnaposto rosso per correggere.
4. Sul posto, con il telefono: **"Usa la mia posizione"**.
5. **Salva**: l'icona diventa verde e la fermata compare nella Mappa e in Fermate vicino a me.

### 8.7 Linee e orari

La pagina **Linee e orari** gestisce tutto il servizio di linea. A sinistra le linee divise per categoria; scelta una linea, a destra quattro schede.

**Corse e orari** (andata e ritorno, una corsa per riga)

1. Modifica partenza, percorso, descrizione (es. Primaria), nota per i passeggeri, giorni (L M M G V S D), scuola (Sempre / Solo giorni di scuola / Solo vacanze) e **Attiva**. L'arrivo si calcola da solo.
2. Le righe modificate diventano **gialle** e in alto compare la barra **"corse modificate non ancora salvate"**: premi **Salva tutto** (o il dischetto verde della riga) e attendi il messaggio verde. **Annulla le modifiche** torna ai dati salvati.
3. **Nuova corsa** aggiunge una riga; **Duplica** crea una copia da cambiare solo nell'orario; il cestino elimina.
4. Per sospendere una corsa senza cancellarla: togli **Attiva** e salva.

**Percorsi e fermate**

1. Scegli il percorso, oppure crea **Percorso di andata** o **di ritorno**.
2. Aggiungi le fermate in ordine dal menu in fondo (raggruppate per paese) o **crea una fermata nuova**; frecce per spostarle, cestino per toglierle.
3. Indica i **minuti dalla partenza**: 0 per il capolinea, poi valori crescenti.
4. **Salva percorso**. Il percorso vale per tutte le corse che lo usano: per un giro diverso crea un altro percorso.

**Dati della linea**: nome mostrato nell'app, categoria, comune, colore, committente, ordine nel menu, "a mesi alterni con", informazioni per i passeggeri, **Attiva** (togliendola la linea sparisce dall'app), subappalto. Da qui si elimina anche la linea, con doppia conferma.

**Calendario**

1. **Sospensioni**: dal / al, "solo corse scolastiche" (vacanze) o "tutte le corse" (fermo), per tutte le linee o solo per questa, descrizione.
2. **Periodi di servizio**: se presenti, la linea circola solo in quelle date; "solo informativo" indica i mesi svolti da noi senza nascondere le corse (come la navetta Bari).

**Creare un servizio nuovo** (es. urbano di Montescaglioso)

1. **+ Nuova linea…** → scegli la voce già presente nel menu dell'app (Montescaglioso – Servizio urbano o Trasporto scolastico) oppure **Altra linea…**: le linee nuove compaiono da sole nel menu della Home.
2. Crea i percorsi con le fermate e i minuti.
3. Crea la prima corsa, poi usa Duplica per le altre.
4. Posiziona le fermate nuove in **Fermate: posizione** (8.6).

Le modifiche sono subito visibili ai passeggeri dopo **Info → Aggiorna orari** o la riapertura dell'app: per i cambi grossi (nuovo anno scolastico) conviene lavorare con calma e controllare l'app alla fine.

### 8.8 Notifiche app

La pagina **Notifiche app** invia un avviso sul telefono di tutti i passeggeri che hanno attivato le notifiche. In alto c'è il numero di **telefoni iscritti**.

1. Pubblica prima la novità in **Novità app** (per esempio una Variazione del servizio).
2. In **Notifiche app**, a destra, tocca la novità: titolo e testo si compilano da soli (per le variazioni il titolo inizia con ⚠️). In alternativa scrivi a mano titolo (massimo 80 caratteri) e testo (massimo 200).
3. Controlla l'**anteprima** e premi **Invia a N telefoni**, poi conferma.
4. In fondo, negli **Ultimi invii**, compare quante notifiche sono state consegnate; le iscrizioni di telefoni che hanno disinstallato l'app vengono tolte da sole.

Usarle solo per avvisi importanti (scioperi, deviazioni, corse soppresse, novità di rilievo): troppe notifiche spingono i passeggeri a disattivarle. Le novità pubblicate senza notifica compaiono comunque nel banner della Home.

## 9. Orari e dati su Supabase

Linee, fermate, percorsi, corse e calendario si gestiscono dal gestionale, pagina **Linee e orari** (8.7). Supabase (supabase.com → progetto `hmdpaypyljdgoehztbvi`) serve solo per i caricamenti in blocco con lo **SQL Editor** e per le tabelle senza pagina, come le tariffe. Dopo ogni modifica, sul telefono: **Info → Aggiorna orari** o riaprire l'app.

| Tabella | Contenuto | Quando si tocca |
| --- | --- | --- |
| orari_linee | Linee e servizi (nome, colore, categoria, comune, testo informativo) | Nuovo servizio o cambio descrizione |
| orari_fermate | Fermate (nome, comune, posizione) | Nuova fermata; la posizione si mette dal gestionale (8.6) |
| orari_percorsi + orari_percorsi_fermate | Sequenza delle fermate e minuti dal capolinea | Cambio di percorso |
| orari_corse | Ogni corsa: orario di partenza, giorni (1 = lunedì … 7 = domenica), solo giorni di scuola, attiva | Nuovi orari, corsa soppressa |
| orari_periodi | Periodi di attività di una linea (o mesi informativi, come la navetta Bari) | Servizi stagionali |
| orari_sospensioni | Giorni senza servizio: vacanze scolastiche (ambito scolastico) o fermo totale (ambito tutti) | Calendario scolastico, festività |
| orari_tariffe | Tariffe Cotrab tra zone | Aggiornamento tariffe |
| orari_novita, richieste_preventivo, segnalazioni_app, territorio_gusto, territorio_foto, push_iscrizioni, push_invii | Contenuti gestiti dal gestionale | Solo dal gestionale |

**Operazioni frequenti**

1. **Corsa soppressa per un periodo**: Linee e orari → Corse e orari → togli **Attiva** → Salva tutto (rimettila alla ripresa). Se è un'interruzione da comunicare, aggiungi anche una Variazione del servizio in Novità app.
2. **Vacanze scolastiche**: Linee e orari → Calendario → Sospensioni, "solo corse scolastiche", per tutte le linee. Le corse "solo giorni di scuola" spariscono in quei giorni.
3. **Nuovi orari di un servizio**: dalla pagina Linee e orari (8.7). Per un orario lungo da PDF o Excel conviene farsi preparare il file SQL e incollarlo nello SQL Editor, come per lo scolastico di Grottole.

**File SQL già eseguiti** (cartella `orari-deangelisbus\sql`, nell'ordine): v1 dati Cotrab, v2 servizi e calendario, v3 nuovi servizi, v4 colori e preventivi, v5 email, v6 novità, v7 permessi gestionale, v8 collegamento noleggi, v9 navetta e segnalazioni, v10 preventivo come il sito, v11 viaggi (non usata), v12 scolastico Grottole, v13 navetta corse 3 e 5, v14 navetta mesi alterni, v15 cosa mangiare, v16 foto, v17 notifiche push, v18 manuali. Si possono rieseguire senza danni.

## 10. Pubblicazione e manutenzione

Tutte le operazioni tecniche passano dal **menu Strumenti** (`orari-deangelisbus\strumenti\DeAngelisBus-Strumenti.bat`, icona sul Desktop), uguale su ogni PC e sulla chiavetta.

| Voce | Quando |
| --- | --- |
| 1 Prima installazione | Solo su un PC nuovo |
| 2 Aggiorna tutto | **Sempre all'inizio**: scarica da GitHub il lavoro fatto altrove |
| 3 Salva tutto su GitHub | **Sempre alla fine**: alla domanda rispondi `s`, poi una descrizione breve |
| 4 Pubblica l'app Orari | Dopo una modifica al codice dell'app (non serve per orari e contenuti) |
| 5 Pubblica il gestionale | Dopo una modifica al codice del gestionale |
| 6 Copia su chiavetta | Copia di sicurezza |
| 7 Controllo postazione | Verifica: deve risultare tutto [OK], senza "behind" o "ahead" |

**Regole d'oro**

1. Prima la **2**, poi si lavora, poi la **3**. Un PC rimasto indietro blocca la pubblicazione ("Compilazione non riuscita"): non è un danno, basta la 2. Prima della **5** sempre la **2**, per non ripubblicare un gestionale vecchio.
2. Uno zip ricevuto si estrae **dopo** la 2 e **prima** della 4.
3. La 4 deve dire "Uploaded X files" con X maggiore di 0: con 0 non è cambiato niente online.
4. Alla domanda "Salvo queste modifiche (s/n)" si risponde solo `s`; la descrizione va alla domanda successiva.
5. Sulla chiavetta l'aggiornamento parte da solo all'apertura; prima di toglierla: voce 3 e rimozione sicura.

**Postazioni**

| Postazione | App Orari | Gestionale (da compilare) | Chiavi |
| --- | --- | --- | --- |
| PC | C:\DEANGELISBUS\orari-deangelisbus | dentro C:\DEANGELISBUS\2-SORGENTE-APP (il menu trova da solo la cartella giusta) | .env o .env.local |
| Chiavetta | K:\DEANGELISBUS-USB-v21\orari-deangelisbus | K:\...\2-SORGENTE-APP\2-SORGENTE-APP\2-SORGENTE-APP | .env |

**App Android (prove)**: dopo la voce 4, `npx.cmd cap sync android`, poi ▶ in Android Studio con il telefono collegato. Non accettare l'aggiornamento proposto dall'"Upgrade Assistant" fino alla preparazione del Play Store.

**File da non perdere**: `.env` / `.env.local` su ogni PC, `android\local.properties`, e in futuro la chiave di firma del Play Store.

## 11. Configurazioni e servizi esterni

Queste impostazioni si fanno una volta; vanno toccate solo per cambiare destinatari, motore dell'assistente o dominio.

| Cosa | Dove si imposta | Come si cambia |
| --- | --- | --- |
| Destinatari delle email (preventivi e segnalazioni) | Supabase → Edge Functions → Secrets: `EMAIL_TO` (oggi info@ e tiziana@) | Aggiungere indirizzi separati da virgola, es. commerciale@deangelisbus.it |
| Casella che invia le email | Secrets `SMTP_HOST`, `SMTP_PORT` (465), `SMTP_USER`, `SMTP_PASS` (posta Aruba) | Cambiare solo se cambia la password della casella |
| Sicurezza del collegamento email | Secret `WEBHOOK_SECRET`, uguale a quello nei trigger del database | Non toccare |
| Notifiche push: chiavi | Secrets `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (mailto:info@deangelisbus.it) | Non cambiarle: con chiavi nuove tutti i telefoni dovrebbero riattivare le notifiche. La chiave privata non va mai condivisa |
| Notifiche push: funzione di invio | Edge Function `invia-notifica` (codice in `supabase\functions\invia-notifica`), senza verifica JWT | Ripubblicarla solo se cambia il codice, dal PC: `npx.cmd supabase functions deploy invia-notifica --project-ref hmdpaypyljdgoehztbvi --no-verify-jwt` (la prima volta `npx.cmd supabase login`). Non crearla dal sito: dà un indirizzo diverso |
| Assistente gratuito | Cloudflare Pages → orari-deangelisbus → Impostazioni → Collegamenti → Workers AI, nome `AI` | Già attivo |
| Assistente più preciso (Claude Haiku) | Cloudflare Pages → Impostazioni → Variabili: segreto `ANTHROPIC_API_KEY` | Aggiungere la chiave e ripubblicare (voce 4); circa un centesimo a domanda |
| Dominio orari.deangelisbus.it | Cloudflare Pages → orari-deangelisbus → Domini personalizzati | Non toccare |
| Chiavi del database nell'app | File `.env` / `.env.local` (VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY) | Il menu le controlla da solo |
| Spazio foto e musica | Supabase → Storage → bucket `territorio` (pubblico in lettura) | Si gestisce dal gestionale (8.5) |

I permessi di scrittura dal gestionale valgono solo per gli utenti **amministratori** (funzione `is_admin_gestionale` nel database): un dipendente senza quel ruolo vede le pagine ma non può salvare.

## 12. Risoluzione dei problemi

Quasi tutti i problemi si risolvono riaprendo l'app o con la voce 2 del menu.

| Problema | Causa probabile | Soluzione |
| --- | --- | --- |
| L'app non mostra una novità appena pubblicata | Data "visibile dal" nel futuro, oppure telefono con la versione salvata | Controllare la data in Novità app; chiudere l'app e riaprirla, Info → Aggiorna orari |
| Ancora vecchia dopo più riaperture | Dati del telefono vecchi | Tenere premuta l'icona → Info app → Spazio di archiviazione → Cancella dati (si perde la fermata preferita) |
| Il gestionale sul telefono non mostra le pagine nuove | Icona installata da un indirizzo "con codice" (fermo a una vecchia versione) o memoria vecchia | Disinstallare l'icona vecchia e usare solo quella dell'indirizzo principale; cancellare i dati dell'app |
| Una funzione nuova non compare | Zip estratto dopo la pubblicazione | Voce 4 (o 5) di nuovo: deve dire "Uploaded X files" con X > 0 |
| "Compilazione non riuscita" alla voce 4 o 5 | PC rimasto indietro, zip parziale o disco pieno ("no space left on device") | Voce 2, poi rifare; se il disco è pieno liberare spazio (installatori nei Download, cache) |
| `$zip.Name` vuoto o "argomento null" in PowerShell | Lo zip non è stato scaricato | Scaricarlo e controllare l'icona dei download del browser; scrivere `exit` se si è aperta una PowerShell dentro l'altra |
| "Non riesco ad attivarle: Servizio notifiche non disponibile" | Funzione `invia-notifica` assente, con indirizzo diverso o senza la chiave pubblica | Ripubblicarla con il comando della sezione 11 e controllare i Secrets VAPID |
| "Le notifiche sono bloccate" | Permesso negato sul telefono | Impostazioni del telefono → Notifiche → l'app o Chrome → consentire |
| Una fermata manca in Fermate vicino a me o nella Mappa | Fermata senza posizione | Gestionale → Fermate: posizione (8.6) |
| La card In giro con noi non c'è | Nessuna foto visibile | Caricare le foto (8.5) |
| La presentazione è muta | Volume multimediale a zero o musica non caricata | Alzare il volume; controllare la musica in 8.5 |
| L'assistente dice di aver esaurito le risposte | Quota gratuita giornaliera finita | Riprova il giorno dopo, o attivare Claude Haiku (sezione 11) |
| Non arrivano le email dei preventivi | Destinatari o password SMTP | Controllare i Secrets (sezione 11); le richieste restano comunque nel gestionale |
| Il gestionale non salva (errore di permesso) | Utente non amministratore | Accedere con un utente con ruolo admin |
| Una modifica in Linee e orari "torna indietro" | Non salvata (riga gialla) | Premere Salva tutto nella barra gialla e attendere il messaggio verde |
| Sulla chiavetta l'aggiornamento è lentissimo | Reinstallazione delle librerie | Lasciarlo finire; capita solo quando cambiano le librerie |
$md$)
on conflict (slug) do nothing;

insert into manuali (slug, titolo, categoria, ordine, contenuto) values ('come-usare-operativita', 'Come usare questa sezione', 'operativita', 1, $md$# Procedure operative: come usare questa sezione

Questa sezione raccoglie le **procedure operative** dell'azienda: istruzioni brevi su "come si fa", da consultare e aggiornare quando servono.

## Come aggiungere una procedura

1. Premi **Nuovo documento** e scegli la categoria **Operatività**.
2. Dai un titolo chiaro (per esempio "Gestione di uno sciopero" o "Apertura e chiusura deposito").
3. Scrivi i passaggi in ordine, uno per riga, iniziando con `1.`, `2.`, `3.`.
4. Premi **Salva**.

## Come scrivere il testo

| Per ottenere | Scrivi |
| --- | --- |
| Titolo di sezione | `## Titolo` |
| Sottotitolo | `### Sottotitolo` |
| Elenco numerato | `1. Primo passo` |
| Elenco puntato | `- Voce` |
| Grassetto | `**parola**` |
| Tabella | righe con `|` tra le colonne, la seconda riga `| --- | --- |` |

Usa l'**Anteprima** per vedere il risultato prima di salvare.

## Esempio: gestione di uno sciopero

1. Ricevuta la comunicazione dello sciopero, pubblica una **Variazione del servizio** in Novità app, con data "visibile dal" di oggi.
2. Invia la **notifica** ai passeggeri da Notifiche app.
3. Se alcune corse non si effettueranno, toglile da **Linee e orari** (spunta Attiva) per il solo giorno dello sciopero, e rimettile il giorno dopo.
4. Avvisa gli autisti interessati con le notifiche dell'app autisti.
$md$)
on conflict (slug) do nothing;

-- Aggiornamento dei tre manuali all'ultima versione (sovrascrive eventuali modifiche fatte a questi tre documenti;
-- le procedure di Operatività non vengono toccate).
update manuali set titolo = 'Manuale del Gestionale', contenuto = $md$# Manuale del Gestionale Deangelisbus

Versione 5.0 — Ottobre 2026. Unisce il Manuale Utente v4.1 (giugno 2026) e il Manuale Amministratore v2.2 (maggio 2026), aggiornati con i moduli arrivati dopo: Noleggi, Scadenzario, Gestione ferie, sincronizzazioni automatiche, pagine App Orari e questa sezione Manuali.

## 1. Introduzione

DEANGELISBUS è il sistema gestionale web di De Angelis Bus S.r.l. per il trasporto pubblico locale (TPL) e il noleggio con conducente (NCC). È composto da due applicazioni, usabili da qualsiasi browser o installabili come app sul telefono.

| Applicazione | A chi serve | Indirizzo |
| --- | --- | --- |
| Gestionale (amministrazione) | Amministrazione e responsabili | amministrazione-deangelisbus-v2.pages.dev |
| App Autista | Autisti, ottimizzata per smartphone | deangelisbussrl-app.pages.dev (vedi il Manuale App Autisti) |
| Login | Email e password; le credenziali degli autisti si creano dalla sezione Autisti | — |

**Installare il gestionale sul telefono.** Android: Chrome → tre puntini → **Aggiungi a schermata Home**. iPhone: Safari → **Condividi** → **Aggiungi alla schermata Home**. Usare sempre l'indirizzo principale: gli indirizzi con un codice davanti (es. `abc123.amministrazione-…`) restano fermi a una vecchia versione.

**Permessi.** Le funzioni di modifica sono riservate agli utenti **amministratori**; chi non ha quel ruolo vede le pagine ma non può salvare.

## 2. Dashboard e navigazione

La dashboard è la schermata principale; il menu laterale porta a tutte le sezioni.

| Statistica | Significato |
| --- | --- |
| Da verificare | Fogli di viaggio compilati dall'autista che attendono la verifica |
| Fogli mese | Fogli di viaggio creati nel mese |
| Fatturato mese | Somma dei totali servizio dei fogli del mese |
| Manutenzioni | Manutenzioni dei veicoli in scadenza nei prossimi 30 giorni |
| Preventivi attivi | Preventivi inviati in attesa di risposta |

**Ricerca globale**

1. Scrivi almeno 2 caratteri nella barra di ricerca sotto l'intestazione.
2. I risultati compaiono subito: autisti, veicoli, committenti, fogli di viaggio, preventivi.
3. Clicca un risultato per aprire la pagina; **X** cancella la ricerca.

La ricerca trova cognome dell'autista, targa, nome del committente, numero del foglio o del preventivo e oggetto del servizio.

**Aree del menu**

| Area | Sezioni |
| --- | --- |
| Autisti e turni | Autisti, Presenze, Richieste, Report autista, Calendario turni, Carica turni, Turni TPL, Turni ricorrenti, Planning turni, Riposi, Gestione ferie, Scadenze autisti |
| Veicoli e operatività | Veicoli, Rifornimenti, Carichi serbatoio, Manutenzioni, Anomalie, Report veicolo, Fogli di viaggio, Archivio |
| Commerciale | Committenti, Preventivi, Fatture proforma, Feedback clienti, Biglietti, Report incassi, Noleggi |
| Amministrazione | Scadenzario, Report ed export, Statistiche, Impostazioni |
| Comunicazioni | Chat, notifiche agli autisti |
| App Orari | Linee e orari, Novità, Notifiche, Richieste preventivo, Segnalazioni, Territorio, Foto, Fermate |
| Manuali e operatività | Manuali e procedure operative |

## 3. Turni

### 3.1 Calendario turni

1. Menu → **Calendario turni** → scegli la settimana con le frecce.
2. Clicca la cella autista × giorno per assegnare un turno.
3. Scegli il tipo: **TPL**, **NCC**, **Assenza** o **Vuoto**.
4. Scegli il turno dal catalogo oppure inserisci orari personalizzati.
5. Salva: la **presenza** viene creata in automatico (il tipo TPL/NCC/assenza deriva dalla descrizione del turno).

I turni "Vuoto" (Disposizione, Garage, Scuole) non generano presenza e non compaiono nel report autista.

### 3.2 Caricare i turni della settimana da file

1. La Titolare prepara i turni in Word e li salva in **PDF** (2 pagine A4 orizzontali; la seconda pagina senza intestazione).
2. Menu → **Carica turni** → carica il PDF. Il PDF deve avere il **testo selezionabile**: immagini, foto e screenshot vengono rifiutati.
3. Controlla l'anteprima: verifica che i nomi degli autisti siano abbinati correttamente.
4. **Importa**: i turni vengono salvati senza cancellare le presenze dei giorni passati, e ogni autista riceve la notifica del turno assegnato.

### 3.3 Turni TPL e turni ricorrenti

- **Turni TPL**: archivio dei turni ufficiali con codice, linee servite, km e frequenza.
- **Turni ricorrenti**: catalogo dei turni con orari fissi (es. "1 NAVETTA/1 TURNO" = 04:00–15:00). Creando un turno con la stessa descrizione gli orari si compilano da soli; i turni nuovi vengono aggiunti al catalogo in automatico.

### 3.4 Planning turni (archivio settimanale)

1. Menu → **Planning turni** → **Archivia settimana**: si propone la settimana corrente; il sistema recupera i turni dal Calendario → **Archivia**.
2. Clicca una settimana archiviata per vederla; **Stampa / PDF** genera il prospetto aziendale (A3 orizzontale, autisti in righe e giorni in colonne).
3. **Invia in chat**: il planning arriva a tutti gli autisti come messaggio con link, con notifica push; dal telefono si apre una tabella ottimizzata.
4. Il planning evidenzia in rosso gli autisti con riposo insufficiente.

### 3.5 Riposi e conformità (Reg. CE 561/2006)

Menu → **Riposi e conformità**: elenco degli autisti con avvisi sul riposo giornaliero e settimanale. Tra un turno e l'altro servono almeno 11 ore consecutive di riposo; il sistema segnala le violazioni. Gran parte del servizio TPL rientra nell'esenzione prevista dal regolamento (art. 3a) e viene trattata di conseguenza.

## 4. Presenze, richieste e ferie

### 4.1 Presenze

1. Menu → **Presenze** → scegli mese e autista.
2. Per ogni giorno la griglia mostra **Programmato** (dal turno) ed **Effettivo** (inserito dall'autista; se modificato appare in arancione con la matita).
3. Clicca una cella per cambiare lo stato o inserire gli orari effettivi. Stati: Presente, Assente, Ferie, Malattia, Infortunio, Permesso, Festivo, Riposo. Lo stato della presenza è **provvisoria** finché non viene confermata.

Tipi: TPL (T), NCC (N), riposo/ferie/malattia senza tipo. Se un autista ha riposo programmato ma viene creato un foglio di viaggio NCC per lo stesso giorno, la presenza diventa NCC in automatico. I veicoli usati e i km vengono registrati insieme alla presenza.

### 4.2 Richieste di ferie e permessi

1. Menu → **Richieste**: le richieste in attesa hanno il badge arancione.
2. Apri la richiesta → **Approva** o **Rifiuta**, con nota facoltativa.
3. L'autista riceve subito la notifica.

### 4.3 Gestione ferie

1. Menu → **Gestione ferie** → scegli l'autista.
2. La dotazione annua segue il livello CCNL (fasce di 31/32 giorni); i saldi iniziali sono caricati come rettifiche; il calcolo vale anche su più anni.
3. Per il primo semestre 2026 fanno fede le schede cartacee; dal luglio 2026 fa fede il gestionale.

## 5. Fogli di viaggio (NCC)

### 5.1 Ciclo di vita

| Stato | Significato |
| --- | --- |
| Bozza | Creato ma non inviato: lo vede e lo modifica solo l'amministrazione |
| Inviato autista | Visibile all'autista, che lo compila a fine servizio |
| Compilato autista | L'autista ha inserito orari e spese: va verificato |
| Verificato | Dati controllati, pronto per l'archiviazione |
| Archiviato | Chiuso definitivamente, solo consultazione |

### 5.2 Creare un foglio

1. Menu → **Fogli di viaggio** → **Nuovo foglio**.
2. Oggetto del servizio (es. "Gita scolastica Roma"), committente dall'anagrafica (i dati fiscali si compilano da soli) o dati manuali, date di partenza e rientro.
3. Autista principale e veicolo.
4. **Programma giorni**: ogni giornata con data, orari e destinazione (obbligatori prima dell'invio).
5. Totale servizio (importo da fatturare).
6. **Salva come bozza** oppure **Invia all'autista** (l'autista riceve la notifica).

### 5.3 Verificare un foglio compilato

1. Dashboard → contatore **Da verificare** → apri il foglio.
2. Controlla km effettivi, orari e spese con le foto degli scontrini.
3. **Analizza AI** (viola): valutazione automatica di orari anomali, km incoerenti e spese fuori norma (OK / DA VERIFICARE / ATTENZIONE).
4. **Note e comunicazioni**: chiarimenti con l'autista, che riceve la notifica.
5. **Verifica** per approvare; facoltativo **Richiedi feedback** al committente; **Archivia** per chiudere. Un foglio chiuso si può riaprire con **Riapri**.

### 5.4 Duplicare un foglio

Nella riga del foglio clicca l'icona copia: nasce una nuova bozza con prefisso "COPIA - "; cambia date e dettagli. Utile per committenti abituali con gli stessi percorsi.

### 5.5 Fogli di viaggio dal CRM

I fogli di viaggio del CRM vtenext vengono sincronizzati nel gestionale in sola lettura (solo i dati di testata). In caso di differenze vale il CRM.

## 6. Veicoli e operatività

- **Manutenzioni**: Menu → Veicoli → Manutenzioni → **Nuova manutenzione**: veicolo, tipo (tagliando, revisione, assicurazione, bollo, tachigrafo…), data intervento, scadenza, km, costo, officina. Colori: verde oltre 90 giorni, arancione sotto 30, rosso scaduta.
- **Rifornimenti**: registro carburante con calcolo km/litro per veicolo e report mensile, filtri ed export CSV.
- **Carichi serbatoio**: registro dei carichi del serbatoio del deposito.
- **Anomalie veicoli**: segnalazioni degli autisti con urgenza bassa/media/alta; con urgenza alta arriva subito una notifica.
- **Report veicolo**: scegli veicolo e periodo (mese, anno, tutto): rifornimenti, litri, km, media km/l, costi di manutenzione, viaggi NCC; **Analizza AI** sui consumi; **Export CSV**.
- **Km da Golia**: le letture dei km arrivano ogni giorno dagli export del portale Golia (cartella Drive "Golia – Export").
- Veicoli, rifornimenti, carichi serbatoio e manutenzioni del CRM vtenext si sincronizzano ogni notte.

## 7. Autisti

**Creare un autista**

1. Menu → **Autisti** → **Nuovo autista**: nome, cognome, email (valida e univoca: serve per login e notifiche), telefono.
2. Spunta **Crea account**: la password viene generata in automatico.
3. Annota la password e comunicala all'autista: dopo non è più recuperabile.

**Scadenze documenti**: Menu → **Scadenze autisti** → **Nuovo documento**: autista, tipo (patente, CQC, carta tachigrafica, visita medica…), numero, rilascio, scadenza. I documenti in scadenza entro 30 giorni compaiono in dashboard.

**Report mensile autista**: Menu → **Report autista** → autista e mese → giorni lavorati, ore effettive, tipo giornate, indennità di trasferta → **Export Excel** per il consulente del lavoro.

## 8. Commerciale

### 8.1 Flusso completo

| Passo | Cosa si fa |
| --- | --- |
| 1 Anagrafica | Creare il committente con tutti i dati fiscali |
| 2 Preventivo | Creare il preventivo (manuale o con AI) e inviarlo via email con PDF |
| 3 Accettazione | Il cliente accetta online dal link, oppure l'accettazione si registra a mano |
| 4 Foglio di viaggio | Convertire il preventivo in foglio con un clic, assegnare autista e veicolo |
| 5 Esecuzione | Inviare il foglio all'autista, che lo compila a fine servizio |
| 6 Verifica | Verificare il foglio, anche con Analizza AI |
| 7 Feedback | Chiedere la valutazione al cliente |
| 8 Fatturazione | Convertire il preventivo in fattura proforma |

### 8.2 Committenti

Menu → **Committenti** → **Nuovo cliente**: denominazione, P.IVA, codice fiscale, SDI/PEC, indirizzo, email, telefono, referente. Inserire sempre l'email: serve per preventivi, proforma e feedback.

### 8.3 Preventivi

1. Menu → **Preventivi** → **Nuovo preventivo**.
2. Manuale: committente, oggetto, tratta, tipo veicolo, voci di costo. Oppure **Genera con AI**: descrivi il servizio a parole (es. "Gita scolastica Roma 2 giorni 50 studenti pullman GT partenza Matera 10 giugno") e l'AI compila oggetto, tratta, veicolo e una stima dell'importo, da verificare sempre.
3. **Calendario giorni**: ogni giornata con data, partenza, arrivo, veicolo.
4. Salva e clicca l'aeroplano: il PDF viene generato e inviato al cliente, che può accettare o rifiutare dal link.
5. Accettazione manuale: icona utente-spunta → email e metodo. Rifiuto: X rossa. Un preventivo senza risposta dopo la validità va messo in "Scaduto"; i rifiutati restano in archivio e si possono duplicare con prezzi aggiornati.
6. Dal preventivo accettato: icona mappa verde → **foglio di viaggio** precompilato; icona documento viola → **fattura proforma** con i dati fiscali del committente.

### 8.4 Fatture proforma

Menu → **Fatture proforma** → apri la fattura → modifica se serve → **Stampa/PDF**. La proforma si crea dal preventivo, così mantiene gli importi concordati. La fattura elettronica resta sul software contabile esterno.

### 8.5 Feedback clienti

1. Sul foglio verificato o archiviato clicca **Richiedi feedback** (serve l'email del committente).
2. Il cliente valuta servizio e autista con le stelle, senza login.
3. Menu → **Feedback clienti**: valutazioni, medie e statistiche; **Rispondi al cliente** pubblica una risposta.

### 8.6 Biglietti TPL e incassi

Gli autisti registrano le vendite per comune e tipo di biglietto; **Report incassi** riepiloga per linea.

### 8.7 Noleggi

1. Menu → **Noleggi**: archivio dei noleggi dal 2022 (oltre 3.400) con ricerca e filtri.
2. **Sincronizza da Drive** importa le modifiche fatte nei file Excel "SCHEDA NOLEGGI": in caso di differenze vince sempre l'Excel.
3. Le richieste di preventivo arrivate dall'app Orari diventano noleggi con **Crea noleggio** (pagina Richieste preventivo).

## 9. Scadenzario

1. Menu → **Scadenzario** → nuova scadenza: categoria (fiscale, gara, assicurazione, contratto, altro), data, giorni di preavviso, eventuale ricorrenza, responsabile.
2. Le scadenze in arrivo vengono segnalate ogni giorno in automatico.
3. A cosa fatta, aggiorna lo stato.

## 10. Comunicazioni

**Chat**

1. Seleziona l'autista dall'elenco a sinistra e scrivi.
2. Messaggi **urgenti** in rosso con badge URGENTE; **Broadcast** per scrivere a tutti gli autisti insieme; cestino per eliminare un messaggio.
3. I link nei messaggi sono cliccabili (per esempio il planning).

**Notifiche push agli autisti**: ogni messaggio, turno assegnato, foglio di viaggio e risposta a una richiesta genera una notifica sul telefono dell'autista, anche ad app chiusa. Ogni autista riceve le notifiche su un solo telefono: l'ultimo da cui ha fatto l'accesso.

## 11. Report, export e impostazioni

- **Report autista**: export in Excel separati per autista, **PRESENZE1** (tutti gli autisti in un file) e **CSV consulente**. Il calcolo delle indennità TPL/NCC usa gli orari effettivi se inseriti, altrimenti quelli programmati.
- **Report ed export**: report con filtri ed Excel multi-foglio; **Statistiche** con grafici.
- **Backup mensile**: 5 CSV via email (presenze, fogli di viaggio, biglietti, manutenzioni, rifornimenti); l'indirizzo si imposta in Impostazioni.
- **Impostazioni**: email del backup, indennità di trasferta, rimborso km, credenziali degli autisti.

## 12. Assistente AI

Il pulsante **Assistente** in basso a destra risponde in italiano usando i dati reali del database.

| Per | Scrivi |
| --- | --- |
| Autista | Il cognome esatto come in anagrafica (es. "Armandi") |
| Veicolo | Il nome esatto come in anagrafica (es. "Mercedes Sprinter") |
| Data | GG/MM o GG/MM/AAAA |
| Mese | "maggio 2026" o "maggio" |

Esempi: "Quanti km ha il bus Mercedes?", "Armandi il 01/05 lavorava?", "Rossi era in ferie il 15 maggio?", "Come si duplica un foglio?". Nelle pagine ci sono anche **Analizza AI** (fogli di viaggio e consumi dei veicoli) e **Genera con AI** (preventivi).

## 13. App Orari e Manuali

- **App Orari**: le otto pagine (Linee e orari, Novità app, Notifiche app, Richieste preventivo, Segnalazioni app, Territorio: cosa mangiare, Foto: in giro con noi, Fermate: posizione) sono descritte nel **Manuale App Orari**.
- **Manuali e operatività**: questa sezione. Gli amministratori possono modificare i manuali (**Modifica**, con anteprima) e aggiungere procedure operative (**Nuovo documento**); **Stampa / PDF** stampa il documento aperto.

## 14. Sincronizzazioni automatiche

| Cosa | Da dove | Quando |
| --- | --- | --- |
| Veicoli, rifornimenti, carichi serbatoio, manutenzioni | CRM vtenext | Ogni notte |
| Fogli di viaggio | CRM vtenext | Su richiesta, solo le modifiche |
| Noleggi | File Excel su Google Drive | Pulsante Sincronizza da Drive |
| Km dei veicoli | Export di Golia nella cartella Drive "Golia – Export" | Ogni giorno |
| Avvisi dello Scadenzario | Scadenze inserite | Ogni giorno |

## 15. Problemi frequenti

| Problema | Soluzione |
| --- | --- |
| Pagina bianca dopo il login | Ctrl+Shift+R; se persiste, Esci, chiudi il browser e riapri |
| Sul telefono mancano le pagine nuove | Usa l'icona creata dall'indirizzo principale; elimina le icone vecchie; cancella i dati dell'app e riaccedi |
| Notifiche agli autisti non arrivano | L'autista deve toccare il banner "Abilita notifiche"; su iPhone l'app va installata dalla schermata Home con Safari |
| L'autista non vede il foglio | Il foglio deve essere "Inviato autista": in bozza lo vede solo l'amministrazione |
| L'autista non può modificare il foglio | I fogli compilati, verificati o archiviati sono bloccati: usa **Riapri** |
| Il preventivo non arriva al cliente | Controlla l'email in anagrafica e la cartella spam del cliente |
| Il PDF del preventivo non si apre | Il browser blocca i popup: abilitali per il dominio del gestionale |
| L'assistente non trova l'autista | Cognome esatto, attenzione ai cognomi composti (es. "De Angelis") |
| Errore "null value" | Mancano campi obbligatori (con asterisco) |
| Il caricamento turni rifiuta il file | Il PDF deve avere il testo selezionabile, non essere una scansione o una foto |
| Upload foto scontrino fallisce | Controlla la connessione; foto JPG/PNG sotto i 5 MB |
| Il gestionale non salva | L'utente non è amministratore |

## 16. Requisiti tecnici

| Voce | Dettaglio |
| --- | --- |
| Browser | Chrome 90 o superiore consigliato; Firefox, Safari, Edge recenti |
| Smartphone | Android 8 o superiore con Chrome; iPhone iOS 14 o superiore con Safari |
| Connessione | Necessaria per tutte le funzioni |
| Tecnologia | React + TypeScript + Vite, database Supabase (PostgreSQL), Cloudflare Pages, notifiche Firebase, email Resend, assistente Claude (Anthropic), app Android con Capacitor |

Aggiornamenti e pubblicazione si fanno dal **menu Strumenti**: sempre voce 2 all'inizio, voce 3 alla fine, e voce 2 prima della voce 5 (pubblica il gestionale).

## 17. Backup e ripristino

Tutti i dati del gestionale (turni, presenze, ferie, autisti, veicoli, noleggi, preventivi, fogli di viaggio, scadenze, orari dell'app e ogni altra tabella) vengono copiati **ogni notte** in un file compresso, in uno spazio privato visibile solo agli amministratori. Si conservano le copie degli **ultimi 30 giorni** e **una copia per ogni mese, per sempre**. Le tabelle nuove entrano nel backup da sole.

**Pagina Backup e ripristino**

1. In alto il riquadro **verde** indica la data dell'ultimo backup, quanti record contiene e quante copie sono conservate. Se diventa **giallo**, l'ultimo backup ha più di un giorno: premere **Fai un backup adesso** e avvisare chi segue la parte tecnica.
2. **Fai un backup adesso**: copia immediata, utile prima di un'operazione importante (per esempio un caricamento grosso di dati).
3. **Scarica**: salva sul computer il file della copia.
4. **Consulta**: si sceglie una tabella e si vedono i dati **com'erano in quella data**, con la ricerca e il pulsante **Scarica per Excel**. Consultare non modifica niente.

**Ripristinare dati cancellati o modificati per errore**

1. Apri la copia di una data in cui i dati erano giusti → **Consulta** → scegli la tabella.
2. Cerca i record, spunta quelli da recuperare → **Ripristina selezionati**. In alternativa **Ripristina tutta la tabella** (chiede di scrivere RIPRISTINA).
3. I record vengono riportati com'erano in quella data; gli altri dati non vengono toccati e i record creati dopo restano.
4. **Prima di ogni ripristino il sistema salva da solo un backup di sicurezza**: se il ripristino non era quello giusto, si torna indietro ripristinando da quella copia.

**Copie in nostro possesso, fuori da internet**

Il menu Strumenti scarica le copie sul PC e sulla chiavetta, nella cartella **BACKUP-DATABASE**: in automatico con la voce 2 (Aggiorna tutto) e quando si apre il menu dalla chiavetta, oppure a mano con la voce **9**. La prima volta su ogni postazione la voce 9 chiede la chiave dei backup, che si legge su Supabase (SQL Editor) con: `select decrypted_secret from vault.decrypted_secrets where name = 'backup_download_key';`

I file sono in formato aperto (JSON compresso): anche senza il gestionale si possono aprire e i dati restano leggibili. Insieme a ogni copia viene salvata anche la **struttura del database** (file `struttura-….sql`), che serve a ricostruirlo da zero (capitolo 18). Le foto (galleria, scontrini) sono conservate a parte nello spazio file e non fanno parte di questo backup.

## 18. Cosa fare in caso di emergenza

I dati non vivono sul PC né sulla chiavetta: stanno nel database su internet (Supabase), con una copia completa ogni notte. Ogni copia contiene **tutti i dati** e anche la **struttura del database** (tabelle, funzioni, regole di accesso), e viene scaricata anche su PC e chiavetta nella cartella **BACKUP-DATABASE** (file `.json.gz` con i dati e file `struttura-….sql` con la struttura).

| Dove sta | Cosa |
| --- | --- |
| Supabase (database) | Tutti i dati, sempre aggiornati |
| Supabase (spazio privato "backup") | Copie complete: ultimi 30 giorni e una per mese, per sempre |
| PC e chiavetta, cartella BACKUP-DATABASE | Le stesse copie, scaricate dal menu Strumenti |
| GitHub | Il codice del gestionale e dell'app Orari |
| Cloudflare | Gestionale e app pubblicati online |

### 18.1 Si rompe un PC

Gestionale e app continuano a funzionare online e nessun dato è perso.

1. Su un PC nuovo installa **Git** e **Node.js**.
2. Avvia il menu Strumenti dalla chiavetta (oppure scaricandolo da GitHub) e usa la **voce 1 – Prima installazione**: riscarica gestionale e app Orari. Le chiavi del database si leggono su Supabase → Project Settings → API.
3. Per pubblicare: `npx.cmd wrangler login` (Cloudflare) e `npx.cmd supabase login` (Supabase).
4. **Voce 9** con la chiave dei backup: il PC nuovo riscarica tutte le copie.

### 18.2 Si perde la chiavetta

Non si perdono dati, ma la chiavetta contiene le copie del database e la chiave per scaricarle: va resa inutile.

1. Su Supabase, SQL Editor, cambia la chiave dei backup:

```sql
select vault.update_secret((select id from vault.secrets where name = 'backup_download_key'), encode(extensions.gen_random_bytes(24), 'hex'));
select decrypted_secret from vault.decrypted_secrets where name = 'backup_download_key';
```

2. Sul PC cancella `BACKUP-DATABASE\chiave-backup.txt` e rifai la **voce 9** con la chiave nuova.
3. Prepara una chiavetta nuova con la **voce 6**.

Per prevenire: cifrare la chiavetta con **BitLocker** (tasto destro sull'unità → Attiva BitLocker → password). Senza password chi la trova non legge niente.

### 18.3 Dati cancellati o modificati per errore

Pagina **Backup e ripristino** → copia di un giorno in cui i dati erano giusti → **Consulta** → tabella → spunta i record → **Ripristina selezionati** (vedi capitolo 17). Prima di ogni ripristino viene salvato un backup di sicurezza.

### 18.4 Il database su internet non è più disponibile

È il caso più improbabile (Supabase ha anche i suoi backup), ma le copie in nostro possesso bastano a ricostruire tutto:

1. Crea un nuovo progetto Supabase.
2. Nello SQL Editor esegui il file `struttura-….sql` più recente della cartella BACKUP-DATABASE: ricrea tabelle, funzioni e regole di accesso.
3. Carica i dati dal file `backup-….json.gz` della stessa data: è un'operazione tecnica, da fare con l'assistenza di chi segue il gestionale, ma il file contiene tutti i record di tutte le tabelle in formato aperto.
4. Aggiorna le chiavi del nuovo progetto nei file `.env` e su Cloudflare, poi ripubblica gestionale e app (voci 4 e 5).

### 18.5 Cose da custodire a parte

Alcune credenziali, per sicurezza, non stanno su GitHub. Conservarne una copia in un gestore di password o in un documento custodito:

- accesso a Supabase, Cloudflare, GitHub e Google (account aziendale);
- password della posta Aruba usata per le email automatiche (SMTP);
- chiavi delle notifiche (VAPID), eventuale chiave Anthropic, credenziali del service account Google per le sincronizzazioni;
- la chiave dei backup (si può sempre rileggere da Supabase);
- in futuro, la chiave di firma dell'app per il Play Store.
$md$, aggiornato_il = now() where slug = 'manuale-gestionale';

update manuali set titolo = 'Manuale App Autisti', contenuto = $md$# Manuale App Autisti

Versione 3.0 — Ottobre 2026. Unisce la Guida Autista v2.2 (maggio 2026) e la parte "Area Autista" del Manuale Utente v4.1 (giugno 2026).

## 1. Installa l'app sul telefono

**Importante:** installa l'app sulla schermata Home. Solo così ricevi le notifiche anche con il telefono in tasca, come WhatsApp.

**Opzione A — dal browser (Android e iPhone)**

Android (Samsung, Huawei, Xiaomi…):

1. Apri **Chrome** e vai su **deangelisbussrl-app.pages.dev**.
2. Tocca i **tre puntini** in alto a destra → **Aggiungi a schermata Home** → **Aggiungi**.

iPhone:

1. Apri **Safari** e vai su **deangelisbussrl-app.pages.dev**.
2. Tocca **Condividi** (quadrato con la freccia) → **Aggiungi alla schermata Home** → **Aggiungi**.

Su iPhone le notifiche funzionano solo con l'app aggiunta alla schermata Home da Safari.

**Opzione B — APK (solo Android)**

1. Ricevi il file dell'app dall'ufficio (WhatsApp o USB).
2. Impostazioni del telefono → Sicurezza → attiva **Installa app sconosciute**.
3. Apri il file e tocca **Installa**. Funziona come la versione dal browser, notifiche comprese.

## 2. Primo accesso e notifiche

1. Apri l'app dall'icona sulla schermata Home (non dal browser).
2. Inserisci email e password ricevute dall'ufficio → **Accedi**.
3. Se compare il banner **"Attiva notifiche"**, toccalo subito; quando il telefono chiede **"Consenti notifiche?"** tocca **Consenti**.

Si fa una volta sola. Le notifiche arrivano su **un solo telefono**: quello da cui hai fatto l'ultimo accesso.

## 3. La schermata principale

Mostra il **turno di oggi** con gli orari, i **prossimi turni** e i pulsanti per tutte le funzioni. Tocca un turno per vedere veicolo, orario e tipo di servizio.

**Turni sul calendario del telefono**: nel box verde **"Sincronizza turni con Google Calendar"**:

- **Apri in Google Calendar** → **Aggiungi calendario**: i turni si aggiornano da soli quando l'ufficio carica i nuovi;
- **Copia URL** → incollalo in Apple Calendar o Outlook come "Sottoscrivi calendario";
- **Scarica .ics** per importare i turni una sola volta.

## 4. Turni e planning

- **I miei turni**: calendario personale con tutti i turni assegnati.
- **Planning settimanale**: ogni settimana l'ufficio lo invia in chat. Tocca la notifica o apri la **Chat** → tocca il link nel messaggio → si apre la tabella con tutti gli autisti; scorri in orizzontale per vedere tutti i giorni.

## 5. Registra la presenza

1. Tocca il pulsante verde **Conferma presenza**.
2. Controlla l'orario mostrato.
3. Tocca **Conferma**: l'ufficio la vede subito.

## 6. Fogli di viaggio (NCC e noleggio)

**Trovare il foglio**: menu → **Fogli di viaggio**. Quelli **da compilare** hanno il bordo blu e il badge "Da compilare"; tocca il foglio o **Compila ora**.

**Compilare**

1. **Programma giorni**: per ogni giornata km iniziali e finali, ora di partenza e di arrivo effettive; se il percorso è cambiato, una nota sulla riga.
2. **Spese di viaggio**: aggiungi ogni spesa (pedaggi, parcheggi…) con descrizione, importo e se pagata con carta aziendale o in contanti; tocca la **fotocamera** per allegare la foto dello scontrino.
3. **Osservazioni autista**: eventuali note per l'ufficio.
4. Tocca **Invia all'ufficio**.

Una volta inviato, il foglio **non si può più modificare**: controlla bene prima. Ricevi una notifica quando l'ufficio lo approva o chiede una correzione.

**Note e comunicazioni**: in fondo al foglio puoi scrivere all'ufficio a proposito di quel servizio; l'ufficio riceve la notifica. I fogli già chiusi restano consultabili in sola lettura.

## 7. Altre funzioni

**Rifornimenti**

1. Menu → **Rifornimenti** → scegli il veicolo.
2. Inserisci litri, costo e distributore (anche con foto) → **Invia**. Il consumo km/litro si calcola da solo.

**Richiesta ferie e permessi**

1. Menu → **Richieste** → tipo: ferie, permesso o altra assenza.
2. Scegli le date, aggiungi una nota se serve → **Invia richiesta**.
3. Ricevi una notifica quando l'ufficio risponde.

**Biglietti TPL**: se lavori sulle linee, registra i biglietti venduti per comune e tipo; a fine turno inserisci il totale incassato per la quadratura.

**Segnala anomalia veicolo**

1. Dalla schermata principale tocca il pulsante rosso **Segnala anomalia veicolo**.
2. Scegli veicolo e tipo di problema (freni, luci, motore, pneumatici, sterzo, porte…).
3. Urgenza: **Bassa** (da verificare), **Media** (prima possibile), **Alta** (non partire!).
4. Descrivi il problema → **Invia segnalazione**. Con urgenza alta l'ufficio riceve subito una notifica: non effettuare il servizio senza autorizzazione.

**Chat con l'ufficio**: scrivi all'ufficio e ricevi una notifica per ogni risposta. I link nei messaggi sono cliccabili; puoi eliminare i tuoi messaggi con il cestino.

**Assistente**: il pulsante in basso a destra risponde alle domande sull'app, per esempio "Come registro la presenza?", "Come compilo il foglio di viaggio?", "Come chiedo le ferie?".

## 8. Le notifiche

Ricevi una notifica quando:

- l'ufficio carica i turni o invia il planning;
- ti viene assegnato un foglio di viaggio;
- il foglio compilato viene approvato o richiede correzioni;
- la richiesta di ferie o permesso viene approvata o rifiutata;
- arriva un messaggio in chat.

Tocca la notifica per aprire l'app direttamente nella sezione giusta.

## 9. Problemi comuni

| Problema | Cosa fare |
| --- | --- |
| Non ricevo le notifiche | Apri l'app dall'icona sulla schermata Home; Impostazioni → App → Chrome → Notifiche → attiva; esci dall'app e rientra; tocca il banner "Attiva notifiche" se compare. Se hai cambiato telefono, accedi da quello nuovo |
| Non riesco ad accedere | Controlla la connessione e email/password (attenzione alle maiuscole); per la password dimenticata contatta l'ufficio |
| Non vedo i miei turni | I turni vengono caricati ogni settimana; trascina la pagina verso il basso per aggiornare; se mancano ancora, contatta l'ufficio |
| Non vedo il foglio di viaggio | L'ufficio deve averlo inviato: se è ancora in bozza non lo vedi |
| L'app non si aggiorna | Chiudi e riapri l'app; se non basta: Impostazioni → App → deAngelisBus → Cancella cache; in ultimo disinstalla e reinstalla |
| La foto dello scontrino non si carica | Controlla la connessione; foto JPG/PNG sotto i 5 MB |

Per qualsiasi problema contatta l'ufficio — De Angelis Bus S.r.l., Grottole (MT).
$md$, aggiornato_il = now() where slug = 'manuale-app-autisti';

update manuali set titolo = 'Manuale App Orari', contenuto = $md$# Manuale App Orari Deangelisbus

## 1. Introduzione

L'app **Orari De Angelis Bus** ha due anime. È prima di tutto uno strumento **informativo**: orari, fermate e prossimi bus di tutte le corse esercitate da De Angelis Bus S.r.l., con biglietti, segnalazioni e assistente. Ma è anche una **vetrina del territorio** in cui viaggia: i Sassi di Matera, i borghi di Grottole, Miglionico e Montescaglioso, i loro monumenti, eventi, piatti tipici e ristoranti, le foto dei nostri viaggi, e l'invito a organizzare una gita con i nostri bus.

Così chi apre l'app per sapere quando passa il bus scopre anche cosa vedere e dove mangiare, e il turista che cerca un transfer trova un motivo in più per fermarsi. Tutti i contenuti che cambiano (orari, novità, foto, piatti, ristoranti, posizione delle fermate) si gestiscono dal **gestionale** o dal **database**, senza ripubblicare l'app.

Il manuale ha due parti: le sezioni 2–7 spiegano l'app dal lato del **passeggero**; le sezioni 8–12 spiegano come **gestirla** dal gestionale.

| Componente | A cosa serve | Dove si trova |
| --- | --- | --- |
| App web | L'app che usano i clienti, installabile dal QR code | https://orari.deangelisbus.it (Cloudflare Pages, progetto `orari-deangelisbus`) |
| App Android | Versione per il Play Store, oggi solo di prova | Pacchetto `it.deangelisbus.orari`, si compila con Android Studio |
| Gestionale | Pagine "App Orari" per linee, novità, notifiche, richieste, segnalazioni, territorio, foto, fermate | amministrazione-deangelisbus-v2 (Cloudflare Pages) |
| Database | Orari, fermate, richieste, segnalazioni, contenuti | Supabase, progetto `hmdpaypyljdgoehztbvi` |
| Codice sorgente | Copia di sicurezza e scambio tra PC | GitHub: `orari-deangelisbus` (ramo main) e `deangelisbus-gestionale` (ramo master) |
| Email automatiche | Avvisano l'ufficio di preventivi e segnalazioni | Funzione Supabase `notifica-preventivo` (posta Aruba) |

Tutti gli orari partono dal database: l'app li scarica all'apertura e ne tiene una copia sul telefono, così funziona anche senza rete.

## 2. Installazione per i passeggeri

Oggi l'app si installa dal **QR code** o dal link https://orari.deangelisbus.it: è gratuita, non serve registrarsi e pesa pochissimo.

**Su Android (Chrome)**

1. Inquadra il QR code con la fotocamera (locandina sui bus, oppure "Passa l'app a un amico" dal telefono di un altro utente) e tocca il link.
2. Si apre l'app nel browser. In fondo alla Home c'è il riquadro **"Installa l'app sul telefono"**: tocca **Installa**. In alternativa: menu di Chrome (tre puntini) → **Aggiungi a schermata Home**.
3. Sulla schermata del telefono compare l'icona **Orari**: da quel momento l'app si apre a tutto schermo come le altre.

**Su iPhone (Safari)**

1. Apri il link in **Safari**.
2. Tocca il pulsante **Condividi** (quadrato con la freccia) → **Aggiungi alla schermata Home** → **Aggiungi**.

**Aggiornamenti.** L'app web si aggiorna da sola: dopo ogni pubblicazione basta chiuderla e riaprirla (a volte due volte). Il riquadro "Installa l'app" sparisce da solo quando l'app è già installata.

**App Android (Play Store).** La versione nativa `it.deangelisbus.orari` esiste ed è provata con Android Studio, ma non è ancora pubblicata. Rispetto all'app web ha in più il pulsante **Esci** che chiude davvero l'app; in futuro le notifiche. Per la pubblicazione servono account sviluppatore aziendale (D-U-N-S), aggiornamento ad Android 16 (API 36), chiave di firma e informativa privacy.

**Locandina.** Per i bus e le fermate c'è la locandina A4 con il QR: `stampa\locandina-orari-A4.pdf` (il QR da solo: `stampa\qr-orari-deangelisbus.png`).

## 3. Primo avvio e Home

Al primo avvio conviene scegliere la **fermata principale**: da quel momento la Home mostra subito il prossimo bus da lì.

1. In Home tocca il riquadro blu **"Il tuo prossimo bus"** (o la scheda **Partenze** in basso).
2. Cerca la fermata per nome o paese e scegli **"Usa come mia fermata"**.
3. Il riquadro mostra l'orario del prossimo bus, i minuti che mancano e la destinazione.

**Ordine della Home, dall'alto in basso**

1. Eventuale **avviso di novità da leggere** (banner rosso o giallo).
2. Benvenuto e **prossimo bus** dalla fermata principale.
3. **Le mie fermate** (se ne hai salvate), **Fermate vicino a me** e l'invito ad attivare le notifiche.
4. **Novità ed eventi**.
5. **Menu dei servizi**: trasporto extraurbano, scolastici (Grottole, Miglionico, Montescaglioso), urbani, disabili Matera, navetta Matera – Aeroporto di Bari, linea Matera – Policoro, più le linee nuove create dal gestionale.
6. **Acquista biglietti e abbonamenti** (biglietteria Cotrab).
7. **Feedback, reclami e segnalazioni**.
8. **Scopri il territorio**.
9. **Noleggio con conducente** (richiesta preventivo).
10. **Viaggi di gruppo** con Ridola Viaggi.
11. **In giro con noi** (galleria foto), **I nostri bus**, **Visita il nostro sito**, **Passa l'app a un amico**, **Installa l'app**.

**Comandi sempre presenti**

- **Barra in basso**: Home, Partenze, Da – a, Mappa, Info.
- **"‹ Indietro"** in alto a sinistra in tutte le pagine interne; funziona anche il tasto indietro di Android.
- **Assistente** (pulsante rotondo in basso a destra).
- **Esci** in alto a destra in Home: nell'app Android chiude l'app; nell'app web installata prova a chiuderla e, se il telefono non lo consente, spiega come fare.
- Riaprendo l'app dopo almeno 30 secondi si torna sempre alla Home.

## 4. Consultare gli orari

Gli orari si trovano in quattro modi: per fermata, per servizio, da un posto a un altro, sulla mappa.

**Per fermata (Partenze)**

1. Scheda **Partenze** → scegli la fermata.
2. Il riquadro grande mostra il **prossimo bus** e tra quanti minuti passa; sotto, tutte le partenze di **Oggi** o **Domani**.
3. Tocca un orario per vedere la corsa completa.

**Per servizio (menu in Home)**

1. Tocca un servizio, per esempio **Trasporto pubblico extraurbano**, poi la linea.
2. In alto scegli la direzione (per gli scolastici: **Andata a scuola / Ritorno da scuola**) e il giorno (Oggi, Domani, i giorni successivi).
3. Ogni riga mostra partenza → arrivo, il percorso e i giorni in cui circola; negli scolastici anche **Secondaria, Primaria o Infanzia**.

**Da – a**: scegli fermata di partenza e di arrivo; l'app mostra le corse dirette del giorno con orari e, per le linee Cotrab, la tariffa.

**Mappa**: mostra le fermate con la posizione; tocca un segnaposto per aprire le partenze.

**Dettaglio corsa**: tutte le fermate con l'orario di passaggio, i giorni di circolazione e il pulsante **Condividi questo orario**.

**Come leggere gli orari**

| Simbolo o scritta | Significato |
| --- | --- |
| ~12:35 | Orario **stimato** in base ai chilometri: le fermate intermedie non hanno un orario ufficiale |
| solo giorni di scuola | La corsa non c'è nei giorni di vacanza scolastica e di sospensione |
| dal lunedì al sabato / tutti i giorni | Giorni in cui circola la corsa |
| Riquadro verde "effettuate da Deangelisbus" | Navetta Bari: mese in cui la svolgiamo noi |
| Riquadro giallo "effettuate da Autobus Tito" | Navetta Bari: stessi orari, mese svolto dall'altra azienda del consorzio |

**Navetta Matera – Aeroporto di Bari.** Sono le corse Cotrab 3 e 5, tutti i giorni festivi compresi: verso Bari alle 8:30 e 14:00, verso Matera alle 11:30 e 17:00. Le svolgiamo a mesi alterni con Autobus Tito; l'app le mostra tutti i mesi e indica chi effettua il servizio. Biglietti solo online su www.marozzivt.it.

## 5. Funzioni personali

Queste funzioni rendono l'app "propria": restano sul telefono dell'utente e non richiedono registrazione.

**Le mie fermate** (fino a 4, oltre alla fermata principale)

1. Apri una fermata (da Partenze, Mappa o Fermate vicino a me).
2. Tocca **"☆ Salva tra le mie fermate"**: diventa **"★ Fermata salvata"**.
3. In Home compare la sezione **Le mie fermate** con il prossimo bus di ognuna; per toglierla, tocca di nuovo la stellina.

**Fermate vicino a me**

1. In Home tocca **"Fermate vicino a me"**; la prima volta consenti l'accesso alla posizione.
2. Compaiono le **6 fermate più vicine** con distanza e prossimo bus; tocca una fermata per aprirla.
3. **"Aggiorna posizione"** in fondo, se ti sposti.

Se il permesso è stato negato: Impostazioni del telefono → Posizione → l'app (o Chrome) → Consenti. Funziona solo per le fermate che hanno la posizione sulla mappa (vedi 8.6).

**Condividi questo orario**

1. Apri una corsa e tocca il pulsante verde **"Condividi questo orario"**.
2. Scegli WhatsApp, SMS o email e il contatto: parte un messaggio con linea, giorno, partenza, arrivo e link all'app.

**Passa l'app a un amico** (in Home e in Info)

1. Tocca **"Passa l'app a un amico"**: compare il QR code a tutto schermo.
2. L'altra persona lo inquadra con la fotocamera e tocca il link.
3. Se non è presente, usa **"Oppure invia il link"**. Il QR funziona anche senza rete.

**Avvisi delle novità e notifiche**

- **Banner in Home**: quando c'è una novità non ancora letta compare in cima alla Home, **rosso** per le variazioni del servizio (scioperi, deviazioni), **giallo** per novità ed eventi. Toccandolo si apre la pagina Novità ed eventi, dove le nuove hanno l'etichetta **Nuova**; la ✕ lo chiude. La voce "Novità ed eventi" del menu mostra un **pallino rosso** con il numero di quelle da leggere.
- **Notifiche sul telefono**: in Home (una volta sola) e sempre in **Info** c'è il riquadro **"Avvisi sul telefono"**. Tocca **Attiva le notifiche** e poi **Consenti**: da quel momento scioperi, variazioni e novità importanti arrivano come notifica anche ad app chiusa; toccandola si apre la pagina Novità. Dallo stesso riquadro in Info si disattivano.
- Su **iPhone** le notifiche funzionano solo con l'app aggiunta alla schermata Home (iOS 16.4 o successivo). L'app Android di prova non le riceve ancora: arriveranno con il Play Store. Se sono state bloccate: Impostazioni del telefono → Notifiche → l'app o Chrome.

## 6. Servizi per il passeggero

Ogni servizio dell'app porta a un'azione concreta; quelli che inviano dati arrivano in ufficio per email e nel gestionale.

| Servizio | Cosa fa il passeggero | Dove arriva |
| --- | --- | --- |
| Acquista biglietti e abbonamenti | Apre la biglietteria online Cotrab (biglietteria.cotrab.it): paga con carta e ha il titolo sul telefono | Sito Cotrab |
| Richiedi un preventivo (Noleggio con conducente) | Compila il modulo, uguale a quello del sito | Email a info@ e tiziana@ + gestionale → Richieste preventivo |
| Feedback, reclami e segnalazioni | Sceglie il tipo, descrive, può restare anonimo | Email + gestionale → Segnalazioni app |
| Assistente | Fa domande in linguaggio naturale su orari, fermate, biglietti, uso dell'app | Risponde l'intelligenza artificiale |
| Novità ed eventi | Legge avvisi, eventi e variazioni del servizio | Gestite dal gestionale → Novità app |

**Richiesta preventivo, passo passo**

1. Home → **"Richiedi un preventivo"** (card blu del noleggio).
2. Campi obbligatori: Nome, Cognome, Telefono, Data partenza e rientro, Luogo partenza e destinazione, Email, consenso privacy. Facoltativi: Azienda, Ora partenza e rientro, Partecipanti, Itinerario, Ulteriori informazioni.
3. **Invia**: compare la conferma "risposta entro 48 ore, preventivo non vincolante". Se manca la rete, c'è il link per scrivere a commerciale@deangelisbus.it.

**Segnalazione, passo passo**

1. Home → **"Feedback, reclami e segnalazioni"**.
2. Scegli: Reclamo, Segnalazione, Suggerimento o Complimento; indica linea, data e ora se servono; descrivi.
3. Lascia nome e contatto per ricevere risposta, oppure invia **in forma anonima**.

**Assistente virtuale**

1. Tocca **Assistente** in basso a destra.
2. Scrivi la domanda o tocca un esempio ("Quando passa il prossimo bus?").
3. Si può continuare la conversazione; **"Nuova domanda"** ricomincia da capo, **"Chiudi"** torna alla pagina di prima.

L'assistente conosce tutti gli orari, le tariffe, le novità, i contenuti del territorio e le istruzioni d'uso dell'app. Con il motore gratuito risponde a circa 30–40 domande al giorno; poi avvisa e riprende il giorno dopo.

## 7. Territorio, galleria e viaggi di gruppo

È la parte dell'app che **promuove il territorio**: trasforma un orario in un invito a scoprire i paesi serviti, sostiene le attività locali (ristoranti, eventi, agenzia Ridola) e porta nuovi clienti al noleggio con le gite organizzate. Anche l'assistente virtuale conosce questi contenuti e li suggerisce a chi chiede.

**Scopri il territorio**

1. Home → card **"Scopri il territorio"**.
2. In alto i nomi dei paesi (Matera, Grottole, Miglionico, Montescaglioso): toccandoli si salta alla scheda.
3. Ogni scheda ha: cosa vedere, l'evento da non perdere, **Cosa mangiare** (piatti tipici e fino a 4 ristoranti con Chiama, Sito, Mappa), i pulsanti per gli orari dei bus e **"Organizza una gita con i nostri bus"** che apre il preventivo.

I testi su monumenti ed eventi sono nel codice dell'app (`src\lib\territorio.ts`): per cambiarli serve una nuova pubblicazione. Piatti e ristoranti invece si gestiscono dal gestionale (8.4).

**In giro con noi (galleria foto)**

1. Home → card **"In giro con noi"** (compare quando ci sono foto) o da Scopri il territorio.
2. Tocca una foto per vederla a tutto schermo, con didascalia e autore; frecce per scorrere.
3. **"▶ Guarda la presentazione"**: le foto scorrono da sole ogni 5 secondi con la musica di sottofondo; pulsanti per pausa, avanti/indietro, musica sì/no, chiudi.

Se la musica non si sente, controllare il volume multimediale del telefono.

**Viaggi di gruppo con Ridola Viaggi**

La card verde con il logo Ridola porta al sito ridolaviaggi.com, dove sono pubblicati i viaggi in programma. Non c'è nulla da gestire nell'app: i viaggi si aggiornano sul sito dell'agenzia.

## 8. Gestione dal gestionale

Nel menu del gestionale, sezione App Orari, ci sono otto pagine; ogni modifica salvata compare nell'app alla riapertura successiva, senza pubblicare nulla. Servono le credenziali di amministratore.

| Pagina del gestionale | Cosa gestisce | Effetto nell'app |
| --- | --- | --- |
| Linee e orari | Linee, percorsi con fermate e minuti, corse, sospensioni e periodi | Tutti gli orari, le linee e il menu dei servizi |
| Novità app | Novità, eventi, variazioni del servizio | Sezione Novità ed eventi e banner "da leggere" in Home |
| Notifiche app | Notifiche push ai telefoni iscritti, storico invii | Notifica sul telefono, anche ad app chiusa |
| Richieste preventivo | Richieste arrivate dal modulo noleggio | Nessuno (lavoro d'ufficio) |
| Segnalazioni app | Reclami, segnalazioni, suggerimenti, complimenti | Nessuno (lavoro d'ufficio) |
| Territorio: cosa mangiare | Piatti tipici e ristoranti per paese | Riquadro Cosa mangiare in Scopri il territorio |
| Foto: in giro con noi | Foto della galleria e musica della presentazione | Card e galleria In giro con noi |
| Fermate: posizione | Posizione sulla mappa di ogni fermata | Mappa e Fermate vicino a me |

### 8.1 Richieste preventivo

1. Apri **Richieste preventivo**: l'elenco si aggiorna da solo quando arriva una richiesta (arriva anche l'email "Preventivo app: …").
2. Filtra per **stato** e per tipo.
3. Apri la richiesta: **Chiama**, **Email** (risposta precompilata), note interne visibili solo all'ufficio, cambio stato.
4. **Crea noleggio**: apre il modulo Noleggi già compilato con committente, itinerario, date e note; la richiesta resta collegata al noleggio.
5. **Elimina** solo per richieste di prova o spam.

### 8.2 Segnalazioni app

1. Apri **Segnalazioni app** (arriva anche l'email "Segnalazione app: …").
2. Filtra per tipo e stato; leggi linea, data e descrizione.
3. Se il passeggero ha lasciato i contatti: **Chiama** o **Rispondi via email**. Annota l'esito nelle note interne e chiudi la segnalazione.

### 8.3 Novità app

1. Apri **Novità app** → **Nuova notizia**.
2. Scegli il **tipo**: Novità, Evento (con data) o Variazione del servizio (per scioperi, deviazioni, sospensioni).
3. Scrivi titolo e testo e compila gli altri campi proposti (per gli eventi la data). Attenzione alla data **"visibile dal"**: se è nel futuro la novità compare solo da quel giorno.
4. Salva. Per toglierla prima: **nascondi** o elimina.

### 8.4 Territorio: cosa mangiare

1. Apri **Territorio: cosa mangiare**: le voci sono divise per paese, in Piatti tipici e Ristoranti.
2. **Aggiungi piatto**: nome e una o due righe di descrizione.
3. **Aggiungi ristorante**: nome, descrizione breve, indirizzo, telefono, sito; l'app ne mostra al massimo 4 per paese.
4. Usa **Ordine** (1 = primo) per decidere la sequenza; l'occhio nasconde una voce senza cancellarla (per esempio un locale chiuso per la stagione).

### 8.5 Foto: in giro con noi

1. Apri **Foto: in giro con noi** → **Scegli foto**: si possono selezionare molte foto insieme, dal PC o dal telefono.
2. Le foto vengono rimpicciolite in automatico (lato lungo 1600 pixel); il nome del file diventa la didascalia: correggila e premi **Salva** sotto la foto.
3. **Autore**: preimpostato "Deangelisbus"; **Ordine** per la sequenza; occhio per nascondere, cestino per eliminare.
4. **Musica di sottofondo**: carica un file **MP3**, ascoltalo, sostituiscilo o toglilo. Solo musica libera da diritti (Audio Library di YouTube, Pixabay Music) o con licenza.

Usare solo foto proprie o con il permesso dell'autore; evitare foto con clienti riconoscibili senza il loro consenso.

### 8.6 Fermate: posizione

1. Apri **Fermate: posizione**. A sinistra l'elenco con il filtro **Senza posizione** (icona rossa) o **Tutte**; a destra la mappa, con le fermate già posizionate come puntini grigi.
2. Scegli una fermata: la mappa si sposta sul suo paese.
3. Dal PC: **clicca sulla mappa** nel punto esatto (casella **Satellite** per riconoscere piazze e pensiline); trascina il segnaposto rosso per correggere.
4. Sul posto, con il telefono: **"Usa la mia posizione"**.
5. **Salva**: l'icona diventa verde e la fermata compare nella Mappa e in Fermate vicino a me.

### 8.7 Linee e orari

La pagina **Linee e orari** gestisce tutto il servizio di linea. A sinistra le linee divise per categoria; scelta una linea, a destra quattro schede.

**Corse e orari** (andata e ritorno, una corsa per riga)

1. Modifica partenza, percorso, descrizione (es. Primaria), nota per i passeggeri, giorni (L M M G V S D), scuola (Sempre / Solo giorni di scuola / Solo vacanze) e **Attiva**. L'arrivo si calcola da solo.
2. Le righe modificate diventano **gialle** e in alto compare la barra **"corse modificate non ancora salvate"**: premi **Salva tutto** (o il dischetto verde della riga) e attendi il messaggio verde. **Annulla le modifiche** torna ai dati salvati.
3. **Nuova corsa** aggiunge una riga; **Duplica** crea una copia da cambiare solo nell'orario; il cestino elimina.
4. Per sospendere una corsa senza cancellarla: togli **Attiva** e salva.

**Percorsi e fermate**

1. Scegli il percorso, oppure crea **Percorso di andata** o **di ritorno**.
2. Aggiungi le fermate in ordine dal menu in fondo (raggruppate per paese) o **crea una fermata nuova**; frecce per spostarle, cestino per toglierle.
3. Indica i **minuti dalla partenza**: 0 per il capolinea, poi valori crescenti.
4. **Salva percorso**. Il percorso vale per tutte le corse che lo usano: per un giro diverso crea un altro percorso.

**Dati della linea**: nome mostrato nell'app, categoria, comune, colore, committente, ordine nel menu, "a mesi alterni con", informazioni per i passeggeri, **Attiva** (togliendola la linea sparisce dall'app), subappalto. Da qui si elimina anche la linea, con doppia conferma.

**Calendario**

1. **Sospensioni**: dal / al, "solo corse scolastiche" (vacanze) o "tutte le corse" (fermo), per tutte le linee o solo per questa, descrizione.
2. **Periodi di servizio**: se presenti, la linea circola solo in quelle date; "solo informativo" indica i mesi svolti da noi senza nascondere le corse (come la navetta Bari).

**Creare un servizio nuovo** (es. urbano di Montescaglioso)

1. **+ Nuova linea…** → scegli la voce già presente nel menu dell'app (Montescaglioso – Servizio urbano o Trasporto scolastico) oppure **Altra linea…**: le linee nuove compaiono da sole nel menu della Home.
2. Crea i percorsi con le fermate e i minuti.
3. Crea la prima corsa, poi usa Duplica per le altre.
4. Posiziona le fermate nuove in **Fermate: posizione** (8.6).

Le modifiche sono subito visibili ai passeggeri dopo **Info → Aggiorna orari** o la riapertura dell'app: per i cambi grossi (nuovo anno scolastico) conviene lavorare con calma e controllare l'app alla fine.

### 8.8 Notifiche app

La pagina **Notifiche app** invia un avviso sul telefono di tutti i passeggeri che hanno attivato le notifiche. In alto c'è il numero di **telefoni iscritti**.

1. Pubblica prima la novità in **Novità app** (per esempio una Variazione del servizio).
2. In **Notifiche app**, a destra, tocca la novità: titolo e testo si compilano da soli (per le variazioni il titolo inizia con ⚠️). In alternativa scrivi a mano titolo (massimo 80 caratteri) e testo (massimo 200).
3. Controlla l'**anteprima** e premi **Invia a N telefoni**, poi conferma.
4. In fondo, negli **Ultimi invii**, compare quante notifiche sono state consegnate; le iscrizioni di telefoni che hanno disinstallato l'app vengono tolte da sole.

Usarle solo per avvisi importanti (scioperi, deviazioni, corse soppresse, novità di rilievo): troppe notifiche spingono i passeggeri a disattivarle. Le novità pubblicate senza notifica compaiono comunque nel banner della Home.

## 9. Orari e dati su Supabase

Linee, fermate, percorsi, corse e calendario si gestiscono dal gestionale, pagina **Linee e orari** (8.7). Supabase (supabase.com → progetto `hmdpaypyljdgoehztbvi`) serve solo per i caricamenti in blocco con lo **SQL Editor** e per le tabelle senza pagina, come le tariffe. Dopo ogni modifica, sul telefono: **Info → Aggiorna orari** o riaprire l'app.

| Tabella | Contenuto | Quando si tocca |
| --- | --- | --- |
| orari_linee | Linee e servizi (nome, colore, categoria, comune, testo informativo) | Nuovo servizio o cambio descrizione |
| orari_fermate | Fermate (nome, comune, posizione) | Nuova fermata; la posizione si mette dal gestionale (8.6) |
| orari_percorsi + orari_percorsi_fermate | Sequenza delle fermate e minuti dal capolinea | Cambio di percorso |
| orari_corse | Ogni corsa: orario di partenza, giorni (1 = lunedì … 7 = domenica), solo giorni di scuola, attiva | Nuovi orari, corsa soppressa |
| orari_periodi | Periodi di attività di una linea (o mesi informativi, come la navetta Bari) | Servizi stagionali |
| orari_sospensioni | Giorni senza servizio: vacanze scolastiche (ambito scolastico) o fermo totale (ambito tutti) | Calendario scolastico, festività |
| orari_tariffe | Tariffe Cotrab tra zone | Aggiornamento tariffe |
| orari_novita, richieste_preventivo, segnalazioni_app, territorio_gusto, territorio_foto, push_iscrizioni, push_invii | Contenuti gestiti dal gestionale | Solo dal gestionale |

**Operazioni frequenti**

1. **Corsa soppressa per un periodo**: Linee e orari → Corse e orari → togli **Attiva** → Salva tutto (rimettila alla ripresa). Se è un'interruzione da comunicare, aggiungi anche una Variazione del servizio in Novità app.
2. **Vacanze scolastiche**: Linee e orari → Calendario → Sospensioni, "solo corse scolastiche", per tutte le linee. Le corse "solo giorni di scuola" spariscono in quei giorni.
3. **Nuovi orari di un servizio**: dalla pagina Linee e orari (8.7). Per un orario lungo da PDF o Excel conviene farsi preparare il file SQL e incollarlo nello SQL Editor, come per lo scolastico di Grottole.

**File SQL già eseguiti** (cartella `orari-deangelisbus\sql`, nell'ordine): v1 dati Cotrab, v2 servizi e calendario, v3 nuovi servizi, v4 colori e preventivi, v5 email, v6 novità, v7 permessi gestionale, v8 collegamento noleggi, v9 navetta e segnalazioni, v10 preventivo come il sito, v11 viaggi (non usata), v12 scolastico Grottole, v13 navetta corse 3 e 5, v14 navetta mesi alterni, v15 cosa mangiare, v16 foto, v17 notifiche push, v18 manuali. Si possono rieseguire senza danni.

## 10. Pubblicazione e manutenzione

Tutte le operazioni tecniche passano dal **menu Strumenti** (`orari-deangelisbus\strumenti\DeAngelisBus-Strumenti.bat`, icona sul Desktop), uguale su ogni PC e sulla chiavetta.

| Voce | Quando |
| --- | --- |
| 1 Prima installazione | Solo su un PC nuovo |
| 2 Aggiorna tutto | **Sempre all'inizio**: scarica da GitHub il lavoro fatto altrove |
| 3 Salva tutto su GitHub | **Sempre alla fine**: alla domanda rispondi `s`, poi una descrizione breve |
| 4 Pubblica l'app Orari | Dopo una modifica al codice dell'app (non serve per orari e contenuti) |
| 5 Pubblica il gestionale | Dopo una modifica al codice del gestionale |
| 6 Copia su chiavetta | Copia di sicurezza |
| 7 Controllo postazione | Verifica: deve risultare tutto [OK], senza "behind" o "ahead" |

**Regole d'oro**

1. Prima la **2**, poi si lavora, poi la **3**. Un PC rimasto indietro blocca la pubblicazione ("Compilazione non riuscita"): non è un danno, basta la 2. Prima della **5** sempre la **2**, per non ripubblicare un gestionale vecchio.
2. Uno zip ricevuto si estrae **dopo** la 2 e **prima** della 4.
3. La 4 deve dire "Uploaded X files" con X maggiore di 0: con 0 non è cambiato niente online.
4. Alla domanda "Salvo queste modifiche (s/n)" si risponde solo `s`; la descrizione va alla domanda successiva.
5. Sulla chiavetta l'aggiornamento parte da solo all'apertura; prima di toglierla: voce 3 e rimozione sicura.

**Postazioni**

| Postazione | App Orari | Gestionale (da compilare) | Chiavi |
| --- | --- | --- | --- |
| PC | C:\DEANGELISBUS\orari-deangelisbus | dentro C:\DEANGELISBUS\2-SORGENTE-APP (il menu trova da solo la cartella giusta) | .env o .env.local |
| Chiavetta | K:\DEANGELISBUS-USB-v21\orari-deangelisbus | K:\...\2-SORGENTE-APP\2-SORGENTE-APP\2-SORGENTE-APP | .env |

**App Android (prove)**: dopo la voce 4, `npx.cmd cap sync android`, poi ▶ in Android Studio con il telefono collegato. Non accettare l'aggiornamento proposto dall'"Upgrade Assistant" fino alla preparazione del Play Store.

**File da non perdere**: `.env` / `.env.local` su ogni PC, `android\local.properties`, e in futuro la chiave di firma del Play Store.

## 11. Configurazioni e servizi esterni

Queste impostazioni si fanno una volta; vanno toccate solo per cambiare destinatari, motore dell'assistente o dominio.

| Cosa | Dove si imposta | Come si cambia |
| --- | --- | --- |
| Destinatari delle email (preventivi e segnalazioni) | Supabase → Edge Functions → Secrets: `EMAIL_TO` (oggi info@ e tiziana@) | Aggiungere indirizzi separati da virgola, es. commerciale@deangelisbus.it |
| Casella che invia le email | Secrets `SMTP_HOST`, `SMTP_PORT` (465), `SMTP_USER`, `SMTP_PASS` (posta Aruba) | Cambiare solo se cambia la password della casella |
| Sicurezza del collegamento email | Secret `WEBHOOK_SECRET`, uguale a quello nei trigger del database | Non toccare |
| Notifiche push: chiavi | Secrets `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (mailto:info@deangelisbus.it) | Non cambiarle: con chiavi nuove tutti i telefoni dovrebbero riattivare le notifiche. La chiave privata non va mai condivisa |
| Notifiche push: funzione di invio | Edge Function `invia-notifica` (codice in `supabase\functions\invia-notifica`), senza verifica JWT | Ripubblicarla solo se cambia il codice, dal PC: `npx.cmd supabase functions deploy invia-notifica --project-ref hmdpaypyljdgoehztbvi --no-verify-jwt` (la prima volta `npx.cmd supabase login`). Non crearla dal sito: dà un indirizzo diverso |
| Assistente gratuito | Cloudflare Pages → orari-deangelisbus → Impostazioni → Collegamenti → Workers AI, nome `AI` | Già attivo |
| Assistente più preciso (Claude Haiku) | Cloudflare Pages → Impostazioni → Variabili: segreto `ANTHROPIC_API_KEY` | Aggiungere la chiave e ripubblicare (voce 4); circa un centesimo a domanda |
| Dominio orari.deangelisbus.it | Cloudflare Pages → orari-deangelisbus → Domini personalizzati | Non toccare |
| Chiavi del database nell'app | File `.env` / `.env.local` (VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY) | Il menu le controlla da solo |
| Spazio foto e musica | Supabase → Storage → bucket `territorio` (pubblico in lettura) | Si gestisce dal gestionale (8.5) |

I permessi di scrittura dal gestionale valgono solo per gli utenti **amministratori** (funzione `is_admin_gestionale` nel database): un dipendente senza quel ruolo vede le pagine ma non può salvare.

## 12. Risoluzione dei problemi

Quasi tutti i problemi si risolvono riaprendo l'app o con la voce 2 del menu.

| Problema | Causa probabile | Soluzione |
| --- | --- | --- |
| L'app non mostra una novità appena pubblicata | Data "visibile dal" nel futuro, oppure telefono con la versione salvata | Controllare la data in Novità app; chiudere l'app e riaprirla, Info → Aggiorna orari |
| Ancora vecchia dopo più riaperture | Dati del telefono vecchi | Tenere premuta l'icona → Info app → Spazio di archiviazione → Cancella dati (si perde la fermata preferita) |
| Il gestionale sul telefono non mostra le pagine nuove | Icona installata da un indirizzo "con codice" (fermo a una vecchia versione) o memoria vecchia | Disinstallare l'icona vecchia e usare solo quella dell'indirizzo principale; cancellare i dati dell'app |
| Una funzione nuova non compare | Zip estratto dopo la pubblicazione | Voce 4 (o 5) di nuovo: deve dire "Uploaded X files" con X > 0 |
| "Compilazione non riuscita" alla voce 4 o 5 | PC rimasto indietro, zip parziale o disco pieno ("no space left on device") | Voce 2, poi rifare; se il disco è pieno liberare spazio (installatori nei Download, cache) |
| `$zip.Name` vuoto o "argomento null" in PowerShell | Lo zip non è stato scaricato | Scaricarlo e controllare l'icona dei download del browser; scrivere `exit` se si è aperta una PowerShell dentro l'altra |
| "Non riesco ad attivarle: Servizio notifiche non disponibile" | Funzione `invia-notifica` assente, con indirizzo diverso o senza la chiave pubblica | Ripubblicarla con il comando della sezione 11 e controllare i Secrets VAPID |
| "Le notifiche sono bloccate" | Permesso negato sul telefono | Impostazioni del telefono → Notifiche → l'app o Chrome → consentire |
| Una fermata manca in Fermate vicino a me o nella Mappa | Fermata senza posizione | Gestionale → Fermate: posizione (8.6) |
| La card In giro con noi non c'è | Nessuna foto visibile | Caricare le foto (8.5) |
| La presentazione è muta | Volume multimediale a zero o musica non caricata | Alzare il volume; controllare la musica in 8.5 |
| L'assistente dice di aver esaurito le risposte | Quota gratuita giornaliera finita | Riprova il giorno dopo, o attivare Claude Haiku (sezione 11) |
| Non arrivano le email dei preventivi | Destinatari o password SMTP | Controllare i Secrets (sezione 11); le richieste restano comunque nel gestionale |
| Il gestionale non salva (errore di permesso) | Utente non amministratore | Accedere con un utente con ruolo admin |
| Una modifica in Linee e orari "torna indietro" | Non salvata (riga gialla) | Premere Salva tutto nella barra gialla e attendere il messaggio verde |
| Sulla chiavetta l'aggiornamento è lentissimo | Reinstallazione delle librerie | Lasciarlo finire; capita solo quando cambiano le librerie |
$md$, aggiornato_il = now() where slug = 'manuale-app-orari';

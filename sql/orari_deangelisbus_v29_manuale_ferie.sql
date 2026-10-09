-- =====================================================
-- GESTIONALE DEANGELISBUS – v29: Manuale del Gestionale 5.4 (Gestione ferie: formato 2025, dotazione per anzianita'
-- anche convenzionale e proporzionata, ferie in continuo, correzioni ed eliminazioni, stampa ed Excel). Rieseguibile.
-- =====================================================
update manuali set contenuto = $md$# Manuale del Gestionale Deangelisbus

Versione 5.4 — Ottobre 2026. Unisce il Manuale Utente v4.1 (giugno 2026) e il Manuale Amministratore v2.2 (maggio 2026), aggiornati con i moduli arrivati dopo: Noleggi, Scadenzario, Gestione ferie, sincronizzazioni automatiche, pagine App Orari e questa sezione Manuali.

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

**Ricerca nel menu (Ctrl+K)**

1. In cima al menu laterale c'è il campo **Cerca nel menu**; da qualsiasi pagina ci si arriva con **Ctrl+K** (sul telefono si apre anche il menu).
2. Scrivendo, il menu mostra solo le voci che corrispondono (es. "fer" mostra Richieste Ferie, Gestione Ferie, Fermate); si può cercare anche il nome di un gruppo, es. "app orari". Accenti e maiuscole non contano.
3. **Invio** apre la prima voce trovata; **Esc** o la ✕ tornano al menu completo.

In fondo al menu, sempre visibili, ci sono i pulsanti **App Autista** e **App Orari** (quest'ultimo apre l'app dei passeggeri in una nuova scheda).

**Aree del menu**

| Area | Sezioni |
| --- | --- |
| Autisti e turni | Carica turni (con archivio dei turni salvati), Calendario turni, Turni ricorrenti, Turni TPL, Planning turni, Presenze, Registri settimanali, Autisti, Richieste ferie, Report autista, Report ed export, Archivio registri, Riposi e conformità, Gestione ferie |
| Veicoli e operatività | Veicoli, **Scadenze mezzi**, Manutenzioni, Report veicolo, Km veicoli, Fogli di viaggio, Fogli viaggio CRM, Archivio fogli, Rifornimenti, Registro rifornimenti, Carichi serbatoio, Checklist veicoli, Anomalie veicoli |
| Commerciale e fatturazione | Committenti, Noleggi, Preventivi, Fatture proforma, Biglietti TPL, Report incassi |
| Report e comunicazioni | **ANAV: circolari e news**, Statistiche, Chat aziendale, Scadenze autisti, Feedback clienti, Scadenzario |
| App Orari | Linee e orari, Novità app, Notifiche app, Richieste preventivo, Segnalazioni app, Territorio: cosa mangiare, Foto: in giro con noi, Fermate: posizione |
| Strumenti | Manuali e operatività, Backup e ripristino, Impostazioni |

## 3. Turni

### 3.1 Calendario turni

1. Menu → **Calendario turni** → scegli la settimana con le frecce.
2. Clicca la cella autista × giorno per assegnare un turno.
3. Scegli il tipo: **TPL**, **NCC**, **Assenza** o **Vuoto**.
4. Scegli il turno dal catalogo oppure inserisci orari personalizzati.
5. Salva: la **presenza** viene creata in automatico (il tipo TPL/NCC/assenza deriva dalla descrizione del turno).

I turni "Vuoto" (Disposizione, Garage, Scuole) non generano presenza e non compaiono nel report autista.

**Apri in griglia (correggi, stampa, condividi).** Il pulsante verde nella barra del Calendario apre la settimana visualizzata in **Carica turni**, con i turni come sono salvati: da lì si correggono e si salvano (**Salva e Assegna**), si stampa il foglio **Turno di lavoro** come il modello (**Stampa PDF**) o lo si manda al gruppo WhatsApp (**Condividi**). Vedi il capitolo 3.2.

### 3.2 Carica turni: da file, griglia manuale, stampa, condivisione e archivio

La pagina **Carica turni** gestisce tutto il ciclo dei turni settimanali. I turni si possono caricare da un PDF oppure **creare direttamente nel gestionale**.

**A. Da file PDF**

1. Il foglio turni preparato in Word va salvato in **PDF** (2 pagine A4 orizzontali; la seconda senza intestazione). Il PDF deve avere il **testo selezionabile**: foto e screenshot vengono rifiutati (in Word: File → Salva con nome → PDF).
2. Menu → **Carica turni** → carica il PDF e controlla l'anteprima, soprattutto l'abbinamento dei nomi degli autisti.
3. **Salva e Assegna**.

**B. Griglia manuale (senza Word)**

1. **Inserimento manuale** → **Crea griglia**: scegli il periodo (o *Settimana prossima*) e, se vuoi, gli autisti.
2. Clicca il **+** di una cella per aggiungere un turno: **Tipo**, **Descrizione** (si può scegliere dall'elenco dei turni già usati, che compila anche gli orari) e orari.
3. Tipi disponibili: **TPL** (compreso lo scalo), **NCC**, **ALTRO** (disposizione, garage, manutenzione), **RIPOSO**, **FERIE**, **PERMESSO**, **MALATTIA**, **INFORTUNIO**, **FESTIVO**. Per RIPOSO, FERIE e simili la descrizione può restare vuota: nella casella compare il tipo. Per TPL, NCC e ALTRO la descrizione è obbligatoria.
4. Senza orari il turno viene salvato 06:00–14:00, come nel caricamento da PDF.
5. Strumenti della griglia: **Copia dal giorno precedente**, **Ripeti nei giorni successivi ancora vuoti**, **Copia questo turno** e incolla con un clic su altre celle.
6. **Salva e Assegna**.

**Salva e Assegna** salva i turni e crea le presenze, senza cancellare le presenze dei giorni passati; gli autisti con turni nuovi o modificati ricevono la notifica (chi non ha attivato le notifiche sul telefono non la riceve, e non è un errore). Dopo il salvataggio, ogni correzione nella griglia riattiva il pulsante.

**C. Stampa e condivisione**

- **Stampa PDF**: crea il foglio **Turno di lavoro** come il modello (intestazione, Mod. 02 MOV PR 01, tabella degli autisti, seconda pagina con Nobile, De Ruvo, Masellis ed Eramo). Chiede il numero della settimana, già proposto secondo la numerazione aziendale. Il foglio mostra **tutti i giorni**, anche quelli senza turni (riquadri vuoti), e almeno 5 colonne. Nella finestra di stampa: **Salva come PDF**, orientamento **Orizzontale**.
- **Condividi**: crea il PDF del foglio e apre la condivisione del telefono o del PC: **WhatsApp** → gruppo. Dove la condivisione diretta non è possibile, il PDF viene scaricato, pronto da allegare.

**D. Turni salvati e archivio**

- **Apri turni salvati** (nel riquadro Inserimento manuale): scegli le date e la griglia mostra i turni come sono salvati nel database.
- **Archivio turni salvati** → **Apri archivio**: elenco delle settimane salvate (ultime 16 e prossime 8) con numero di settimana, periodo, numero di turni e autisti e **ultima modifica**. **Apri** porta direttamente alla griglia di quella settimana, con le ultime correzioni: da lì si può correggere, salvare, stampare e condividere.

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

Menu → **Gestione ferie** → scegli l'anno (◀ ▶) e l'autista. La scheda si compila **da sola dalle presenze** (ferie, riposi, malattia, festivi); ogni correzione viene salvata nelle **rettifiche ferie** e **non tocca mai le presenze**, che continuano ad alimentare i file per il consulente. Per il primo semestre 2026 fanno fede le schede cartacee (importate come rettifiche); dal luglio 2026 fa fede il gestionale.

**La scheda (formato 2025)**

- Colonne: **N | FERIE | SETTIMANA | RIPOSO | COMP. | MAL.** e, a parte, **FESTIVO | ESITO** (PAG = pagato in busta, G gg/mm = goduto, MALATTIA).
- In alto la card **Assunto il / Contratto**: data di assunzione, eventuale **anzianità convenzionale**, tipo di contratto (indeterminato, determinato, a chiamata), **CCNL** (TPL o NCC), eventuale **cessazione**, mesi di rapporto nell'anno e dotazione. Con **✎ Modifica** si correggono direttamente nell'anagrafica (con conferma).
- Festivi: quelli nazionali, **San Rocco (16/08)** patrono, e dal 2026 **San Francesco (4 ottobre)**.

**Dotazione**

- Scaglioni per anzianità: **30** giorni fino a 10 anni, **31** da 11 a 20, **32** oltre 20. L'anzianità si conta dalla **data di anzianità convenzionale** se indicata (come nel cedolino), altrimenti dalla data di assunzione.
- **Proporzionata** nell'anno di assunzione o cessazione: dotazione × mesi di rapporto ÷ 12 (una frazione di almeno 15 giorni vale un mese). Prima dell'assunzione e dopo la cessazione è 0.
- Il menu **Dotazione** permette di impostarla a mano per l'anno (anche **0** per un anno senza scheda); il valore manuale ha la precedenza sul calcolo. Se per un anno ci sono più valori salvati, vale l'ultimo e la scheda lo segnala.

**Ferie in continuo tra gli anni**

- Le ferie di un anno completano **prima il residuo dell'anno precedente**: se le ferie 2025 non sono finite, i primi giorni di ferie del 2026 vengono contati nella scheda 2025 con l'etichetta **"goduta nel 2026"**, e nella scheda 2026 compaiono nel riquadro dei giorni passati al 2025.
- Al contrario, se in un anno le ferie superano la dotazione, i giorni in più passano da soli all'anno successivo. Ogni giorno è contato **una sola volta**.
- Una ferie inserita a mano appartiene alla scheda dell'anno in cui è stata inserita.

**Correzioni ed eliminazioni** (tutte con conferma; in alto a destra compare "Salvato." oppure "Non salvato: motivo")

- **Ferie**: **+ Aggiungi feria** (un giorno) o **+ Aggiungi periodo** (dal… al…, domeniche e festivi esclusi a scelta, senza doppioni); per togliere: spunta uno o più giorni → **Elimina selezionate** (anche le "goduta nel …", che vengono tolte dall'anno a cui appartengono).
- **Riposi**: ✎ sulla riga → data del **riposo** (OK), **Malattia**, oppure **Elimina**; colonna **COMP.**: data del **compensativo** fino a 4 settimane dopo la domenica (OK), **Nessuno**, oppure **Auto** per tornare al calcolo dalle presenze. La ✕ elimina riposo e compensativo della settimana.
- **Festivi**: ✎ per l'esito (goduto con data, pagato, **Malattia**, **Elimina esito**); la ✕ toglie il festivo dalla scheda, con **ripristina** in "Festivi eliminati". I festivi locali aggiunti a mano hanno la loro ✕.

**Stampa ed Excel**

- **🖨 Stampa**: una pagina A4 per scheda, nello stesso formato, con la riga di assunzione, contratto, mesi e dotazione sotto il titolo.
- **⬇ Prospetto Excel**: stesso formato, già impostato per stampare su **un solo foglio A4**; con "tutti" un foglio per autista.

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

### 6.1 Scadenze mezzi e verifica sul Portale

La pagina **Scadenze mezzi** (Veicoli e operatività) riunisce revisioni, polizze e tutte le scadenze della flotta.

1. In alto: revisioni **scadute o senza data**, revisioni **entro 60 giorni**, **polizze scadute o senza data** e mezzi **dismessi** (nascosti).
2. Filtri: **Revisioni da fare (60 gg)** (si apre per primo), **Polizze da verificare**, **Qualsiasi scadenza scaduta**, **Tutti i mezzi**; ricerca per targa, nome o tipologia; **mostra dismessi**. Colori: rosso scaduta, arancione entro 60 giorni, verde in regola.
3. **Revisione → Verifica sul Portale**: copia la targa e apre il servizio ufficiale *Verifica revisioni effettuate* del Portale dell'Automobilista (gratuito, senza credenziali). Se la pagina resta bianca premere **F5**. Scegliere **Autoveicolo**, incollare la targa con **Ctrl+V**, inserire il codice di sicurezza e leggere la data dell'ultima revisione; nel gestionale scriverla accanto al mezzo e premere **Registra**: la scadenza (ultima revisione + 1 anno, revisione annuale per autobus e mezzi a noleggio) si calcola da sola.
4. **Polizza RCA → Verifica RCA**: stesso procedimento con il servizio *Verifica copertura RCA* (Veicolo, Autoveicolo, targa, codice, Ricerca): mostra compagnia e scadenza; scrivere la scadenza e premere **Registra**. Se il risultato è vuoto subito dopo un rinnovo, chiedere conferma alla compagnia o al broker.
5. **Tutte le scadenze**: modulo con tutte le date del mezzo (revisione, polizza, bollo, tachigrafo, scarico, estintore, ZTL, FL) da modificare e salvare insieme; da qui anche **Segna come dismesso** (o **Rimetti in flotta**).

Il codice di sicurezza del Portale impedisce le verifiche automatiche: il controllo va fatto da una persona, circa 30 secondi per targa. La revisione vale fino alla fine del mese di scadenza; se il Portale conferma una revisione scaduta, **il mezzo non deve circolare** finché non viene revisionato.

Le scadenze dei mezzi si gestiscono **solo nel gestionale**: il CRM serve unicamente fino alla messa a regime e non va aggiornato. Ogni data salvata entra da sola nello **Scadenzario** (capitolo 9).

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

1. Menu → **Scadenzario** → nuova scadenza: categoria (fiscale, gara, assicurazione, contratto, **mezzi**, altro), data, giorni di preavviso, eventuale ricorrenza, responsabile.
2. Ogni giorno le scadenze **da fare** o **in corso** che entrano nei giorni di preavviso (o già superate) generano **una** notifica nella campanella del gestionale.
3. A cosa fatta, aggiorna lo stato.

**Scadenze dei mezzi.** Revisione, polizza, bollo, tachigrafo, scarico scheda, estintore, ZTL e FL di ogni mezzo entrano **da sole** nello Scadenzario, categoria **Mezzi** (es. "Revisione – GV266ML"), con 30 giorni di preavviso (15 per bollo, scarico, ZTL e FL). Quando una data viene rinnovata in Scadenze mezzi, la voce si aggiorna e torna "da fare", così l'avviso riparte per la scadenza successiva. I mezzi dismessi o esclusi dagli avvisi spariscono dallo Scadenzario. Le scadenze delle circolari ANAV entrano con **Crea scadenza** (capitolo 10).

## 10. Comunicazioni

**Chat**

1. Seleziona l'autista dall'elenco a sinistra e scrivi.
2. Messaggi **urgenti** in rosso con badge URGENTE; **Broadcast** per scrivere a tutti gli autisti insieme; cestino per eliminare un messaggio.
3. I link nei messaggi sono cliccabili (per esempio il planning).

**Notifiche push agli autisti**: ogni messaggio, turno assegnato, foglio di viaggio e risposta a una richiesta genera una notifica sul telefono dell'autista, anche ad app chiusa. Ogni autista riceve le notifiche su un solo telefono: l'ultimo da cui ha fatto l'accesso.

**ANAV: circolari e news** (prima voce di Report e comunicazioni)

Ogni mattina alle 8:30 il gestionale legge dal sito dell'ANAV le nuove **circolari** e **news** (numero, data, protocollo, titolo, collegamento): solo i dati pubblici, il testo resta nell'area riservata agli associati. Un **pallino rosso** sulla voce del menu indica quante sono da leggere.

1. Apri la pagina: filtri **Da leggere**, **Circolari**, **News**, **Tutte** e ricerca (es. "accise", "TFR"); **Aggiorna da ANAV** legge subito le novità.
2. **Apri su ANAV** porta alla circolare sul sito: si entra con il login dell'azienda.
3. Il cerchio a sinistra segna la voce come **letta** (con chi e quando); **Segna tutte come lette** per svuotare l'elenco.
4. In **Dettagli**: **Carica il PDF della circolare** (scaricato dall'area riservata) e **Riassunto AI**, che spiega cosa dice, cosa deve fare l'azienda, entro quando e se ci riguarda; la data trovata viene proposta per la scadenza.
5. **Crea scadenza** inserisce la circolare nello **Scadenzario** con l'avviso nei giorni scelti; **Note interne** per annotare a chi è stata girata o cosa si è fatto.

Il riassunto AI usa la chiave `ANTHROPIC_API_KEY` salvata nei Secrets di Supabase; tutto il resto funziona anche senza.

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

- **App Orari**: l'app dei passeggeri si chiama **Deangelisbus S.r.l. – Insieme in viaggio** (orari.deangelisbus.it). Le otto pagine (Linee e orari, Novità app, Notifiche app, Richieste preventivo, Segnalazioni app, Territorio: cosa mangiare, Foto: in giro con noi, Fermate: posizione) sono descritte nel **Manuale App Orari**.
- **Manuali e operatività**: questa sezione. Gli amministratori possono modificare i manuali (**Modifica**, con anteprima) e aggiungere procedure operative (**Nuovo documento**); **Stampa / PDF** stampa il documento aperto.

## 14. Sincronizzazioni automatiche

| Cosa | Da dove | Quando |
| --- | --- | --- |
| Veicoli, rifornimenti, carichi serbatoio, manutenzioni | CRM vtenext | Ogni notte |
| Fogli di viaggio | CRM vtenext | Su richiesta, solo le modifiche |
| Noleggi | File Excel su Google Drive | Pulsante Sincronizza da Drive |
| Km dei veicoli | Export di Golia nella cartella Drive "Golia – Export" | Ogni giorno |
| Avvisi dello Scadenzario | Scadenze inserite | Ogni giorno |
| Circolari e news ANAV | Sito anav.it (dati pubblici) | Ogni mattina alle 8:30, oppure Aggiorna da ANAV |

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
| ANAV: "0 elementi letti dal sito" | Il sito ANAV ha cambiato struttura o non risponde: riprovare più tardi e, se persiste, segnalarlo a chi segue la parte tecnica |
| ANAV: il riassunto AI dà errore | Manca o è scaduta la chiave ANTHROPIC_API_KEY nei Secrets di Supabase, oppure il PDF non è stato caricato |
| Non trovo una pagina nel menu | Ctrl+K e scrivere parte del nome |
| La verifica revisioni del Portale resta bianca | Premere F5; se non basta, finestra in incognito o altro browser, oppure l'app iPatente |

## 16. Requisiti tecnici

| Voce | Dettaglio |
| --- | --- |
| Browser | Chrome 90 o superiore consigliato; Firefox, Safari, Edge recenti |
| Smartphone | Android 8 o superiore con Chrome; iPhone iOS 14 o superiore con Safari |
| Connessione | Necessaria per tutte le funzioni |
| Tecnologia | React + TypeScript + Vite, database Supabase (PostgreSQL), Cloudflare Pages, notifiche Firebase, email Resend, assistente Claude (Anthropic), app Android con Capacitor |

Aggiornamenti e pubblicazione si fanno dal **menu Strumenti**: sempre voce 2 all'inizio, voce 3 alla fine, e voce 2 prima della voce 5. La **voce 5** pubblica insieme il gestionale e l'**app autisti** (stessa versione, due indirizzi). Non pubblicare con comandi `wrangler` scritti a mano: con un ramo diverso (es. `--branch=main` per il gestionale) si aggiorna solo una versione di prova, non quella in uso.

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

Il menu Strumenti scarica la copia **più recente** sul PC e sulla chiavetta, nella cartella **BACKUP-DATABASE**, e toglie le precedenti (solo dopo aver verificato che quella nuova sia arrivata), così il disco non si riempie: in automatico con la voce 2 (Aggiorna tutto) e quando si apre il menu dalla chiavetta, oppure a mano con la voce **9**. Tutte le copie restano comunque online su Supabase. La prima volta su ogni postazione la voce 9 chiede la chiave dei backup, che si legge su Supabase (SQL Editor) con: `select decrypted_secret from vault.decrypted_secrets where name = 'backup_download_key';`

I file sono in formato aperto (JSON compresso): anche senza il gestionale si possono aprire e i dati restano leggibili. Insieme a ogni copia viene salvata anche la **struttura del database** (file `struttura-….sql`), che serve a ricostruirlo da zero (capitolo 18). Le foto (galleria, scontrini) sono conservate a parte nello spazio file e non fanno parte di questo backup.

## 18. Cosa fare in caso di emergenza

I dati non vivono sul PC né sulla chiavetta: stanno nel database su internet (Supabase), con una copia completa ogni notte. Ogni copia contiene **tutti i dati** e anche la **struttura del database** (tabelle, funzioni, regole di accesso), e viene scaricata anche su PC e chiavetta nella cartella **BACKUP-DATABASE** (file `.json.gz` con i dati e file `struttura-….sql` con la struttura).

| Dove sta | Cosa |
| --- | --- |
| Supabase (database) | Tutti i dati, sempre aggiornati |
| Supabase (spazio privato "backup") | Copie complete: ultimi 30 giorni e una per mese, per sempre |
| PC e chiavetta, cartella BACKUP-DATABASE | La copia più recente, scaricata dal menu Strumenti |
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
select titolo, left(contenuto, 70) as inizio, aggiornato_il from manuali where slug = 'manuale-gestionale';

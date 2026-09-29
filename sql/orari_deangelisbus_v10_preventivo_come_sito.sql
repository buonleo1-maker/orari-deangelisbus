-- =====================================================
-- ORARI DE ANGELIS BUS – v10: richiesta preventivo uguale al modulo del sito
-- (Nome, Cognome, Azienda, Telefono, Data partenza/rientro, Luoghi, Partecipanti,
--  Email, Itinerario, Ulteriori informazioni). Rieseguibile.
-- =====================================================
alter table richieste_preventivo add column if not exists cognome text;
alter table richieste_preventivo add column if not exists azienda text;
alter table richieste_preventivo add column if not exists itinerario text;

alter table richieste_preventivo drop constraint if exists richieste_preventivo_cognome_len;
alter table richieste_preventivo add constraint richieste_preventivo_cognome_len check (cognome is null or char_length(cognome) <= 120);
alter table richieste_preventivo drop constraint if exists richieste_preventivo_azienda_len;
alter table richieste_preventivo add constraint richieste_preventivo_azienda_len check (azienda is null or char_length(azienda) <= 150);
alter table richieste_preventivo drop constraint if exists richieste_preventivo_itinerario_len;
alter table richieste_preventivo add constraint richieste_preventivo_itinerario_len check (itinerario is null or char_length(itinerario) <= 2000);

-- il modulo del sito non chiede il tipo di servizio: diventa facoltativo
alter table richieste_preventivo alter column tipo drop not null;

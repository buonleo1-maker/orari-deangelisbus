-- v5: traccia l'invio dell'email di notifica delle richieste di preventivo
alter table richieste_preventivo add column if not exists email_inviata_il timestamptz;

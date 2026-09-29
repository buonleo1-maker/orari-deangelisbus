-- =====================================================
-- ORARI DE ANGELIS BUS – v11: viaggi di gruppo Ridola Viaggi nella tabella delle novità.
-- Un viaggio = riga di orari_novita con tipo 'viaggio', data_evento = partenza, data_fine = rientro.
-- Rieseguibile.
-- =====================================================
alter table orari_novita add column if not exists data_fine date;

alter table orari_novita drop constraint if exists orari_novita_tipo_check;
alter table orari_novita add constraint orari_novita_tipo_check
  check (tipo in ('novita','evento','variazione','viaggio'));

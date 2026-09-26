-- =====================================================
-- ORARI DE ANGELIS BUS – v4: colori per tipo di servizio
-- e richieste di preventivo/trasferimento dall'app. Rieseguibile.
-- =====================================================

-- 1) Colori: TPL extraurbano blu, urbani bianco, scolastici giallo, navette blu scuro
update orari_linee set colore = case categoria
  when 'extraurbano' then '#1E5BB8'
  when 'urbano'      then '#FFFFFF'
  when 'scolastico'  then '#FFC628'
  when 'navetta'     then '#152538'
  else colore end;

-- 2) Richieste inviate dall'app (preventivi, trasferimenti, noleggi)
create table if not exists richieste_preventivo (
  id bigint generated always as identity primary key,
  creata_il timestamptz not null default now(),
  tipo text not null check (tipo in ('trasferimento','noleggio','gita','altro')),
  data_andata date,
  ora_andata time,
  partenza text not null check (char_length(partenza) between 2 and 200),
  destinazione text not null check (char_length(destinazione) between 2 and 200),
  ritorno boolean not null default false,
  data_ritorno date,
  ora_ritorno time,
  passeggeri int check (passeggeri between 1 and 90),
  nome text not null check (char_length(nome) between 2 and 120),
  telefono text not null check (char_length(telefono) between 6 and 30),
  email text check (email is null or char_length(email) <= 150),
  note text check (note is null or char_length(note) <= 2000),
  consenso_privacy boolean not null check (consenso_privacy),
  stato text not null default 'nuova' check (stato in ('nuova','in lavorazione','inviato preventivo','confermata','chiusa'))
);

alter table richieste_preventivo enable row level security;

-- l'app (utente anonimo) puo' SOLO inserire, non leggere ne' modificare
drop policy if exists "app inserisce richieste" on richieste_preventivo;
create policy "app inserisce richieste" on richieste_preventivo
  for insert to anon, authenticated
  with check (consenso_privacy and stato = 'nuova');

-- lettura/gestione: solo dal pannello Supabase o dal gestionale (policy admin da aggiungere col modulo)
grant insert on richieste_preventivo to anon, authenticated;

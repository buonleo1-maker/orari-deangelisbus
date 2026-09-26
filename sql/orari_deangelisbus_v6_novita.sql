-- =====================================================
-- ORARI DE ANGELIS BUS – v6: Novità ed eventi. Rieseguibile.
-- Si aggiornano da Supabase > Table Editor > orari_novita (Insert row).
-- =====================================================
create table if not exists orari_novita (
  id bigint generated always as identity primary key,
  tipo text not null default 'novita' check (tipo in ('novita','evento','variazione')),
  titolo text not null,
  testo text,
  data_evento date,                 -- per gli eventi: il giorno dell'evento
  link text,                        -- facoltativo: pagina con i dettagli
  in_evidenza boolean not null default false,  -- in cima all'elenco
  visibile_dal date not null default current_date,
  visibile_al date,                 -- vuoto = sempre visibile
  creato_il timestamptz not null default now()
);

alter table orari_novita enable row level security;
drop policy if exists "lettura pubblica" on orari_novita;
create policy "lettura pubblica" on orari_novita for select to anon, authenticated using (true);

-- prima novità
insert into orari_novita (tipo, titolo, testo, in_evidenza)
select 'novita', 'È arrivata l''app Orari De Angelis Bus',
       'Orari, fermate e prossimi bus sempre a portata di mano. Puoi installarla sul telefono e usarla anche senza internet.', true
where not exists (select 1 from orari_novita);

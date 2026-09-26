-- =====================================================
-- ORARI DE ANGELIS BUS – v2: nuovi tipi di servizio
-- Da eseguire DOPO orari_deangelisbus_setup.sql. Rieseguibile.
-- =====================================================

-- 1) Categoria e gestione delle linee
alter table orari_linee add column if not exists categoria text not null default 'extraurbano';
alter table orari_linee drop constraint if exists orari_linee_categoria_chk;
alter table orari_linee add constraint orari_linee_categoria_chk
  check (categoria in ('extraurbano','urbano','scolastico','navetta'));
alter table orari_linee add column if not exists comune text;          -- per urbani e scolastici
alter table orari_linee add column if not exists esercente text default 'De Angelis Bus S.r.l.';
alter table orari_linee add column if not exists committente text;     -- es. Comune, Cotrab, ditta per cui si lavora in subappalto
alter table orari_linee add column if not exists subappalto boolean not null default false;
alter table orari_linee add column if not exists info_pubblico text;   -- testo libero mostrato in app (biglietti, prenotazioni...)

update orari_linee set categoria = 'extraurbano', committente = 'Cotrab'
where id in ('pisticci','policoro','ponte-bradano','scalo') and committente is null;

-- 2) Validita' delle corse
alter table orari_corse add column if not exists valido_dal date;
alter table orari_corse add column if not exists valido_al date;
alter table orari_corse add column if not exists solo_giorni_scolastici boolean not null default false;
alter table orari_corse add column if not exists note text;

-- 3) Periodi di esercizio di una linea (es. navette a mesi alterni).
--    Nessuna riga = linea attiva tutto l'anno.
create table if not exists orari_periodi (
  id bigint generated always as identity primary key,
  linea_id text not null references orari_linee(id) on delete cascade,
  dal date not null,
  al date not null,
  note text,
  check (al >= dal)
);

-- 4) Sospensioni: vacanze scolastiche, festivita', fermi del servizio.
--    ambito 'scolastico' = vale solo per le corse con solo_giorni_scolastici;
--    linea_id null = vale per tutte le linee.
create table if not exists orari_sospensioni (
  id bigint generated always as identity primary key,
  dal date not null,
  al date not null,
  ambito text not null default 'tutti' check (ambito in ('tutti','scolastico')),
  linea_id text references orari_linee(id) on delete cascade,
  descrizione text,
  check (al >= dal)
);

-- lettura pubblica come le altre tabelle
do $$
declare t text;
begin
  foreach t in array array['orari_periodi','orari_sospensioni'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "lettura pubblica" on %I', t);
    execute format('create policy "lettura pubblica" on %I for select to anon, authenticated using (true)', t);
  end loop;
end $$;

-- 5) Funzione: la corsa circola in questa data?
create or replace function orari_corsa_attiva(p_codice text, p_data date)
returns boolean language sql stable as $$
  select c.attiva
     and extract(isodow from p_data)::smallint = any(c.giorni)
     and (c.valido_dal is null or p_data >= c.valido_dal)
     and (c.valido_al  is null or p_data <= c.valido_al)
     and (not exists (select 1 from orari_periodi p where p.linea_id = c.linea_id)
          or exists (select 1 from orari_periodi p where p.linea_id = c.linea_id and p_data between p.dal and p.al))
     and not exists (select 1 from orari_sospensioni s
                     where p_data between s.dal and s.al
                       and (s.linea_id is null or s.linea_id = c.linea_id)
                       and (s.ambito = 'tutti' or c.solo_giorni_scolastici))
  from orari_corse c where c.codice = p_codice;
$$;
grant execute on function orari_corsa_attiva(text, date) to anon, authenticated;

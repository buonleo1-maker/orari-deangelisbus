-- =====================================================
-- ORARI DE ANGELIS BUS – v9: navetta Bari a mesi alterni + segnalazioni dall'app.
-- Rieseguibile. PRIMA DI ESEGUIRE: sostituisci LA-TUA-PAROLA-SEGRETA (in fondo)
-- con la stessa parola del secret WEBHOOK_SECRET della funzione notifica-preventivo.
-- =====================================================

-- 1) NAVETTA MATERA – AEROPORTO DI BARI: mesi di competenza Deangelisbus (alterni, da ottobre 2026)
insert into orari_periodi (linea_id, dal, al, note)
select 'navetta-bari', v.dal::date, v.al::date, 'Mese di competenza Deangelisbus'
from (values
  ('2026-10-01','2026-10-31'), ('2026-12-01','2026-12-31'),
  ('2027-02-01','2027-02-28'), ('2027-04-01','2027-04-30'),
  ('2027-06-01','2027-06-30'), ('2027-08-01','2027-08-31')
) as v(dal, al)
where not exists (select 1 from orari_periodi p where p.linea_id = 'navetta-bari' and p.dal = v.dal::date);

update orari_corse set attiva = true where linea_id = 'navetta-bari';

-- 2) SEGNALAZIONI, RECLAMI E SUGGERIMENTI inviati dall'app
create table if not exists segnalazioni_app (
  id bigint generated always as identity primary key,
  creata_il timestamptz not null default now(),
  tipo text not null check (tipo in ('suggerimento','reclamo','segnalazione','complimento')),
  linea_id text references orari_linee(id) on delete set null,
  data_evento date,
  ora_evento time,
  luogo text check (luogo is null or char_length(luogo) <= 200),
  messaggio text not null check (char_length(messaggio) between 5 and 3000),
  nome text check (nome is null or char_length(nome) <= 120),
  email text check (email is null or char_length(email) <= 150),
  telefono text check (telefono is null or char_length(telefono) <= 30),
  consenso_privacy boolean not null default false,
  stato text not null default 'nuova' check (stato in ('nuova','in lavorazione','risolta','chiusa')),
  note_interne text,
  aggiornata_il timestamptz,
  email_inviata_il timestamptz,
  -- i dati di contatto si salvano solo con il consenso
  check (consenso_privacy or (nome is null and email is null and telefono is null))
);

alter table segnalazioni_app enable row level security;
drop policy if exists "app inserisce segnalazioni" on segnalazioni_app;
create policy "app inserisce segnalazioni" on segnalazioni_app
  for insert to anon, authenticated with check (stato = 'nuova');
drop policy if exists "admin gestiscono segnalazioni" on segnalazioni_app;
create policy "admin gestiscono segnalazioni" on segnalazioni_app
  for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant insert on segnalazioni_app to anon, authenticated;
grant select, update, delete on segnalazioni_app to authenticated;

-- 3) Email all'ufficio a ogni nuova segnalazione (stessa funzione dei preventivi)
create extension if not exists pg_net;
create or replace function public.notifica_segnalazione_email()
returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  perform net.http_post(
    url := 'https://hmdpaypyljdgoehztbvi.supabase.co/functions/v1/notifica-preventivo',
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-webhook-secret', 'LA-TUA-PAROLA-SEGRETA'),
    body := jsonb_build_object('type', 'INSERT', 'table', 'segnalazioni_app', 'record', to_jsonb(new))
  );
  return new;
end;
$$;
drop trigger if exists email_segnalazioni on public.segnalazioni_app;
create trigger email_segnalazioni after insert on public.segnalazioni_app
  for each row execute function public.notifica_segnalazione_email();

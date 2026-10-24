-- =====================================================
-- ORARI DE ANGELIS BUS – v59: Prenotazione auto e minivan con conducente
-- Servizi: "ultimo miglio" (dalla fermata del bus alla destinazione) e "visita medica" (accompagnamento).
-- L'app inserisce la richiesta (stato 'nuova'); gli amministratori del gestionale la leggono e la gestiscono.
-- A ogni nuova prenotazione: email all'ufficio + notifica sul telefono degli amministratori
-- (Edge Function notifica-preventivo, aggiornata insieme a questo script).
-- Rieseguibile.
-- =====================================================
create table if not exists prenotazioni_auto (
  id bigint generated always as identity primary key,
  creata_il timestamptz not null default now(),
  servizio text not null check (servizio in ('ultimo_miglio', 'visita_medica')),
  stato text not null default 'nuova'
    check (stato in ('nuova', 'in lavorazione', 'preventivo inviato', 'confermata', 'completata', 'annullata')),
  -- chi prenota
  nome text not null check (char_length(nome) between 2 and 80),
  cognome text not null check (char_length(cognome) between 2 and 80),
  telefono text not null check (char_length(telefono) between 6 and 30),
  email text check (email is null or char_length(email) <= 120),
  -- chi viaggia (se diverso da chi prenota, es. il figlio prenota per il padre)
  per_altri boolean not null default false,
  passeggero_nome text check (passeggero_nome is null or char_length(passeggero_nome) <= 120),
  passeggero_telefono text check (passeggero_telefono is null or char_length(passeggero_telefono) <= 30),
  -- il viaggio
  data date not null,
  ora time,                         -- ultimo miglio: arrivo del bus; visita medica: ora dell'appuntamento
  partenza text not null check (char_length(partenza) between 2 and 200),       -- fermata del bus / indirizzo di casa
  destinazione text not null check (char_length(destinazione) between 2 and 200), -- indirizzo / ospedale o studio
  corsa text check (corsa is null or char_length(corsa) <= 120),               -- ultimo miglio: corsa del bus
  attesa boolean not null default false,  -- visita medica: l'autista aspetta e riporta a casa
  ritorno boolean not null default false,
  ora_ritorno time,
  passeggeri int not null default 1 check (passeggeri between 1 and 8),
  bagagli int check (bagagli is null or bagagli between 0 and 20),
  esigenze text check (esigenze is null or char_length(esigenze) <= 500),
  note text check (note is null or char_length(note) <= 1000),
  consenso_privacy boolean not null,
  -- gestione interna
  prezzo numeric(8,2),
  note_interne text,
  noleggio_id text,
  aggiornata_il timestamptz,
  email_inviata_il timestamptz,
  push_inviata_il timestamptz
);

alter table prenotazioni_auto enable row level security;
drop policy if exists "app inserisce prenotazioni" on prenotazioni_auto;
create policy "app inserisce prenotazioni" on prenotazioni_auto for insert to anon, authenticated
  with check (stato = 'nuova' and consenso_privacy and prezzo is null and note_interne is null and noleggio_id is null);
drop policy if exists "admin gestiscono prenotazioni" on prenotazioni_auto;
create policy "admin gestiscono prenotazioni" on prenotazioni_auto for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant insert on prenotazioni_auto to anon, authenticated;
grant select, update, delete on prenotazioni_auto to authenticated;

-- Aggiornamento automatico della pagina del gestionale quando arriva una prenotazione
do $$ begin
  alter publication supabase_realtime add table prenotazioni_auto;
exception when duplicate_object then null; when undefined_object then null;
end $$;

-- Email + notifica a ogni nuova prenotazione.
-- La parola segreta viene copiata dal trigger gia' esistente delle segnalazioni/preventivi: non serve riscriverla.
create extension if not exists pg_net;
do $$
declare s text;
begin
  select substring(prosrc from $r$'x-webhook-secret', '([^']+)'$r$) into s
  from pg_proc
  where prosrc like '%x-webhook-secret%' and prosrc like '%notifica-preventivo%'
  limit 1;
  if s is null or s = 'LA-TUA-PAROLA-SEGRETA' then
    raise exception 'Parola segreta del webhook non trovata: controlla il trigger delle segnalazioni (script v9).';
  end if;
  execute format($f$
    create or replace function public.notifica_prenotazione_auto()
    returns trigger language plpgsql security definer set search_path = public, extensions as $b$
    begin
      perform net.http_post(
        url := 'https://hmdpaypyljdgoehztbvi.supabase.co/functions/v1/notifica-preventivo',
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-webhook-secret', %L),
        body := jsonb_build_object('type', 'INSERT', 'table', 'prenotazioni_auto', 'record', to_jsonb(new))
      );
      return new;
    end;
    $b$;
  $f$, s);
end $$;

drop trigger if exists avviso_prenotazioni_auto on public.prenotazioni_auto;
create trigger avviso_prenotazioni_auto after insert on public.prenotazioni_auto
  for each row execute function public.notifica_prenotazione_auto();

select 'prenotazioni_auto pronta' as esito;

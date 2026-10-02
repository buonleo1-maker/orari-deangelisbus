-- =====================================================
-- ORARI DE ANGELIS BUS – v17: notifiche push dell'app.
-- I telefoni si iscrivono con push_iscrivi (dall'app, senza login); le notifiche le invia
-- la funzione "invia-notifica" (solo admin del gestionale). Rieseguibile.
-- =====================================================
create table if not exists push_iscrizioni (
  endpoint text primary key check (endpoint like 'https://%' and char_length(endpoint) < 1000),
  p256dh text not null check (char_length(p256dh) < 200),
  auth text not null check (char_length(auth) < 100),
  piattaforma text,
  creato_il timestamptz not null default now(),
  aggiornato_il timestamptz not null default now(),
  ultimo_invio timestamptz
);
alter table push_iscrizioni enable row level security;   -- nessuna lettura diretta: solo tramite le funzioni qui sotto

create or replace function push_iscrivi(p_endpoint text, p_p256dh text, p_auth text, p_piattaforma text default null)
returns void language sql security definer set search_path = public as $$
  insert into push_iscrizioni (endpoint, p256dh, auth, piattaforma)
  values (p_endpoint, p_p256dh, p_auth, left(p_piattaforma, 40))
  on conflict (endpoint) do update set p256dh = excluded.p256dh, auth = excluded.auth,
    piattaforma = excluded.piattaforma, aggiornato_il = now();
$$;
create or replace function push_disiscrivi(p_endpoint text)
returns void language sql security definer set search_path = public as $$
  delete from push_iscrizioni where endpoint = p_endpoint;
$$;
create or replace function push_conta_iscritti()
returns integer language sql security definer stable set search_path = public as $$
  select case when public.is_admin_gestionale() then (select count(*)::int from push_iscrizioni) end;
$$;
revoke all on function push_iscrivi(text, text, text, text) from public;
revoke all on function push_disiscrivi(text) from public;
revoke all on function push_conta_iscritti() from public;
grant execute on function push_iscrivi(text, text, text, text) to anon, authenticated;
grant execute on function push_disiscrivi(text) to anon, authenticated;
grant execute on function push_conta_iscritti() to authenticated;

-- storico degli invii (visibile agli admin nel gestionale)
create table if not exists push_invii (
  id bigint generated always as identity primary key,
  titolo text not null, testo text, url text, novita_id bigint,
  destinatari int, inviate int, errori int, rimosse int,
  creato_il timestamptz not null default now()
);
alter table push_invii enable row level security;
drop policy if exists "admin leggono" on push_invii;
create policy "admin leggono" on push_invii for select to authenticated using (public.is_admin_gestionale());
grant select on push_invii to authenticated;

alter table orari_novita add column if not exists notificata_il timestamptz;

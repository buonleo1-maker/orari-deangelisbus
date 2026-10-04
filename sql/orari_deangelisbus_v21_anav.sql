-- =====================================================
-- GESTIONALE DEANGELISBUS – v21: circolari e news ANAV nel gestionale.
-- Ogni mattina la funzione "anav-sync" legge dal sito ANAV i dati PUBBLICI (numero, data, titolo, link)
-- di circolari e news. Il testo resta nell'area riservata ANAV (login dell'azienda).
-- Rieseguibile.
-- =====================================================
create table if not exists anav_documenti (
  id bigint generated always as identity primary key,
  chiave text not null unique,                  -- es. circolare-184-2026 / news-<slug>
  tipo text not null check (tipo in ('circolare','news','evento')),
  numero text,                                   -- es. 184/2026
  protocollo text,                               -- es. 184/L/RI/AE/GaPa
  data date,
  titolo text not null,
  link text,
  letta boolean not null default false,
  letta_il timestamptz,
  letta_da text,
  note text,
  scadenza date,
  scadenza_id bigint,                            -- riga creata nello Scadenzario
  pdf_percorso text,                             -- PDF caricato dall'area riservata (spazio privato "anav")
  riassunto text,
  riassunto_il timestamptz,
  creato_il timestamptz not null default now()
);
create index if not exists anav_documenti_data on anav_documenti (data desc);
alter table anav_documenti enable row level security;
drop policy if exists "admin gestiscono" on anav_documenti;
create policy "admin gestiscono" on anav_documenti for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant select, insert, update, delete on anav_documenti to authenticated;

-- registro delle letture dal sito ANAV
create table if not exists anav_sync_log (
  id bigint generated always as identity primary key,
  eseguito_il timestamptz not null default now(),
  nuovi int, trovati int, esito text, dettagli text
);
alter table anav_sync_log enable row level security;
drop policy if exists "admin leggono" on anav_sync_log;
create policy "admin leggono" on anav_sync_log for select to authenticated using (public.is_admin_gestionale());
grant select on anav_sync_log to authenticated;

-- spazio privato per i PDF delle circolari (scaricati dall'area riservata e caricati a mano)
insert into storage.buckets (id, name, public) values ('anav', 'anav', false)
on conflict (id) do update set public = false;
drop policy if exists "anav admin leggono" on storage.objects;
create policy "anav admin leggono" on storage.objects for select to authenticated using (bucket_id = 'anav' and public.is_admin_gestionale());
drop policy if exists "anav admin caricano" on storage.objects;
create policy "anav admin caricano" on storage.objects for insert to authenticated with check (bucket_id = 'anav' and public.is_admin_gestionale());
drop policy if exists "anav admin aggiornano" on storage.objects;
create policy "anav admin aggiornano" on storage.objects for update to authenticated using (bucket_id = 'anav' and public.is_admin_gestionale());
drop policy if exists "anav admin eliminano" on storage.objects;
create policy "anav admin eliminano" on storage.objects for delete to authenticated using (bucket_id = 'anav' and public.is_admin_gestionale());

-- crea una scadenza nello Scadenzario partendo da una circolare (si adatta ai nomi delle colonne della tabella "scadenze")
create or replace function anav_crea_scadenza(p_id bigint, p_data date, p_preavviso int default 7)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  d record; cols text[]; c_tit text; c_data text; c_cat text; c_pre text; c_note text; c_stato text;
  nomi text := ''; valori text := ''; nuovo bigint;
begin
  if not public.is_admin_gestionale() then raise exception 'Solo gli amministratori'; end if;
  select * into d from anav_documenti where id = p_id;
  if not found then raise exception 'Circolare non trovata'; end if;
  if to_regclass('public.scadenze') is null then raise exception 'Tabella scadenze non trovata'; end if;
  select array_agg(column_name::text) into cols from information_schema.columns where table_schema = 'public' and table_name = 'scadenze';
  c_tit  := (select x from unnest(array['titolo','descrizione','oggetto','nome']) x where x = any(cols) limit 1);
  c_data := (select x from unnest(array['data_scadenza','scadenza','data']) x where x = any(cols) limit 1);
  c_cat  := (select x from unnest(array['categoria']) x where x = any(cols) limit 1);
  c_pre  := (select x from unnest(array['giorni_preavviso','preavviso_giorni','preavviso']) x where x = any(cols) limit 1);
  c_note := (select x from unnest(array['note','dettagli']) x where x = any(cols) limit 1);
  c_stato:= (select x from unnest(array['stato']) x where x = any(cols) limit 1);
  if c_tit is null or c_data is null then raise exception 'Colonne titolo/data non trovate nella tabella scadenze'; end if;
  nomi := quote_ident(c_tit) || ', ' || quote_ident(c_data);
  valori := quote_literal(left('ANAV ' || coalesce('circ. ' || d.numero || ' – ', '') || d.titolo, 250)) || ', ' || quote_literal(p_data);
  if c_cat  is not null then nomi := nomi || ', ' || quote_ident(c_cat);  valori := valori || ', ' || quote_literal('altro'); end if;
  if c_pre  is not null then nomi := nomi || ', ' || quote_ident(c_pre);  valori := valori || ', ' || coalesce(p_preavviso, 7); end if;
  if c_note is not null then nomi := nomi || ', ' || quote_ident(c_note); valori := valori || ', ' || quote_literal(coalesce(d.riassunto, '') || case when d.link is not null then E'\n' || d.link else '' end); end if;
  execute format('insert into public.scadenze (%s) values (%s) returning id', nomi, valori) into nuovo;
  update anav_documenti set scadenza = p_data, scadenza_id = nuovo where id = p_id;
  return nuovo;
end $$;
revoke all on function anav_crea_scadenza(bigint, date, int) from public, anon;
grant execute on function anav_crea_scadenza(bigint, date, int) to authenticated;

-- lettura automatica ogni mattina alle 06:30 UTC (8:30 / 7:30 italiane), con la stessa chiave del backup notturno
select cron.unschedule(jobid) from cron.job where jobname = 'anav-mattino';
select cron.schedule('anav-mattino', '30 6 * * *', $job$
  select net.http_post(
    url := 'https://hmdpaypyljdgoehztbvi.supabase.co/functions/v1/anav-sync',
    headers := jsonb_build_object('Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'backup_cron_secret')),
    body := '{"azione":"aggiorna"}'::jsonb, timeout_milliseconds := 60000);
$job$);

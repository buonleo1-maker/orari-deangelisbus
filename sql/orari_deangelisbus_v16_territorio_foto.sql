-- =====================================================
-- ORARI DE ANGELIS BUS – v16: galleria "In giro con noi" e musica della presentazione, caricate dal gestionale.
-- File in Supabase Storage (bucket pubblico "territorio"), elenco nella tabella territorio_foto.
-- Rieseguibile.
-- =====================================================
insert into storage.buckets (id, name, public)
values ('territorio', 'territorio', true)
on conflict (id) do update set public = true;

-- chiunque può vedere le foto; solo gli admin del gestionale caricano, modificano ed eliminano
drop policy if exists "territorio lettura pubblica" on storage.objects;
create policy "territorio lettura pubblica" on storage.objects for select to anon, authenticated
  using (bucket_id = 'territorio');
drop policy if exists "territorio admin caricano" on storage.objects;
create policy "territorio admin caricano" on storage.objects for insert to authenticated
  with check (bucket_id = 'territorio' and public.is_admin_gestionale());
drop policy if exists "territorio admin modificano" on storage.objects;
create policy "territorio admin modificano" on storage.objects for update to authenticated
  using (bucket_id = 'territorio' and public.is_admin_gestionale());
drop policy if exists "territorio admin eliminano" on storage.objects;
create policy "territorio admin eliminano" on storage.objects for delete to authenticated
  using (bucket_id = 'territorio' and public.is_admin_gestionale());

create table if not exists territorio_foto (
  id bigint generated always as identity primary key,
  paese text not null default 'altro' check (paese in ('matera','grottole','miglionico','montescaglioso','altro')),
  percorso text not null,                       -- percorso del file nel bucket, es. matera/1759312345.jpg
  didascalia text check (didascalia is null or char_length(didascalia) <= 200),
  crediti text check (crediti is null or char_length(crediti) <= 120),
  ordine int not null default 0,
  visibile boolean not null default true,
  creato_il timestamptz not null default now()
);
alter table territorio_foto alter column paese set default 'altro';
alter table territorio_foto enable row level security;
drop policy if exists "lettura pubblica" on territorio_foto;
create policy "lettura pubblica" on territorio_foto for select to anon, authenticated using (visibile);
drop policy if exists "admin gestiscono" on territorio_foto;
create policy "admin gestiscono" on territorio_foto for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant select on territorio_foto to anon, authenticated;
grant insert, update, delete on territorio_foto to authenticated;

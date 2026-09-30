-- =====================================================
-- ORARI DE ANGELIS BUS – v15: "Cosa mangiare" nella sezione Scopri il territorio.
-- Piatti tipici e qualche ristorante per paese, gestiti dal gestionale
-- (pagina "Territorio: cosa mangiare"). Rieseguibile.
-- paese: matera | grottole | miglionico | montescaglioso
-- =====================================================
create table if not exists territorio_gusto (
  id bigint generated always as identity primary key,
  paese text not null check (paese in ('matera','grottole','miglionico','montescaglioso')),
  tipo text not null check (tipo in ('piatto','ristorante')),
  nome text not null check (char_length(nome) between 2 and 120),
  descrizione text check (descrizione is null or char_length(descrizione) <= 400),
  indirizzo text,
  telefono text,
  link text,
  ordine int not null default 0,
  visibile boolean not null default true,
  creato_il timestamptz not null default now()
);

alter table territorio_gusto enable row level security;
drop policy if exists "lettura pubblica" on territorio_gusto;
create policy "lettura pubblica" on territorio_gusto for select to anon, authenticated using (visibile);
drop policy if exists "admin gestiscono" on territorio_gusto;
create policy "admin gestiscono" on territorio_gusto for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant select on territorio_gusto to anon, authenticated;
grant insert, update, delete on territorio_gusto to authenticated;

-- piatti tipici di partenza (solo se la tabella è vuota): il resto si aggiunge dal gestionale
insert into territorio_gusto (paese, tipo, nome, descrizione, ordine)
select * from (values
  ('matera','piatto','Pane di Matera IGP','Il pane di grano duro dalla tipica forma "a cornetto", con crosta croccante.',1),
  ('matera','piatto','Crapiata','Zuppa contadina di legumi e cereali misti, tradizione di inizio agosto.',2),
  ('matera','piatto','Peperoni cruschi','Peperoni dolci essiccati e fritti in un attimo: croccanti, sulla pasta o da soli.',3),
  ('matera','piatto','Cialledda','Pane raffermo con pomodoro, cipolla, olio e origano: il piatto dei contadini.',4)
) as v(paese, tipo, nome, descrizione, ordine)
where not exists (select 1 from territorio_gusto);

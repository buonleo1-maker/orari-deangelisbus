-- =====================================================
-- ORARI DE ANGELIS BUS – v55: "Luoghi ed eventi" nella sezione Scopri il territorio, gestiti dal gestionale
-- (pagina "Territorio: luoghi ed eventi"), come "Cosa mangiare". Prima erano scritti nel codice dell'app.
-- tipo: luogo (cosa vedere) | evento (da non perdere). Gli eventi con data_al passata spariscono da soli.
-- I testi di oggi vengono copiati qui (solo se la tabella e' vuota). Rieseguibile.
-- =====================================================
create table if not exists territorio_luoghi (
  id bigint generated always as identity primary key,
  paese text not null check (paese in ('matera','grottole','miglionico','montescaglioso')),
  tipo text not null check (tipo in ('luogo','evento')),
  nome text not null check (char_length(nome) between 2 and 120),
  descrizione text check (descrizione is null or char_length(descrizione) <= 600),
  quando text,                      -- per gli eventi, come si legge: "2 luglio", "in agosto", "dal 10 al 12 maggio"
  data_dal date,                    -- facoltative: per gli eventi con date precise
  data_al date,                     -- dopo questa data l'evento non si vede piu'
  indirizzo text,
  link text,
  ordine int not null default 0,
  visibile boolean not null default true,
  creato_il timestamptz not null default now()
);

alter table territorio_luoghi enable row level security;
drop policy if exists "lettura pubblica" on territorio_luoghi;
create policy "lettura pubblica" on territorio_luoghi for select to anon, authenticated using (visibile);
drop policy if exists "admin gestiscono" on territorio_luoghi;
create policy "admin gestiscono" on territorio_luoghi for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant select on territorio_luoghi to anon, authenticated;
grant insert, update, delete on territorio_luoghi to authenticated;

insert into territorio_luoghi (paese, tipo, nome, descrizione, quando, ordine)
select * from (values
  ('matera','luogo','I Sassi','Il Sasso Caveoso e il Sasso Barisano: case e chiese scavate nella roccia, Patrimonio dell''Umanità dal 1993.',null,1),
  ('matera','luogo','Parco della Murgia Materana','Le chiese rupestri e il belvedere di fronte ai Sassi, tra sentieri e gravine.',null,2),
  ('matera','luogo','Cattedrale e Civita','La Cattedrale romanica domina i Sassi dal punto più alto della città antica.',null,3),
  ('matera','evento','Festa della Madonna della Bruna','La festa patronale, con il Carro trionfale.','2 luglio',1),
  ('grottole','luogo','Chiesa Diruta','I resti imponenti della chiesa dei Santi Luca e Giuliano, simbolo del paese: si visita dall''esterno.',null,1),
  ('grottole','luogo','Castello Sichinulfo','La torre sulla collina della Motta, con vista sulle valli del Basento e del Bradano.',null,2),
  ('grottole','luogo','Oasi di San Giuliano e Bosco Coste','Natura e birdwatching sul lago, con un sentiero ad anello di circa 5 km nel bosco.',null,3),
  ('grottole','evento','Krùptai','La manifestazione dedicata a cultura, artigianato e tradizioni.',null,1),
  ('miglionico','luogo','Castello del Malconsiglio','Qui nel 1485 i baroni congiurarono contro re Ferdinando I d''Aragona: percorso multimediale nella Sala Stella.',null,1),
  ('miglionico','luogo','Polittico di Cima da Conegliano','Nella Chiesa Madre di Santa Maria Maggiore, il grande polittico di 18 tavole del 1499.',null,2),
  ('miglionico','evento','Congiura dei Baroni e Palio dei Rioni','La rievocazione storica della Congiura dei Baroni.','in agosto',1),
  ('montescaglioso','luogo','Abbazia di San Michele Arcangelo','Grande abbazia benedettina nel centro storico, con chiostri e cicli di affreschi.',null,1),
  ('montescaglioso','luogo','I monasteri e Piazza Roma','Il monastero di Sant''Agostino, i Cappuccini e la Chiesa di San Rocco, a pochi passi.',null,2),
  ('montescaglioso','evento','Carnevale','Una tradizione che risale al 1638.','a Carnevale',1)
) as v(paese, tipo, nome, descrizione, quando, ordine)
where not exists (select 1 from territorio_luoghi);

select paese, tipo, count(*) from territorio_luoghi group by paese, tipo order by paese, tipo;

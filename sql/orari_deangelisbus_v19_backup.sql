-- =====================================================
-- GESTIONALE DEANGELISBUS – v19: backup completo del database e ripristino.
-- Ogni notte la funzione "backup-dati" copia TUTTE le tabelle in un file compresso
-- nello spazio privato "backup"; dal gestionale si consulta, si scarica e si ripristina.
-- Rieseguibile.
-- =====================================================

-- spazio privato per i file di backup (non pubblico)
insert into storage.buckets (id, name, public) values ('backup', 'backup', false)
on conflict (id) do update set public = false;
drop policy if exists "backup admin leggono" on storage.objects;
create policy "backup admin leggono" on storage.objects for select to authenticated
  using (bucket_id = 'backup' and public.is_admin_gestionale());

-- registro dei backup
create table if not exists backup_registro (
  id bigint generated always as identity primary key,
  creato_il timestamptz not null default now(),
  tipo text not null default 'automatico' check (tipo in ('automatico','manuale','sicurezza')),
  percorso text,
  dimensione bigint,
  tabelle jsonb,                -- { "nome_tabella": numero_righe, ... }
  durata_ms int,
  esito text not null default 'ok' check (esito in ('ok','errore')),
  errore text,
  note text
);
alter table backup_registro enable row level security;
drop policy if exists "admin leggono" on backup_registro;
create policy "admin leggono" on backup_registro for select to authenticated using (public.is_admin_gestionale());
grant select on backup_registro to authenticated;

-- elenco delle tabelle da copiare, con la chiave primaria (usata per il ripristino)
create or replace function backup_tabelle()
returns table (tabella text, chiave text[])
language sql security definer stable set search_path = public as $$
  select c.relname::text,
         coalesce((select array_agg(a.attname::text order by k.ord)
                   from pg_index i
                   cross join lateral unnest(i.indkey) with ordinality as k(attnum, ord)
                   join pg_attribute a on a.attrelid = i.indrelid and a.attnum = k.attnum
                   where i.indrelid = c.oid and i.indisprimary), '{}')
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and c.relname <> 'backup_registro'
  order by c.relname;
$$;
revoke all on function backup_tabelle() from public, anon, authenticated;

-- chiavi segrete generate qui (nessuno deve inventarle): una per il backup notturno, una per scaricare le copie sul PC
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'backup_cron_secret') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(24), 'hex'), 'backup_cron_secret');
  end if;
  if not exists (select 1 from vault.secrets where name = 'backup_download_key') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(24), 'hex'), 'backup_download_key');
  end if;
end $$;

create or replace function backup_verifica_chiave(p_nome text, p_valore text)
returns boolean language sql security definer stable set search_path = public as $$
  select p_nome in ('backup_cron_secret', 'backup_download_key')
     and exists (select 1 from vault.decrypted_secrets where name = p_nome and decrypted_secret = p_valore);
$$;
revoke all on function backup_verifica_chiave(text, text) from public, anon, authenticated;

-- backup automatico ogni notte alle 02:45 (ora UTC, cioe' le 3:45/4:45 italiane)
create extension if not exists pg_cron;
create extension if not exists pg_net;
select cron.unschedule(jobid) from cron.job where jobname = 'backup-notturno';
select cron.schedule('backup-notturno', '45 2 * * *', $job$
  select net.http_post(
    url := 'https://hmdpaypyljdgoehztbvi.supabase.co/functions/v1/backup-dati',
    headers := jsonb_build_object('Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'backup_cron_secret')),
    body := '{"azione":"esegui","tipo":"automatico"}'::jsonb,
    timeout_milliseconds := 120000);
$job$);

-- capitolo "Backup e ripristino" nel Manuale del Gestionale (solo se non c'e' gia')
update manuali set contenuto = contenuto || $md$
## 17. Backup e ripristino

Tutti i dati del gestionale (turni, presenze, ferie, autisti, veicoli, noleggi, preventivi, fogli di viaggio, scadenze, orari dell'app e ogni altra tabella) vengono copiati **ogni notte** in un file compresso, in uno spazio privato visibile solo agli amministratori. Si conservano le copie degli **ultimi 30 giorni** e **una copia per ogni mese, per sempre**. Le tabelle nuove entrano nel backup da sole.

**Pagina Backup e ripristino**

1. In alto il riquadro **verde** indica la data dell'ultimo backup, quanti record contiene e quante copie sono conservate. Se diventa **giallo**, l'ultimo backup ha più di un giorno: premere **Fai un backup adesso** e avvisare chi segue la parte tecnica.
2. **Fai un backup adesso**: copia immediata, utile prima di un'operazione importante (per esempio un caricamento grosso di dati).
3. **Scarica**: salva sul computer il file della copia.
4. **Consulta**: si sceglie una tabella e si vedono i dati **com'erano in quella data**, con la ricerca e il pulsante **Scarica per Excel**. Consultare non modifica niente.

**Ripristinare dati cancellati o modificati per errore**

1. Apri la copia di una data in cui i dati erano giusti → **Consulta** → scegli la tabella.
2. Cerca i record, spunta quelli da recuperare → **Ripristina selezionati**. In alternativa **Ripristina tutta la tabella** (chiede di scrivere RIPRISTINA).
3. I record vengono riportati com'erano in quella data; gli altri dati non vengono toccati e i record creati dopo restano.
4. **Prima di ogni ripristino il sistema salva da solo un backup di sicurezza**: se il ripristino non era quello giusto, si torna indietro ripristinando da quella copia.

**Copie in nostro possesso, fuori da internet**

Il menu Strumenti scarica le copie sul PC e sulla chiavetta, nella cartella **BACKUP-DATABASE**: in automatico con la voce 2 (Aggiorna tutto) e quando si apre il menu dalla chiavetta, oppure a mano con la voce **9**. La prima volta su ogni postazione la voce 9 chiede la chiave dei backup, che si legge su Supabase (SQL Editor) con: `select decrypted_secret from vault.decrypted_secrets where name = 'backup_download_key';`

I file sono in formato aperto (JSON compresso): anche senza il gestionale si possono aprire e i dati restano leggibili. Le foto (galleria, scontrini) sono conservate a parte nello spazio file e non fanno parte di questo backup.
$md$, aggiornato_il = now()
where slug = 'manuale-gestionale' and contenuto not like '%## 17. Backup e ripristino%';

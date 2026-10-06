-- =====================================================
-- GESTIONALE DEANGELISBUS – v24: le scadenze dei mezzi entrano da sole nello Scadenzario.
-- Ogni volta che si salva una data di un mezzo (revisione, polizza, bollo, tachigrafo, estintore, ZTL, FL),
-- lo Scadenzario crea o aggiorna la voce "Tipo – TARGA"; i mezzi dismessi o esclusi dagli avvisi vengono tolti.
-- Così anche gli avvisi giornalieri (funzione controllo-scadenze, che legge la tabella scadenze) coprono i mezzi.
-- Contiene anche la correzione del collegamento circolari ANAV -> Scadenzario (id di tipo uuid). Rieseguibile.
-- =====================================================

-- 1) chiave che lega una voce dello Scadenzario alla scadenza di un mezzo (es. veicolo:12:scadenza_revisione)
alter table scadenze add column if not exists origine text;
create unique index if not exists scadenze_origine_uk on scadenze (origine);

-- giorni di preavviso per tipo di scadenza
create or replace function scadenze_preavviso_mezzo(p_campo text)
returns int language sql immutable as $$
  select case p_campo
    when 'scadenza_revisione' then 30 when 'prossimo_rinnovo_polizza' then 30
    when 'scadenza_revisione_tachigrafo' then 30 when 'scadenza_revisione_estintore' then 30
    when 'prossimo_rinnovo_bollo' then 15 when 'scadenza_scarico_tachigrafo' then 15
    else 15 end;
$$;

-- 2) allinea lo Scadenzario con le scadenze di un mezzo
create or replace function scadenze_sync_mezzo(p_veicolo text)
returns void language plpgsql security definer set search_path = public as $$
declare r record; chiavi text[] := '{}'; k text; cambia boolean;
begin
  for r in select * from v_scadenze_veicoli where veicolo_id::text = p_veicolo loop
    k := 'veicolo:' || p_veicolo || ':' || r.campo;
    if coalesce(r.attivo, true) = false or coalesce(r.escludi_da_alert, false) then
      continue;                                   -- mezzo dismesso o escluso: la voce viene tolta sotto
    end if;
    if k = any(chiavi) then continue; end if;      -- evita doppioni (piu' righe in scadenze_esterne)
    chiavi := chiavi || k;
    insert into scadenze (titolo, categoria, descrizione, data_scadenza, giorni_preavviso, stato, responsabile, ricorrenza, note, origine)
    values (r.tipo_scadenza || ' – ' || upper(regexp_replace(r.targa, '\s', '', 'g')),
            case when r.tipo_scadenza = 'Polizza assicurativa' then 'assicurazione' else 'altro' end,
            'Scadenza del mezzo' || coalesce(' ' || nullif(r.nome_veicolo, ''), '') || ' – aggiornata automaticamente da Scadenze mezzi',
            r.data_scadenza, scadenze_preavviso_mezzo(r.campo), 'da_fare', r.gestita_da, 'nessuna', r.nota_gestione, k)
    on conflict (origine) do update set
      titolo = excluded.titolo,
      categoria = excluded.categoria,
      descrizione = excluded.descrizione,
      responsabile = coalesce(excluded.responsabile, scadenze.responsabile),
      -- data rinnovata: la voce torna "da fare" e l'avviso potra' ripartire
      stato = case when scadenze.data_scadenza is distinct from excluded.data_scadenza then 'da_fare' else scadenze.stato end,
      notifica_inviata_il = case when scadenze.data_scadenza is distinct from excluded.data_scadenza then null else scadenze.notifica_inviata_il end,
      data_scadenza = excluded.data_scadenza,
      updated_at = now();
  end loop;
  -- tolgo le voci del mezzo che non servono piu' (data cancellata, mezzo dismesso o escluso)
  delete from scadenze where origine like 'veicolo:' || p_veicolo || ':%' and not (origine = any(chiavi));
end $$;
revoke all on function scadenze_sync_mezzo(text) from public, anon;

-- 3) regola automatica: dopo ogni salvataggio di un mezzo
create or replace function tg_veicoli_scadenzario()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    delete from scadenze where origine like 'veicolo:' || old.id::text || ':%';
    return old;
  end if;
  perform scadenze_sync_mezzo(new.id::text);
  return new;
end $$;
drop trigger if exists veicoli_scadenzario on veicoli;
create trigger veicoli_scadenzario after insert or update or delete on veicoli
  for each row execute function tg_veicoli_scadenzario();

-- 4) primo allineamento di tutta la flotta
do $$ declare v record; begin
  for v in select id from veicoli loop perform scadenze_sync_mezzo(v.id::text); end loop;
end $$;
-- le date gia' scadute oggi (dati ancora da aggiornare) non devono far partire decine di avvisi domattina:
-- restano visibili nello Scadenzario e l'avviso ripartira' quando la data verra' rinnovata
update scadenze set notifica_inviata_il = current_date
where origine like 'veicolo:%' and data_scadenza < current_date and notifica_inviata_il is null;

-- 5) correzione circolari ANAV: l'id dello Scadenzario e' un uuid
alter table anav_documenti alter column scadenza_id type uuid using null;
drop function if exists anav_crea_scadenza(bigint, date, int);
create or replace function anav_crea_scadenza(p_id bigint, p_data date, p_preavviso int default 7)
returns uuid language plpgsql security definer set search_path = public as $$
declare d record; nuovo uuid;
begin
  if not public.is_admin_gestionale() then raise exception 'Solo gli amministratori'; end if;
  select * into d from anav_documenti where id = p_id;
  if not found then raise exception 'Circolare non trovata'; end if;
  insert into scadenze (titolo, categoria, descrizione, data_scadenza, giorni_preavviso, stato, ricorrenza, note, origine)
  values (left('ANAV ' || coalesce('circ. ' || d.numero || ' – ', '') || d.titolo, 250), 'altro',
          'Da circolare ANAV', p_data, coalesce(p_preavviso, 7), 'da_fare', 'nessuna',
          nullif(coalesce(d.riassunto, '') || case when d.link is not null then E'\n' || d.link else '' end, ''),
          'anav:' || p_id)
  on conflict (origine) do update set data_scadenza = excluded.data_scadenza, giorni_preavviso = excluded.giorni_preavviso,
    stato = 'da_fare', notifica_inviata_il = null, updated_at = now()
  returning id into nuovo;
  update anav_documenti set scadenza = p_data, scadenza_id = nuovo where id = p_id;
  return nuovo;
end $$;
revoke all on function anav_crea_scadenza(bigint, date, int) from public, anon;
grant execute on function anav_crea_scadenza(bigint, date, int) to authenticated;

-- riepilogo
select count(*) filter (where origine like 'veicolo:%') as voci_mezzi_nello_scadenzario,
       count(*) filter (where origine like 'veicolo:%' and data_scadenza < current_date) as gia_scadute
from scadenze;

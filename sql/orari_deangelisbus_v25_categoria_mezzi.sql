-- =====================================================
-- GESTIONALE DEANGELISBUS – v25: nuova categoria "Mezzi" nello Scadenzario.
-- Tutte le scadenze dei mezzi (revisione, polizza, bollo, tachigrafo, estintore, ZTL, FL)
-- passano nella categoria "mezzi"; "assicurazione" resta per le polizze non legate ai mezzi. Rieseguibile.
-- =====================================================
alter table scadenze drop constraint if exists scadenze_categoria_check;
alter table scadenze add constraint scadenze_categoria_check
  check (categoria in ('fiscale', 'gara', 'assicurazione', 'contratto', 'mezzi', 'altro'));

-- la regola automatica d'ora in poi usa "mezzi"
create or replace function scadenze_sync_mezzo(p_veicolo text)
returns void language plpgsql security definer set search_path = public as $$
declare r record; chiavi text[] := '{}'; k text;
begin
  for r in select * from v_scadenze_veicoli where veicolo_id::text = p_veicolo loop
    k := 'veicolo:' || p_veicolo || ':' || r.campo;
    if coalesce(r.attivo, true) = false or coalesce(r.escludi_da_alert, false) then continue; end if;
    if k = any(chiavi) then continue; end if;
    chiavi := chiavi || k;
    insert into scadenze (titolo, categoria, descrizione, data_scadenza, giorni_preavviso, stato, responsabile, ricorrenza, note, origine)
    values (r.tipo_scadenza || ' – ' || upper(regexp_replace(r.targa, '\s', '', 'g')), 'mezzi',
            'Scadenza del mezzo' || coalesce(' ' || nullif(r.nome_veicolo, ''), '') || ' – aggiornata automaticamente da Scadenze mezzi',
            r.data_scadenza, scadenze_preavviso_mezzo(r.campo), 'da_fare', r.gestita_da, 'nessuna', r.nota_gestione, k)
    on conflict (origine) do update set
      titolo = excluded.titolo,
      categoria = excluded.categoria,
      descrizione = excluded.descrizione,
      responsabile = coalesce(excluded.responsabile, scadenze.responsabile),
      stato = case when scadenze.data_scadenza is distinct from excluded.data_scadenza then 'da_fare' else scadenze.stato end,
      notifica_inviata_il = case when scadenze.data_scadenza is distinct from excluded.data_scadenza then null else scadenze.notifica_inviata_il end,
      data_scadenza = excluded.data_scadenza,
      updated_at = now();
  end loop;
  delete from scadenze where origine like 'veicolo:' || p_veicolo || ':%' and not (origine = any(chiavi));
end $$;
revoke all on function scadenze_sync_mezzo(text) from public, anon;

-- sposto nella categoria "mezzi" le voci gia' create
update scadenze set categoria = 'mezzi' where origine like 'veicolo:%' and categoria <> 'mezzi';

select categoria, count(*) as voci from scadenze group by categoria order by categoria;

-- =====================================================
-- GESTIONALE DEANGELISBUS – v46: scadenze dei documenti degli autisti aggiornate in automatico.
--  1) scadenze_autisti_tipo(categoria): il valore di "tipo" ammesso dalla tabella per PATENTE, CQC, CARTA, VISITA
--  2) scadenze_autisti_aggiorna(righe, fonte): aggiorna o crea le scadenze (una per documento e autista),
--     usata dalla scheda del dipendente e dalla lettura giornaliera degli export Golia
--  3) cron giornaliero della funzione sync-scadenze-golia (stesso segreto del cron dei km Golia)
-- Rieseguibile.
-- =====================================================

create or replace function public.scadenze_autisti_tipo(p_categoria text)
returns text language plpgsql stable security definer set search_path = public as $$
declare def text; modello text; predefinito text; v text;
begin
  modello := case upper(p_categoria)
    when 'PATENTE' then 'patent' when 'CQC' then 'cqc' when 'CARTA' then '(tachigraf|carta)' when 'VISITA' then '(visita|medic)' else null end;
  predefinito := case upper(p_categoria)
    when 'PATENTE' then 'PATENTE' when 'CQC' then 'CQC' when 'CARTA' then 'CARTA_TACHIGRAFICA' when 'VISITA' then 'VISITA_MEDICA' else null end;
  if modello is null then return null; end if;
  select string_agg(pg_get_constraintdef(oid), ' ') into def from pg_constraint
   where conrelid = 'public.scadenze_autisti'::regclass and contype = 'c';
  select m[1] into v from regexp_matches(coalesce(def, ''), '''([^'']*' || modello || '[^'']*)''', 'gi') as m limit 1;
  if v is not null then return v; end if;
  select tipo into v from scadenze_autisti where tipo ~* modello group by tipo order by count(*) desc limit 1;
  return coalesce(v, predefinito);
end $$;

-- righe: [{ "autista_id"?, "cognome"?, "nome"?, "nominativo"?, "categoria", "numero"?, "scadenza" (AAAA-MM-GG) }]
create or replace function public.scadenze_autisti_aggiorna(p_righe jsonb, p_fonte text default 'gestionale')
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  r jsonb; aid uuid; t text; sc date; num text; es record;
  n_agg int := 0; n_nuovi int := 0; n_uguali int := 0; non_trovati text[] := '{}';
begin
  if not (coalesce(auth.role(), '') = 'service_role' or current_user in ('postgres', 'supabase_admin') or public.is_admin_gestionale()) then
    raise exception 'Solo un amministratore del gestionale puo'' aggiornare le scadenze degli autisti';
  end if;
  for r in select * from jsonb_array_elements(coalesce(p_righe, '[]'::jsonb)) loop
    sc := nullif(r->>'scadenza', '')::date;
    if sc is null then continue; end if;
    t := scadenze_autisti_tipo(r->>'categoria');
    if t is null then continue; end if;
    num := nullif(trim(coalesce(r->>'numero', '')), '');
    aid := nullif(r->>'autista_id', '')::uuid;
    if aid is null then
      select a.id into aid from autisti a
       where (upper(trim(a.cognome)) = upper(trim(coalesce(r->>'cognome', ''))) and upper(trim(a.nome)) = upper(trim(coalesce(r->>'nome', ''))))
          or (r->>'nominativo' is not null and upper(trim(a.cognome) || ' ' || trim(a.nome)) = upper(trim(r->>'nominativo')))
       order by coalesce(a.attivo, true) desc limit 1;
    end if;
    if aid is null then
      non_trovati := array_append(non_trovati, coalesce(r->>'nominativo', trim(coalesce(r->>'cognome','') || ' ' || coalesce(r->>'nome',''))) || ' (' || (r->>'categoria') || ')');
      continue;
    end if;
    select * into es from scadenze_autisti where autista_id = aid and tipo = t order by data_scadenza desc nulls last limit 1;
    if es.id is null then
      insert into scadenze_autisti (autista_id, tipo, numero_documento, data_scadenza, note)
      values (aid, t, num, sc, 'Da ' || p_fonte || ' (' || to_char(now(), 'DD/MM/YYYY') || ')');
      n_nuovi := n_nuovi + 1;
    else
      -- il numero breve di Golia (senza le ultime cifre della carta) non sostituisce quello completo gia' presente
      if num is not null and es.numero_documento is not null and es.numero_documento like num || '%' then num := es.numero_documento; end if;
      if es.data_scadenza is not distinct from sc and coalesce(num, es.numero_documento) is not distinct from es.numero_documento then
        n_uguali := n_uguali + 1;
      else
        update scadenze_autisti set data_scadenza = sc, numero_documento = coalesce(num, numero_documento), updated_at = now()
        where id = es.id;
        n_agg := n_agg + 1;
      end if;
    end if;
    es := null;
  end loop;
  return jsonb_build_object('aggiornati', n_agg, 'nuovi', n_nuovi, 'invariati', n_uguali, 'non_trovati', to_jsonb(non_trovati));
end $$;

revoke all on function public.scadenze_autisti_aggiorna(jsonb, text) from public, anon;
grant execute on function public.scadenze_autisti_aggiorna(jsonb, text) to authenticated, service_role;
grant execute on function public.scadenze_autisti_tipo(text) to authenticated, service_role;

-- cron giornaliero 05:45 UTC, con lo stesso segreto del cron dei km Golia
do $$
declare segreto text;
begin
  select substring(command from 'x-cron-secret'', *''([^'']+)''') into segreto from cron.job where jobname = 'sync-km-golia' limit 1;
  if segreto is null or segreto = 'INCOLLA_QUI_IL_SEGRETO' then
    raise notice 'Cron NON creato: non trovo il segreto del cron sync-km-golia. Lancia la sincronizzazione a mano dalla pagina Scadenze autisti.';
    return;
  end if;
  perform cron.unschedule(jobid) from cron.job where jobname = 'sync-scadenze-golia';
  perform cron.schedule('sync-scadenze-golia', '45 5 * * *', format($c$
    select net.http_post(
      url := 'https://hmdpaypyljdgoehztbvi.supabase.co/functions/v1/sync-scadenze-golia',
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', %L),
      body := '{}'::jsonb, timeout_milliseconds := 60000);
  $c$, segreto));
  raise notice 'Cron sync-scadenze-golia creato: ogni giorno alle 05:45 UTC';
end $$;

select jobname, schedule, active from cron.job where jobname in ('sync-km-golia', 'sync-scadenze-golia');

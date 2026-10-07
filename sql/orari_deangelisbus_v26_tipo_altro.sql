-- =====================================================
-- GESTIONALE DEANGELISBUS – v26: tipo di turno "ALTRO" (disposizione, garage, scalo, manutenzione).
-- Se la tabella turni_programmati ha una regola sui tipi ammessi, la si allarga aggiungendo ALTRO
-- (mantenendo tutti i tipi gia' usati). Le presenze non cambiano: per i tipi non standard il trigger
-- crea_presenza_da_turno_programmato ricava gia' il tipo dalla descrizione. Rieseguibile.
-- =====================================================
do $$
declare c record; tipi text[];
begin
  select array_agg(distinct x) into tipi from (
    select unnest(array['TPL','NCC','ALTRO','RIPOSO','FERIE','PERMESSO','MALATTIA','INFORTUNIO','FESTIVO']) x
    union select distinct tipo from turni_programmati where tipo is not null) t;
  for c in select conname from pg_constraint
           where conrelid = 'public.turni_programmati'::regclass and contype = 'c'
             and pg_get_constraintdef(oid) ilike '%tipo%' loop
    execute format('alter table public.turni_programmati drop constraint %I', c.conname);
    raise notice 'Regola % sostituita', c.conname;
  end loop;
  execute format('alter table public.turni_programmati add constraint turni_programmati_tipo_check check (tipo is null or tipo = any (%L::text[]))', tipi);
end $$;

select pg_get_constraintdef(oid) as tipi_ammessi from pg_constraint
where conrelid = 'public.turni_programmati'::regclass and conname = 'turni_programmati_tipo_check';

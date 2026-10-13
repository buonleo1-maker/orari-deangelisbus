-- =====================================================
-- GESTIONALE DEANGELISBUS – v49: promemoria ogni mattina alle 8:30 (ora legale; 7:30 con l'ora solare)
-- per i fogli di viaggio inviati all'autista e non compilati (funzione promemoria-fogli-viaggio).
-- Usa lo stesso segreto del cron dei km Golia. Rieseguibile.
-- =====================================================
do $$
declare segreto text;
begin
  select substring(command from 'x-cron-secret'', *''([^'']+)''') into segreto from cron.job where jobname = 'sync-km-golia' limit 1;
  if segreto is null then raise notice 'Cron NON creato: non trovo il segreto del cron sync-km-golia.'; return; end if;
  perform cron.unschedule(jobid) from cron.job where jobname = 'promemoria-fogli-viaggio';
  perform cron.schedule('promemoria-fogli-viaggio', '30 6 * * *', format($c$
    select net.http_post(
      url := 'https://hmdpaypyljdgoehztbvi.supabase.co/functions/v1/promemoria-fogli-viaggio',
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', %L),
      body := '{}'::jsonb, timeout_milliseconds := 60000);
  $c$, segreto));
  raise notice 'Cron promemoria-fogli-viaggio creato: ogni giorno alle 06:30 UTC';
end $$;
select jobname, schedule, active from cron.job where jobname in ('sync-km-golia', 'sync-scadenze-golia', 'promemoria-fogli-viaggio') order by jobname;

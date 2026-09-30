-- =====================================================
-- ORARI DE ANGELIS BUS – v14: navetta Bari visibile tutto l'anno.
-- I periodi della navetta diventano "solo informativi": dicono chi effettua il servizio
-- (Deangelisbus nei suoi mesi, Autobus Tito negli altri), ma le corse circolano ogni giorno.
-- Rieseguibile.
-- =====================================================
alter table orari_periodi add column if not exists solo_informativo boolean not null default false;
alter table orari_linee   add column if not exists alternanza_con text;

update orari_periodi set solo_informativo = true, note = 'Mese di servizio Deangelisbus'
where linea_id = 'navetta-bari';

update orari_linee set
  alternanza_con = 'Autobus Tito',
  info_pubblico  = 'Corse 3 e 5 del servizio Cotrab Matera – Aeroporto di Bari, tutti i giorni festivi compresi. Svolte a mesi alterni da Deangelisbus e da Autobus Tito. Biglietti solo online su www.marozzivt.it. Controlla sul parabrezza la tabella con la destinazione.'
where id = 'navetta-bari';

update orari_corse set note = 'Tutti i giorni, festivi compresi.' where linea_id = 'navetta-bari';

-- la funzione di controllo lato database ignora i periodi solo informativi
create or replace function orari_corsa_attiva(p_codice text, p_data date)
returns boolean language sql stable as $$
  select c.attiva
     and extract(isodow from p_data)::smallint = any(c.giorni)
     and (c.valido_dal is null or p_data >= c.valido_dal)
     and (c.valido_al  is null or p_data <= c.valido_al)
     and (not exists (select 1 from orari_periodi p where p.linea_id = c.linea_id and not p.solo_informativo)
          or exists (select 1 from orari_periodi p where p.linea_id = c.linea_id and not p.solo_informativo and p_data between p.dal and p.al))
     and not exists (select 1 from orari_sospensioni s
                     where p_data between s.dal and s.al
                       and (s.linea_id is null or s.linea_id = c.linea_id)
                       and (s.ambito = 'tutti' or c.solo_giorni_scolastici))
     and (not c.solo_giorni_non_scolastici
          or exists (select 1 from orari_sospensioni s
                     where p_data between s.dal and s.al and s.ambito = 'scolastico'
                       and (s.linea_id is null or s.linea_id = c.linea_id)))
  from orari_corse c where c.codice = p_codice;
$$;
grant execute on function orari_corsa_attiva(text, date) to anon, authenticated;

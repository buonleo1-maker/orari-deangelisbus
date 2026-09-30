-- v13: navetta Matera – Aeroporto di Bari, corse Deangelisbus 3 e 5 (orario in vigore dall'11/5/2026). Rieseguibile.
delete from orari_corse where linea_id = 'navetta-bari';
insert into orari_corse (codice,linea_id,percorso_id,denominazione,direzione,partenza,frequenza,giorni,solo_giorni_scolastici,solo_giorni_non_scolastici,attiva,note) values
  ('BARI-3A','navetta-bari','navetta-bari-a-1','Corsa 3 – Matera → Aeroporto','A','08:30',NULL,'{1,2,3,4,5,6,7}',false,false,true,'Tutti i giorni, festivi compresi, nei mesi di servizio Deangelisbus.'),
  ('BARI-5A','navetta-bari','navetta-bari-a-1','Corsa 5 – Matera → Aeroporto','A','14:00',NULL,'{1,2,3,4,5,6,7}',false,false,true,'Tutti i giorni, festivi compresi, nei mesi di servizio Deangelisbus.'),
  ('BARI-3R','navetta-bari','navetta-bari-r-1','Corsa 3 – Aeroporto → Matera','R','11:30',NULL,'{1,2,3,4,5,6,7}',false,false,true,'Tutti i giorni, festivi compresi, nei mesi di servizio Deangelisbus.'),
  ('BARI-5R','navetta-bari','navetta-bari-r-1','Corsa 5 – Aeroporto → Matera','R','17:00',NULL,'{1,2,3,4,5,6,7}',false,false,true,'Tutti i giorni, festivi compresi, nei mesi di servizio Deangelisbus.');

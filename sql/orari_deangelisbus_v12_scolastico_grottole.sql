-- =====================================================
-- ORARI DE ANGELIS BUS – v12: trasporto scolastico di Grottole
-- (andata e ritorno: secondaria extraurbano, primaria urbano, infanzia). Rieseguibile.
-- Fonte: prospetto orari scolastico Grottole (foglio 1).
-- =====================================================
insert into orari_linee (id,nome,colore,ordine,categoria,comune,committente,subappalto,info_pubblico) values
  ('grottole-scuolabus','Grottole – Trasporto scolastico','#F1C40F',19,'scolastico','Grottole','Comune di Grottole',false,'Servizio riservato agli alunni iscritti al trasporto scolastico. Nei giorni senza scuola il servizio non è effettuato.')
on conflict (id) do update set nome=excluded.nome, colore=excluded.colore, ordine=excluded.ordine, categoria=excluded.categoria, comune=excluded.comune, committente=excluded.committente, subappalto=excluded.subappalto, info_pubblico=excluded.info_pubblico;

insert into orari_fermate (id,nome,comune,zona_tariffaria,lat,lon) values
  (67,'SP 8 – direzione Grassano','Grottole',NULL,NULL,NULL),
  (68,'Via Scalo Ferroviario (Grottole Scalo)','Grottole',NULL,NULL,NULL),
  (69,'Stazione – Ponte Basento','Grottole',NULL,NULL,NULL),
  (70,'Via Fontana dei Fichi','Grottole',NULL,NULL,NULL),
  (71,'Via Fontana di Lupo (ex Macello)','Grottole',NULL,NULL,NULL),
  (72,'Via Kennedy','Grottole',NULL,NULL,NULL),
  (73,'Piazza Vittorio Emanuele','Grottole',NULL,NULL,NULL),
  (74,'Istituto scolastico','Grottole',NULL,NULL,NULL),
  (75,'Contrada Cupone','Grottole',NULL,NULL,NULL),
  (76,'Via Nazionale','Grottole',NULL,NULL,NULL),
  (77,'Viale della Resistenza','Grottole',NULL,NULL,NULL),
  (78,'Incrocio Via Nazionale – Viale della Resistenza','Grottole',NULL,NULL,NULL),
  (79,'Corso Umberto I','Grottole',NULL,NULL,NULL)
on conflict (id) do update set nome=excluded.nome, comune=excluded.comune;

delete from orari_corse where linea_id = 'grottole-scuolabus';
delete from orari_percorsi_fermate where percorso_id like 'grottole-scuolabus-%';
delete from orari_percorsi where linea_id = 'grottole-scuolabus';

insert into orari_percorsi (id,linea_id,direzione,nome) values
  ('grottole-scuolabus-a-1','grottole-scuolabus','A','Secondaria – extraurbano'),
  ('grottole-scuolabus-a-2','grottole-scuolabus','A','Primaria – urbano'),
  ('grottole-scuolabus-a-3','grottole-scuolabus','A','Infanzia'),
  ('grottole-scuolabus-r-1','grottole-scuolabus','R','Secondaria – extraurbano'),
  ('grottole-scuolabus-r-2','grottole-scuolabus','R','Primaria – urbano'),
  ('grottole-scuolabus-r-3','grottole-scuolabus','R','Infanzia');

insert into orari_percorsi_fermate (percorso_id,ordine,fermata_id,minuti,minuti_stimati) values
  ('grottole-scuolabus-a-1',1,67,0,0),
  ('grottole-scuolabus-a-1',2,68,20,20),
  ('grottole-scuolabus-a-1',3,69,30,30),
  ('grottole-scuolabus-a-1',4,70,40,40),
  ('grottole-scuolabus-a-1',5,71,45,45),
  ('grottole-scuolabus-a-1',6,72,49,49),
  ('grottole-scuolabus-a-1',7,23,53,53),
  ('grottole-scuolabus-a-1',8,73,55,55),
  ('grottole-scuolabus-a-1',9,74,60,60),
  ('grottole-scuolabus-a-2',1,78,0,0),
  ('grottole-scuolabus-a-2',2,23,1,1),
  ('grottole-scuolabus-a-2',3,77,3,3),
  ('grottole-scuolabus-a-2',4,73,5,5),
  ('grottole-scuolabus-a-2',5,79,6,6),
  ('grottole-scuolabus-a-2',6,72,8,8),
  ('grottole-scuolabus-a-2',7,71,10,10),
  ('grottole-scuolabus-a-2',8,70,13,13),
  ('grottole-scuolabus-a-2',9,1,15,15),
  ('grottole-scuolabus-a-2',10,74,18,18),
  ('grottole-scuolabus-a-3',1,74,0,0),
  ('grottole-scuolabus-a-3',2,71,3,3),
  ('grottole-scuolabus-a-3',3,75,5,5),
  ('grottole-scuolabus-a-3',4,76,10,10),
  ('grottole-scuolabus-a-3',5,77,11,11),
  ('grottole-scuolabus-a-3',6,23,12,12),
  ('grottole-scuolabus-a-3',7,73,14,14),
  ('grottole-scuolabus-a-3',8,74,17,17),
  ('grottole-scuolabus-r-1',1,74,0,0),
  ('grottole-scuolabus-r-1',2,23,5,5),
  ('grottole-scuolabus-r-1',3,73,10,10),
  ('grottole-scuolabus-r-1',4,72,15,15),
  ('grottole-scuolabus-r-1',5,71,17,17),
  ('grottole-scuolabus-r-1',6,70,20,20),
  ('grottole-scuolabus-r-1',7,69,30,30),
  ('grottole-scuolabus-r-1',8,68,45,45),
  ('grottole-scuolabus-r-1',9,67,60,60),
  ('grottole-scuolabus-r-2',1,74,0,0),
  ('grottole-scuolabus-r-2',2,1,5,5),
  ('grottole-scuolabus-r-2',3,70,6,6),
  ('grottole-scuolabus-r-2',4,71,8,8),
  ('grottole-scuolabus-r-2',5,72,12,12),
  ('grottole-scuolabus-r-2',6,78,15,15),
  ('grottole-scuolabus-r-2',7,23,16,16),
  ('grottole-scuolabus-r-2',8,77,18,18),
  ('grottole-scuolabus-r-2',9,73,19,19),
  ('grottole-scuolabus-r-2',10,79,20,20),
  ('grottole-scuolabus-r-3',1,74,0,0),
  ('grottole-scuolabus-r-3',2,71,3,3),
  ('grottole-scuolabus-r-3',3,75,5,5),
  ('grottole-scuolabus-r-3',4,76,10,10),
  ('grottole-scuolabus-r-3',5,77,11,11),
  ('grottole-scuolabus-r-3',6,23,12,12),
  ('grottole-scuolabus-r-3',7,73,15,15),
  ('grottole-scuolabus-r-3',8,74,20,20);

insert into orari_corse (codice,linea_id,percorso_id,denominazione,direzione,partenza,frequenza,giorni,solo_giorni_scolastici,solo_giorni_non_scolastici,attiva,note) values
  ('GRS-SEC-A','grottole-scuolabus','grottole-scuolabus-a-1','Secondaria – extraurbano','A','07:00',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('GRS-PRI-A','grottole-scuolabus','grottole-scuolabus-a-2','Primaria – urbano','A','08:10',NULL,'{1,2,3,4,5,6}',true,false,true,'Il sabato partenza alle 7:45 per un utente sulla SP 8.'),
  ('GRS-INF-A','grottole-scuolabus','grottole-scuolabus-a-3','Infanzia','A','08:15',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('GRS-SEC-R','grottole-scuolabus','grottole-scuolabus-r-1','Secondaria – extraurbano','R','14:00',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('GRS-PRI-R','grottole-scuolabus','grottole-scuolabus-r-2','Primaria – urbano','R','13:30',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('GRS-PRI-R13','grottole-scuolabus','grottole-scuolabus-r-2','Primaria – corsa aggiuntiva per una classe','R','13:00',NULL,'{5,6}',true,false,true,'Solo venerdì e sabato.'),
  ('GRS-INF-R','grottole-scuolabus','grottole-scuolabus-r-3','Infanzia','R','13:30',NULL,'{1,2,3,4,5,6}',true,false,true,NULL);

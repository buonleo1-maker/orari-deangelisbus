-- =====================================================
-- ORARI DE ANGELIS BUS – v3: urbano Grottole, scolastico Miglionico,
-- linea 354 Matera–Policoro, navette Matera–Aeroporto Bari
-- Da eseguire DOPO setup + v2. Rieseguibile.
-- =====================================================

-- fermate nuove senza coordinate: si posizionano poi sulla mappa
alter table orari_fermate alter column lat drop not null;
alter table orari_fermate alter column lon drop not null;
alter table orari_corse add column if not exists solo_giorni_non_scolastici boolean not null default false;

create or replace function orari_corsa_attiva(p_codice text, p_data date)
returns boolean language sql stable as $$
  select c.attiva
     and extract(isodow from p_data)::smallint = any(c.giorni)
     and (c.valido_dal is null or p_data >= c.valido_dal)
     and (c.valido_al  is null or p_data <= c.valido_al)
     and (not exists (select 1 from orari_periodi p where p.linea_id = c.linea_id)
          or exists (select 1 from orari_periodi p where p.linea_id = c.linea_id and p_data between p.dal and p.al))
     and not exists (select 1 from orari_sospensioni s
                     where p_data between s.dal and s.al
                       and (s.linea_id is null or s.linea_id = c.linea_id)
                       and (s.ambito = 'tutti' or c.solo_giorni_scolastici))
     -- corse "solo non scolastiche": circolano solo nei periodi di sospensione scolastica
     and (not c.solo_giorni_non_scolastici
          or exists (select 1 from orari_sospensioni s
                     where p_data between s.dal and s.al and s.ambito = 'scolastico'
                       and (s.linea_id is null or s.linea_id = c.linea_id)))
  from orari_corse c where c.codice = p_codice;
$$;
grant execute on function orari_corsa_attiva(text, date) to anon, authenticated;

insert into orari_linee (id,nome,colore,ordine,categoria,comune,committente,subappalto,info_pubblico) values
  ('grottole-sociale','Grottole – Trasporto sociale urbano','#C0392B',10,'urbano','Grottole','Comune di Grottole',false,'Biglietto corsa semplice € 0,40 – Abbonamento mensile € 12,00. Servizio non effettuato il sabato e nei giorni festivi.'),
  ('miglionico-scuolabus','Miglionico – Trasporto scolastico','#F1C40F',20,'scolastico','Miglionico','Comune di Miglionico',false,'Servizio riservato agli alunni iscritti al trasporto scolastico. A.S. 2026/2027 – orari di andata a scuola.'),
  ('matera-policoro','Matera – Metaponto – Policoro (linea 354)','#16A085',30,'extraurbano',NULL,'Cotrab',true,'Circa da metà giugno a metà settembre (date da stabilire) le corse transitano per Metaponto Lido.'),
  ('navetta-bari','Navetta Matera – Aeroporto di Bari','#2C3E50',40,'navetta',NULL,'Cotrab',true,'Biglietti solo online su www.marozzivt.it. Controlla sul parabrezza la tabella con la destinazione.')
on conflict (id) do update set nome=excluded.nome, colore=excluded.colore, ordine=excluded.ordine, categoria=excluded.categoria, comune=excluded.comune, committente=excluded.committente, subappalto=excluded.subappalto, info_pubblico=excluded.info_pubblico;

insert into orari_fermate (id,nome,comune,zona_tariffaria,lat,lon) values
  (21,'Via Nazionale incrocio Via Arcioni','Grottole',NULL,NULL,NULL),
  (22,'V.le della Resistenza – ASL','Grottole',NULL,NULL,NULL),
  (23,'V.le della Resistenza – Chiesa S. Rocco','Grottole',NULL,NULL,NULL),
  (24,'V.le della Resistenza – Chiesa Caduta','Grottole',NULL,NULL,NULL),
  (25,'V.le della Resistenza – Chiesa S. Pietro','Grottole',NULL,NULL,NULL),
  (26,'Via Nazionale incrocio C.so Umberto','Grottole',NULL,NULL,NULL),
  (27,'Via Nazionale incrocio Cimitero','Grottole',NULL,NULL,NULL),
  (28,'Via Madonna delle Grazie','Grottole',NULL,NULL,NULL),
  (29,'Cimitero','Grottole',NULL,NULL,NULL),
  (30,'Via Nazionale – Scuole','Grottole',NULL,NULL,NULL),
  (31,'C.da Serre','Grottole',NULL,NULL,NULL),
  (32,'Villaggio AGIP','Grottole',NULL,NULL,NULL),
  (33,'Rione Macello','Grottole',NULL,NULL,NULL),
  (34,'Municipio','Grottole',NULL,NULL,NULL),
  (35,'V.le Kennedy incrocio Villaggio AGIP','Grottole',NULL,NULL,NULL),
  (36,'V.le Kennedy incrocio De Gasperi','Grottole',NULL,NULL,NULL),
  (37,'Scuola secondaria','Miglionico',NULL,NULL,NULL),
  (38,'Scuola primaria','Miglionico',NULL,NULL,NULL),
  (39,'Scuola dell''infanzia','Miglionico',NULL,NULL,NULL),
  (40,'Rione Alcide De Gasperi','Miglionico',NULL,NULL,NULL),
  (41,'Fontana Pila','Miglionico',NULL,NULL,NULL),
  (42,'Contrada Pila','Miglionico',NULL,NULL,NULL),
  (43,'Viale Kennedy','Miglionico',NULL,NULL,NULL),
  (44,'Via Carlo Levi','Miglionico',NULL,NULL,NULL),
  (45,'Via Trinità','Miglionico',NULL,NULL,NULL),
  (46,'Via Dante (sopra)','Miglionico',NULL,NULL,NULL),
  (47,'Via Berlinguer','Miglionico',NULL,NULL,NULL),
  (48,'Via Sandro Pertini','Miglionico',NULL,NULL,NULL),
  (49,'Piazza del Popolo','Miglionico',NULL,NULL,NULL),
  (50,'Via Quaranta / P.zza Marconi','Miglionico',NULL,NULL,NULL),
  (51,'Via Papa Giovanni','Miglionico',NULL,NULL,NULL),
  (52,'Via A. Moro','Miglionico',NULL,NULL,NULL),
  (53,'Cimitero','Miglionico',NULL,NULL,NULL),
  (54,'Campagna (zone rurali)','Miglionico',NULL,NULL,NULL),
  (55,'Incrocio Via A. Moro / Via Papa Giovanni','Miglionico',NULL,NULL,NULL),
  (56,'Matera – P.zza della Visitazione','Matera',NULL,NULL,NULL),
  (57,'Svincolo SS7 / SS380','Matera',NULL,NULL,NULL),
  (58,'Svincolo SS175 / SS380','Montescaglioso',NULL,NULL,NULL),
  (59,'Bivio Litoranea','Bernalda',NULL,NULL,NULL),
  (60,'Metaponto Borgo','Bernalda',NULL,NULL,NULL),
  (61,'Metaponto Scalo','Bernalda',NULL,NULL,NULL),
  (62,'Bernalda – Bivio Litoranea','Bernalda',NULL,NULL,NULL),
  (63,'Policoro – Ospedale','Policoro',NULL,NULL,NULL),
  (64,'Matera – Viale Aldo Moro (tra Stazione FAL e Comune)','Matera',NULL,NULL,NULL),
  (65,'Altamura – Via Santeramo in Colle ang. Via Scotellaro','Altamura',NULL,NULL,NULL),
  (66,'Aeroporto di Bari Palese','Bari',NULL,NULL,NULL)
on conflict (id) do update set nome=excluded.nome, comune=excluded.comune;

-- ripulisce e ricarica i percorsi delle linee di questo script
delete from orari_corse where linea_id in ('grottole-sociale','miglionico-scuolabus','matera-policoro','navetta-bari');
delete from orari_percorsi where linea_id in ('grottole-sociale','miglionico-scuolabus','matera-policoro','navetta-bari');

insert into orari_percorsi (id,linea_id,direzione,nome) values
  ('grottole-sociale-a-1','grottole-sociale','A','1ª corsa'),
  ('grottole-sociale-a-2','grottole-sociale','A','1ª corsa – ripasso'),
  ('miglionico-scuolabus-a-1','miglionico-scuolabus','A','Secondaria – urbano'),
  ('miglionico-scuolabus-a-2','miglionico-scuolabus','A','Secondaria – extraurbano'),
  ('miglionico-scuolabus-a-3','miglionico-scuolabus','A','Primaria – urbano'),
  ('miglionico-scuolabus-a-4','miglionico-scuolabus','A','Primaria – extraurbano'),
  ('miglionico-scuolabus-a-5','miglionico-scuolabus','A','Infanzia'),
  ('matera-policoro-a-1','matera-policoro','A','Matera → Policoro'),
  ('matera-policoro-a-2','matera-policoro','A','Matera → Policoro'),
  ('matera-policoro-a-3','matera-policoro','A','Matera → Policoro'),
  ('matera-policoro-r-1','matera-policoro','R','Policoro → Matera'),
  ('matera-policoro-r-2','matera-policoro','R','Policoro → Matera'),
  ('navetta-bari-a-1','navetta-bari','A','Matera → Aeroporto'),
  ('navetta-bari-r-1','navetta-bari','R','Aeroporto → Matera');

insert into orari_percorsi_fermate (percorso_id,ordine,fermata_id,minuti,minuti_stimati) values
  ('grottole-sociale-a-1',1,21,0,0),
  ('grottole-sociale-a-1',2,22,1,1),
  ('grottole-sociale-a-1',3,23,2,2),
  ('grottole-sociale-a-1',4,24,2,2),
  ('grottole-sociale-a-1',5,25,3,3),
  ('grottole-sociale-a-1',6,26,4,4),
  ('grottole-sociale-a-1',7,27,5,5),
  ('grottole-sociale-a-1',8,28,6,6),
  ('grottole-sociale-a-1',9,29,7,7),
  ('grottole-sociale-a-1',10,30,9,9),
  ('grottole-sociale-a-1',11,31,11,11),
  ('grottole-sociale-a-1',12,32,12,12),
  ('grottole-sociale-a-1',13,33,13,13),
  ('grottole-sociale-a-1',14,1,14,14),
  ('grottole-sociale-a-1',15,34,15,15),
  ('grottole-sociale-a-1',16,35,16,16),
  ('grottole-sociale-a-1',17,36,17,17),
  ('grottole-sociale-a-1',18,2,18,18),
  ('grottole-sociale-a-1',19,3,19,19),
  ('grottole-sociale-a-2',1,21,0,0),
  ('grottole-sociale-a-2',2,22,1,1),
  ('grottole-sociale-a-2',3,23,2,2),
  ('grottole-sociale-a-2',4,24,2,2),
  ('grottole-sociale-a-2',5,25,3,3),
  ('grottole-sociale-a-2',6,26,4,4),
  ('grottole-sociale-a-2',7,27,5,5),
  ('grottole-sociale-a-2',8,28,6,6),
  ('grottole-sociale-a-2',9,29,7,7),
  ('miglionico-scuolabus-a-1',1,40,0,0),
  ('miglionico-scuolabus-a-1',2,41,1,1),
  ('miglionico-scuolabus-a-1',3,42,3,3),
  ('miglionico-scuolabus-a-1',4,43,4,4),
  ('miglionico-scuolabus-a-1',5,44,6,6),
  ('miglionico-scuolabus-a-1',6,45,9,9),
  ('miglionico-scuolabus-a-1',7,37,15,15),
  ('miglionico-scuolabus-a-2',1,54,0,0),
  ('miglionico-scuolabus-a-2',2,9,10,10),
  ('miglionico-scuolabus-a-2',3,50,11,11),
  ('miglionico-scuolabus-a-2',4,15,13,13),
  ('miglionico-scuolabus-a-2',5,16,15,15),
  ('miglionico-scuolabus-a-2',6,37,20,20),
  ('miglionico-scuolabus-a-3',1,46,0,0),
  ('miglionico-scuolabus-a-3',2,47,1,1),
  ('miglionico-scuolabus-a-3',3,45,3,3),
  ('miglionico-scuolabus-a-3',4,44,5,5),
  ('miglionico-scuolabus-a-3',5,48,6,6),
  ('miglionico-scuolabus-a-3',6,40,8,8),
  ('miglionico-scuolabus-a-3',7,41,10,10),
  ('miglionico-scuolabus-a-3',8,42,13,13),
  ('miglionico-scuolabus-a-3',9,43,15,15),
  ('miglionico-scuolabus-a-3',10,38,18,18),
  ('miglionico-scuolabus-a-4',1,49,0,0),
  ('miglionico-scuolabus-a-4',2,50,1,1),
  ('miglionico-scuolabus-a-4',3,51,3,3),
  ('miglionico-scuolabus-a-4',4,52,5,5),
  ('miglionico-scuolabus-a-4',5,15,8,8),
  ('miglionico-scuolabus-a-4',6,38,11,11),
  ('miglionico-scuolabus-a-5',1,49,0,0),
  ('miglionico-scuolabus-a-5',2,9,1,1),
  ('miglionico-scuolabus-a-5',3,50,2,2),
  ('miglionico-scuolabus-a-5',4,53,3,3),
  ('miglionico-scuolabus-a-5',5,55,4,4),
  ('miglionico-scuolabus-a-5',6,15,5,5),
  ('miglionico-scuolabus-a-5',7,42,8,8),
  ('miglionico-scuolabus-a-5',8,43,9,9),
  ('miglionico-scuolabus-a-5',9,46,10,10),
  ('miglionico-scuolabus-a-5',10,47,11,11),
  ('miglionico-scuolabus-a-5',11,45,13,13),
  ('miglionico-scuolabus-a-5',12,48,15,15),
  ('miglionico-scuolabus-a-5',13,39,20,20),
  ('matera-policoro-a-1',1,56,0,0),
  ('matera-policoro-a-1',2,57,15,15),
  ('matera-policoro-a-1',3,58,25,25),
  ('matera-policoro-a-1',4,59,40,40),
  ('matera-policoro-a-1',5,60,45,45),
  ('matera-policoro-a-1',6,61,50,50),
  ('matera-policoro-a-1',7,62,60,60),
  ('matera-policoro-a-1',8,12,80,80),
  ('matera-policoro-a-1',9,63,85,85),
  ('matera-policoro-a-1',10,13,90,90),
  ('matera-policoro-a-2',1,56,0,0),
  ('matera-policoro-a-2',2,57,15,15),
  ('matera-policoro-a-2',3,58,25,25),
  ('matera-policoro-a-2',4,59,40,40),
  ('matera-policoro-a-2',5,60,45,45),
  ('matera-policoro-a-2',6,61,50,50),
  ('matera-policoro-a-2',7,62,60,60),
  ('matera-policoro-a-2',8,12,80,80),
  ('matera-policoro-a-2',9,13,90,90),
  ('matera-policoro-a-3',1,56,0,0),
  ('matera-policoro-a-3',2,57,15,15),
  ('matera-policoro-a-3',3,58,25,25),
  ('matera-policoro-a-3',4,59,40,40),
  ('matera-policoro-a-3',5,60,45,45),
  ('matera-policoro-a-3',6,61,50,50),
  ('matera-policoro-a-3',7,62,60,60),
  ('matera-policoro-a-3',8,12,70,70),
  ('matera-policoro-a-3',9,63,80,80),
  ('matera-policoro-a-3',10,13,90,90),
  ('matera-policoro-r-1',1,13,0,0),
  ('matera-policoro-r-1',2,12,10,10),
  ('matera-policoro-r-1',3,62,30,30),
  ('matera-policoro-r-1',4,61,40,40),
  ('matera-policoro-r-1',5,60,45,45),
  ('matera-policoro-r-1',6,59,50,50),
  ('matera-policoro-r-1',7,58,65,65),
  ('matera-policoro-r-1',8,57,75,75),
  ('matera-policoro-r-1',9,56,90,90),
  ('matera-policoro-r-2',1,13,0,0),
  ('matera-policoro-r-2',2,63,5,5),
  ('matera-policoro-r-2',3,12,10,10),
  ('matera-policoro-r-2',4,62,30,30),
  ('matera-policoro-r-2',5,61,40,40),
  ('matera-policoro-r-2',6,60,45,45),
  ('matera-policoro-r-2',7,59,50,50),
  ('matera-policoro-r-2',8,58,65,65),
  ('matera-policoro-r-2',9,57,75,75),
  ('matera-policoro-r-2',10,56,90,90),
  ('navetta-bari-a-1',1,64,0,0),
  ('navetta-bari-a-1',2,65,25,25),
  ('navetta-bari-a-1',3,66,75,75),
  ('navetta-bari-r-1',1,66,0,0),
  ('navetta-bari-r-1',2,65,50,50),
  ('navetta-bari-r-1',3,64,75,75);

insert into orari_corse (codice,linea_id,percorso_id,denominazione,direzione,partenza,frequenza,giorni,solo_giorni_scolastici,solo_giorni_non_scolastici,attiva,note) values
  ('GRS-1','grottole-sociale','grottole-sociale-a-1','1ª corsa ore 8.35','A','08:35',NULL,'{1,2,3,4,5,7}',false,false,true,NULL),
  ('GRS-1B','grottole-sociale','grottole-sociale-a-2','1ª corsa – ripasso ore 8.55','A','08:55',NULL,'{1,2,3,4,5,7}',false,false,true,NULL),
  ('GRS-2','grottole-sociale','grottole-sociale-a-1','2ª corsa ore 10.00','A','10:00',NULL,'{1,2,3,4,5,7}',false,false,true,NULL),
  ('GRS-2B','grottole-sociale','grottole-sociale-a-2','2ª corsa – ripasso ore 10.20','A','10:20',NULL,'{1,2,3,4,5,7}',false,false,true,NULL),
  ('GRS-3','grottole-sociale','grottole-sociale-a-1','3ª corsa ore 11.30','A','11:30',NULL,'{1,2,3,4,5,7}',false,false,true,NULL),
  ('GRS-3B','grottole-sociale','grottole-sociale-a-2','3ª corsa – ripasso ore 11.50','A','11:50',NULL,'{1,2,3,4,5,7}',false,false,true,NULL),
  ('MIG-SEC-U','miglionico-scuolabus','miglionico-scuolabus-a-1','Secondaria – urbano','A','07:45',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('MIG-SEC-E','miglionico-scuolabus','miglionico-scuolabus-a-2','Secondaria – extraurbano','A','07:40',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('MIG-PRI-U','miglionico-scuolabus','miglionico-scuolabus-a-3','Primaria – urbano','A','08:07',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('MIG-PRI-E','miglionico-scuolabus','miglionico-scuolabus-a-4','Primaria – extraurbano','A','08:12',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('MIG-INF','miglionico-scuolabus','miglionico-scuolabus-a-5','Infanzia','A','08:30',NULL,'{1,2,3,4,5,6}',true,false,true,NULL),
  ('A2479','matera-policoro','matera-policoro-a-1','Matera → Policoro ore 6.20','A','06:20',NULL,'{1,2,3,4,5,6}',false,false,true,'Coincidenza SS175/SS380 con bus provinciale da Montescaglioso per Bernalda'),
  ('A2480','matera-policoro','matera-policoro-a-2','Matera → Policoro ore 12.30','A','12:30',NULL,'{1,2,3,4,5,6}',false,false,true,NULL),
  ('A3111','matera-policoro','matera-policoro-a-3','Matera → Policoro ore 14.10','A','14:10',NULL,'{1,2,3,4,5,6}',false,true,true,'Solo nei giorni non scolastici'),
  ('A2481','matera-policoro','matera-policoro-a-2','Matera → Policoro ore 18.10','A','18:10',NULL,'{1,2,3,4,5,6}',false,false,true,NULL),
  ('R2374','matera-policoro','matera-policoro-r-1','Policoro → Matera ore 6.25','R','06:25',NULL,'{1,2,3,4,5,6}',false,false,true,NULL),
  ('R2482','matera-policoro','matera-policoro-r-1','Policoro → Matera ore 8.20','R','08:20',NULL,'{1,2,3,4,5,6}',false,false,true,NULL),
  ('R2483','matera-policoro','matera-policoro-r-2','Policoro → Matera ore 14.10','R','14:10',NULL,'{1,2,3,4,5,6}',false,false,true,'Coincidenza SS175/SS380 con bus provinciale da Bernalda per Montescaglioso'),
  ('R2484','matera-policoro','matera-policoro-r-1','Policoro → Matera ore 16.30','R','16:30',NULL,'{1,2,3,4,5,6}',false,false,true,NULL),
  ('BARI-3A','navetta-bari','navetta-bari-a-1','Matera → Aeroporto ore 8.30','A','08:30',NULL,'{1,2,3,4,5,6,7}',false,false,false,NULL),
  ('BARI-5A','navetta-bari','navetta-bari-a-1','Matera → Aeroporto ore 14.00','A','14:00',NULL,'{1,2,3,4,5,6,7}',false,false,false,NULL),
  ('BARI-3R','navetta-bari','navetta-bari-r-1','Aeroporto → Matera ore 11.30','R','11:30',NULL,'{1,2,3,4,5,6,7}',false,false,false,NULL),
  ('BARI-5R','navetta-bari','navetta-bari-r-1','Aeroporto → Matera ore 18.30','R','18:30',NULL,'{1,2,3,4,5,6,7}',false,false,false,NULL);

-- tariffa unica urbano Grottole ('*' = qualsiasi fermata)
insert into orari_tariffe (linea_id,tipo_codice,tipo_nome,da_zona,a_zona,km,prezzo,prezzo_scontato) values
  ('grottole-sociale',1,'Corsa Semplice','*','*',NULL,0.40,0.40),
  ('grottole-sociale',3,'Abb. Mensile','*','*',NULL,12.00,12.00)
on conflict (linea_id,tipo_codice,da_zona,a_zona) do update set prezzo=excluded.prezzo, prezzo_scontato=excluded.prezzo_scontato;

-- NAVETTA BARI: corse inserite come NON attive finche' non si inseriscono
-- i mesi di competenza De Angelis, ad esempio:
-- insert into orari_periodi (linea_id,dal,al,note) values ('navetta-bari','2026-10-01','2026-10-31','mese De Angelis');
-- update orari_corse set attiva = true where linea_id = 'navetta-bari';

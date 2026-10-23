-- =====================================================
-- ORARI DE ANGELIS BUS – v56: Audioguida GPS
-- Le tappe dell'audioguida (bus panoramico dei Sassi, in seguito anche la linea Grottole–Miglionico–Pisticci).
-- Ogni tappa ha il testo in 5 lingue. Il racconto parte da solo quando il telefono del passeggero
-- arriva entro "raggio_m" metri dal punto (lat, lon).
-- Le tappe SENZA coordinate sono "racconti di collegamento": partono subito dopo la tappa precedente (per ordine).
-- audio_xx: facoltativo, percorso di un file mp3 nel bucket "audioguida" (es. 'panoramico-matera/1-it.mp3').
--           Se manca, l'app legge il testo con la voce del telefono.
-- Rieseguibile: le tappe vengono inserite solo se la tabella e' vuota.
-- =====================================================
create table if not exists audioguida_tappe (
  id bigint generated always as identity primary key,
  percorso text not null check (percorso in ('panoramico-matera','grottole-pisticci')),
  ordine int not null default 0,
  nome text not null check (char_length(nome) between 2 and 120),
  lat double precision,                       -- vuoto = racconto di collegamento
  lon double precision,
  raggio_m int not null default 150 check (raggio_m between 30 and 2000),
  testo_it text, testo_en text, testo_de text, testo_fr text, testo_es text,
  audio_it text, audio_en text, audio_de text, audio_fr text, audio_es text,
  visibile boolean not null default true,
  creato_il timestamptz not null default now(),
  check ((lat is null) = (lon is null))
);

alter table audioguida_tappe enable row level security;
drop policy if exists "lettura pubblica" on audioguida_tappe;
create policy "lettura pubblica" on audioguida_tappe for select to anon, authenticated using (visibile);
drop policy if exists "admin gestiscono" on audioguida_tappe;
create policy "admin gestiscono" on audioguida_tappe for all to authenticated
  using (public.is_admin_gestionale()) with check (public.is_admin_gestionale());
grant select on audioguida_tappe to anon, authenticated;
grant insert, update, delete on audioguida_tappe to authenticated;

-- Spazio per i file audio (mp3), leggibili da tutti, caricabili solo dagli amministratori
insert into storage.buckets (id, name, public) values ('audioguida', 'audioguida', true)
on conflict (id) do nothing;
drop policy if exists "audioguida lettura" on storage.objects;
create policy "audioguida lettura" on storage.objects for select to anon, authenticated using (bucket_id = 'audioguida');
drop policy if exists "audioguida admin" on storage.objects;
create policy "audioguida admin" on storage.objects for all to authenticated
  using (bucket_id = 'audioguida' and public.is_admin_gestionale())
  with check (bucket_id = 'audioguida' and public.is_admin_gestionale());

-- Tappe del bus panoramico dei Sassi.
-- ATTENZIONE: le coordinate sono APPROSSIMATIVE. Verificale (Google Maps: tasto destro sul punto > copia le coordinate)
-- e correggile da Supabase > Table Editor > audioguida_tappe.
insert into audioguida_tappe (percorso, ordine, nome, lat, lon, raggio_m, testo_it, testo_en, testo_de, testo_fr, testo_es)
select * from (values
('panoramico-matera', 0, 'Partenza da via Ridola', 40.6638, 16.6094, 150,
 $t$Benvenuti a bordo del bus panoramico Deangelisbus. Siamo in via Ridola, nel cuore della Matera "di sopra". Qui accanto ci sono il Museo archeologico nazionale Domenico Ridola e Palazzo Lanfranchi, dove è esposto il grande dipinto "Lucania '61" di Carlo Levi. Da Piazza Pascoli, a pochi passi, si affaccia il belvedere sul Sasso Caveoso. Mettete le cuffie: il viaggio nei Sassi comincia.$t$,
 $t$Welcome aboard the Deangelisbus panoramic bus. We are in Via Ridola, in the heart of upper Matera. Nearby are the Domenico Ridola National Archaeological Museum and Palazzo Lanfranchi, home to Carlo Levi's great painting "Lucania '61". A few steps away, Piazza Pascoli looks out over the Sasso Caveoso. Put on your headphones: our journey through the Sassi begins.$t$,
 $t$Willkommen an Bord des Panoramabusses von Deangelisbus. Wir sind in der Via Ridola, im Herzen der Oberstadt von Matera. Ganz in der Nähe liegen das Nationale Archäologische Museum Domenico Ridola und der Palazzo Lanfranchi mit Carlo Levis großem Gemälde „Lucania '61“. Nur wenige Schritte entfernt blickt man von der Piazza Pascoli auf den Sasso Caveoso. Setzen Sie Ihre Kopfhörer auf: Die Reise durch die Sassi beginnt.$t$,
 $t$Bienvenue à bord du bus panoramique Deangelisbus. Nous sommes via Ridola, au cœur de la ville haute de Matera. Tout près se trouvent le Musée archéologique national Domenico Ridola et le Palazzo Lanfranchi, qui abrite la grande toile de Carlo Levi « Lucania '61 ». À quelques pas, la Piazza Pascoli offre une vue sur le Sasso Caveoso. Mettez vos écouteurs : le voyage dans les Sassi commence.$t$,
 $t$Bienvenidos a bordo del autobús panorámico de Deangelisbus. Estamos en la Via Ridola, en el corazón de la parte alta de Matera. Muy cerca se encuentran el Museo Arqueológico Nacional Domenico Ridola y el Palazzo Lanfranchi, donde se expone el gran cuadro de Carlo Levi «Lucania '61». A pocos pasos, la Piazza Pascoli se asoma al Sasso Caveoso. Pónganse los auriculares: comienza el viaje por los Sassi.$t$),

('panoramico-matera', 1, 'Via Madonna delle Virtù', 40.6650, 16.6135, 150,
 $t$Stiamo percorrendo via Madonna delle Virtù, la strada panoramica che corre lungo il bordo della gravina. Da una parte i Sassi, dall'altra il canyon e la Murgia: è uno dei panorami più fotografati d'Italia.$t$,
 $t$We are driving along Via Madonna delle Virtù, the panoramic road that runs along the edge of the ravine. On one side the Sassi, on the other the canyon and the Murgia plateau: one of the most photographed views in Italy.$t$,
 $t$Wir fahren auf der Via Madonna delle Virtù, der Panoramastraße am Rand der Schlucht. Auf der einen Seite die Sassi, auf der anderen der Canyon und die Murgia: einer der meistfotografierten Ausblicke Italiens.$t$,
 $t$Nous longeons la via Madonna delle Virtù, la route panoramique qui suit le bord du ravin. D'un côté les Sassi, de l'autre le canyon et la Murgia : l'un des panoramas les plus photographiés d'Italie.$t$,
 $t$Recorremos la Via Madonna delle Virtù, la carretera panorámica que bordea el barranco. A un lado los Sassi, al otro el cañón y la Murgia: una de las vistas más fotografiadas de Italia.$t$),

('panoramico-matera', 2, 'Da vergogna nazionale a patrimonio UNESCO', null, null, 150,
 $t$Negli anni Cinquanta i Sassi furono definiti "vergogna nazionale", e una legge del 1952 trasferì gli abitanti nei nuovi quartieri. Abbandonati per decenni, sono rinati: patrimonio UNESCO dal 1993 e Capitale europea della cultura nel 2019.$t$,
 $t$In the 1950s the Sassi were called a "national disgrace", and a 1952 law moved their inhabitants to new districts. Abandoned for decades, they came back to life: a UNESCO World Heritage Site since 1993 and European Capital of Culture in 2019.$t$,
 $t$In den 1950er-Jahren wurden die Sassi als „nationale Schande“ bezeichnet, und ein Gesetz von 1952 siedelte die Bewohner in neue Stadtviertel um. Jahrzehntelang verlassen, sind sie wieder aufgeblüht: seit 1993 UNESCO-Welterbe und 2019 Kulturhauptstadt Europas.$t$,
 $t$Dans les années 1950, les Sassi furent qualifiés de « honte nationale », et une loi de 1952 transféra leurs habitants dans de nouveaux quartiers. Abandonnés pendant des décennies, ils ont repris vie : patrimoine mondial de l'UNESCO depuis 1993 et Capitale européenne de la culture en 2019.$t$,
 $t$En los años cincuenta, los Sassi fueron llamados «vergüenza nacional», y una ley de 1952 trasladó a sus habitantes a los nuevos barrios. Abandonados durante décadas, renacieron: Patrimonio de la Humanidad de la UNESCO desde 1993 y Capital Europea de la Cultura en 2019.$t$),

('panoramico-matera', 3, 'Il Sasso Barisano', 40.6698, 16.6114, 150,
 $t$Questo è il Sasso Barisano, il rione rivolto verso Bari. Le facciate che vedete nascondono case scavate nella roccia, dove si è vissuto per secoli, spesso con gli animali nella stessa stanza.$t$,
 $t$This is the Sasso Barisano, the district facing towards Bari. Behind these façades lie homes carved into the rock, where people lived for centuries, often sharing a single room with their animals.$t$,
 $t$Dies ist der Sasso Barisano, das Viertel in Richtung Bari. Hinter diesen Fassaden verbergen sich in den Fels gehauene Häuser, in denen Menschen jahrhundertelang lebten, oft mit ihren Tieren im selben Raum.$t$,
 $t$Voici le Sasso Barisano, le quartier tourné vers Bari. Derrière ces façades se cachent des maisons creusées dans la roche, où l'on a vécu pendant des siècles, souvent avec les animaux dans la même pièce.$t$,
 $t$Este es el Sasso Barisano, el barrio orientado hacia Bari. Tras estas fachadas se esconden casas excavadas en la roca, donde se vivió durante siglos, a menudo con los animales en la misma habitación.$t$),

('panoramico-matera', 4, 'La Civita e la Cattedrale', 40.6672, 16.6132, 150,
 $t$Sullo sperone roccioso che divide i due Sassi c'è la Civita, il nucleo più antico della città. In cima, la Cattedrale romanica del Duecento, con il campanile alto oltre cinquanta metri.$t$,
 $t$On the rocky spur that separates the two Sassi stands the Civita, the oldest part of the city. At the top is the thirteenth-century Romanesque Cathedral, with its bell tower more than fifty metres high.$t$,
 $t$Auf dem Felssporn zwischen den beiden Sassi liegt die Civita, der älteste Teil der Stadt. Ganz oben thront die romanische Kathedrale aus dem dreizehnten Jahrhundert mit ihrem über fünfzig Meter hohen Glockenturm.$t$,
 $t$Sur l'éperon rocheux qui sépare les deux Sassi se trouve la Civita, le cœur le plus ancien de la ville. Au sommet, la cathédrale romane du treizième siècle et son clocher de plus de cinquante mètres.$t$,
 $t$En el espolón rocoso que separa los dos Sassi está la Civita, el núcleo más antiguo de la ciudad. En lo alto, la catedral románica del siglo trece, con su campanario de más de cincuenta metros.$t$),

('panoramico-matera', 5, 'Sasso Caveoso e San Pietro Caveoso', 40.6627, 16.6125, 150,
 $t$Siamo nel Sasso Caveoso, il più scavato nella roccia. Davanti a noi la chiesa di San Pietro Caveoso; sopra, sulla rupe, Santa Maria de Idris, una chiesa in parte ricavata nella pietra.$t$,
 $t$We are in the Sasso Caveoso, the district most deeply carved into the rock. In front of us is the church of San Pietro Caveoso; above it, on the cliff, Santa Maria de Idris, a church partly hewn out of the stone.$t$,
 $t$Wir sind im Sasso Caveoso, dem am tiefsten in den Fels gegrabenen Viertel. Vor uns die Kirche San Pietro Caveoso; darüber, auf dem Felsen, Santa Maria de Idris, eine teilweise aus dem Stein gehauene Kirche.$t$,
 $t$Nous sommes dans le Sasso Caveoso, le quartier le plus creusé dans la roche. Devant nous, l'église San Pietro Caveoso ; au-dessus, sur le rocher, Santa Maria de Idris, une église en partie taillée dans la pierre.$t$,
 $t$Estamos en el Sasso Caveoso, el barrio más excavado en la roca. Delante tenemos la iglesia de San Pietro Caveoso; arriba, sobre la roca, Santa Maria de Idris, una iglesia en parte tallada en la piedra.$t$),

('panoramico-matera', 6, 'Matera e il cinema', null, null, 150,
 $t$Matera è un set naturale. Qui Pasolini girò "Il Vangelo secondo Matteo", Mel Gibson "La Passione di Cristo", e più di recente James Bond ha sfrecciato tra queste strade in "No Time to Die".$t$,
 $t$Matera is a natural film set. Here Pasolini shot "The Gospel According to St. Matthew", Mel Gibson "The Passion of the Christ", and more recently James Bond raced through these streets in "No Time to Die".$t$,
 $t$Matera ist eine natürliche Filmkulisse. Hier drehte Pasolini „Das erste Evangelium – Matthäus“, Mel Gibson „Die Passion Christi“, und zuletzt raste James Bond in „Keine Zeit zu sterben“ durch diese Straßen.$t$,
 $t$Matera est un décor de cinéma naturel. Pasolini y a tourné « L'Évangile selon saint Matthieu », Mel Gibson « La Passion du Christ », et plus récemment James Bond a filé dans ces rues dans « Mourir peut attendre ».$t$,
 $t$Matera es un plató natural. Aquí Pasolini rodó «El Evangelio según San Mateo», Mel Gibson «La Pasión de Cristo» y, más recientemente, James Bond recorrió a toda velocidad estas calles en «Sin tiempo para morir».$t$)
) as v(percorso, ordine, nome, lat, lon, raggio_m, testo_it, testo_en, testo_de, testo_fr, testo_es)
where not exists (select 1 from audioguida_tappe);

select ordine, nome, lat, lon, raggio_m from audioguida_tappe order by percorso, ordine;

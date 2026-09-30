/** Contenuti turistici dei paesi serviti (testi brevi, verificati su fonti pubbliche: italia.it e siti turistici). */
export interface Luogo { nome: string; testo: string }
export interface Paese {
  id: string; nome: string; motto: string; colore: string;
  luoghi: Luogo[];
  evento?: string;
  servizi: { etichetta: string; apri: { tipo: 'linea'; id: string } | { tipo: 'servizio'; id: string } | { tipo: 'categoria'; categoria: 'extraurbano' } }[];
}

export const PAESI: Paese[] = [
  {
    id: 'matera', nome: 'Matera', motto: 'La Città dei Sassi, Patrimonio UNESCO', colore: '#9A6B3F',
    luoghi: [
      { nome: 'I Sassi', testo: 'Il Sasso Caveoso e il Sasso Barisano: case e chiese scavate nella roccia, Patrimonio dell\u2019Umanità dal 1993.' },
      { nome: 'Parco della Murgia Materana', testo: 'Le chiese rupestri e il belvedere di fronte ai Sassi, tra sentieri e gravine.' },
      { nome: 'Cattedrale e Civita', testo: 'La Cattedrale romanica domina i Sassi dal punto più alto della città antica.' },
    ],
    evento: 'Il 2 luglio la Festa della Madonna della Bruna, con il Carro trionfale.',
    servizi: [
      { etichetta: 'Navetta Matera – Aeroporto di Bari', apri: { tipo: 'linea', id: 'navetta-bari' } },
      { etichetta: 'Linea Matera – Policoro', apri: { tipo: 'linea', id: 'matera-policoro' } },
    ],
  },
  {
    id: 'grottole', nome: 'Grottole', motto: 'Il borgo tra Basento e Bradano', colore: '#1E5BB8',
    luoghi: [
      { nome: 'Chiesa Diruta', testo: 'I resti imponenti della chiesa dei Santi Luca e Giuliano, simbolo del paese: si visita dall\u2019esterno.' },
      { nome: 'Castello Sichinulfo', testo: 'La torre sulla collina della Motta, con vista sulle valli del Basento e del Bradano.' },
      { nome: 'Oasi di San Giuliano e Bosco Coste', testo: 'Natura e birdwatching sul lago, con un sentiero ad anello di circa 5 km nel bosco.' },
    ],
    evento: 'Krùptai, la manifestazione dedicata a cultura, artigianato e tradizioni.',
    servizi: [
      { etichetta: 'Linee extraurbane da Grottole', apri: { tipo: 'categoria', categoria: 'extraurbano' } },
      { etichetta: 'Servizio urbano Grottole', apri: { tipo: 'linea', id: 'grottole-sociale' } },
    ],
  },
  {
    id: 'miglionico', nome: 'Miglionico', motto: 'Il borgo della Congiura dei Baroni', colore: '#7B3F8C',
    luoghi: [
      { nome: 'Castello del Malconsiglio', testo: 'Qui nel 1485 i baroni congiurarono contro re Ferdinando I d\u2019Aragona: percorso multimediale nella Sala Stella.' },
      { nome: 'Polittico di Cima da Conegliano', testo: 'Nella Chiesa Madre di Santa Maria Maggiore, il grande polittico di 18 tavole del 1499.' },
    ],
    evento: 'In agosto la rievocazione della Congiura dei Baroni con il Palio dei Rioni.',
    servizi: [
      { etichetta: 'Linee Grottole – Miglionico', apri: { tipo: 'categoria', categoria: 'extraurbano' } },
    ],
  },
  {
    id: 'montescaglioso', nome: 'Montescaglioso', motto: 'La città dei Monasteri', colore: '#2E7D5B',
    luoghi: [
      { nome: 'Abbazia di San Michele Arcangelo', testo: 'Grande abbazia benedettina nel centro storico, con chiostri e cicli di affreschi.' },
      { nome: 'I monasteri e Piazza Roma', testo: 'Il monastero di Sant\u2019Agostino, i Cappuccini e la Chiesa di San Rocco, a pochi passi.' },
    ],
    evento: 'Il Carnevale, una tradizione che risale al 1638.',
    servizi: [
      { etichetta: 'Servizio urbano Montescaglioso', apri: { tipo: 'servizio', id: 'urb-montescaglioso' } },
    ],
  },
];

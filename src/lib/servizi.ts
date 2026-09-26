/** Menu dei servizi mostrato nella home. Se una linea con quell'id esiste nei dati, si apre la linea;
 *  altrimenti si apre una pagina informativa (orari in arrivo, servizio su prenotazione, ecc.). */
export type VoceServizio =
  | { id: string; titolo: string; sotto?: string; colore: string; tipo: 'categoria' }
  | { id: string; titolo: string; sotto?: string; colore: string; tipo: 'linea'; linea: string; testo?: string };

export const BLU = '#1E5BB8', BIANCO = '#FFFFFF', GIALLO = '#FFC628', NAVY = '#020a5d', VERDE = '#2E9E5B';

export const SERVIZI: VoceServizio[] = [
  { id: 'extraurbano', titolo: 'Trasporto pubblico extraurbano', sotto: 'Linee Cotrab da Grottole', colore: BLU, tipo: 'categoria' },
  { id: 'scol-grottole', titolo: 'Trasporto scolastico Grottole', colore: GIALLO, tipo: 'linea', linea: 'grottole-scuolabus',
    testo: 'Gli orari del trasporto scolastico di Grottole per l\u2019anno 2026/2027 saranno pubblicati a breve.' },
  { id: 'scol-miglionico', titolo: 'Trasporto scolastico Miglionico', colore: GIALLO, tipo: 'linea', linea: 'miglionico-scuolabus' },
  { id: 'scol-montescaglioso', titolo: 'Trasporto scolastico Montescaglioso', colore: GIALLO, tipo: 'linea', linea: 'montescaglioso-scuolabus',
    testo: 'Gli orari del trasporto scolastico di Montescaglioso per l\u2019anno 2026/2027 saranno pubblicati a breve.' },
  { id: 'urb-grottole', titolo: 'Servizio urbano Grottole', colore: BIANCO, tipo: 'linea', linea: 'grottole-sociale' },
  { id: 'urb-montescaglioso', titolo: 'Servizio urbano Montescaglioso', colore: BIANCO, tipo: 'linea', linea: 'montescaglioso-urbano',
    testo: 'Gli orari del servizio urbano di Montescaglioso saranno pubblicati a breve.' },
  { id: 'disabili-matera', titolo: 'Trasporto disabili Matera', sotto: 'Servizio su prenotazione', colore: VERDE, tipo: 'linea', linea: 'matera-disabili',
    testo: 'Servizio di trasporto per alunni con disabilitÃ  svolto per conto del Comune di Matera. Il servizio Ã¨ organizzato su prenotazione: per informazioni contatta i nostri uffici.' },
  { id: 'navetta-bari', titolo: 'Trasferimenti Matera â€“ Bari Aeroporto', colore: NAVY, tipo: 'linea', linea: 'navetta-bari',
    testo: 'Navetta Cotrab Matera â€“ Aeroporto di Bari Palese. I biglietti si acquistano solo online su marozzivt.it.' },
  { id: 'matera-policoro', titolo: 'Linea Matera â€“ Policoro', sotto: 'Linea 354 via Metaponto', colore: BLU, tipo: 'linea', linea: 'matera-policoro' },
];

/** Pagina del parco macchine sul sito aziendale. */
export const URL_FLOTTA = 'https://www.deangelisbus.it/parco-macchine/';

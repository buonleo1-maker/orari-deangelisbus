export type Categoria = 'extraurbano' | 'urbano' | 'scolastico' | 'navetta';

export interface Linea {
  id: string; nome: string; colore: string | null; ordine: number; attiva: boolean;
  categoria: Categoria; comune: string | null; esercente: string | null;
  committente: string | null; subappalto: boolean; info_pubblico: string | null;
  alternanza_con?: string | null;
}
export interface Fermata {
  id: number; nome: string; comune: string; zona_tariffaria: string | null;
  lat: number | null; lon: number | null;
}
export interface Percorso { id: string; linea_id: string; direzione: 'A' | 'R'; nome: string }
export interface PercorsoFermata {
  percorso_id: string; ordine: number; fermata_id: number;
  minuti: number | null; minuti_stimati: number | null;
}
export interface Corsa {
  codice: string; linea_id: string; percorso_id: string; denominazione: string | null;
  direzione: 'A' | 'R'; partenza: string; giorni: number[]; stagionale: string | null;
  attiva: boolean; valido_dal: string | null; valido_al: string | null;
  solo_giorni_scolastici: boolean; solo_giorni_non_scolastici: boolean; note: string | null;
}
export interface Tariffa {
  linea_id: string; tipo_codice: number; tipo_nome: string; da_zona: string; a_zona: string;
  km: number | null; prezzo: number; prezzo_scontato: number | null;
}
export interface Avviso { id: number; titolo: string; testo: string | null; linea_id: string | null; dal: string | null; al: string | null }
export interface Novita {
  id: number; tipo: 'novita' | 'evento' | 'variazione' | 'viaggio'; titolo: string; testo: string | null;
  data_evento: string | null; data_fine?: string | null; link: string | null; in_evidenza: boolean;
  visibile_dal: string; visibile_al: string | null; creato_il: string;
}
export interface Gusto {
  id: number; paese: string; tipo: 'piatto' | 'ristorante'; nome: string; descrizione: string | null;
  indirizzo: string | null; telefono: string | null; link: string | null; ordine: number; visibile: boolean;
}
export interface Foto {
  id: number; paese: string; percorso: string; didascalia: string | null; crediti: string | null; ordine: number; visibile: boolean;
}
export interface Periodo { id: number; linea_id: string; dal: string; al: string; note: string | null; solo_informativo?: boolean }
export interface Sospensione { id: number; dal: string; al: string; ambito: 'tutti' | 'scolastico'; linea_id: string | null; descrizione: string | null }

export interface Dati {
  generato: string;
  linee: Linea[]; fermate: Fermata[]; percorsi: Percorso[]; percorsi_fermate: PercorsoFermata[];
  corse: Corsa[]; tariffe: Tariffa[]; avvisi: Avviso[]; novita?: Novita[]; gusto?: Gusto[]; foto?: Foto[]; periodi: Periodo[]; sospensioni: Sospensione[];
}

/** Un passaggio di una corsa a una fermata, già calcolato. */
export interface Passaggio {
  fermata: Fermata; ordine: number; minuto: number; confermato: boolean;
}

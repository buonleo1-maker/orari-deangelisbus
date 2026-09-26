import { createClient } from '@supabase/supabase-js';
import snapshot from '../data/snapshot.json';
import type { Dati } from './types';

const CACHE_KEY = 'orari_dati_v1';
const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
const supabase = url && key ? createClient(url, key, { auth: { persistSession: false } }) : null;

const TABELLE = {
  linee: 'orari_linee', fermate: 'orari_fermate', percorsi: 'orari_percorsi',
  percorsi_fermate: 'orari_percorsi_fermate', corse: 'orari_corse', tariffe: 'orari_tariffe',
  avvisi: 'orari_avvisi', periodi: 'orari_periodi', sospensioni: 'orari_sospensioni',
} as const;

/** Dati disponibili subito: copia salvata sul telefono, altrimenti quelli inclusi nell'app. */
export function datiIniziali(): Dati {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (raw) return JSON.parse(raw) as Dati;
  } catch { /* copia locale non leggibile: si usano i dati inclusi */ }
  return snapshot as unknown as Dati;
}

async function leggiTutto(tabella: string): Promise<unknown[]> {
  const out: unknown[] = [];
  for (let da = 0; ; da += 1000) {
    const { data, error } = await supabase!.from(tabella).select('*').range(da, da + 999);
    if (error) throw error;
    out.push(...(data ?? []));
    if (!data || data.length < 1000) return out;
  }
}

/** Scarica gli orari aggiornati. Restituisce null se offline o non configurato. */
export async function aggiornaDati(): Promise<Dati | null> {
  if (!supabase) return null;
  try {
    const voci = await Promise.all(
      Object.entries(TABELLE).map(async ([k, t]) => [k, await leggiTutto(t)] as const),
    );
    const dati = { generato: new Date().toISOString(), ...Object.fromEntries(voci) } as Dati;
    dati.corse.forEach((c) => { c.partenza = c.partenza.slice(0, 5); });
    try { localStorage.setItem(CACHE_KEY, JSON.stringify(dati)); } catch { /* spazio esaurito */ }
    return dati;
  } catch {
    return null;
  }
}

export const onlineConfigurato = Boolean(supabase);

export interface Richiesta {
  tipo: 'trasferimento' | 'noleggio' | 'gita' | 'altro';
  data_andata: string | null; ora_andata: string | null;
  partenza: string; destinazione: string;
  ritorno: boolean; data_ritorno: string | null; ora_ritorno: string | null;
  passeggeri: number | null; nome: string; telefono: string; email: string | null;
  note: string | null; consenso_privacy: boolean;
}

/** Invia la richiesta di preventivo. Restituisce true se salvata. */
export async function inviaRichiesta(r: Richiesta): Promise<boolean> {
  if (!supabase) return false;
  try {
    const { error } = await supabase.from('richieste_preventivo').insert(r);
    return !error;
  } catch {
    return false;
  }
}

import type { Novita } from './types';

/** Novità già viste dall'utente, conservate sul telefono. */
const CHIAVE = 'novita_lette';

function leggi(): Set<number> | null {
  try { const v = localStorage.getItem(CHIAVE); return v ? new Set<number>(JSON.parse(v)) : null; } catch { return new Set(); }
}
function scrivi(s: Set<number>) {
  try { localStorage.setItem(CHIAVE, JSON.stringify([...s].slice(-300))); } catch { /* ignora */ }
}

/**
 * Novità non ancora lette. Al primo avvio dell'app le novità ed eventi già pubblicati
 * si considerano letti (per non sommergere chi installa ora); restano da leggere solo
 * le variazioni del servizio, che sono importanti.
 */
export function nonLette(lista: Novita[]): Novita[] {
  let s = leggi();
  if (!s) {
    s = new Set(lista.filter((n) => n.tipo !== 'variazione').map((n) => n.id));
    scrivi(s);
  }
  return lista.filter((n) => n.tipo !== 'viaggio' && !s!.has(n.id));
}

export function segnaLette(ids: number[]) {
  const s = leggi() ?? new Set<number>();
  ids.forEach((id) => s.add(id));
  scrivi(s);
}

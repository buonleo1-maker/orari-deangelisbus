/** Fermate salvate dall'utente (oltre alla fermata "di casa"), conservate sul telefono. */
const CHIAVE = 'fermate_salvate';
const MAX = 4;

export function leggiSalvate(): number[] {
  try {
    const v = JSON.parse(localStorage.getItem(CHIAVE) ?? '[]');
    return Array.isArray(v) ? v.filter((x) => Number.isFinite(x)).slice(0, MAX) : [];
  } catch { return []; }
}

export function scriviSalvate(ids: number[]) {
  try { localStorage.setItem(CHIAVE, JSON.stringify([...new Set(ids)].slice(0, MAX))); } catch { /* ignora */ }
}

export function alternaSalvata(id: number): number[] {
  const attuali = leggiSalvate();
  const nuove = attuali.includes(id) ? attuali.filter((x) => x !== id) : [id, ...attuali].slice(0, MAX);
  scriviSalvate(nuove);
  return nuove;
}

/** Distanza in metri tra due punti (formula dell'emisenoverso). */
export function distanzaMetri(lat1: number, lon1: number, lat2: number, lon2: number) {
  const r = 6371000, rad = Math.PI / 180;
  const dLat = (lat2 - lat1) * rad, dLon = (lon2 - lon1) * rad;
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLon / 2) ** 2;
  return 2 * r * Math.asin(Math.sqrt(a));
}

/** Condivide un testo con il menu del telefono, oppure con WhatsApp se il menu non c'è. */
export async function condividi(testo: string) {
  if (navigator.share) {
    try { await navigator.share({ text: testo }); return; } catch { /* annullato: niente */ return; }
  }
  window.open(`https://wa.me/?text=${encodeURIComponent(testo)}`, '_blank');
}

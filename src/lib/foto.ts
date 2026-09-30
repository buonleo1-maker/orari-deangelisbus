import type { Foto } from './types';

const BASE = (import.meta.env.VITE_SUPABASE_URL as string | undefined)?.replace(/\/$/, '') ?? '';
const PUBBLICO = `${BASE}/storage/v1/object/public/territorio`;

/** Indirizzo pubblico di una foto della galleria. */
export const urlFoto = (f: Foto) => `${PUBBLICO}/${f.percorso}`;
/** Musica di sottofondo della presentazione (caricata dal gestionale). */
export const URL_MUSICA = `${PUBBLICO}/musica/sottofondo.mp3`;

export const fotoOrdinate = (foto: Foto[] | undefined) =>
  (foto ?? []).filter((f) => f.visibile).sort((a, b) => a.ordine - b.ordine || b.id - a.id);

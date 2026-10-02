import { useState } from 'react';
import { alternaSalvata, leggiSalvate } from '../lib/preferiti';

/** Pulsante per salvare/togliere una fermata dalle "Mie fermate". */
export default function StellaFermata({ id, casa }: { id: number; casa: boolean }) {
  const [salvata, setSalvata] = useState(() => leggiSalvate().includes(id));
  if (casa) return <p className="stella-info">★ È la tua fermata principale</p>;
  return (
    <button className={salvata ? 'stella attiva' : 'stella'} onClick={() => setSalvata(alternaSalvata(id).includes(id))}>
      {salvata ? '★ Fermata salvata – tocca per togliere' : '☆ Salva tra le mie fermate'}
    </button>
  );
}

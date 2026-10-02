import { useState } from 'react';
import { segnaLette } from '../lib/lette';
import type { Novita } from '../lib/types';

const ETICHETTA: Record<string, string> = { variazione: 'Variazione del servizio', evento: 'Nuovo evento', novita: 'Novità' };

/** Banner in cima alla Home con la novità non letta più importante. */
export default function AvvisoNovita({ lista, onApri }: { lista: Novita[]; onApri: () => void }) {
  const [chiuso, setChiuso] = useState(false);
  if (chiuso || !lista.length) return null;
  const n = [...lista].sort((a, b) => Number(b.tipo === 'variazione') - Number(a.tipo === 'variazione') || b.creato_il.localeCompare(a.creato_il))[0];
  const altre = lista.length - 1;
  return (
    <div className={`avviso-novita ${n.tipo === 'variazione' ? 'importante' : ''}`} role="status">
      <button className="an-corpo" onClick={onApri}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 0 1-3.4 0" /></svg>
        <span>
          <small>{ETICHETTA[n.tipo] ?? 'Novità'}{altre > 0 ? ` · e altre ${altre}` : ''}</small>
          <strong>{n.titolo}</strong>
          <em>Tocca per leggere</em>
        </span>
      </button>
      <button className="an-chiudi" aria-label="Segna come letto" onClick={() => { segnaLette(lista.map((x) => x.id)); setChiuso(true); }}>✕</button>
    </div>
  );
}

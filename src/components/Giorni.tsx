import { addGiorni, isoData, oggi } from '../lib/schedule';

const fmt = new Intl.DateTimeFormat('it-IT', { weekday: 'short', day: 'numeric' });

export default function Giorni({ valore, onCambia }: { valore: string; onCambia: (iso: string) => void }) {
  const base = oggi();
  const giorni = Array.from({ length: 7 }, (_, i) => addGiorni(base, i));
  return (
    <div className="giorni" role="tablist" aria-label="Giorno">
      {giorni.map((g, i) => {
        const iso = isoData(g);
        return (
          <button key={iso} role="tab" aria-selected={iso === valore} className={iso === valore ? 'giorno attivo' : 'giorno'}
            onClick={() => onCambia(iso)}>
            {i === 0 ? 'Oggi' : i === 1 ? 'Domani' : fmt.format(g)}
          </button>
        );
      })}
    </div>
  );
}

export const daIso = (iso: string) => { const [y, m, d] = iso.split('-').map(Number); return new Date(y, m - 1, d); };

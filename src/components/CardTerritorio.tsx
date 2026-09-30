import { PAESI } from '../lib/territorio';

/** Card in Home che invita a scoprire i paesi serviti. */
export default function CardTerritorio({ onApri }: { onApri: () => void }) {
  return (
    <button className="card-territorio" onClick={onApri}>
      <span className="ct-etichetta">Scopri il territorio</span>
      <strong>Sassi, castelli e abbazie a due passi</strong>
      <span className="ct-paesi">{PAESI.map((p) => <i key={p.id} style={{ background: p.colore }}>{p.nome}</i>)}</span>
      <span className="ct-vai">Cosa vedere e come arrivarci →</span>
    </button>
  );
}

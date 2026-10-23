/** Card che apre l'audioguida del bus panoramico. */
export default function CardAudioguida({ onApri }: { onApri: () => void }) {
  return (
    <button className="card-audioguida" onClick={onApri}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M3 18v-6a9 9 0 0 1 18 0v6" /><path d="M21 19a2 2 0 0 1-2 2h-1v-6h3zM3 19a2 2 0 0 0 2 2h1v-6H3z" /></svg>
      <span>
        <i className="ca-nuovo">Novità</i>
        <strong>Audioguida dei Sassi</strong>
        <small>Sul bus panoramico il racconto parte da solo, luogo per luogo. In 5 lingue.</small>
        <em>Italiano · English · Deutsch · Français · Español</em>
      </span>
    </button>
  );
}

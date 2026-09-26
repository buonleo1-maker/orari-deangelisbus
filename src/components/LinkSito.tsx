/** Collegamento al sito aziendale. "grande" = riquadro blu, "compatto" = riga semplice. */
export default function LinkSito({ variante = 'grande' }: { variante?: 'grande' | 'compatto' }) {
  const freccia = (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5" />
    </svg>
  );
  if (variante === 'compatto') {
    return (
      <a className="sito-compatto" href="https://www.deangelisbus.it" target="_blank" rel="noreferrer">
        Visita il nostro sito <b>deangelisbus.it</b>{freccia}
      </a>
    );
  }
  return (
    <a className="sito" href="https://www.deangelisbus.it" target="_blank" rel="noreferrer">
      <span>
        <strong>Visita il nostro sito</strong>
        <small>Noleggio con autista, gite, flotta e servizi su deangelisbus.it</small>
      </span>
      {freccia}
    </a>
  );
}

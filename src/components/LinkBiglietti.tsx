import { URL_BIGLIETTERIA, URL_GUIDA_BIGLIETTI } from '../lib/servizi';

/** Collegamento alla biglietteria online Cotrab (linee extraurbane). */
export default function LinkBiglietti({ compatto }: { compatto?: boolean }) {
  return (
    <div className={compatto ? 'biglietti compatto' : 'biglietti'}>
      <a className="biglietti-link" href={URL_BIGLIETTERIA} target="_blank" rel="noreferrer">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M3 8a2 2 0 0 0 2-2h14a2 2 0 0 0 2 2v2a2 2 0 0 0 0 4v2a2 2 0 0 0-2 2H5a2 2 0 0 0-2-2v-2a2 2 0 0 0 0-4V8zM13 6v2M13 11v2M13 16v2" />
        </svg>
        <span>
          <strong>Acquista biglietti e abbonamenti</strong>
          <small>Biglietteria online Cotrab: paghi con carta e hai il titolo sul telefono</small>
        </span>
      </a>
      {!compatto && (
        <a className="biglietti-guida" href={URL_GUIDA_BIGLIETTI} target="_blank" rel="noreferrer">Come si acquista online (guida Cotrab)</a>
      )}
    </div>
  );
}

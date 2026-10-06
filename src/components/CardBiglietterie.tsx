import { URL_BIGLIETTERIA } from '../lib/servizi';

/** Le nostre biglietterie: online (Cotrab) e a terra (punti vendita sul territorio). */
// "dove" compare sotto il nome; "cerca" e' il testo usato per la mappa
const A_TERRA = [
  { nome: 'Deangelisbus S.r.l.', dove: 'Via Arcioni, 6 – Grottole', cerca: 'Via Arcioni 6, 75010 Grottole MT' },
  { nome: 'Tabaccheria Faniello Antonio', dove: 'Miglionico', cerca: 'Tabaccheria Faniello Antonio Miglionico MT' },
  { nome: 'Bar Tabaccheria Speranza Francesco', dove: 'Grottole', cerca: 'Bar Tabaccheria Speranza Francesco Grottole MT' },
];
const mappa = (cerca: string) => `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(cerca)}`;

export default function CardBiglietterie() {
  return (
    <section className="card-biglietterie" aria-labelledby="tit-biglietterie">
      <h2 id="tit-biglietterie">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M3 8a2 2 0 0 0 2-2h14a2 2 0 0 0 2 2v2a2 2 0 0 0 0 4v2a2 2 0 0 0-2 2H5a2 2 0 0 0-2-2v-2a2 2 0 0 0 0-4V8zM13 6v2M13 11v2M13 16v2" />
        </svg>
        Le nostre biglietterie
      </h2>

      <a className="cb-online" href={URL_BIGLIETTERIA} target="_blank" rel="noreferrer">
        <span>
          <strong>Biglietteria online</strong>
          <small>Sito Cotrab: biglietti e abbonamenti, paghi con carta e hai il titolo sul telefono</small>
        </span>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5" /></svg>
      </a>

      <h3>Biglietterie a terra</h3>
      <ul>
        {A_TERRA.map((b) => (
          <li key={b.nome}>
            <span><strong>{b.nome}</strong><small>{b.dove}</small></span>
            <a href={mappa(b.cerca)} target="_blank" rel="noreferrer" aria-label={`Indicazioni per ${b.nome}, ${b.dove}`}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 22s7-7.5 7-13a7 7 0 0 0-14 0c0 5.5 7 13 7 13zM12 11.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z" /></svg>
              Mappa
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}

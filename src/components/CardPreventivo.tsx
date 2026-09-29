/** Card in evidenza per la richiesta di preventivo (noleggio con conducente, trasferimenti, gite). */
export default function CardPreventivo({ onApri }: { onApri: () => void }) {
  return (
    <section className="card-preventivo">
      <div className="cp-testo">
        <span className="cp-etichetta">Noleggio con conducente</span>
        <strong>Bus, minibus e auto per ogni viaggio</strong>
        <span>Trasferimenti, aeroporti, gite, matrimoni ed eventi aziendali. Preventivo gratuito e senza impegno, risposta entro 48 ore.</span>
      </div>
      <button className="cp-bottone" onClick={onApri}>
        Richiedi un preventivo
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" /></svg>
      </button>
    </section>
  );
}

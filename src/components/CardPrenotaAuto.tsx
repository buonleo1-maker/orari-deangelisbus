/** Card in Home per prenotare auto o minivan con conducente (ultimo miglio e visite mediche). */
export default function CardPrenotaAuto({ onApri }: { onApri: (servizio: 'ultimo_miglio' | 'visita_medica') => void }) {
  return (
    <section className="card-auto">
      <span className="cp-etichetta">Novità · auto e minivan con conducente</span>
      <strong>Ti portiamo dove il bus non arriva</strong>
      <div className="ca-scelte">
        <button onClick={() => onApri('ultimo_miglio')}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M5 17h-2v-5l2-5h10l4 5h2v5h-2" /><circle cx="7.5" cy="17.5" r="2" /><circle cx="16.5" cy="17.5" r="2" /><path d="M9.5 17.5h5" /></svg>
          <span><b>Dal bus a destinazione</b><small>Dalla fermata a casa, masseria o agriturismo</small></span>
        </button>
        <button onClick={() => onApri('visita_medica')}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 21s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 5.6-7 10-7 10z" /><path d="M12 9v5M9.5 11.5h5" /></svg>
          <span><b>Visite mediche</b><small>Andata, attesa e ritorno. Anche per un familiare</small></span>
        </button>
      </div>
    </section>
  );
}

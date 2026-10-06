import { useState } from 'react';
import qr from '../assets/qr-app.png';

const LINK = 'https://orari.deangelisbus.it';

/** "Passa l'app a un amico": QR code a tutto schermo da far inquadrare, oppure invio del link. */
export default function CondividiApp() {
  const [aperto, setAperto] = useState(false);
  const inviaLink = async () => {
    const testo = 'L\u2019app Deangelisbus S.r.l. \u2013 Insieme in viaggio: orari, fermate e servizi sempre a portata di mano. Apri il link e aggiungi l\u2019app alla schermata Home.';
    if (navigator.share) { try { await navigator.share({ title: 'Deangelisbus S.r.l.', text: testo, url: LINK }); } catch { /* annullato */ } return; }
    window.open(`https://wa.me/?text=${encodeURIComponent(`${testo} ${LINK}`)}`, '_blank');
  };
  return (
    <>
      <button className="card-condividi" onClick={() => setAperto(true)}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h3v3h-3zM18 18h3v3h-3zM14 20h2M20 14v2" />
        </svg>
        <span><strong>Passa l'app a un amico</strong><small>Mostra il QR code da inquadrare con la fotocamera</small></span>
      </button>
      {aperto && (
        <div className="qr-schermo" role="dialog" aria-modal="true" aria-label="QR code dell'app">
          <button className="qr-chiudi" onClick={() => setAperto(false)} aria-label="Chiudi">✕</button>
          <p className="qr-titolo">Inquadra con la fotocamera</p>
          <img src={qr} alt="QR code per aprire l'app Deangelisbus" />
          <p className="qr-link">orari.deangelisbus.it</p>
          <p className="qr-aiuto">Apri la fotocamera del telefono, punta il QR code e tocca il link che compare.</p>
          <button className="qr-invia" onClick={inviaLink}>Oppure invia il link (WhatsApp, SMS…)</button>
        </div>
      )}
    </>
  );
}

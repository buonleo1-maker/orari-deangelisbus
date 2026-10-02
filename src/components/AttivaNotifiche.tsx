import { useEffect, useState } from 'react';
import { attivaPush, disattivaPush, statoPush, type StatoPush } from '../lib/push';

const NASCOSTO = 'notifiche_invito_chiuso';

/** Riquadro per attivare le notifiche. "invito": in Home, si mostra solo finche' non si sceglie. */
export default function AttivaNotifiche({ invito = false }: { invito?: boolean }) {
  const [stato, setStato] = useState<StatoPush | null>(null);
  const [lavoro, setLavoro] = useState(false);
  const [errore, setErrore] = useState<string | null>(null);
  const [chiuso, setChiuso] = useState(() => invito && localStorage.getItem(NASCOSTO) === '1');
  useEffect(() => { statoPush().then(setStato).catch(() => setStato('non-supportate')); }, []);

  if (!stato || stato === 'non-supportate') return null;
  if (invito && (chiuso || stato !== 'spente')) return null;

  const attiva = async () => {
    setLavoro(true); setErrore(null);
    try { setStato(await attivaPush()); } catch (e) { setErrore((e as Error).message); }
    setLavoro(false);
  };
  const chiudi = () => { localStorage.setItem(NASCOSTO, '1'); setChiuso(true); };

  return (
    <div className={`notifiche ${invito ? 'invito' : ''}`}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 0 1-3.4 0" /></svg>
      <div>
        <strong>{stato === 'attive' ? 'Notifiche attive' : 'Avvisi sul telefono'}</strong>
        {stato === 'spente' && <p>Ricevi subito una notifica per scioperi, variazioni del servizio e novità, anche ad app chiusa.</p>}
        {stato === 'attive' && <p>Riceverai le notifiche di scioperi, variazioni e novità.</p>}
        {stato === 'bloccate' && <p>Le notifiche sono bloccate: riattivale dalle impostazioni del telefono (Notifiche, poi l'app o Chrome).</p>}
        {stato === 'installa-prima' && <p>Su iPhone le notifiche funzionano con l'app aggiunta alla schermata Home: tocca Condividi, poi "Aggiungi alla schermata Home".</p>}
        {errore && <p className="notifiche-errore">Non riesco ad attivarle: {errore}. Riprova più tardi.</p>}
        <div className="notifiche-azioni">
          {stato === 'spente' && <button className="pieno" onClick={attiva} disabled={lavoro}>{lavoro ? 'Attivo…' : 'Attiva le notifiche'}</button>}
          {stato === 'attive' && !invito && <button onClick={async () => setStato(await disattivaPush())}>Disattiva</button>}
          {invito && stato === 'spente' && <button onClick={chiudi}>No, grazie</button>}
        </div>
      </div>
    </div>
  );
}

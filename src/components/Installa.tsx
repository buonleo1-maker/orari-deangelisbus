import { useEffect, useState } from 'react';
import { Capacitor } from '@capacitor/core';

interface EventoInstallazione extends Event { prompt: () => Promise<void>; userChoice: Promise<{ outcome: string }> }

let eventoSalvato: EventoInstallazione | null = null;
if (typeof window !== 'undefined') {
  window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); eventoSalvato = e as EventoInstallazione; });
}

const giaInstallata = () =>
  window.matchMedia('(display-mode: standalone)').matches || (navigator as unknown as { standalone?: boolean }).standalone === true;
const iPhone = () => /iphone|ipad|ipod/i.test(navigator.userAgent);

/** Box "Installa l'app": solo nella versione web, e solo se non è già installata. */
export default function Installa() {
  const [evento, setEvento] = useState<EventoInstallazione | null>(eventoSalvato);
  const [fatto, setFatto] = useState(false);

  useEffect(() => {
    const h = (e: Event) => { e.preventDefault(); eventoSalvato = e as EventoInstallazione; setEvento(eventoSalvato); };
    window.addEventListener('beforeinstallprompt', h);
    return () => window.removeEventListener('beforeinstallprompt', h);
  }, []);

  if (Capacitor.isNativePlatform() || giaInstallata() || fatto) return null;

  return (
    <section className="installa">
      <strong>Installa l'app sul telefono</strong>
      {evento ? (
        <>
          <span>Avrai l'icona nella schermata Home e gli orari anche senza internet.</span>
          <button className="primario" onClick={async () => { await evento.prompt(); const r = await evento.userChoice; if (r.outcome === 'accepted') setFatto(true); }}>
            Installa
          </button>
        </>
      ) : iPhone() ? (
        <span>Su iPhone: tocca il pulsante Condividi (il quadrato con la freccia in su) e poi <b>Aggiungi alla schermata Home</b>.</span>
      ) : (
        <span>Apri il menu del browser (i tre puntini in alto) e scegli <b>Installa app</b> oppure <b>Aggiungi a schermata Home</b>.</span>
      )}
    </section>
  );
}

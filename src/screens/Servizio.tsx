import type { Nav } from '../App';
import Testata from '../components/Testata';
import { SERVIZI } from '../lib/servizi';

/** Pagina informativa per i servizi senza orari pubblicati. */
export default function Servizio({ id, nav }: { id: string; nav: Nav }) {
  const v = SERVIZI.find((x) => x.id === id);
  if (!v) return <Testata titolo="Servizio non trovato" onIndietro={nav.indietro} />;
  const testo = v.tipo === 'linea' ? v.testo : undefined;
  return (
    <>
      <Testata titolo={v.titolo} sotto={v.sotto} onIndietro={nav.indietro} colore={v.colore === '#FFFFFF' ? '#8FA3B8' : v.colore} />
      <p className="avviso-linea">{testo ?? 'Gli orari di questo servizio saranno pubblicati a breve.'}</p>
      <section className="sezione contatti">
        <h2 className="gruppo">Per informazioni</h2>
        <a className="contatto" href="tel:+390835758126">Chiama 0835 758126<small>dal lunedì al venerdì, 8:30–13:30 e 15:30–19:00</small></a>
        <a className="contatto" href="mailto:info@deangelisbus.it">Scrivi a info@deangelisbus.it</a>
      </section>
    </>
  );
}

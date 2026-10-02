import type { Nav } from '../App';
import { daIso } from '../components/Giorni';
import Testata from '../components/Testata';
import { condividi } from '../lib/preferiti';
import { descriviGiorni, hhmm, type Orario } from '../lib/schedule';

const tratto = (c: string | null) => (!c || c.toUpperCase() === '#FFFFFF' ? '#8FA3B8' : c);
const fmt = new Intl.DateTimeFormat('it-IT', { weekday: 'long', day: 'numeric', month: 'long' });

export default function CorsaView({ orario, codice, giorno, nav }: { orario: Orario; codice: string; giorno: string; nav: Nav }) {
  const corsa = orario.d.corse.find((c) => c.codice === codice);
  if (!corsa) return <Testata titolo="Corsa non trovata" onIndietro={nav.indietro} />;
  const linea = orario.linee.get(corsa.linea_id)!;
  const ps = orario.passaggi(corsa);
  const stime = ps.some((p) => !p.confermato);

  return (
    <>
      <Testata titolo={`${hhmm(ps[0].minuto)} da ${ps[0].fermata.comune}`} sotto={`${linea.nome} – ${fmt.format(daIso(giorno))}`}
        onIndietro={nav.indietro} colore={linea.colore} />
      <ol className="percorso" style={{ ['--linea' as string]: tratto(linea.colore) }}>
        {ps.map((p) => (
          <li key={p.ordine}>
            <span className="ora">{!p.confermato && '~'}{hhmm(p.minuto)}</span>
            <span className="nodo" aria-hidden="true" />
            <button className="fermata" onClick={() => nav.apri({ tipo: 'fermata', id: p.fermata.id })}>
              {p.fermata.nome}<small>{p.fermata.comune}</small>
            </button>
          </li>
        ))}
      </ol>
      <button className="condividi" onClick={() => condividi(
        `🚌 ${linea.nome}\n${fmt.format(daIso(giorno))}\n` +
        `Partenza ${hhmm(ps[0].minuto)} da ${ps[0].fermata.nome} (${ps[0].fermata.comune})\n` +
        `Arrivo ${!ps[ps.length - 1].confermato ? 'circa ' : ''}${hhmm(ps[ps.length - 1].minuto)} a ${ps[ps.length - 1].fermata.nome} (${ps[ps.length - 1].fermata.comune})\n` +
        `Tutti gli orari: https://orari.deangelisbus.it`)}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4" /></svg>
        Condividi questo orario
      </button>
      <div className="scheda-corsa">
        <p>Circola {descriviGiorni(corsa.giorni)}{corsa.solo_giorni_scolastici ? ', solo nei giorni di scuola' : ''}{corsa.solo_giorni_non_scolastici ? ', solo quando le scuole sono chiuse' : ''}.</p>
        {corsa.note && <p>{corsa.note}</p>}
        {stime && <p className="nota">Gli orari con ~ sono stimati in base ai chilometri.</p>}
        <p className="codice">Corsa {corsa.codice}</p>
      </div>
    </>
  );
}

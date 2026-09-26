import type { Nav } from '../App';
import { daIso } from '../components/Giorni';
import Testata from '../components/Testata';
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
      <div className="scheda-corsa">
        <p>Circola {descriviGiorni(corsa.giorni)}{corsa.solo_giorni_scolastici ? ', solo nei giorni di scuola' : ''}{corsa.solo_giorni_non_scolastici ? ', solo quando le scuole sono chiuse' : ''}.</p>
        {corsa.note && <p>{corsa.note}</p>}
        {stime && <p className="nota">Gli orari con ~ sono stimati in base ai chilometri.</p>}
        <p className="codice">Corsa {corsa.codice}</p>
      </div>
    </>
  );
}

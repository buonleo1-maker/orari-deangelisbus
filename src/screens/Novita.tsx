import type { Nav } from '../App';
import SchedaNovita from '../components/SchedaNovita';
import Testata from '../components/Testata';
import { oggi, type Orario } from '../lib/schedule';

export default function NovitaView({ orario, nav }: { orario: Orario; nav: Nav }) {
  const lista = orario.novitaVisibili(oggi());
  return (
    <>
      <Testata titolo="Novità ed eventi" sotto="De Angelis Bus" onIndietro={nav.indietro} />
      {lista.length === 0
        ? <p className="vuoto">Al momento non ci sono novità. Torna a trovarci: qui trovi eventi, variazioni del servizio e comunicazioni.</p>
        : <div className="elenco-novita">{lista.map((n) => <SchedaNovita key={n.id} n={n} />)}</div>}
    </>
  );
}

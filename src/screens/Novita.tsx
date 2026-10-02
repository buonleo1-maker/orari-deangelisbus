import type { Nav } from '../App';
import SchedaNovita from '../components/SchedaNovita';
import Testata from '../components/Testata';
import { useEffect, useState } from 'react';
import { nonLette, segnaLette } from '../lib/lette';
import { oggi, type Orario } from '../lib/schedule';

export default function NovitaView({ orario, nav }: { orario: Orario; nav: Nav }) {
  const lista = orario.novitaVisibili(oggi());
  const [nuove] = useState(() => new Set(nonLette(lista).map((n) => n.id)));
  useEffect(() => { segnaLette(lista.map((n) => n.id)); }, [lista]);
  return (
    <>
      <Testata titolo="Novità ed eventi" sotto="Deangelisbus S.r.l." onIndietro={nav.indietro} />
      {lista.length === 0
        ? <p className="vuoto">Al momento non ci sono novità. Torna a trovarci: qui trovi eventi, variazioni del servizio e comunicazioni.</p>
        : <div className="elenco-novita">{lista.map((n) => (
            <div key={n.id} className={nuove.has(n.id) ? 'novita-nuova' : undefined}>
              {nuove.has(n.id) && <span className="etichetta-nuova">Nuova</span>}
              <SchedaNovita n={n} />
            </div>
          ))}</div>}
    </>
  );
}

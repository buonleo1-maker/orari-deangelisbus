import { useEffect, useState } from 'react';
import type { Nav } from '../App';
import Testata from '../components/Testata';
import { distanzaMetri } from '../lib/preferiti';
import { hhmm, minutoAdesso, oggi, type Orario } from '../lib/schedule';

type Stato = { tipo: 'cerco' } | { tipo: 'errore'; msg: string } | { tipo: 'ok'; lat: number; lon: number };

const metri = (m: number) => (m < 1000 ? `${Math.round(m / 10) * 10} m` : `${(m / 1000).toFixed(1).replace('.', ',')} km`);

/** Fermate più vicine alla posizione del telefono, con il prossimo bus. */
export default function Vicine({ orario, nav }: { orario: Orario; nav: Nav }) {
  const [stato, setStato] = useState<Stato>({ tipo: 'cerco' });
  const cerca = () => {
    setStato({ tipo: 'cerco' });
    if (!navigator.geolocation) { setStato({ tipo: 'errore', msg: 'Questo telefono non permette di leggere la posizione.' }); return; }
    navigator.geolocation.getCurrentPosition(
      (p) => setStato({ tipo: 'ok', lat: p.coords.latitude, lon: p.coords.longitude }),
      (e) => setStato({ tipo: 'errore', msg: e.code === 1
        ? 'Per trovare le fermate vicine serve il permesso alla posizione. Puoi attivarlo nelle impostazioni del telefono (Posizione) e riprovare.'
        : 'Non riesco a trovare la tua posizione in questo momento. Controlla che la localizzazione sia attiva e riprova.' }),
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 60000 },
    );
  };
  useEffect(cerca, []);

  const ora = minutoAdesso();
  const vicine = stato.tipo === 'ok'
    ? [...orario.fermate.values()]
        .filter((f) => f.lat != null && f.lon != null)
        .map((f) => ({ f, d: distanzaMetri(stato.lat, stato.lon, f.lat as number, f.lon as number) }))
        .sort((a, b) => a.d - b.d)
        .slice(0, 6)
        .map((x) => ({ ...x, prossimo: orario.partenze(x.f.id, oggi()).find((p) => p.passaggio.minuto >= ora) }))
    : [];

  return (
    <>
      <Testata titolo="Fermate vicino a me" sotto="In base alla posizione del telefono" onIndietro={nav.indietro} />
      {stato.tipo === 'cerco' && <p className="vuoto">Sto cercando la tua posizione…</p>}
      {stato.tipo === 'errore' && (
        <div className="vuoto-box"><p>{stato.msg}</p><button className="link" onClick={cerca}>Riprova</button></div>
      )}
      {stato.tipo === 'ok' && (
        <>
          <ul className="elenco-vicine">
            {vicine.map(({ f, d, prossimo }) => (
              <li key={f.id}>
                <button onClick={() => nav.apri({ tipo: 'fermata', id: f.id })}>
                  <span className="vic-dist">{metri(d)}</span>
                  <span className="vic-nome">{f.nome}<small>{f.comune}</small></span>
                  <span className="vic-bus">{prossimo
                    ? <><b>{!prossimo.passaggio.confermato && '~'}{hhmm(prossimo.passaggio.minuto)}</b><small>per {prossimo.capolinea.comune}</small></>
                    : <small>nessun altro bus oggi</small>}</span>
                </button>
              </li>
            ))}
          </ul>
          {vicine.length > 0 && vicine[0].d > 3000 && <p className="nota" style={{ margin: '8px 18px' }}>La fermata più vicina è a oltre 3 km: forse sei fuori dalla zona servita.</p>}
          <button className="link" style={{ margin: '4px 18px 18px' }} onClick={cerca}>Aggiorna posizione</button>
        </>
      )}
    </>
  );
}

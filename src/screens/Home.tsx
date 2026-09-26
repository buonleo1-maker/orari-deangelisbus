import { useEffect, useState } from 'react';
import type { Nav } from '../App';
import Installa from '../components/Installa';
import LinkSito from '../components/LinkSito';
import SchedaNovita from '../components/SchedaNovita';
import Testata from '../components/Testata';
import { hhmm, minutoAdesso, oggi, type Orario } from '../lib/schedule';
import { SERVIZI, type VoceServizio } from '../lib/servizi';

export default function Home({ orario, nav, casa }: { orario: Orario; nav: Nav; casa: number | null }) {
  const [ora, setOra] = useState(minutoAdesso());
  useEffect(() => { const t = setInterval(() => setOra(minutoAdesso()), 30000); return () => clearInterval(t); }, []);

  const fermata = casa != null ? orario.fermate.get(casa) : undefined;
  const prossimo = fermata ? orario.partenze(fermata.id, oggi()).find((p) => p.passaggio.minuto >= ora) : undefined;

  const novita = orario.novitaVisibili(oggi());

  const apri = (v: VoceServizio) => {
    if (v.tipo === 'categoria') nav.apri({ tipo: 'categoria', categoria: 'extraurbano' });
    else if (orario.linee.has(v.linea)) nav.apri({ tipo: 'linea', id: v.linea });
    else nav.apri({ tipo: 'servizio', id: v.id });
  };

  return (
    <>
      <Testata titolo="Orari e servizi" conLogo />
      <p className="saluto-home">Benvenuti! Ecco gli orari delle corse esercitate da De Angelis Bus:</p>

      <button className="mini-partenza" onClick={() => nav.apri({ tipo: 'tab', tab: 'partenze' })}>
        {fermata ? (
          prossimo ? (
            <>
              <span className="mp-etichetta">Prossimo bus da {fermata.nome}</span>
              <span className="mp-ora">{!prossimo.passaggio.confermato && '~'}{hhmm(prossimo.passaggio.minuto)}</span>
              <span className="mp-dest">per {prossimo.capolinea.comune} – {prossimo.capolinea.nome}</span>
            </>
          ) : (
            <>
              <span className="mp-etichetta">Da {fermata.nome}</span>
              <span className="mp-dest">Per oggi non ci sono altri bus. Tocca per vedere domani.</span>
            </>
          )
        ) : (
          <>
            <span className="mp-etichetta">Il tuo prossimo bus</span>
            <span className="mp-dest">Scegli la tua fermata e vedi subito quando passa il bus.</span>
          </>
        )}
      </button>

      {novita.length > 0 && (
        <section className="sezione">
          <div className="gruppo-riga">
            <h2 className="gruppo">Novità ed eventi</h2>
            {novita.length > 2 && <button className="link" onClick={() => nav.apri({ tipo: 'novita' })}>Vedi tutte ({novita.length})</button>}
          </div>
          <button className="novita-anteprima" onClick={() => nav.apri({ tipo: 'novita' })}>
            {novita.slice(0, 2).map((n) => <SchedaNovita key={n.id} n={n} breve />)}
          </button>
        </section>
      )}

      <ul className="menu-servizi">
        {SERVIZI.map((v) => (
          <li key={v.id}>
            <button onClick={() => apri(v)}>
              <i className="barra" style={{ background: v.colore }} />
              <span className="nome">{v.titolo}{v.sotto && <small>{v.sotto}</small>}</span>
              <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 5l7 7-7 7" /></svg>
            </button>
          </li>
        ))}
        <li>
          <button onClick={() => nav.apri({ tipo: 'novita' })}>
            <i className="barra" style={{ background: '#E07A1F' }} />
            <span className="nome">Novità ed eventi<small>Eventi, variazioni del servizio e comunicazioni</small></span>
            <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 5l7 7-7 7" /></svg>
          </button>
        </li>
      </ul>

      <button className="richiesta" onClick={() => nav.apri({ tipo: 'preventivo' })}>
        <strong>Richiesta trasferimenti e noleggio con conducente</strong>
        <span>Compila la richiesta: ti ricontattiamo noi con il preventivo.</span>
      </button>
      <LinkSito />
      <Installa />
    </>
  );
}

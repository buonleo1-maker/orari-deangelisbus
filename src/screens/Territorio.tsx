import type { Nav } from '../App';
import Testata from '../components/Testata';
import { PAESI } from '../lib/territorio';
import type { Orario } from '../lib/schedule';

/** Scopri il territorio: cosa vedere nei paesi serviti e come arrivarci. */
export default function Territorio({ orario, nav }: { orario: Orario; nav: Nav }) {
  return (
    <>
      <Testata titolo="Scopri il territorio" sotto="Matera, Grottole, Miglionico e Montescaglioso" onIndietro={nav.indietro} />
      <p className="terr-intro">Borghi, castelli, abbazie e i Sassi di Matera: tutto a pochi chilometri, e con noi ci arrivi in bus.</p>
      <nav className="terr-indice" aria-label="Paesi">
        {PAESI.map((p) => <a key={p.id} href={`#paese-${p.id}`} style={{ borderColor: p.colore, color: p.colore }}>{p.nome}</a>)}
      </nav>
      {PAESI.map((p) => (
        <section key={p.id} id={`paese-${p.id}`} className="paese" style={{ ['--paese' as string]: p.colore }}>
          <header className="paese-testa">
            <h2>{p.nome}</h2>
            <p>{p.motto}</p>
          </header>
          <ul className="paese-luoghi">
            {p.luoghi.map((l) => <li key={l.nome}><strong>{l.nome}</strong><span>{l.testo}</span></li>)}
          </ul>
          {p.evento && <p className="paese-evento"><b>Da non perdere:</b> {p.evento}</p>}
          {(() => {
            const g = (orario.d.gusto ?? []).filter((x) => x.paese === p.id && x.visibile).sort((a, b) => a.ordine - b.ordine || a.nome.localeCompare(b.nome));
            const piatti = g.filter((x) => x.tipo === 'piatto');
            const ristoranti = g.filter((x) => x.tipo === 'ristorante').slice(0, 4);
            if (!piatti.length && !ristoranti.length) return null;
            return (
              <div className="gusto">
                <h3>Cosa mangiare</h3>
                {piatti.length > 0 && (
                  <ul className="gusto-piatti">
                    {piatti.map((x) => <li key={x.id}><strong>{x.nome}</strong>{x.descrizione && <span>{x.descrizione}</span>}</li>)}
                  </ul>
                )}
                {ristoranti.length > 0 && (
                  <>
                    <h4>Dove mangiare</h4>
                    <ul className="gusto-ristoranti">
                      {ristoranti.map((x) => (
                        <li key={x.id}>
                          <strong>{x.nome}</strong>
                          {x.descrizione && <span>{x.descrizione}</span>}
                          {x.indirizzo && <small>{x.indirizzo}</small>}
                          <span className="gusto-azioni">
                            {x.telefono && <a href={`tel:${x.telefono.replace(/\s/g, '')}`}>Chiama</a>}
                            {x.link && <a href={x.link} target="_blank" rel="noreferrer">Sito</a>}
                            {x.indirizzo && <a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${x.nome} ${x.indirizzo} ${p.nome}`)}`} target="_blank" rel="noreferrer">Mappa</a>}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </>
                )}
              </div>
            );
          })()}
          <div className="paese-azioni">
            {p.servizi.map((s) => {
              const esiste = s.apri.tipo !== 'linea' || orario.linee.has(s.apri.id);
              if (!esiste) return null;
              return (
                <button key={s.etichetta} className="paese-bus" onClick={() => nav.apri(s.apri)}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="4" y="3" width="16" height="14" rx="3" /><path d="M4 11h16M8 21l1-4M16 21l-1-4" /></svg>
                  {s.etichetta}
                </button>
              );
            })}
            <button className="paese-gita" onClick={() => nav.apri({ tipo: 'preventivo' })}>Organizza una gita a {p.nome} con i nostri bus</button>
          </div>
        </section>
      ))}
      <p className="nota" style={{ margin: '4px 18px 24px' }}>Orari di apertura e date degli eventi possono variare: verificali sui siti dei Comuni prima di partire.</p>
    </>
  );
}

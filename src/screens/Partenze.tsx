import { useEffect, useState } from 'react';
import type { Nav } from '../App';
import Installa from '../components/Installa';
import LinkSito from '../components/LinkSito';
import Logo from '../components/Logo';
import StopPicker from '../components/StopPicker';
import StellaFermata from '../components/StellaFermata';
import Testata from '../components/Testata';
import { addGiorni, hhmm, isoData, minutoAdesso, oggi, type Orario } from '../lib/schedule';

export default function Partenze({ orario, fermataId, nav, onScegli, dettaglio, casa }: {
  orario: Orario; fermataId: number | null; nav: Nav; onScegli: (id: number) => void; dettaglio?: boolean; casa: number | null;
}) {
  const [picker, setPicker] = useState(false);
  const [domani, setDomani] = useState(false);
  const [ora, setOra] = useState(minutoAdesso());
  useEffect(() => { const t = setInterval(() => setOra(minutoAdesso()), 30000); return () => clearInterval(t); }, []);

  const fermata = fermataId != null ? orario.fermate.get(fermataId) : undefined;

  if (!fermata) {
    return (
      <div className="benvenuto">
        <Logo dimensione="grande" motto />
        <div className="palina" aria-hidden="true"><span>FERMATA</span></div>
        <h1>Da quale fermata parti?</h1>
        <p>Scegli la fermata che usi di più: da qui vedrai subito i prossimi bus.</p>
        <button className="primario" onClick={() => setPicker(true)}>Scegli la fermata</button>
        <div style={{ marginTop: 32 }}><Installa /></div>
        <LinkSito variante="compatto" />
        {picker && <StopPicker orario={orario} titolo="La tua fermata" onChiudi={() => setPicker(false)}
          onScegli={(id) => { onScegli(id); setPicker(false); }} />}
      </div>
    );
  }

  const giorno = domani ? addGiorni(oggi(), 1) : oggi();
  const tutte = orario.partenze(fermata.id, giorno);
  const lista = domani ? tutte : tutte.filter((p) => p.passaggio.minuto >= ora);
  const [prima, ...altre] = lista;
  const attesa = prima && !domani ? prima.passaggio.minuto - ora : null;

  return (
    <>
      <Testata titolo={fermata.nome} sotto={fermata.comune} onIndietro={dettaglio ? nav.indietro : undefined}>
        {!dettaglio && <button className="link chiaro" onClick={() => setPicker(true)}>Cambia</button>}
      </Testata>

      <div className="azioni-fermata"><StellaFermata id={fermata.id} casa={fermata.id === casa} /></div>

      <div className="interruttore" role="tablist">
        <button role="tab" aria-selected={!domani} className={!domani ? 'attivo' : ''} onClick={() => setDomani(false)}>Oggi</button>
        <button role="tab" aria-selected={domani} className={domani ? 'attivo' : ''} onClick={() => setDomani(true)}>Domani</button>
      </div>

      {prima ? (
        <button className="tabellone" onClick={() => nav.apri({ tipo: 'corsa', codice: prima.corsa.codice, giorno: isoData(giorno) })}>
          <span className="tabellone-etichetta">{domani ? 'Primo bus di domani' : 'Prossimo bus'}</span>
          <span className="tabellone-ora">{!prima.passaggio.confermato && <small>circa </small>}{hhmm(prima.passaggio.minuto)}</span>
          {attesa != null && <span className="tabellone-attesa">{attesa <= 0 ? 'in partenza' : attesa < 60 ? `tra ${attesa} min` : `tra ${Math.floor(attesa / 60)} h ${attesa % 60} min`}</span>}
          <span className="tabellone-dest">
            <i style={{ background: prima.linea.colore ?? undefined }} />per {prima.capolinea.comune} – {prima.capolinea.nome}
          </span>
          <span className="tabellone-linea">{prima.linea.nome}</span>
        </button>
      ) : (
        <div className="vuoto-box">
          <p><strong>{domani ? 'Domani non ci sono bus da questa fermata.' : 'Per oggi non ci sono altri bus da questa fermata.'}</strong></p>
          {!domani && <button className="link" onClick={() => setDomani(true)}>Guarda i bus di domani</button>}
        </div>
      )}

      {altre.length > 0 && (
        <ul className="elenco-partenze">
          {altre.map((p) => (
            <li key={p.corsa.codice}>
              <button onClick={() => nav.apri({ tipo: 'corsa', codice: p.corsa.codice, giorno: isoData(giorno) })}>
                <span className="ora">{!p.passaggio.confermato && '~'}{hhmm(p.passaggio.minuto)}</span>
                <i className="barra" style={{ background: p.linea.colore ?? undefined }} />
                <span className="dest"><b>{p.capolinea.comune}</b> {p.capolinea.nome}<small>{p.linea.nome}</small></span>
              </button>
            </li>
          ))}
        </ul>
      )}

      {dettaglio && casa !== fermata.id && (
        <button className="secondario centrato" onClick={() => onScegli(fermata.id)}>Usa come mia fermata</button>
      )}
      <p className="nota">I tempi con ~ o "circa" sono stimati: presentati alla fermata qualche minuto prima.</p>

      {picker && <StopPicker orario={orario} titolo="Cambia fermata" onChiudi={() => setPicker(false)}
        onScegli={(id) => { onScegli(id); setPicker(false); }} />}
    </>
  );
}

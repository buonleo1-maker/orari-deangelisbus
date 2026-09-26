import { useState } from 'react';
import type { Nav } from '../App';
import Giorni, { daIso } from '../components/Giorni';
import StopPicker from '../components/StopPicker';
import Testata from '../components/Testata';
import { euro, hhmm, isoData, minutoAdesso, oggi, type Orario } from '../lib/schedule';

export default function Viaggio({ orario, nav }: { orario: Orario; nav: Nav }) {
  const [da, setDa] = useState<number | null>(() => Number(localStorage.getItem('viaggio_da')) || null);
  const [a, setA] = useState<number | null>(() => Number(localStorage.getItem('viaggio_a')) || null);
  const [giorno, setGiorno] = useState(isoData(oggi()));
  const [picker, setPicker] = useState<'da' | 'a' | null>(null);

  const imposta = (quale: 'da' | 'a', id: number | null) => {
    (quale === 'da' ? setDa : setA)(id);
    localStorage.setItem(`viaggio_${quale}`, id ? String(id) : '');
  };
  const fDa = da ? orario.fermate.get(da) : undefined;
  const fA = a ? orario.fermate.get(a) : undefined;
  const eOggi = giorno === isoData(oggi());
  const risultati = fDa && fA ? orario.viaggi(fDa.id, fA.id, daIso(giorno)) : [];
  const ora = minutoAdesso();

  return (
    <>
      <Testata titolo="Trova il tuo bus" sotto="Scegli partenza e arrivo" />
      <div className="da-a">
        <button className="campo" onClick={() => setPicker('da')}>
          <small>Da</small>{fDa ? `${fDa.comune} – ${fDa.nome}` : 'Scegli la fermata di partenza'}
        </button>
        <button className="campo" onClick={() => setPicker('a')}>
          <small>A</small>{fA ? `${fA.comune} – ${fA.nome}` : 'Scegli la fermata di arrivo'}
        </button>
        <button className="scambia" aria-label="Scambia partenza e arrivo" onClick={() => { imposta('da', a); imposta('a', da); }}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M8 4v16m0 0-4-4m4 4 4-4M16 20V4m0 0-4 4m4-4 4 4" /></svg>
        </button>
      </div>
      <Giorni valore={giorno} onCambia={setGiorno} />

      {fDa && fA && (risultati.length === 0 ? (
        <p className="vuoto">Nessun bus diretto tra queste fermate in questo giorno. Prova un altro giorno o una fermata vicina dello stesso paese.</p>
      ) : (
        <ul className="elenco-corse">
          {risultati.map((r) => {
            const t = orario.tariffa(r.linea.id, r.da.fermata, r.a.fermata);
            const passato = eOggi && r.da.minuto < ora;
            return (
              <li key={r.corsa.codice} className={passato ? 'passato' : undefined}>
                <button onClick={() => nav.apri({ tipo: 'corsa', codice: r.corsa.codice, giorno })}>
                  <span className="ora">{!r.da.confermato && '~'}{hhmm(r.da.minuto)}</span>
                  <span className="freccia" aria-hidden="true" />
                  <span className="ora arrivo">{!r.a.confermato && '~'}{hhmm(r.a.minuto)}</span>
                  <span className="dettagli">
                    <i className="pallino" style={{ background: r.linea.colore ?? undefined }} />{r.linea.nome}
                    <small>{r.a.minuto - r.da.minuto} min{t ? ` – corsa semplice ${euro(t.prezzo)}` : ''}</small>
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      ))}

      {picker && <StopPicker orario={orario} titolo={picker === 'da' ? 'Parto da' : 'Arrivo a'} onChiudi={() => setPicker(null)}
        onScegli={(id) => { imposta(picker, id); setPicker(null); }} />}
    </>
  );
}

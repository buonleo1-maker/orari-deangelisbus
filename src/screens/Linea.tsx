import { useMemo, useState } from 'react';
import type { Nav } from '../App';
import Giorni, { daIso } from '../components/Giorni';
import Testata from '../components/Testata';
import { descriviGiorni, euro, hhmm, isoData, oggi, type Orario } from '../lib/schedule';

export default function LineaView({ orario, id, nav }: { orario: Orario; id: string; nav: Nav }) {
  const linea = orario.linee.get(id);
  const [dir, setDir] = useState<'A' | 'R'>('A');
  const [giorno, setGiorno] = useState(isoData(oggi()));
  const direzioni = useMemo(() => (['A', 'R'] as const).filter((d) => orario.d.corse.some((c) => c.linea_id === id && c.direzione === d)), [orario, id]);

  if (!linea) return <Testata titolo="Linea non trovata" onIndietro={nav.indietro} />;
  const corse = orario.corseDelGiorno(id, dir, daIso(giorno));
  const esempio = orario.d.corse.find((c) => c.linea_id === id && c.direzione === dir);
  const ps = esempio ? orario.passaggi(esempio) : [];
  const etichetta = (d: 'A' | 'R') => {
    const c = orario.d.corse.find((x) => x.linea_id === id && x.direzione === d);
    const p = c ? orario.passaggi(c) : [];
    return p.length ? `verso ${p[p.length - 1].fermata.comune === p[0].fermata.comune ? p[p.length - 1].fermata.nome : p[p.length - 1].fermata.comune}` : d;
  };
  const tariffe = orario.tariffeLinea(id).filter((t) => t.tipo_codice === 1 || t.tipo_codice === 3);
  const cs = tariffe.filter((t) => t.tipo_codice === 1);
  const unica = tariffe.filter((t) => t.da_zona === '*');

  return (
    <>
      <Testata titolo={linea.nome} sotto={linea.subappalto ? `Servizio ${linea.committente ?? ''} svolto da Deangelisbus S.r.l.` : linea.comune ?? undefined}
        onIndietro={nav.indietro} colore={linea.colore} />

      {!orario.d.corse.some((c) => c.linea_id === id && c.attiva) ? (
        <>
          {linea.info_pubblico && <p className="avviso-linea">{linea.info_pubblico}</p>}
          <p className="avviso-linea">Gli orari di questo servizio sono in aggiornamento. Per informazioni chiama lo 0835 758126 o scrivi a info@deangelisbus.it.</p>
        </>
      ) : (<>
      {direzioni.length > 1 && (
        <div className="interruttore" role="tablist">
          {direzioni.map((d) => (
            <button key={d} role="tab" aria-selected={dir === d} className={dir === d ? 'attivo' : ''} onClick={() => setDir(d)}>{etichetta(d)}</button>
          ))}
        </div>
      )}
      <Giorni valore={giorno} onCambia={setGiorno} />

      {corse.length === 0 ? (
        (() => {
          const periodi = orario.d.periodi.filter((p) => p.linea_id === id).sort((a, b) => a.dal.localeCompare(b.dal));
          const fuoriTurno = periodi.length > 0 && !periodi.some((p) => giorno >= p.dal && giorno <= p.al);
          const prossimo = periodi.find((p) => p.dal > giorno);
          return fuoriTurno ? (
            <p className="avviso-linea">In questo periodo il servizio è svolto da un'altra azienda del consorzio Cotrab: gli orari sono su cotrab.it.
              {prossimo && <> Il prossimo turno di Deangelisbus inizia il {new Date(prossimo.dal + 'T12:00:00').toLocaleDateString('it-IT', { day: 'numeric', month: 'long', year: 'numeric' })}.</>}</p>
          ) : <p className="vuoto">Nessuna corsa in questo giorno. Prova un altro giorno.</p>;
        })()
      ) : (
        <ul className="elenco-corse">
          {corse.map((c) => {
            const p = orario.passaggi(c);
            const a = p[p.length - 1];
            return (
              <li key={c.codice}>
                <button onClick={() => nav.apri({ tipo: 'corsa', codice: c.codice, giorno })}>
                  <span className="ora">{hhmm(p[0].minuto)}</span>
                  <span className="freccia" aria-hidden="true" />
                  <span className="ora arrivo">{!a.confermato && '~'}{hhmm(a.minuto)}</span>
                  <span className="dettagli">
                    {p[0].fermata.comune === a.fermata.comune ? `${p[0].fermata.nome} → ${a.fermata.nome}` : `${p[0].fermata.comune} → ${a.fermata.comune}`}
                    <small>{[descriviGiorni(c.giorni), c.solo_giorni_scolastici && 'solo giorni di scuola', c.solo_giorni_non_scolastici && 'solo quando le scuole sono chiuse', c.stagionale && `stagione ${c.stagionale}`].filter(Boolean).join(' – ')}</small>
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      )}

      {linea.info_pubblico && <p className="avviso-linea">{linea.info_pubblico}</p>}
      </>)}

      {unica.length > 0 && (
        <section className="sezione">
          <h2 className="gruppo">Biglietti</h2>
          <table className="tariffe"><tbody>
            {unica.map((t) => <tr key={t.tipo_codice}><td>{t.tipo_nome}</td><td>{euro(t.prezzo)}</td></tr>)}
          </tbody></table>
        </section>
      )}
      {unica.length === 0 && cs.length > 0 && ps.length > 0 && (
        <section className="sezione">
          <h2 className="gruppo">Corsa semplice da {ps[0].fermata.comune}</h2>
          <table className="tariffe"><tbody>
            {[...new Map(ps.slice(1).map((x) => [x.fermata.zona_tariffaria, x.fermata])).values()].map((f) => {
              const t = orario.tariffa(id, ps[0].fermata, f);
              return t ? <tr key={f.id}><td>{f.comune}{f.zona_tariffaria && f.zona_tariffaria !== f.comune.toUpperCase() ? ` (${f.nome})` : ''}</td><td>{euro(t.prezzo)}</td></tr> : null;
            })}
          </tbody></table>
        </section>
      )}
    </>
  );
}

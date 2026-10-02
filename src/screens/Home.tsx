import { useEffect, useState } from 'react';
import type { Nav } from '../App';
import Installa from '../components/Installa';
import { App as CapApp } from '@capacitor/app';
import { Capacitor } from '@capacitor/core';
import CardPreventivo from '../components/CardPreventivo';
import { leggiSalvate } from '../lib/preferiti';
import CardRidola from '../components/CardRidola';
import CardTerritorio from '../components/CardTerritorio';
import CondividiApp from '../components/CondividiApp';
import { fotoOrdinate, urlFoto } from '../lib/foto';
import LinkBiglietti from '../components/LinkBiglietti';
import LinkSito from '../components/LinkSito';
import SchedaNovita from '../components/SchedaNovita';
import Testata from '../components/Testata';
import { hhmm, minutoAdesso, oggi, type Orario } from '../lib/schedule';
import { SERVIZI, URL_FLOTTA, type VoceServizio } from '../lib/servizi';

export default function Home({ orario, nav, casa }: { orario: Orario; nav: Nav; casa: number | null }) {
  const [ora, setOra] = useState(minutoAdesso());
  useEffect(() => { const t = setInterval(() => setOra(minutoAdesso()), 30000); return () => clearInterval(t); }, []);

  const fermata = casa != null ? orario.fermate.get(casa) : undefined;
  const salvate = leggiSalvate().filter((id) => id !== casa).map((id) => orario.fermate.get(id)).filter((f) => f != null);
  const prossimo = fermata ? orario.partenze(fermata.id, oggi()).find((p) => p.passaggio.minuto >= ora) : undefined;

  const tutte = orario.novitaVisibili(oggi());
  const novita = tutte.filter((n) => n.tipo !== 'viaggio');

  // "Esci": nell'app Android chiude davvero; nell'app web installata prova a chiudere la finestra
  // e, se il telefono non lo consente, spiega come chiuderla.
  const installataWeb = typeof window !== 'undefined' && window.matchMedia?.('(display-mode: standalone)').matches;
  const [aiutoEsci, setAiutoEsci] = useState(false);
  const esci = () => {
    if (Capacitor.isNativePlatform()) { CapApp.exitApp(); return; }
    window.close();
    setTimeout(() => { if (!document.hidden) setAiutoEsci(true); }, 400);
  };

  const apri = (v: VoceServizio) => {
    if (v.tipo === 'categoria') nav.apri({ tipo: 'categoria', categoria: 'extraurbano' });
    else if (orario.linee.has(v.linea)) nav.apri({ tipo: 'linea', id: v.linea });
    else nav.apri({ tipo: 'servizio', id: v.id });
  };

  return (
    <>
      <Testata titolo="Orari e servizi" conLogo>
        {(Capacitor.isNativePlatform() || installataWeb) && (
          <button className="esci" onClick={esci} aria-label="Esci dall'app">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M15 17l5-5-5-5M20 12H9M12 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7" /></svg>
            <span>Esci</span>
          </button>
        )}
      </Testata>
      {aiutoEsci && (
        <div className="aiuto-esci" role="status">
          <span>Per chiudere l'app usa il tasto <strong>Home</strong> del telefono oppure scorri via l'app dalle app recenti.</span>
          <button onClick={() => setAiutoEsci(false)} aria-label="Chiudi messaggio">✕</button>
        </div>
      )}
      <p className="saluto-home">Benvenuti! Ecco gli orari delle corse esercitate dalla Deangelisbus S.r.l.:</p>

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

      {salvate.length > 0 && (
        <section className="mie-fermate">
          <h2 className="gruppo">Le mie fermate</h2>
          <ul>
            {salvate.map((f) => {
              const p = orario.partenze(f.id, oggi()).find((x) => x.passaggio.minuto >= ora);
              return (
                <li key={f.id}>
                  <button onClick={() => nav.apri({ tipo: 'fermata', id: f.id })}>
                    <span className="mf-nome">{f.nome}<small>{f.comune}</small></span>
                    <span className="mf-bus">{p ? <><b>{!p.passaggio.confermato && '~'}{hhmm(p.passaggio.minuto)}</b><small>per {p.capolinea.comune}</small></> : <small>nessun altro bus oggi</small>}</span>
                  </button>
                </li>
              );
            })}
          </ul>
        </section>
      )}

      <button className="vicino-a-me" onClick={() => nav.apri({ tipo: 'vicine' })}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 22s7-7.5 7-13a7 7 0 0 0-14 0c0 5.5 7 13 7 13z" /><circle cx="12" cy="9" r="2.5" /></svg>
        <span><strong>Fermate vicino a me</strong><small>Trova la fermata più vicina e il prossimo bus</small></span>
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
        {(() => {
          // linee create dal gestionale che non hanno una voce fissa nel menu (gli extraurbani stanno gia' nella loro voce)
          const fisse = new Set(SERVIZI.flatMap((v) => (v.tipo === 'linea' ? [v.linea] : [])));
          return orario.lineeOrdinate().filter((l) => l.categoria !== 'extraurbano' && !fisse.has(l.id)).map((l) => (
            <li key={l.id}>
              <button onClick={() => nav.apri({ tipo: 'linea', id: l.id })}>
                <i className="barra" style={{ background: l.colore ?? '#1E5BB8' }} />
                <span className="nome">{l.nome}{l.comune && <small>{l.comune}</small>}</span>
                <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 5l7 7-7 7" /></svg>
              </button>
            </li>
          ));
        })()}
        <li>
          <button onClick={() => nav.apri({ tipo: 'novita' })}>
            <i className="barra" style={{ background: '#E07A1F' }} />
            <span className="nome">Novità ed eventi<small>Eventi, variazioni del servizio e comunicazioni</small></span>
            <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 5l7 7-7 7" /></svg>
          </button>
        </li>
      </ul>

      <LinkBiglietti compatto />

      <button className="card-segnala" onClick={() => nav.apri({ tipo: 'segnalazione' })}>
        <strong>Feedback, reclami e segnalazioni</strong>
        <span>Un ritardo, un problema a bordo o un suggerimento? Scrivici.</span>
      </button>

      <CardTerritorio onApri={() => nav.apri({ tipo: 'territorio' })} />

      <CardPreventivo onApri={() => nav.apri({ tipo: 'preventivo' })} />

      <CardRidola />
      {(() => {
        const ff = fotoOrdinate(orario.d.foto);
        if (!ff.length) return null;
        return (
          <button className="card-foto" onClick={() => nav.apri({ tipo: 'galleria' })}>
            <span className="cf-strip">{ff.slice(0, 3).map((f) => <img key={f.id} src={urlFoto(f)} alt="" loading="lazy" />)}</span>
            <span className="cf-testo"><strong>In giro con noi</strong><small>Le foto dei nostri viaggi, con musica</small></span>
          </button>
        );
      })()}
      <a className="nostri-bus" href={URL_FLOTTA} target="_blank" rel="noreferrer">
        <svg viewBox="0 0 64 40" aria-hidden="true">
          <rect x="2" y="4" width="60" height="26" rx="6" fill="currentColor" />
          <rect x="8" y="9" width="12" height="9" rx="2" fill="#fff" /><rect x="23" y="9" width="12" height="9" rx="2" fill="#fff" /><rect x="38" y="9" width="12" height="9" rx="2" fill="#fff" />
          <rect x="53" y="9" width="6" height="15" rx="1.5" fill="#fff" />
          <circle cx="16" cy="31" r="5" fill="#101c28" stroke="#fff" strokeWidth="2" /><circle cx="48" cy="31" r="5" fill="#101c28" stroke="#fff" strokeWidth="2" />
        </svg>
        <span>
          <strong>I nostri bus</strong>
          <small>Autobus e minibus Gran Turismo, minivan e auto con conducente: scopri il parco macchine</small>
        </span>
        <svg className="freccia-esterna" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5" /></svg>
      </a>
      <LinkSito />
      <CondividiApp />
      <Installa />
    </>
  );
}

import { useEffect, useMemo, useRef, useState } from 'react';
import type { Nav } from '../App';
import Testata from '../components/Testata';
import { url as supabaseUrl } from '../lib/data';
import { distanzaMetri } from '../lib/preferiti';
import type { Orario } from '../lib/schedule';
import type { TappaAudioguida } from '../lib/types';
import {
  LINGUE, PERCORSI, audioTappa, creaLettore, linguaIniziale, salvaLingua, testoTappa, tr, vocePresente, type Lingua,
} from '../lib/audioguida';

type Gps = { tipo: 'spento' } | { tipo: 'cerco' } | { tipo: 'errore'; negato: boolean } | { tipo: 'ok'; lat: number; lon: number; acc: number };

const metri = (m: number) => (m < 1000 ? `${Math.round(m / 10) * 10} m` : `${(m / 1000).toFixed(1).replace('.', ',')} km`);

/**
 * Audioguida GPS: il racconto di ogni tappa parte da solo quando il telefono arriva vicino al luogo.
 * Le tappe senza coordinate sono "racconti di collegamento" e partono subito dopo la tappa precedente.
 */
export default function Audioguida({ orario, nav, percorso = 'panoramico-matera' }: { orario: Orario; nav: Nav; percorso?: string }) {
  const tappe = useMemo<TappaAudioguida[]>(
    () => (orario.d.audioguida ?? []).filter((t) => t.percorso === percorso && t.visibile).sort((a, b) => a.ordine - b.ordine),
    [orario, percorso],
  );
  const [lingua, setLingua] = useState<Lingua>(linguaIniziale);
  const voce = LINGUE.find((l) => l.id === lingua)!.voce;
  const [attiva, setAttiva] = useState(false);
  const [gps, setGps] = useState<Gps>({ tipo: 'spento' });
  const [sentite, setSentite] = useState<Set<number>>(() => new Set());
  const [coda, setCoda] = useState<number[]>([]);
  const [corrente, setCorrente] = useState<{ id: number; n: number } | null>(null);
  const [inPausa, setInPausa] = useState(false);
  const lettore = useRef(creaLettore());

  const titoloPercorso = PERCORSI[percorso]?.titolo[lingua] ?? '';

  // --- GPS: segue la posizione solo mentre l'audioguida è attiva
  useEffect(() => {
    if (!attiva) { setGps({ tipo: 'spento' }); return; }
    if (!navigator.geolocation) { setGps({ tipo: 'errore', negato: false }); return; }
    setGps({ tipo: 'cerco' });
    const id = navigator.geolocation.watchPosition(
      (p) => setGps({ tipo: 'ok', lat: p.coords.latitude, lon: p.coords.longitude, acc: p.coords.accuracy }),
      (e) => setGps({ tipo: 'errore', negato: e.code === 1 }),
      { enableHighAccuracy: true, maximumAge: 5000, timeout: 20000 },
    );
    return () => navigator.geolocation.clearWatch(id);
  }, [attiva]);

  // --- Schermo sempre acceso mentre l'audioguida è attiva (dove il telefono lo permette)
  useEffect(() => {
    if (!attiva) return;
    type Blocco = { release: () => Promise<void> };
    const wl = (navigator as unknown as { wakeLock?: { request: (t: 'screen') => Promise<Blocco> } }).wakeLock;
    if (!wl) return;
    let blocco: Blocco | null = null;
    const chiedi = () => { wl.request('screen').then((b) => { blocco = b; }).catch(() => undefined); };
    chiedi();
    const onVis = () => { if (document.visibilityState === 'visible') chiedi(); };
    document.addEventListener('visibilitychange', onVis);
    return () => { document.removeEventListener('visibilitychange', onVis); blocco?.release().catch(() => undefined); };
  }, [attiva]);

  // --- Arrivo vicino a una tappa: la mette in coda
  useEffect(() => {
    if (!attiva || gps.tipo !== 'ok') return;
    const tolleranza = Math.min(gps.acc, 50);
    const vicine = tappe
      .filter((t) => t.lat != null && t.lon != null)
      .filter((t) => !sentite.has(t.id) && t.id !== corrente?.id)
      .filter((t) => distanzaMetri(gps.lat, gps.lon, t.lat as number, t.lon as number) <= t.raggio_m + tolleranza)
      .map((t) => t.id);
    if (vicine.length) setCoda((c) => [...c, ...vicine.filter((id) => !c.includes(id))]);
  }, [gps, attiva, tappe, sentite, corrente]);

  // --- Se non sta parlando, prende la prossima della coda
  useEffect(() => {
    if (!attiva || inPausa || corrente || !coda.length) return;
    const [prima, ...resto] = coda;
    setCoda(resto);
    setCorrente({ id: prima, n: Date.now() });
  }, [attiva, inPausa, corrente, coda]);

  // --- Racconta la tappa corrente; alla fine passa ai racconti di collegamento che la seguono
  useEffect(() => {
    if (!corrente) return;
    const t = tappe.find((x) => x.id === corrente.id);
    if (!t) { setCorrente(null); return; }
    setInPausa(false);
    lettore.current.suona(testoTappa(t, lingua), voce, audioTappa(t, lingua, supabaseUrl), () => {
      setSentite((s) => new Set(s).add(t.id));
      const i = tappe.findIndex((x) => x.id === t.id);
      const collegati: number[] = [];
      for (let j = i + 1; j < tappe.length && tappe[j].lat == null; j += 1) collegati.push(tappe[j].id);
      setSentite((s) => {
        const nuovi = collegati.filter((id) => !s.has(id));
        if (nuovi.length) setCoda((c) => [...nuovi, ...c.filter((id) => !nuovi.includes(id))]);
        return s;
      });
      setCorrente(null);
    });
    // la lingua cambiata a metà fa ripartire il racconto nella nuova lingua
  }, [corrente, lingua]); // eslint-disable-line react-hooks/exhaustive-deps

  // --- Uscendo dalla schermata si ferma tutto
  useEffect(() => { const l = lettore.current; return () => l.ferma(); }, []);

  const avvia = () => {
    setAttiva(true);
    setInPausa(false);
    lettore.current.annuncia(tr(lingua, 'attiva'), voce);
  };
  const ferma = () => {
    lettore.current.ferma();
    setAttiva(false); setCorrente(null); setCoda([]); setInPausa(false);
  };
  const ricomincia = () => { ferma(); setSentite(new Set()); };
  const pausa = () => { lettore.current.pausa(); setInPausa(true); };
  const riprendi = () => { lettore.current.riprendi(); setInPausa(false); };
  const salta = () => {
    if (!corrente) return;
    const id = corrente.id;
    lettore.current.ferma();
    setSentite((s) => new Set(s).add(id));
    setCorrente(null);
  };
  const ascoltaOra = (id: number) => {
    if (!attiva) { setAttiva(true); }
    lettore.current.ferma();
    setCoda((c) => c.filter((x) => x !== id));
    setCorrente({ id, n: Date.now() });
  };
  const cambiaLingua = (l: Lingua) => { setLingua(l); salvaLingua(l); };

  const tappaCorrente = corrente ? tappe.find((t) => t.id === corrente.id) : undefined;

  return (
    <>
      <Testata titolo={tr(lingua, 'titolo')} sotto={titoloPercorso} onIndietro={() => { ferma(); nav.indietro(); }} />

      {!tappe.length ? (
        <p className="vuoto">{tr(lingua, 'vuota')}</p>
      ) : (
        <>
          <div className="ag-lingue" role="radiogroup" aria-label={tr(lingua, 'lingua')}>
            {LINGUE.map((l) => (
              <button key={l.id} role="radio" aria-checked={l.id === lingua} className={l.id === lingua ? 'attiva' : undefined} onClick={() => cambiaLingua(l.id)}>
                {l.nome}
              </button>
            ))}
          </div>

          {!attiva ? (
            <div className="ag-avvio">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M3 18v-6a9 9 0 0 1 18 0v6" /><path d="M21 19a2 2 0 0 1-2 2h-1v-6h3zM3 19a2 2 0 0 0 2 2h1v-6H3z" /></svg>
              <p>{tr(lingua, 'automatico')}<br /><small>{tr(lingua, 'consiglio')}</small></p>
              <button className="primario" onClick={avvia}>{tr(lingua, 'avvia')}</button>
            </div>
          ) : (
            <section className="ag-lettore" aria-live="polite">
              <span className="ag-stato">
                {tappaCorrente ? tr(lingua, 'inAscolto') : tr(lingua, 'attesa')}
                {gps.tipo === 'cerco' && <small> · {tr(lingua, 'cercoGps')}</small>}
              </span>
              {tappaCorrente && (
                <>
                  <strong>{tappaCorrente.nome}</strong>
                  <p className="ag-testo">{testoTappa(tappaCorrente, lingua)}</p>
                </>
              )}
              <div className="ag-comandi">
                {tappaCorrente && (inPausa
                  ? <button onClick={riprendi}>▶ {tr(lingua, 'riprendi')}</button>
                  : <button onClick={pausa}>❚❚ {tr(lingua, 'pausa')}</button>)}
                {tappaCorrente && <button onClick={salta}>⏭ {tr(lingua, 'salta')}</button>}
                <button onClick={ferma}>■ {tr(lingua, 'ferma')}</button>
              </div>
            </section>
          )}

          {!vocePresente && <p className="nota ag-avviso">{tr(lingua, 'senzaVoce')}</p>}
          {gps.tipo === 'errore' && <p className="nota ag-avviso">{tr(lingua, gps.negato ? 'gpsNegato' : 'gpsErrore')}</p>}

          <h2 className="gruppo ag-titolo-tappe">{tr(lingua, 'tappe')}</h2>
          <p className="nota" style={{ marginTop: 0 }}>{tr(lingua, 'tocca')}</p>
          <ol className="ag-tappe">
            {tappe.map((t) => {
              const d = gps.tipo === 'ok' && t.lat != null && t.lon != null ? distanzaMetri(gps.lat, gps.lon, t.lat, t.lon) : null;
              const stato = corrente?.id === t.id ? 'ora' : sentite.has(t.id) ? 'fatta' : '';
              return (
                <li key={t.id} className={stato}>
                  <button onClick={() => ascoltaOra(t.id)}>
                    <span className="ag-n">{stato === 'fatta' ? '✓' : t.ordine + 1}</span>
                    <span className="ag-nome">
                      {t.nome}
                      <small>
                        {t.lat == null ? tr(lingua, 'collegamento') : d != null ? metri(d) : ''}
                        {stato === 'fatta' && ` · ${tr(lingua, 'ascoltata')}`}
                      </small>
                    </span>
                    <span className="ag-play" aria-hidden="true">▶</span>
                  </button>
                </li>
              );
            })}
          </ol>
          {sentite.size > 0 && <button className="link" style={{ margin: '4px 18px 18px' }} onClick={ricomincia}>{tr(lingua, 'ricomincia')}</button>}
        </>
      )}
    </>
  );
}

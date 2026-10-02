import { useCallback, useEffect, useMemo, useState } from 'react';
import { App as CapApp } from '@capacitor/app';
import { aggiornaDati, datiIniziali } from './lib/data';
import { Orario } from './lib/schedule';
import type { Dati } from './lib/types';
import TabBar, { type Tab } from './components/TabBar';
import Partenze from './screens/Partenze';
import Linee from './screens/Linee';
import LineaView from './screens/Linea';
import CorsaView from './screens/Corsa';
import Viaggio from './screens/Viaggio';
import Mappa from './screens/Mappa';
import Info from './screens/Info';
import Preventivo from './screens/Preventivo';
import Home from './screens/Home';
import Servizio from './screens/Servizio';
import NovitaView from './screens/Novita';
import SegnalazioneView from './screens/Segnalazione';
import Assistente from './screens/Assistente';
import Territorio from './screens/Territorio';
import Vicine from './screens/Vicine';
import Galleria from './screens/Galleria';
import BottoneAssistente from './components/BottoneAssistente';

export type Schermata =
  | { tipo: 'tab'; tab: Tab }
  | { tipo: 'linea'; id: string }
  | { tipo: 'corsa'; codice: string; giorno: string }
  | { tipo: 'fermata'; id: number }
  | { tipo: 'preventivo' }
  | { tipo: 'categoria'; categoria: 'extraurbano' }
  | { tipo: 'servizio'; id: string }
  | { tipo: 'novita' }
  | { tipo: 'segnalazione' }
  | { tipo: 'assistente' }
  | { tipo: 'territorio' }
  | { tipo: 'galleria' }
  | { tipo: 'vicine' };

export interface Nav {
  apri: (s: Schermata) => void;
  indietro: () => void;
}

const FERMATA_KEY = 'fermata_preferita';

export default function App() {
  const [dati, setDati] = useState<Dati>(datiIniziali);
  const [stato, setStato] = useState<'pronto' | 'aggiorno' | 'offline'>('aggiorno');
  const [pila, setPila] = useState<Schermata[]>([{ tipo: 'tab', tab: 'home' }]);
  const [fermataCasa, setFermataCasa] = useState<number | null>(() => {
    const v = localStorage.getItem(FERMATA_KEY);
    return v ? Number(v) : null;
  });

  const orario = useMemo(() => new Orario(dati), [dati]);

  // Aperta toccando una notifica: va direttamente alle novita'
  useEffect(() => {
    const q = new URLSearchParams(window.location.search);
    if (q.get('apri') === 'novita') {
      setPila([{ tipo: 'tab', tab: 'home' }, { tipo: 'novita' }]);
      window.history.replaceState(null, '', window.location.pathname);
    }
    const daSw = (e: MessageEvent) => { if (e.data?.apri === 'novita') setPila([{ tipo: 'tab', tab: 'home' }, { tipo: 'novita' }]); };
    navigator.serviceWorker?.addEventListener('message', daSw);
    return () => navigator.serviceWorker?.removeEventListener('message', daSw);
  }, []);

  const aggiorna = useCallback(async () => {
    setStato('aggiorno');
    const nuovi = await aggiornaDati();
    if (nuovi) { setDati(nuovi); setStato('pronto'); } else setStato('offline');
  }, []);
  useEffect(() => { aggiorna(); }, [aggiorna]);

  const nav: Nav = useMemo(() => ({
    apri: (s) => setPila((p) => (s.tipo === 'tab' ? [s] : [...p, s])),
    indietro: () => setPila((p) => (p.length > 1 ? p.slice(0, -1) : p)),
  }), []);

  // Riaprendo l'app dopo un po' si riparte dalla schermata iniziale, con orari aggiornati
  const [ripresa, setRipresa] = useState(0);
  useEffect(() => {
    const SOGLIA_MS = 30_000; // tempo in secondo piano oltre il quale si torna alla home
    let nascostaDal = 0;
    const via = () => { nascostaDal = Date.now(); };
    const torna = () => {
      if (nascostaDal && Date.now() - nascostaDal >= SOGLIA_MS) {
        setPila([{ tipo: 'tab', tab: 'home' }]);
        setRipresa((n) => n + 1);
        aggiorna();
      }
      nascostaDal = 0;
    };
    const onVis = () => (document.visibilityState === 'hidden' ? via() : torna());
    document.addEventListener('visibilitychange', onVis);
    const h = CapApp.addListener('appStateChange', ({ isActive }) => (isActive ? torna() : via()));
    return () => { document.removeEventListener('visibilitychange', onVis); h.then((x) => x.remove()); };
  }, [aggiorna]);

  // tasto "indietro" di Android
  useEffect(() => {
    const h = CapApp.addListener('backButton', () => {
      setPila((p) => {
        if (p.length > 1) return p.slice(0, -1);
        if (!(p[0].tipo === 'tab' && p[0].tab === 'partenze')) return [{ tipo: 'tab', tab: 'home' }];
        CapApp.exitApp();
        return p;
      });
    });
    return () => { h.then((x) => x.remove()); };
  }, []);

  const scegliCasa = (id: number) => { setFermataCasa(id); localStorage.setItem(FERMATA_KEY, String(id)); };

  const cima = pila[pila.length - 1];
  const tabAttivo: Tab = pila[0].tipo === 'tab' ? pila[0].tab : 'home';

  let contenuto: JSX.Element;
  switch (cima.tipo) {
    case 'linea': contenuto = <LineaView orario={orario} id={cima.id} nav={nav} />; break;
    case 'corsa': contenuto = <CorsaView orario={orario} codice={cima.codice} giorno={cima.giorno} nav={nav} />; break;
    case 'categoria': contenuto = <Linee orario={orario} nav={nav} soloExtraurbano />; break;
    case 'vicine': contenuto = <Vicine orario={orario} nav={nav} />; break;
    case 'galleria': contenuto = <Galleria orario={orario} nav={nav} />; break;
    case 'territorio': contenuto = <Territorio orario={orario} nav={nav} />; break;
    case 'assistente': contenuto = <Assistente orario={orario} nav={nav} />; break;
    case 'segnalazione': contenuto = <SegnalazioneView orario={orario} nav={nav} />; break;
    case 'novita': contenuto = <NovitaView orario={orario} nav={nav} />; break;
    case 'servizio': contenuto = <Servizio id={cima.id} nav={nav} />; break;
    case 'preventivo': contenuto = <Preventivo nav={nav} />; break;
    case 'fermata': contenuto = <Partenze orario={orario} fermataId={cima.id} nav={nav} dettaglio onScegli={scegliCasa} casa={fermataCasa} />; break;
    default:
      switch (cima.tab) {
        case 'linee': contenuto = <Linee orario={orario} nav={nav} />; break;
        case 'partenze': contenuto = <Partenze orario={orario} fermataId={fermataCasa} nav={nav} onScegli={scegliCasa} casa={fermataCasa} />; break;
        case 'viaggio': contenuto = <Viaggio orario={orario} nav={nav} />; break;
        case 'mappa': contenuto = <Mappa orario={orario} nav={nav} />; break;
        case 'info': contenuto = <Info orario={orario} stato={stato} onAggiorna={aggiorna} nav={nav} />; break;
        default: contenuto = <Home orario={orario} nav={nav} casa={fermataCasa} />;
      }
  }

  return (
    <div className="app">
      <main className="schermo" key={JSON.stringify(cima) + ripresa}>{contenuto}</main>
      {cima.tipo === 'tab' && cima.tab !== 'mappa' && <BottoneAssistente onApri={() => nav.apri({ tipo: 'assistente' })} />}
      <TabBar attivo={tabAttivo} onCambia={(tab) => nav.apri({ tipo: 'tab', tab })} />
    </div>
  );
}

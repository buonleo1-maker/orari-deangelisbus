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

export type Schermata =
  | { tipo: 'tab'; tab: Tab }
  | { tipo: 'linea'; id: string }
  | { tipo: 'corsa'; codice: string; giorno: string }
  | { tipo: 'fermata'; id: number }
  | { tipo: 'preventivo' };

export interface Nav {
  apri: (s: Schermata) => void;
  indietro: () => void;
}

const FERMATA_KEY = 'fermata_preferita';

export default function App() {
  const [dati, setDati] = useState<Dati>(datiIniziali);
  const [stato, setStato] = useState<'pronto' | 'aggiorno' | 'offline'>('aggiorno');
  const [pila, setPila] = useState<Schermata[]>([{ tipo: 'tab', tab: 'partenze' }]);
  const [fermataCasa, setFermataCasa] = useState<number | null>(() => {
    const v = localStorage.getItem(FERMATA_KEY);
    return v ? Number(v) : null;
  });

  const orario = useMemo(() => new Orario(dati), [dati]);

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

  // tasto "indietro" di Android
  useEffect(() => {
    const h = CapApp.addListener('backButton', () => {
      setPila((p) => {
        if (p.length > 1) return p.slice(0, -1);
        if (!(p[0].tipo === 'tab' && p[0].tab === 'partenze')) return [{ tipo: 'tab', tab: 'partenze' }];
        CapApp.exitApp();
        return p;
      });
    });
    return () => { h.then((x) => x.remove()); };
  }, []);

  const scegliCasa = (id: number) => { setFermataCasa(id); localStorage.setItem(FERMATA_KEY, String(id)); };

  const cima = pila[pila.length - 1];
  const tabAttivo: Tab = pila[0].tipo === 'tab' ? pila[0].tab : 'partenze';

  let contenuto: JSX.Element;
  switch (cima.tipo) {
    case 'linea': contenuto = <LineaView orario={orario} id={cima.id} nav={nav} />; break;
    case 'corsa': contenuto = <CorsaView orario={orario} codice={cima.codice} giorno={cima.giorno} nav={nav} />; break;
    case 'preventivo': contenuto = <Preventivo nav={nav} />; break;
    case 'fermata': contenuto = <Partenze orario={orario} fermataId={cima.id} nav={nav} dettaglio onScegli={scegliCasa} casa={fermataCasa} />; break;
    default:
      switch (cima.tab) {
        case 'linee': contenuto = <Linee orario={orario} nav={nav} />; break;
        case 'viaggio': contenuto = <Viaggio orario={orario} nav={nav} />; break;
        case 'mappa': contenuto = <Mappa orario={orario} nav={nav} />; break;
        case 'info': contenuto = <Info orario={orario} stato={stato} onAggiorna={aggiorna} nav={nav} />; break;
        default: contenuto = <Partenze orario={orario} fermataId={fermataCasa} nav={nav} onScegli={scegliCasa} casa={fermataCasa} />;
      }
  }

  return (
    <div className="app">
      <main className="schermo" key={JSON.stringify(cima)}>{contenuto}</main>
      <TabBar attivo={tabAttivo} onCambia={(tab) => nav.apri({ tipo: 'tab', tab })} />
    </div>
  );
}

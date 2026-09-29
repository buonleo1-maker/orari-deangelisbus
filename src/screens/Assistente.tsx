import { useEffect, useMemo, useRef, useState } from 'react';
import type { Nav } from '../App';
import Testata from '../components/Testata';
import { adesso, contestoOrari } from '../lib/contesto';
import type { Orario } from '../lib/schedule';

interface Messaggio { ruolo: 'utente' | 'assistente'; testo: string }

const SUGGERIMENTI = [
  'Quando passa il prossimo bus da Grottole per Miglionico?',
  'Come installo l\u2019app sul telefono?',
  'Dove compro i biglietti?',
  'Come chiedo un preventivo per un noleggio?',
];
const CHIAVE = 'assistente_conversazione';

export default function Assistente({ orario, nav }: { orario: Orario; nav: Nav }) {
  const [msg, setMsg] = useState<Messaggio[]>(() => {
    try { return JSON.parse(sessionStorage.getItem(CHIAVE) ?? '[]') as Messaggio[]; } catch { return []; }
  });
  const [testo, setTesto] = useState('');
  const [attesa, setAttesa] = useState(false);
  const fondo = useRef<HTMLDivElement>(null);
  const contesto = useMemo(() => contestoOrari(orario), [orario]);

  useEffect(() => {
    try { sessionStorage.setItem(CHIAVE, JSON.stringify(msg.slice(-20))); } catch { /* ignora */ }
    fondo.current?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }, [msg, attesa]);

  const nuovaConversazione = () => {
    setMsg([]); setTesto('');
    try { sessionStorage.removeItem(CHIAVE); } catch { /* ignora */ }
  };

  const chiedi = async (domanda: string) => {
    const d = domanda.trim();
    if (!d || attesa) return;
    const nuovi: Messaggio[] = [...msg, { ruolo: 'utente', testo: d.slice(0, 800) }];
    setMsg(nuovi); setTesto(''); setAttesa(true);
    try {
      const r = await fetch('/api/assistente', {
        method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ messaggi: nuovi.slice(-12), contesto, adesso: adesso() }),
      });
      const j = await r.json().catch(() => ({}));
      setMsg([...nuovi, { ruolo: 'assistente', testo: j.risposta ?? 'Al momento non riesco a rispondere. Riprova tra poco oppure chiama lo 0835 758126.' }]);
    } catch {
      setMsg([...nuovi, { ruolo: 'assistente', testo: 'Sembra che tu sia offline. Gli orari restano consultabili nelle schede Partenze, Linee e Da – a.' }]);
    }
    setAttesa(false);
  };

  return (
    <div className="chat-pagina">
      <Testata titolo="Assistente virtuale" sotto="Chiedimi orari, fermate, biglietti o come usare l'app" onIndietro={nav.indietro} />
      <div className="chat-lista" aria-live="polite">
        {msg.length === 0 && (
          <div className="chat-benvenuto">
            <p><strong>Ciao! Sono l'assistente dell'app Deangelisbus.</strong></p>
            <p>Posso aiutarti a trovare un orario, capire come funziona l'app o dove comprare i biglietti. Prova con una di queste domande:</p>
            <div className="chat-suggerimenti">
              {SUGGERIMENTI.map((s) => <button key={s} onClick={() => chiedi(s)}>{s}</button>)}
            </div>
          </div>
        )}
        {msg.map((m, i) => <div key={i} className={`bolla ${m.ruolo}`}>{m.testo}</div>)}
        {attesa && <div className="bolla assistente attesa" aria-label="Sto scrivendo"><span /><span /><span /></div>}
        <div ref={fondo} />
      </div>
      {msg.length > 0 && !attesa && (
        <div className="chat-comandi">
          <button onClick={nuovaConversazione}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 5v14M5 12h14" /></svg>
            Nuova domanda
          </button>
          <button onClick={nav.indietro}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" /></svg>
            Chiudi
          </button>
        </div>
      )}
      <p className="chat-nota">Risposte automatiche: in caso di dubbio controlla gli orari nell'app o chiama lo 0835 758126.</p>
      <form className="chat-invio" onSubmit={(e) => { e.preventDefault(); chiedi(testo); }}>
        <input value={testo} onChange={(e) => setTesto(e.target.value)} placeholder="Scrivi una domanda…" maxLength={800} aria-label="La tua domanda" />
        <button type="submit" disabled={!testo.trim() || attesa} aria-label="Invia">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12l16-8-6 16-2-7-8-1z" /></svg>
        </button>
      </form>
    </div>
  );
}

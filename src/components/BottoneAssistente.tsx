import { useRef, useState, type PointerEvent as EventoPuntatore } from 'react';

/**
 * Pulsante dell'assistente virtuale, con accanto il pulsante "Aggiorna" (scarica l'ultima versione dell'app).
 * Si puo' spostare trascinandolo (dito o mouse): la posizione resta memorizzata; doppio tocco = torna nell'angolo.
 */
const CHIAVE = 'assistente_pos_orari';
type Pos = { r: number; b: number } | null;

export default function BottoneAssistente({ onApri }: { onApri: () => void }) {
  const [pos, setPos] = useState<Pos>(() => {
    try { const v = JSON.parse(localStorage.getItem(CHIAVE) || 'null'); return v && typeof v.r === 'number' ? v : null; } catch { return null; }
  });
  const [aggiorno, setAggiorno] = useState(false);
  const mosso = useRef(false);
  const gruppo = useRef<HTMLDivElement>(null);

  const inizia = (e: EventoPuntatore) => {
    if (e.button !== undefined && e.button !== 0) return;
    const el = gruppo.current; if (!el) return;
    const rect = el.getBoundingClientRect();
    const start = { x: e.clientX, y: e.clientY, r: window.innerWidth - rect.right, b: window.innerHeight - rect.bottom };
    mosso.current = false;
    const muovi = (ev: PointerEvent) => {
      const dx = ev.clientX - start.x, dy = ev.clientY - start.y;
      if (Math.abs(dx) + Math.abs(dy) > 6) mosso.current = true;
      if (!mosso.current) return;
      const r = Math.min(Math.max(start.r - dx, 4), window.innerWidth - rect.width - 4);
      const b = Math.min(Math.max(start.b - dy, 4), window.innerHeight - rect.height - 4);
      setPos({ r, b });
    };
    const fine = () => {
      window.removeEventListener('pointermove', muovi); window.removeEventListener('pointerup', fine);
      setPos((p) => { try { if (p) localStorage.setItem(CHIAVE, JSON.stringify(p)); } catch { /* */ } return p; });
    };
    window.addEventListener('pointermove', muovi); window.addEventListener('pointerup', fine);
  };

  const aggiorna = async () => {
    setAggiorno(true);
    try {
      if ('serviceWorker' in navigator) {
        const regs = await navigator.serviceWorker.getRegistrations();
        await Promise.all(regs.map((r) => r.update().catch(() => undefined)));
      }
      if ('caches' in window) { const k = await caches.keys(); await Promise.all(k.map((x) => caches.delete(x))); }
    } catch { /* si ricarica comunque */ }
    const u = new URL(window.location.href); u.searchParams.set('agg', String(Date.now()));
    window.location.replace(u.toString());
  };

  return (
    <div ref={gruppo} className="fab-gruppo" style={pos ? { right: pos.r, bottom: pos.b } : undefined}>
      <button className="fab-aggiorna" onClick={aggiorna} disabled={aggiorno} aria-label="Aggiorna l'app all'ultima versione" title="Aggiorna l'app">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" className={aggiorno ? 'gira' : ''}>
          <path d="M21 12a9 9 0 1 1-2.64-6.36" /><path d="M21 3v6h-6" />
        </svg>
      </button>
      <button className="fab-assistente" onPointerDown={inizia}
        onClick={() => { if (!mosso.current) onApri(); mosso.current = false; }}
        onDoubleClick={() => { setPos(null); try { localStorage.removeItem(CHIAVE); } catch { /* */ } }}
        aria-label="Apri l'assistente virtuale (trascina per spostarlo)" style={{ touchAction: 'none' }}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /><path d="M8 9h8M8 13h5" />
        </svg>
        <span>Assistente</span>
      </button>
    </div>
  );
}

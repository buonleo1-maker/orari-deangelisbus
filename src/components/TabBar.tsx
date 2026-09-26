export type Tab = 'home' | 'partenze' | 'linee' | 'viaggio' | 'mappa' | 'info';

const VOCI: { tab: Tab; label: string; icona: JSX.Element }[] = [
  { tab: 'home', label: 'Home', icona: <path d="M4 11l8-7 8 7v8a1 1 0 0 1-1 1h-4v-6H9v6H5a1 1 0 0 1-1-1v-8Z" /> },
  { tab: 'partenze', label: 'Partenze', icona: <path d="M12 3v11m0 0-4-4m4 4 4-4M5 20h14" /> },
  { tab: 'viaggio', label: 'Da – a', icona: <path d="M6 4v10a4 4 0 0 0 4 4h8m0 0-3-3m3 3-3 3M6 4 3 7m3-3 3 3" /> },
  { tab: 'mappa', label: 'Mappa', icona: <path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2Zm0 0v14m6-12v14" /> },
  { tab: 'info', label: 'Info', icona: <path d="M12 8h.01M11 12h1v5h1M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18Z" /> },
];

export default function TabBar({ attivo, onCambia }: { attivo: Tab; onCambia: (t: Tab) => void }) {
  return (
    <nav className="tabbar" aria-label="Sezioni">
      {VOCI.map((v) => (
        <button key={v.tab} className={v.tab === attivo ? 'tab attivo' : 'tab'}
          aria-current={v.tab === attivo ? 'page' : undefined} onClick={() => onCambia(v.tab)}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{v.icona}</svg>
          <span>{v.label}</span>
        </button>
      ))}
    </nav>
  );
}

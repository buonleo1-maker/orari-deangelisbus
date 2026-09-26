import type { ReactNode } from 'react';
import Logo from './Logo';

export default function Testata({ titolo, sotto, onIndietro, colore, children, conLogo }: {
  titolo: string; sotto?: string; onIndietro?: () => void; colore?: string | null; children?: ReactNode;
  /** Mostra il logo al posto del titolo (il titolo resta per i lettori di schermo). */
  conLogo?: boolean;
}) {
  return (
    <header className={conLogo ? 'testata con-logo' : 'testata'} style={colore ? { borderBottomColor: colore } : undefined}>
      {onIndietro && (
        <button className="indietro" onClick={onIndietro} aria-label="Indietro">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 5l-7 7 7 7" /></svg>
        </button>
      )}
      <div className="testata-testo">
        {conLogo ? (
          <>
            <h1 className="nascosto">{titolo}</h1>
            <Logo variante="chiaro" />
            <p>{titolo}</p>
          </>
        ) : (
          <>
            <h1>{titolo}</h1>
            {sotto && <p>{sotto}</p>}
          </>
        )}
      </div>
      {children}
    </header>
  );
}

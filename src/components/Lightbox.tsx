import { useEffect } from 'react';
import { urlFoto } from '../lib/foto';
import type { Foto } from '../lib/types';

/** Foto a tutto schermo, con didascalia, crediti e frecce per scorrere. */
export default function Lightbox({ foto, indice, onCambia, onChiudi }: { foto: Foto[]; indice: number; onCambia: (i: number) => void; onChiudi: () => void }) {
  const f = foto[indice];
  useEffect(() => {
    const tasto = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onChiudi();
      if (e.key === 'ArrowRight') onCambia((indice + 1) % foto.length);
      if (e.key === 'ArrowLeft') onCambia((indice - 1 + foto.length) % foto.length);
    };
    window.addEventListener('keydown', tasto);
    return () => window.removeEventListener('keydown', tasto);
  }, [indice, foto.length, onCambia, onChiudi]);
  if (!f) return null;
  return (
    <div className="lightbox" role="dialog" aria-modal="true" onClick={onChiudi}>
      <button className="lb-chiudi" onClick={onChiudi} aria-label="Chiudi">✕</button>
      <img src={urlFoto(f)} alt={f.didascalia ?? ''} onClick={(e) => e.stopPropagation()} />
      <div className="lb-testo" onClick={(e) => e.stopPropagation()}>
        {f.didascalia && <strong>{f.didascalia}</strong>}
        {f.crediti && <span>Foto: {f.crediti}</span>}
      </div>
      {foto.length > 1 && (
        <>
          <button className="lb-freccia sx" aria-label="Foto precedente" onClick={(e) => { e.stopPropagation(); onCambia((indice - 1 + foto.length) % foto.length); }}>‹</button>
          <button className="lb-freccia dx" aria-label="Foto successiva" onClick={(e) => { e.stopPropagation(); onCambia((indice + 1) % foto.length); }}>›</button>
        </>
      )}
    </div>
  );
}

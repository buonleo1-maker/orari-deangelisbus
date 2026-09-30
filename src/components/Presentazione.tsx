import { useEffect, useRef, useState } from 'react';
import { URL_MUSICA, urlFoto } from '../lib/foto';
import type { Foto } from '../lib/types';

/** Presentazione a tutto schermo: le foto scorrono da sole, con musica di sottofondo se presente. */
export default function Presentazione({ foto, onChiudi }: { foto: Foto[]; onChiudi: () => void }) {
  const [i, setI] = useState(0);
  const [pausa, setPausa] = useState(false);
  const [musica, setMusica] = useState(true);
  const audio = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    const a = new Audio(URL_MUSICA);
    a.loop = true; a.volume = 0.6;
    a.play().catch(() => setMusica(false)); // nessun brano caricato o riproduzione non consentita
    audio.current = a;
    return () => { a.pause(); a.src = ''; };
  }, []);
  useEffect(() => { if (audio.current) { if (musica && !pausa) audio.current.play().catch(() => undefined); else audio.current.pause(); } }, [musica, pausa]);
  useEffect(() => {
    if (pausa) return;
    const t = setTimeout(() => setI((x) => (x + 1) % foto.length), 5000);
    return () => clearTimeout(t);
  }, [i, pausa, foto.length]);

  const f = foto[i];
  return (
    <div className="presentazione" role="dialog" aria-modal="true">
      {foto.map((x, k) => (
        <img key={x.id} src={urlFoto(x)} alt={x.didascalia ?? ''} className={k === i ? 'visibile' : ''} />
      ))}
      <div className="pr-testo">
        {f?.didascalia && <strong>{f.didascalia}</strong>}
        <span>{i + 1} / {foto.length}{f?.crediti ? ` · Foto: ${f.crediti}` : ''}</span>
      </div>
      <div className="pr-comandi">
        <button onClick={() => setI((i - 1 + foto.length) % foto.length)} aria-label="Foto precedente"><Icona d="M15 5l-7 7 7 7" /></button>
        <button onClick={() => setPausa((p) => !p)} aria-label={pausa ? 'Riprendi' : 'Pausa'}>{pausa ? <Icona d="M8 5v14l11-7z" pieno /> : <Icona d="M8 5v14M16 5v14" />}</button>
        <button onClick={() => setI((i + 1) % foto.length)} aria-label="Foto successiva"><Icona d="M9 5l7 7-7 7" /></button>
        <button onClick={() => setMusica((m) => !m)} aria-label={musica ? 'Togli la musica' : 'Metti la musica'}>
          {musica ? <Icona d="M11 5L6 9H3v6h3l5 4zM15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13" /> : <Icona d="M11 5L6 9H3v6h3l5 4zM16 9l6 6M22 9l-6 6" />}
        </button>
        <button onClick={onChiudi} aria-label="Chiudi"><Icona d="M6 6l12 12M18 6L6 18" /></button>
      </div>
    </div>
  );
}

function Icona({ d, pieno }: { d: string; pieno?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" width="24" height="24" fill={pieno ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={d} /></svg>
  );
}

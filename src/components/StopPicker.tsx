import { useMemo, useState } from 'react';
import type { Orario } from '../lib/schedule';

export default function StopPicker({ orario, titolo, onScegli, onChiudi }: {
  orario: Orario; titolo: string; onScegli: (id: number) => void; onChiudi: () => void;
}) {
  const [q, setQ] = useState('');
  const gruppi = useMemo(() => {
    const t = q.trim().toLowerCase();
    const lista = orario.fermateServite().filter((f) =>
      !t || f.nome.toLowerCase().includes(t) || f.comune.toLowerCase().includes(t));
    const g = new Map<string, typeof lista>();
    lista.forEach((f) => { if (!g.has(f.comune)) g.set(f.comune, []); g.get(f.comune)!.push(f); });
    return [...g.entries()];
  }, [orario, q]);

  return (
    <div className="foglio" role="dialog" aria-modal="true" aria-label={titolo}>
      <div className="foglio-testa">
        <h2>{titolo}</h2>
        <button className="link" onClick={onChiudi}>Chiudi</button>
      </div>
      <input className="cerca" autoFocus placeholder="Cerca paese o fermata" value={q}
        onChange={(e) => setQ(e.target.value)} />
      <div className="foglio-lista">
        {gruppi.length === 0 && <p className="vuoto">Nessuna fermata trovata. Prova con il nome del paese.</p>}
        {gruppi.map(([comune, fs]) => (
          <section key={comune}>
            <h3 className="gruppo">{comune}</h3>
            {fs.map((f) => (
              <button key={f.id} className="riga-fermata" onClick={() => onScegli(f.id)}>
                <span>{f.nome}</span>
                <span className="pallini">
                  {orario.lineeDellaFermata(f.id).map((l) => <i key={l.id} style={{ background: l.colore ?? undefined }} />)}
                </span>
              </button>
            ))}
          </section>
        ))}
      </div>
    </div>
  );
}

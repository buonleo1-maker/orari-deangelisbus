import type { Nav } from '../App';
import LinkSito from '../components/LinkSito';
import Testata from '../components/Testata';
import type { Orario } from '../lib/schedule';
import type { Categoria } from '../lib/types';

const TITOLI: Record<Categoria, string> = {
  extraurbano: 'Linee extraurbane', urbano: 'Servizi urbani', scolastico: 'Trasporto scolastico', navetta: 'Navette aeroporto',
};

export default function Linee({ orario, nav }: { orario: Orario; nav: Nav }) {
  const linee = orario.lineeOrdinate();
  const cat = (Object.keys(TITOLI) as Categoria[]).filter((c) => linee.some((l) => l.categoria === c));
  return (
    <>
      <Testata titolo="Linee e servizi" conLogo />
      {cat.map((c) => (
        <section key={c} className="sezione">
          <h2 className="gruppo">{TITOLI[c]}</h2>
          <ul className="elenco-linee">
            {linee.filter((l) => l.categoria === c).map((l) => {
              const attive = orario.d.corse.some((x) => x.linea_id === l.id && x.attiva);
              return (
                <li key={l.id}>
                  <button onClick={() => nav.apri({ tipo: 'linea', id: l.id })}>
                    <i className="barra" style={{ background: l.colore ?? undefined }} />
                    <span className="nome">{l.nome}
                      <small>{[l.comune ?? (l.committente ? `Servizio ${l.committente}` : null), !attive ? 'orari in aggiornamento' : null].filter(Boolean).join(' – ')}</small>
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        </section>
      ))}
      <div className="sezione"><LinkSito /></div>
    </>
  );
}

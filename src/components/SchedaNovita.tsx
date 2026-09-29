import type { Novita } from '../lib/types';

const TIPO = { novita: 'Novità', evento: 'Evento', variazione: 'Variazione del servizio', viaggio: 'Viaggio di gruppo – Ridola Viaggi' } as const;
const fmt = new Intl.DateTimeFormat('it-IT', { weekday: 'long', day: 'numeric', month: 'long' });
const dataIt = (iso: string) => { const [y, m, d] = iso.slice(0, 10).split('-').map(Number); return fmt.format(new Date(y, m - 1, d)); };

export default function SchedaNovita({ n, breve }: { n: Novita; breve?: boolean }) {
  return (
    <article className={`novita novita-${n.tipo}`}>
      <span className="novita-tipo">{TIPO[n.tipo]}{n.data_evento ? ` – ${n.data_fine && n.data_fine !== n.data_evento ? `dal ${dataIt(n.data_evento)} al ${dataIt(n.data_fine)}` : dataIt(n.data_evento)}` : ''}</span>
      <h3>{n.titolo}</h3>
      {n.testo && <p className={breve ? 'novita-testo breve' : 'novita-testo'}>{n.testo}</p>}
      {!breve && n.link && <a className="link" href={n.link} target="_blank" rel="noreferrer">Scopri di più</a>}
    </article>
  );
}

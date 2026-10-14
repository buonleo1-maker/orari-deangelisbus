import type { Nav } from '../App';
import Installa from '../components/Installa';
import LinkBiglietti from '../components/LinkBiglietti';
import AttivaNotifiche from '../components/AttivaNotifiche';
import CondividiApp from '../components/CondividiApp';
import LinkSito from '../components/LinkSito';
import Logo from '../components/Logo';
import Testata from '../components/Testata';
import { onlineConfigurato } from '../lib/data';
import { oggi, type Orario } from '../lib/schedule';
import { useState } from 'react';

// testo in formato Markdown semplice -> elementi (titoli, elenchi, tabelle, grassetto)
function MdSemplice({ testo }: { testo: string }) {
  const inline = (s: string, k: number) => s.split(/(\*\*[^*]+\*\*|\*[^*]+\*)/g).filter(Boolean).map((p: string, i: number) =>
    p.startsWith('**') ? <strong key={k + '-' + i}>{p.slice(2, -2)}</strong>
      : p.startsWith('*') && p.length > 2 ? <em key={k + '-' + i}>{p.slice(1, -1)}</em> : <span key={k + '-' + i}>{p}</span>);
  const righe = String(testo || '').replace(/\r/g, '').split('\n');
  const out: JSX.Element[] = []; let i = 0, k = 0;
  while (i < righe.length) {
    const r = righe[i];
    if (!r.trim()) { i++; continue; }
    const h = r.match(/^(#{1,4})\s+(.*)$/);
    if (h) { const T = ('h' + Math.min(h[1].length + 1, 5)) as 'h2'; out.push(<T key={k++} style={{ fontWeight: 700, fontSize: h[1].length === 1 ? '1.25em' : h[1].length === 2 ? '1.1em' : '1em', margin: '1em 0 .4em' }}>{inline(h[2], k)}</T>); i++; continue; }
    if (r.trim().startsWith('|')) {
      const t: string[] = []; while (i < righe.length && righe[i].trim().startsWith('|')) { t.push(righe[i]); i++; }
      const celle = (l: string) => l.trim().replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
      const corpo = t.filter((l: string, j: number) => j !== 1 || !/^[\s|:-]+$/.test(l));
      out.push(<div key={k++} style={{ overflowX: 'auto', margin: '.5em 0' }}><table style={{ borderCollapse: 'collapse', width: '100%', fontSize: '.9em' }}><tbody>{corpo.map((l: string, j: number) => <tr key={j}>{celle(l).map((c: string, x: number) => j === 0 ? <th key={x} style={{ border: '1px solid #ccc', padding: '4px 6px', textAlign: 'left', background: '#f1f5f9' }}>{inline(c, k + j + x)}</th> : <td key={x} style={{ border: '1px solid #ccc', padding: '4px 6px', verticalAlign: 'top' }}>{inline(c, k + j + x)}</td>)}</tr>)}</tbody></table></div>);
      continue;
    }
    if (/^\s*[-•]\s+/.test(r)) {
      const v: string[] = []; while (i < righe.length && /^\s*[-•]\s+/.test(righe[i])) { v.push(righe[i].replace(/^\s*[-•]\s+/, '')); i++; }
      out.push(<ul key={k++} style={{ paddingLeft: '1.2em', margin: '.3em 0', listStyle: 'disc' }}>{v.map((x: string, j: number) => <li key={j} style={{ margin: '.15em 0' }}>{inline(x, k + j)}</li>)}</ul>);
      continue;
    }
    const p: string[] = []; while (i < righe.length && righe[i].trim() && !/^(#|\||\s*[-•]\s)/.test(righe[i])) { p.push(righe[i]); i++; }
    out.push(<p key={k++} style={{ margin: '.4em 0', lineHeight: 1.5 }}>{inline(p.join(' '), k)}</p>);
  }
  return <>{out}</>;
}

// politica aziendale e certificazione: letta dal gestionale (tabella manuali, slug politica-integrata-iso)
function Qualita() {
  const [testo, setTesto] = useState<string | null>(null);
  const [aperta, setAperta] = useState(false);
  const apri = async () => {
    const nuova = !aperta; setAperta(nuova);
    if (!nuova || testo !== null) return;
    try {
      const env = (import.meta as any).env || {};
      const r = await fetch(`${env.VITE_SUPABASE_URL}/rest/v1/manuali?slug=eq.politica-integrata-iso&select=contenuto`, { headers: { apikey: env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${env.VITE_SUPABASE_ANON_KEY}` } });
      const d = await r.json();
      setTesto(d?.[0]?.contenuto || 'La politica aziendale è disponibile su richiesta: scrivi a info@deangelisbus.it.');
    } catch { setTesto('Serve la connessione a internet per leggere la politica aziendale.'); }
  };
  return (
    <section className="sezione">
      <h2 className="gruppo">Qualità certificata</h2>
      <p className="testo">Sistema di gestione per la qualità certificato <strong>UNI EN ISO 9001:2015</strong> – certificato n. 026D-DAB-Q (SI Cert Italy) per trasporto pubblico locale, noleggio con conducente e trasporto scolastico con accompagnamento.</p>
      <button className="secondario" onClick={apri}>{aperta ? 'Chiudi la politica aziendale' : 'Leggi la nostra politica aziendale'}</button>
      {aperta && <div className="testo" style={{ marginTop: '.8em' }}>{testo === null ? 'Carico…' : <MdSemplice testo={testo} />}</div>}
    </section>
  );
}

const fmt = new Intl.DateTimeFormat('it-IT', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' });

export default function Info({ orario, stato, onAggiorna, nav }: {
  orario: Orario; stato: 'pronto' | 'aggiorno' | 'offline'; onAggiorna: () => void; nav: Nav;
}) {
  const avvisi = orario.avvisiAttivi(oggi());
  const agg = new Date(orario.d.generato);
  return (
    <>
      <Testata titolo="Informazioni" conLogo />
      <Installa />
      <button className="richiesta" onClick={() => nav.apri({ tipo: 'preventivo' })}>
        <strong>Richiedi un preventivo</strong>
        <span>Trasferimenti, noleggio con autista, gite di gruppo. Ti ricontattiamo noi.</span>
      </button>
      {avvisi.length > 0 && (
        <section className="sezione">
          <h2 className="gruppo">Avvisi</h2>
          {avvisi.map((a) => (
            <article key={a.id} className="avviso">
              <h3>{a.titolo}</h3>
              {a.testo && <p>{a.testo}</p>}
              {a.linea_id && <small>{orario.linee.get(a.linea_id)?.nome}</small>}
            </article>
          ))}
        </section>
      )}
      <button className="card-segnala" onClick={() => nav.apri({ tipo: 'segnalazione' })}>
        <strong>Feedback, reclami e segnalazioni</strong>
        <span>Un ritardo, un problema a bordo o un suggerimento? Scrivici.</span>
      </button>
      <LinkSito />
      <Qualita />
      <AttivaNotifiche />
      <CondividiApp />

      <section className="sezione contatti">
        <h2 className="gruppo">Contatti</h2>
        <a className="contatto" href="tel:+390835758126">Chiama 0835 758126<small>dal lunedì al venerdì, 8:30–13:30 e 15:30–19:00</small></a>
        <a className="contatto" href="mailto:info@deangelisbus.it">Scrivi a info@deangelisbus.it</a>
      </section>
      <section className="sezione">
        <h2 className="gruppo">Biglietti</h2>
        <LinkBiglietti />
        <p className="testo">Per le linee extraurbane Cotrab puoi comprare biglietti e abbonamenti online, con l'app Cotrab, nelle rivendite autorizzate o a bordo (con sovrapprezzo). Per la navetta per l'aeroporto di Bari i biglietti si comprano solo online su marozzivt.it.</p>
      </section>
      <section className="sezione">
        <h2 className="gruppo">Orari dell'app</h2>
        <p className="testo">
          {isNaN(agg.getTime()) ? 'Orari inclusi nell\u2019app.' : `Aggiornati il ${fmt.format(agg)}.`}{' '}
          {onlineConfigurato && stato === 'offline' && 'Sei offline: stai vedendo l\u2019ultima copia salvata.'}
          {!onlineConfigurato && 'Aggiornamento online non configurato.'}
        </p>
        <button className="secondario" disabled={stato === 'aggiorno'} onClick={onAggiorna}>
          {stato === 'aggiorno' ? 'Aggiornamento in corso' : 'Aggiorna orari'}
        </button>
        <p className="nota">Gli orari preceduti da ~ o "circa" sono stimati. Presentati alla fermata qualche minuto prima.</p>
      </section>

      <footer className="azienda">
        <Logo variante="scuro" dimensione="grande" motto />
        <p><strong>Deangelisbus S.r.l.</strong><br />C.so Umberto I, 28 – 75010 Grottole (MT)</p>
        <h3>Uffici</h3>
        <p>
          <a href="https://www.google.com/maps/search/?api=1&query=Via+degli+Arcioni+8+75010+Grottole+MT" target="_blank" rel="noreferrer">Via degli Arcioni, 8 – 75010 Grottole (MT)</a><br />
          <a href="https://www.google.com/maps/search/?api=1&query=Via+della+Tecnica+5+75100+Matera" target="_blank" rel="noreferrer">Via della Tecnica, 5 – 75100 Matera</a>
        </p>
        <p>Tel. <a href="tel:+390835758126">0835 758126</a> – <a href="https://www.deangelisbus.it" target="_blank" rel="noreferrer">www.deangelisbus.it</a></p>
        <p className="fiscale">P.IVA 01238100778 – SDI W7YVJK9</p>
      </footer>
    </>
  );
}

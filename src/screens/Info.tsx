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

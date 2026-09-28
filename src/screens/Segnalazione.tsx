import { useState } from 'react';
import type { Nav } from '../App';
import Testata from '../components/Testata';
import { inviaSegnalazione, type Segnalazione } from '../lib/data';
import type { Orario } from '../lib/schedule';

const TIPI: { v: Segnalazione['tipo']; label: string }[] = [
  { v: 'suggerimento', label: 'Suggerimento' },
  { v: 'segnalazione', label: 'Segnalazione' },
  { v: 'reclamo', label: 'Reclamo' },
  { v: 'complimento', label: 'Complimento' },
];

const vuota: Segnalazione = {
  tipo: 'segnalazione', linea_id: null, data_evento: null, ora_evento: null, luogo: null,
  messaggio: '', nome: null, email: null, telefono: null, consenso_privacy: false,
};

export default function SegnalazioneView({ orario, nav }: { orario: Orario; nav: Nav }) {
  const [s, setS] = useState<Segnalazione>(vuota);
  const [risposta, setRisposta] = useState(false);
  const [stato, setStato] = useState<'modulo' | 'invio' | 'inviata' | 'errore'>('modulo');
  const [errori, setErrori] = useState<string[]>([]);
  const set = <K extends keyof Segnalazione>(k: K, v: Segnalazione[K]) => setS((x) => ({ ...x, [k]: v }));

  const controlla = () => {
    const e: string[] = [];
    if (s.messaggio.trim().length < 5) e.push('Scrivi il messaggio (almeno qualche parola).');
    if (risposta) {
      if (!s.telefono?.trim() && !s.email?.trim()) e.push('Per ricevere una risposta indica telefono o email.');
      if (s.email && !/^\S+@\S+\.\S+$/.test(s.email)) e.push('L\u2019email non sembra corretta.');
      if (!s.consenso_privacy) e.push('Per usare i tuoi contatti serve il consenso al trattamento dei dati.');
    }
    setErrori(e);
    return e.length === 0;
  };

  const invia = async () => {
    if (!controlla()) return;
    setStato('invio');
    const pulita: Segnalazione = {
      ...s,
      messaggio: s.messaggio.trim(), luogo: s.luogo?.trim() || null,
      nome: risposta ? s.nome?.trim() || null : null,
      email: risposta ? s.email?.trim() || null : null,
      telefono: risposta ? s.telefono?.trim() || null : null,
      consenso_privacy: risposta ? s.consenso_privacy : false,
    };
    setStato((await inviaSegnalazione(pulita)) ? 'inviata' : 'errore');
  };

  const testoEmail = () => encodeURIComponent(
    `${TIPI.find((t) => t.v === s.tipo)?.label}\n` +
    (s.linea_id ? `Linea: ${orario.linee.get(s.linea_id)?.nome ?? s.linea_id}\n` : '') +
    (s.data_evento ? `Quando: ${s.data_evento} ${s.ora_evento ?? ''}\n` : '') +
    (s.luogo ? `Dove: ${s.luogo}\n` : '') + `\n${s.messaggio}\n`);

  if (stato === 'inviata') {
    return (
      <>
        <Testata titolo="Grazie!" onIndietro={nav.indietro} />
        <div className="conferma">
          <p><strong>Abbiamo ricevuto il tuo messaggio.</strong></p>
          <p>{risposta ? 'Ti ricontattiamo appena possibile negli orari d\u2019ufficio.' : 'Lo leggeremo con attenzione: ci aiuta a migliorare il servizio.'}</p>
          <button className="primario" onClick={nav.indietro}>Torna indietro</button>
        </div>
      </>
    );
  }

  return (
    <>
      <Testata titolo="Feedback, reclami e segnalazioni" sotto="Aiutaci a migliorare il servizio" onIndietro={nav.indietro} />
      <form className="modulo" onSubmit={(e) => { e.preventDefault(); invia(); }} noValidate>
        <fieldset>
          <legend>Di cosa si tratta?</legend>
          <div className="scelte">
            {TIPI.map((t) => (
              <label key={t.v} className={s.tipo === t.v ? 'scelta attiva' : 'scelta'}>
                <input type="radio" name="tipo" checked={s.tipo === t.v} onChange={() => set('tipo', t.v)} />{t.label}
              </label>
            ))}
          </div>
        </fieldset>

        <fieldset>
          <legend>Dettagli (facoltativi)</legend>
          <label>Linea o servizio
            <select value={s.linea_id ?? ''} onChange={(e) => set('linea_id', e.target.value || null)}>
              <option value="">— Non riguarda una linea precisa —</option>
              {orario.lineeOrdinate().map((l) => <option key={l.id} value={l.id}>{l.nome}</option>)}
            </select>
          </label>
          <div className="coppia">
            <label>Giorno<input type="date" value={s.data_evento ?? ''} onChange={(e) => set('data_evento', e.target.value || null)} /></label>
            <label>Ora<input type="time" value={s.ora_evento ?? ''} onChange={(e) => set('ora_evento', e.target.value || null)} /></label>
          </div>
          <label>Fermata o luogo<input value={s.luogo ?? ''} onChange={(e) => set('luogo', e.target.value)} placeholder="Es. Grottole, Via Nitti" /></label>
        </fieldset>

        <fieldset>
          <legend>Il tuo messaggio</legend>
          <label className="nascosto" htmlFor="msg">Messaggio</label>
          <textarea id="msg" rows={6} value={s.messaggio} onChange={(e) => set('messaggio', e.target.value)}
            placeholder="Raccontaci cosa è successo o cosa possiamo migliorare" />
        </fieldset>

        <fieldset>
          <label className="spunta"><input type="checkbox" checked={risposta} onChange={(e) => setRisposta(e.target.checked)} />Voglio essere ricontattato</label>
          {risposta && (
            <>
              <label>Nome<input autoComplete="name" value={s.nome ?? ''} onChange={(e) => set('nome', e.target.value)} /></label>
              <label>Telefono<input type="tel" autoComplete="tel" value={s.telefono ?? ''} onChange={(e) => set('telefono', e.target.value)} /></label>
              <label>Email<input type="email" autoComplete="email" value={s.email ?? ''} onChange={(e) => set('email', e.target.value)} /></label>
              <label className="spunta">
                <input type="checkbox" checked={s.consenso_privacy} onChange={(e) => set('consenso_privacy', e.target.checked)} />
                <span>Acconsento al trattamento dei miei dati da parte di Deangelisbus S.r.l. solo per rispondere a questo messaggio.{' '}
                  <a href="https://www.deangelisbus.it/privacy-policy/" target="_blank" rel="noreferrer">Informativa privacy</a></span>
              </label>
            </>
          )}
          {!risposta && <p className="nota" style={{ margin: 0 }}>Senza contatti il messaggio resta anonimo.</p>}
        </fieldset>

        {errori.length > 0 && <ul className="errori" role="alert">{errori.map((e) => <li key={e}>{e}</li>)}</ul>}
        {stato === 'errore' && (
          <div className="errori" role="alert">
            <p>Non siamo riusciti a inviare il messaggio: controlla la connessione e riprova.</p>
            <p>In alternativa puoi <a href={`mailto:info@deangelisbus.it?subject=Segnalazione%20dall%27app&body=${testoEmail()}`}>inviarlo per email</a> o chiamare lo 0835 758126.</p>
          </div>
        )}
        <button type="submit" className="primario pieno" disabled={stato === 'invio'}>{stato === 'invio' ? 'Invio in corso' : 'Invia'}</button>
      </form>
    </>
  );
}

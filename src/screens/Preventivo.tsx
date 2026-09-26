import { useState } from 'react';
import type { Nav } from '../App';
import Testata from '../components/Testata';
import { inviaRichiesta, type Richiesta } from '../lib/data';

const TIPI: { v: Richiesta['tipo']; label: string }[] = [
  { v: 'trasferimento', label: 'Trasferimento' },
  { v: 'noleggio', label: 'Noleggio con autista' },
  { v: 'gita', label: 'Gita o viaggio di gruppo' },
  { v: 'altro', label: 'Altro' },
];

const vuoto: Richiesta = {
  tipo: 'trasferimento', data_andata: null, ora_andata: null, partenza: '', destinazione: '',
  ritorno: false, data_ritorno: null, ora_ritorno: null, passeggeri: null,
  nome: '', telefono: '', email: null, note: null, consenso_privacy: false,
};

export default function Preventivo({ nav }: { nav: Nav }) {
  const [r, setR] = useState<Richiesta>(vuoto);
  const [stato, setStato] = useState<'modulo' | 'invio' | 'inviata' | 'errore'>('modulo');
  const [errori, setErrori] = useState<string[]>([]);
  const set = <K extends keyof Richiesta>(k: K, v: Richiesta[K]) => setR((x) => ({ ...x, [k]: v }));

  const controlla = () => {
    const e: string[] = [];
    if (r.partenza.trim().length < 2) e.push('Scrivi da dove si parte.');
    if (r.destinazione.trim().length < 2) e.push('Scrivi la destinazione.');
    if (!r.data_andata) e.push('Indica la data di partenza.');
    if (r.nome.trim().length < 2) e.push('Scrivi nome e cognome.');
    if (r.telefono.replace(/\D/g, '').length < 6) e.push('Scrivi un numero di telefono valido.');
    if (r.email && !/^\S+@\S+\.\S+$/.test(r.email)) e.push('L\u2019email non sembra corretta.');
    if (!r.consenso_privacy) e.push('Per inviare la richiesta serve il consenso al trattamento dei dati.');
    setErrori(e);
    return e.length === 0;
  };

  const invia = async () => {
    if (!controlla()) return;
    setStato('invio');
    const pulita: Richiesta = { ...r, partenza: r.partenza.trim(), destinazione: r.destinazione.trim(), nome: r.nome.trim(),
      telefono: r.telefono.trim(), email: r.email?.trim() || null, note: r.note?.trim() || null,
      data_ritorno: r.ritorno ? r.data_ritorno : null, ora_ritorno: r.ritorno ? r.ora_ritorno : null };
    setStato((await inviaRichiesta(pulita)) ? 'inviata' : 'errore');
  };

  const testoEmail = () => encodeURIComponent(
    `Richiesta di preventivo – ${TIPI.find((t) => t.v === r.tipo)?.label}\n` +
    `Partenza: ${r.partenza} il ${r.data_andata ?? ''} ${r.ora_andata ?? ''}\nDestinazione: ${r.destinazione}\n` +
    (r.ritorno ? `Ritorno: ${r.data_ritorno ?? ''} ${r.ora_ritorno ?? ''}\n` : 'Solo andata\n') +
    `Passeggeri: ${r.passeggeri ?? ''}\nNome: ${r.nome}\nTelefono: ${r.telefono}\n${r.note ? `Note: ${r.note}\n` : ''}`);

  if (stato === 'inviata') {
    return (
      <>
        <Testata titolo="Richiesta inviata" onIndietro={nav.indietro} />
        <div className="conferma">
          <p><strong>Grazie, {r.nome.split(' ')[0]}.</strong></p>
          <p>Abbiamo ricevuto la tua richiesta. Ti ricontattiamo al numero {r.telefono} negli orari d'ufficio: dal lunedì al venerdì, 8:30–13:30 e 15:30–19:00.</p>
          <button className="primario" onClick={nav.indietro}>Torna alle informazioni</button>
        </div>
      </>
    );
  }

  return (
    <>
      <Testata titolo="Richiedi un preventivo" sotto="Trasferimenti, noleggi e gite" onIndietro={nav.indietro} />
      <form className="modulo" onSubmit={(e) => { e.preventDefault(); invia(); }} noValidate>
        <fieldset>
          <legend>Che servizio ti serve?</legend>
          <div className="scelte">
            {TIPI.map((t) => (
              <label key={t.v} className={r.tipo === t.v ? 'scelta attiva' : 'scelta'}>
                <input type="radio" name="tipo" checked={r.tipo === t.v} onChange={() => set('tipo', t.v)} />{t.label}
              </label>
            ))}
          </div>
        </fieldset>

        <fieldset>
          <legend>Il viaggio</legend>
          <label>Partenza<input value={r.partenza} onChange={(e) => set('partenza', e.target.value)} placeholder="Es. Grottole, Piazza Vittoria" /></label>
          <label>Destinazione<input value={r.destinazione} onChange={(e) => set('destinazione', e.target.value)} placeholder="Es. Aeroporto di Bari" /></label>
          <div className="coppia">
            <label>Data<input type="date" value={r.data_andata ?? ''} onChange={(e) => set('data_andata', e.target.value || null)} /></label>
            <label>Ora<input type="time" value={r.ora_andata ?? ''} onChange={(e) => set('ora_andata', e.target.value || null)} /></label>
          </div>
          <label className="spunta"><input type="checkbox" checked={r.ritorno} onChange={(e) => set('ritorno', e.target.checked)} />Serve anche il ritorno</label>
          {r.ritorno && (
            <div className="coppia">
              <label>Data ritorno<input type="date" value={r.data_ritorno ?? ''} onChange={(e) => set('data_ritorno', e.target.value || null)} /></label>
              <label>Ora ritorno<input type="time" value={r.ora_ritorno ?? ''} onChange={(e) => set('ora_ritorno', e.target.value || null)} /></label>
            </div>
          )}
          <label>Numero di passeggeri<input type="number" inputMode="numeric" min={1} max={90} value={r.passeggeri ?? ''}
            onChange={(e) => set('passeggeri', e.target.value ? Math.min(90, Math.max(1, Number(e.target.value))) : null)} /></label>
          <label>Note<textarea rows={3} value={r.note ?? ''} onChange={(e) => set('note', e.target.value)} placeholder="Bagagli, soste, esigenze particolari" /></label>
        </fieldset>

        <fieldset>
          <legend>I tuoi contatti</legend>
          <label>Nome e cognome<input autoComplete="name" value={r.nome} onChange={(e) => set('nome', e.target.value)} /></label>
          <label>Telefono<input type="tel" autoComplete="tel" value={r.telefono} onChange={(e) => set('telefono', e.target.value)} /></label>
          <label>Email (facoltativa)<input type="email" autoComplete="email" value={r.email ?? ''} onChange={(e) => set('email', e.target.value)} /></label>
          <label className="spunta">
            <input type="checkbox" checked={r.consenso_privacy} onChange={(e) => set('consenso_privacy', e.target.checked)} />
            <span>Acconsento al trattamento dei miei dati da parte di Deangelisbus S.r.l. solo per rispondere a questa richiesta.{' '}
              <a href="https://www.deangelisbus.it/privacy-policy/" target="_blank" rel="noreferrer">Informativa privacy</a></span>
          </label>
        </fieldset>

        {errori.length > 0 && <ul className="errori" role="alert">{errori.map((e) => <li key={e}>{e}</li>)}</ul>}
        {stato === 'errore' && (
          <div className="errori" role="alert">
            <p>Non siamo riusciti a inviare la richiesta: controlla la connessione e riprova.</p>
            <p>In alternativa puoi <a href={`mailto:info@deangelisbus.it?subject=Richiesta%20preventivo&body=${testoEmail()}`}>inviarla per email</a> o chiamare lo 0835 758126.</p>
          </div>
        )}
        <button type="submit" className="primario pieno" disabled={stato === 'invio'}>
          {stato === 'invio' ? 'Invio in corso' : 'Invia richiesta'}
        </button>
      </form>
    </>
  );
}

import { useState } from 'react';
import type { Nav } from '../App';
import Testata from '../components/Testata';
import { inviaRichiesta, type Richiesta } from '../lib/data';

// Stessi campi, ordine e obbligatorietà del modulo "Richiedi un preventivo" di www.deangelisbus.it
const vuoto: Richiesta = {
  tipo: null, nome: '', cognome: '', azienda: null, telefono: '',
  data_andata: null, data_ritorno: null, ritorno: true, ora_andata: null, ora_ritorno: null,
  partenza: '', destinazione: '', passeggeri: null, email: '',
  itinerario: null, note: null, consenso_privacy: false,
};

export default function Preventivo({ nav }: { nav: Nav }) {
  const [r, setR] = useState<Richiesta>(vuoto);
  const [stato, setStato] = useState<'modulo' | 'invio' | 'inviata' | 'errore'>('modulo');
  const [errori, setErrori] = useState<string[]>([]);
  const set = <K extends keyof Richiesta>(k: K, v: Richiesta[K]) => setR((x) => ({ ...x, [k]: v }));

  const controlla = () => {
    const e: string[] = [];
    if (r.nome.trim().length < 2) e.push('Scrivi il nome.');
    if (r.cognome.trim().length < 2) e.push('Scrivi il cognome.');
    if (r.telefono.replace(/\D/g, '').length < 6) e.push('Scrivi un numero di telefono valido.');
    if (!r.data_andata) e.push('Indica la data di partenza.');
    if (!r.data_ritorno) e.push('Indica la data di rientro.');
    if (r.data_andata && r.data_ritorno && r.data_ritorno < r.data_andata) e.push('La data di rientro non può essere prima della partenza.');
    if (r.partenza.trim().length < 2) e.push('Scrivi il luogo di partenza.');
    if (r.destinazione.trim().length < 2) e.push('Scrivi il luogo di destinazione.');
    if (!r.email || !/^\S+@\S+\.\S+$/.test(r.email.trim())) e.push('Scrivi un recapito email valido.');
    if (!r.consenso_privacy) e.push('Per inviare la richiesta serve il consenso al trattamento dei dati personali.');
    setErrori(e);
    return e.length === 0;
  };

  const invia = async () => {
    if (!controlla()) return;
    setStato('invio');
    const pulita: Richiesta = {
      ...r,
      nome: r.nome.trim(), cognome: r.cognome.trim(), azienda: r.azienda?.trim() || null,
      telefono: r.telefono.trim(), partenza: r.partenza.trim(), destinazione: r.destinazione.trim(),
      email: r.email?.trim() || null, itinerario: r.itinerario?.trim() || null, note: r.note?.trim() || null,
      ritorno: Boolean(r.data_ritorno),
    };
    setStato((await inviaRichiesta(pulita)) ? 'inviata' : 'errore');
  };

  const testoEmail = () => encodeURIComponent(
    `Richiesta di preventivo\nNome: ${r.nome} ${r.cognome}\n${r.azienda ? `Azienda: ${r.azienda}\n` : ''}Telefono: ${r.telefono}\n` +
    `Partenza: ${r.partenza} il ${r.data_andata ?? ''}\nDestinazione: ${r.destinazione}\nRientro: ${r.data_ritorno ?? ''}\n` +
    `Partecipanti: ${r.passeggeri ?? ''}\n${r.itinerario ? `Itinerario: ${r.itinerario}\n` : ''}${r.note ? `Ulteriori informazioni: ${r.note}\n` : ''}`);

  if (stato === 'inviata') {
    return (
      <>
        <Testata titolo="Richiesta inviata" onIndietro={nav.indietro} />
        <div className="conferma">
          <p><strong>Grazie, {r.nome}.</strong></p>
          <p>Abbiamo ricevuto la tua richiesta di preventivo. Solitamente rispondiamo entro 48 ore; nei periodi di alta stagione potrebbe volerci un po' di più.</p>
          <p>Il preventivo non è vincolante: potrai decidere liberamente se accettarlo.</p>
          <button className="primario" onClick={nav.indietro}>Torna indietro</button>
        </div>
      </>
    );
  }

  return (
    <>
      <Testata titolo="Richiedi un preventivo" sotto="Noleggio bus, minibus e auto con conducente" onIndietro={nav.indietro} />
      <form className="modulo" onSubmit={(e) => { e.preventDefault(); invia(); }} noValidate>
        <p className="nota" style={{ margin: '12px 0 0' }}>I campi con * sono obbligatori.</p>
        <fieldset>
          <legend>I tuoi dati</legend>
          <div className="coppia">
            <label>Nome *<input autoComplete="given-name" value={r.nome} onChange={(e) => set('nome', e.target.value)} /></label>
            <label>Cognome *<input autoComplete="family-name" value={r.cognome} onChange={(e) => set('cognome', e.target.value)} /></label>
          </div>
          <label>Azienda<input autoComplete="organization" value={r.azienda ?? ''} onChange={(e) => set('azienda', e.target.value)} /></label>
          <label>Telefono *<input type="tel" autoComplete="tel" value={r.telefono} onChange={(e) => set('telefono', e.target.value)} /></label>
        </fieldset>

        <fieldset>
          <legend>Il viaggio</legend>
          <div className="coppia">
            <label>Data di partenza *<input type="date" value={r.data_andata ?? ''} onChange={(e) => set('data_andata', e.target.value || null)} /></label>
            <label>Data di rientro *<input type="date" value={r.data_ritorno ?? ''} min={r.data_andata ?? undefined} onChange={(e) => set('data_ritorno', e.target.value || null)} /></label>
          </div>
          <label>Luogo di partenza *<input value={r.partenza} onChange={(e) => set('partenza', e.target.value)} placeholder="Es. Grottole" /></label>
          <label>Luogo di destinazione *<input value={r.destinazione} onChange={(e) => set('destinazione', e.target.value)} placeholder="Es. Roma" /></label>
          <label>Numero di partecipanti<input type="number" inputMode="numeric" min={1} max={90} value={r.passeggeri ?? ''}
            onChange={(e) => set('passeggeri', e.target.value ? Math.min(90, Math.max(1, Number(e.target.value))) : null)} /></label>
          <label>Recapito email *<input type="email" autoComplete="email" value={r.email ?? ''} onChange={(e) => set('email', e.target.value)} /></label>
          <label>Itinerario<textarea rows={3} value={r.itinerario ?? ''} onChange={(e) => set('itinerario', e.target.value)} placeholder="Fermate intermedie, tappe, orari indicativi" /></label>
          <label>Ulteriori informazioni<textarea rows={3} value={r.note ?? ''} onChange={(e) => set('note', e.target.value)} placeholder="Bagagli, esigenze particolari, richieste speciali" /></label>
        </fieldset>

        <fieldset>
          <label className="spunta">
            <input type="checkbox" checked={r.consenso_privacy} onChange={(e) => set('consenso_privacy', e.target.checked)} />
            <span>Ho letto e acconsento al trattamento dei dati personali secondo l'{' '}
              <a href="https://www.deangelisbus.it/privacy-policy/" target="_blank" rel="noreferrer">informativa sulla privacy</a>.</span>
          </label>
        </fieldset>

        {errori.length > 0 && <ul className="errori" role="alert">{errori.map((e) => <li key={e}>{e}</li>)}</ul>}
        {stato === 'errore' && (
          <div className="errori" role="alert">
            <p>Non siamo riusciti a inviare la richiesta: controlla la connessione e riprova.</p>
            <p>In alternativa puoi <a href={`mailto:commerciale@deangelisbus.it?subject=Richiesta%20preventivo&body=${testoEmail()}`}>inviarla per email</a> o chiamare lo 0835 758126.</p>
          </div>
        )}
        <button type="submit" className="primario pieno" disabled={stato === 'invio'}>{stato === 'invio' ? 'Invio in corso' : 'Invia la richiesta'}</button>
      </form>
    </>
  );
}

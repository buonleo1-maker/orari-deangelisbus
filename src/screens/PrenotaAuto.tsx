import { useMemo, useState } from 'react';
import type { Nav } from '../App';
import Testata from '../components/Testata';
import { inviaPrenotazioneAuto, type PrenotazioneAuto } from '../lib/data';
import type { Orario } from '../lib/schedule';

type Servizio = PrenotazioneAuto['servizio'];

const vuota = (servizio: Servizio): PrenotazioneAuto => ({
  servizio, nome: '', cognome: '', telefono: '', email: null,
  per_altri: false, passeggero_nome: null, passeggero_telefono: null,
  data: null, ora: null, partenza: '', destinazione: '', corsa: null,
  attesa: servizio === 'visita_medica', ritorno: false, ora_ritorno: null,
  passeggeri: 1, bagagli: null, esigenze: null, note: null, consenso_privacy: false,
});

const oggiIso = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};

/**
 * Prenotazione di auto o minivan con conducente:
 * - ultimo miglio: dalla fermata del bus fino a casa, alla masseria, all'agriturismo;
 * - visita medica: da casa all'ospedale o allo studio, con attesa e ritorno.
 * La richiesta arriva nel gestionale (Prenotazioni auto), che ricontatta il cliente con il preventivo.
 */
export default function PrenotaAuto({ orario, nav, servizio: iniziale = 'ultimo_miglio' }: { orario: Orario; nav: Nav; servizio?: Servizio }) {
  const [p, setP] = useState<PrenotazioneAuto>(() => vuota(iniziale));
  const [stato, setStato] = useState<'modulo' | 'invio' | 'inviata' | 'errore'>('modulo');
  const [errori, setErrori] = useState<string[]>([]);
  const set = <K extends keyof PrenotazioneAuto>(k: K, v: PrenotazioneAuto[K]) => setP((x) => ({ ...x, [k]: v }));
  const visita = p.servizio === 'visita_medica';

  // Nomi delle fermate per i suggerimenti (ultimo miglio)
  const fermate = useMemo(() => {
    const nomi = new Set<string>();
    orario.d.fermate.forEach((f) => nomi.add(f.comune && !f.nome.toLowerCase().includes(f.comune.toLowerCase()) ? `${f.comune} – ${f.nome}` : f.nome));
    return [...nomi].sort((a, b) => a.localeCompare(b, 'it'));
  }, [orario]);

  const cambiaServizio = (s: Servizio) => {
    if (s === p.servizio) return;
    setP((x) => ({ ...vuota(s), nome: x.nome, cognome: x.cognome, telefono: x.telefono, email: x.email, data: x.data }));
    setErrori([]);
  };

  const controlla = () => {
    const e: string[] = [];
    if (p.nome.trim().length < 2) e.push('Scrivi il tuo nome.');
    if (p.cognome.trim().length < 2) e.push('Scrivi il tuo cognome.');
    if (p.telefono.replace(/\D/g, '').length < 6) e.push('Scrivi un numero di telefono valido.');
    if (p.email && !/^\S+@\S+\.\S+$/.test(p.email.trim())) e.push("L'indirizzo email non sembra corretto.");
    if (p.per_altri && (p.passeggero_nome ?? '').trim().length < 2) e.push('Scrivi nome e cognome della persona che viaggia.');
    if (!p.data) e.push('Indica la data.');
    else if (p.data < oggiIso()) e.push('La data non può essere già passata.');
    if (!p.ora) e.push(visita ? "Indica l'ora dell'appuntamento." : "Indica l'ora di arrivo del bus.");
    if (p.partenza.trim().length < 2) e.push(visita ? "Scrivi l'indirizzo da cui partire." : 'Scrivi la fermata in cui arrivi con il bus.');
    if (p.destinazione.trim().length < 2) e.push(visita ? "Scrivi l'ospedale o lo studio medico." : 'Scrivi dove vuoi andare.');
    if (!p.consenso_privacy) e.push('Per inviare la prenotazione serve il consenso al trattamento dei dati personali.');
    setErrori(e);
    return e.length === 0;
  };

  const invia = async () => {
    if (!controlla()) { window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' }); return; }
    setStato('invio');
    const t = (s: string | null) => (s ?? '').trim() || null;
    const pulita: PrenotazioneAuto = {
      ...p,
      nome: p.nome.trim(), cognome: p.cognome.trim(), telefono: p.telefono.trim(), email: t(p.email),
      passeggero_nome: p.per_altri ? t(p.passeggero_nome) : null,
      passeggero_telefono: p.per_altri ? t(p.passeggero_telefono) : null,
      partenza: p.partenza.trim(), destinazione: p.destinazione.trim(), corsa: visita ? null : t(p.corsa),
      attesa: visita ? p.attesa : false,
      ritorno: visita ? p.attesa || p.ritorno : p.ritorno,
      ora_ritorno: (visita && p.attesa) ? null : p.ritorno ? p.ora_ritorno : null,
      bagagli: visita ? null : p.bagagli, esigenze: t(p.esigenze), note: t(p.note),
    };
    setStato((await inviaPrenotazioneAuto(pulita)) ? 'inviata' : 'errore');
  };

  const testoEmail = () => encodeURIComponent(
    `Prenotazione ${visita ? 'accompagnamento visita medica' : 'ultimo miglio'}\nNome: ${p.nome} ${p.cognome}\nTelefono: ${p.telefono}\n` +
    `${p.per_altri ? `Passeggero: ${p.passeggero_nome ?? ''} ${p.passeggero_telefono ?? ''}\n` : ''}` +
    `Data: ${p.data ?? ''} ore ${p.ora ?? ''}\nDa: ${p.partenza}\nA: ${p.destinazione}\n${p.corsa ? `Corsa: ${p.corsa}\n` : ''}` +
    `Persone: ${p.passeggeri}\n${p.esigenze ? `Esigenze: ${p.esigenze}\n` : ''}${p.note ? `Note: ${p.note}\n` : ''}`);

  if (stato === 'inviata') {
    return (
      <>
        <Testata titolo="Prenotazione inviata" onIndietro={nav.indietro} />
        <div className="conferma">
          <p><strong>Grazie, {p.nome}.</strong></p>
          <p>Abbiamo ricevuto la tua richiesta. Ti chiameremo al numero <strong>{p.telefono}</strong> per confermare il servizio e comunicarti il prezzo.</p>
          <p>La prenotazione diventa definitiva solo dopo la nostra conferma. Per servizi urgenti chiama lo <a href="tel:0835758126">0835 758126</a>.</p>
          <button className="primario" onClick={nav.indietro}>Torna indietro</button>
        </div>
      </>
    );
  }

  return (
    <>
      <Testata titolo="Prenota auto o minivan" sotto="Con conducente, su prenotazione" onIndietro={nav.indietro} />

      <div className="interruttore" role="tablist" style={{ marginTop: 14 }}>
        <button role="tab" aria-selected={!visita} className={!visita ? 'attivo' : ''} onClick={() => cambiaServizio('ultimo_miglio')}>Dal bus a destinazione</button>
        <button role="tab" aria-selected={visita} className={visita ? 'attivo' : ''} onClick={() => cambiaServizio('visita_medica')}>Visita medica</button>
      </div>
      <p className="nota pa-intro">
        {visita
          ? 'Ti accompagniamo da casa all\u2019ospedale o allo studio medico. L\u2019autista può aspettarti e riportarti a casa. Puoi prenotare anche per un familiare.'
          : 'Arrivi in paese con il bus? Un\u2019auto o un minivan ti aspetta alla fermata e ti porta a casa, alla masseria, all\u2019agriturismo o dove il bus non arriva.'}
      </p>

      <form className="modulo" onSubmit={(e) => { e.preventDefault(); invia(); }} noValidate>
        <p className="nota" style={{ margin: '4px 0 0' }}>I campi con * sono obbligatori.</p>

        <fieldset>
          <legend>{visita ? 'La visita' : 'Il viaggio'}</legend>
          <div className="coppia">
            <label>Data *<input type="date" min={oggiIso()} value={p.data ?? ''} onChange={(e) => set('data', e.target.value || null)} /></label>
            <label>{visita ? 'Ora appuntamento *' : 'Arrivo del bus *'}<input type="time" value={p.ora ?? ''} onChange={(e) => set('ora', e.target.value || null)} /></label>
          </div>
          {visita ? (
            <>
              <label>Indirizzo di partenza *<input autoComplete="street-address" value={p.partenza} onChange={(e) => set('partenza', e.target.value)} placeholder="Es. Via Roma 10, Grottole" /></label>
              <label>Ospedale o studio medico *<input value={p.destinazione} onChange={(e) => set('destinazione', e.target.value)} placeholder="Es. Ospedale Madonna delle Grazie, Matera" /></label>
              <label className="spunta">
                <input type="checkbox" checked={p.attesa} onChange={(e) => set('attesa', e.target.checked)} />
                <span>L'autista mi aspetta e mi riporta a casa</span>
              </label>
              {!p.attesa && (
                <>
                  <label className="spunta">
                    <input type="checkbox" checked={p.ritorno} onChange={(e) => set('ritorno', e.target.checked)} />
                    <span>Mi serve anche il ritorno, più tardi</span>
                  </label>
                  {p.ritorno && <label>Ora del ritorno (indicativa)<input type="time" value={p.ora_ritorno ?? ''} onChange={(e) => set('ora_ritorno', e.target.value || null)} /></label>}
                </>
              )}
            </>
          ) : (
            <>
              <label>Fermata in cui arrivi *<input list="pa-fermate" value={p.partenza} onChange={(e) => set('partenza', e.target.value)} placeholder="Es. Miglionico – Piazza Castello" /></label>
              <datalist id="pa-fermate">{fermate.map((f) => <option key={f} value={f} />)}</datalist>
              <label>Con quale corsa<input value={p.corsa ?? ''} onChange={(e) => set('corsa', e.target.value)} placeholder="Es. bus da Matera delle 10:15" /></label>
              <label>Dove vuoi andare *<input value={p.destinazione} onChange={(e) => set('destinazione', e.target.value)} placeholder="Indirizzo, masseria, agriturismo…" /></label>
              <label className="spunta">
                <input type="checkbox" checked={p.ritorno} onChange={(e) => set('ritorno', e.target.checked)} />
                <span>Mi serve anche il ritorno alla fermata</span>
              </label>
              {p.ritorno && <label>Ora del ritorno (indicativa)<input type="time" value={p.ora_ritorno ?? ''} onChange={(e) => set('ora_ritorno', e.target.value || null)} /></label>}
            </>
          )}
          <div className="coppia">
            <label>Persone<input type="number" inputMode="numeric" min={1} max={8} value={p.passeggeri}
              onChange={(e) => set('passeggeri', Math.min(8, Math.max(1, Number(e.target.value) || 1)))} /></label>
            {!visita && <label>Bagagli<input type="number" inputMode="numeric" min={0} max={20} value={p.bagagli ?? ''}
              onChange={(e) => set('bagagli', e.target.value === '' ? null : Math.min(20, Math.max(0, Number(e.target.value))))} /></label>}
          </div>
          <label>Esigenze particolari<textarea rows={2} value={p.esigenze ?? ''} onChange={(e) => set('esigenze', e.target.value)}
            placeholder={visita ? 'Es. carrozzina pieghevole, deambulatore, viaggia con un accompagnatore' : 'Es. seggiolino per bambini, bici, animali'} /></label>
          {visita && <p className="nota">Non serve indicare il motivo della visita: ci bastano luogo e orario.</p>}
        </fieldset>

        <fieldset>
          <legend>I tuoi dati</legend>
          <div className="coppia">
            <label>Nome *<input autoComplete="given-name" value={p.nome} onChange={(e) => set('nome', e.target.value)} /></label>
            <label>Cognome *<input autoComplete="family-name" value={p.cognome} onChange={(e) => set('cognome', e.target.value)} /></label>
          </div>
          <label>Telefono *<input type="tel" autoComplete="tel" value={p.telefono} onChange={(e) => set('telefono', e.target.value)} /></label>
          <label>Email<input type="email" autoComplete="email" value={p.email ?? ''} onChange={(e) => set('email', e.target.value)} /></label>
          <label className="spunta">
            <input type="checkbox" checked={p.per_altri} onChange={(e) => set('per_altri', e.target.checked)} />
            <span>Prenoto per un'altra persona (es. un genitore)</span>
          </label>
          {p.per_altri && (
            <>
              <label>Nome e cognome di chi viaggia *<input value={p.passeggero_nome ?? ''} onChange={(e) => set('passeggero_nome', e.target.value)} /></label>
              <label>Telefono di chi viaggia<input type="tel" value={p.passeggero_telefono ?? ''} onChange={(e) => set('passeggero_telefono', e.target.value)} /></label>
            </>
          )}
          <label>Note<textarea rows={2} value={p.note ?? ''} onChange={(e) => set('note', e.target.value)} placeholder="Altre informazioni utili" /></label>
        </fieldset>

        <fieldset>
          <label className="spunta">
            <input type="checkbox" checked={p.consenso_privacy} onChange={(e) => set('consenso_privacy', e.target.checked)} />
            <span>Ho letto e acconsento al trattamento dei dati personali secondo l'{' '}
              <a href="https://www.deangelisbus.it/privacy-policy/" target="_blank" rel="noreferrer">informativa sulla privacy</a>.
              I dati servono solo a organizzare il servizio.</span>
          </label>
        </fieldset>

        <p className="nota">Ti ricontattiamo per confermare e comunicarti il prezzo: la prenotazione è definitiva solo dopo la nostra conferma.</p>

        {errori.length > 0 && <ul className="errori" role="alert">{errori.map((e) => <li key={e}>{e}</li>)}</ul>}
        {stato === 'errore' && (
          <div className="errori" role="alert">
            <p>Non siamo riusciti a inviare la prenotazione: controlla la connessione e riprova.</p>
            <p>In alternativa puoi <a href={`mailto:info@deangelisbus.it?subject=Prenotazione%20auto&body=${testoEmail()}`}>inviarla per email</a> o chiamare lo 0835 758126.</p>
          </div>
        )}
        <button type="submit" className="primario pieno" disabled={stato === 'invio'}>{stato === 'invio' ? 'Invio in corso' : 'Invia la prenotazione'}</button>
      </form>
    </>
  );
}

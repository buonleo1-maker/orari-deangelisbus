import { descriviGiorni, hhmm, isoData, type Orario } from './schedule';
import { PAESI } from './territorio';

const fmtGiorno = new Intl.DateTimeFormat('it-IT', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

/** Riassunto testuale di linee, corse, fermate, periodi e tariffe per l'assistente virtuale. */
export function contestoOrari(orario: Orario): string {
  const ora = new Date();
  const oggi = new Date(ora); oggi.setHours(0, 0, 0, 0);
  const domani = new Date(oggi); domani.setDate(domani.getDate() + 1);
  const righe: string[] = [];
  righe.push(`Dati del giorno: ${fmtGiorno.format(ora)}.`);
  righe.push('Formato corse: codice | giorni | [circola oggi? domani?] | fermata ora, fermata ora ... ("~" = orario stimato).');

  for (const l of orario.lineeOrdinate()) {
    const corse = orario.d.corse.filter((c) => c.linea_id === l.id && c.attiva)
      .sort((a, b) => a.direzione.localeCompare(b.direzione) || a.partenza.localeCompare(b.partenza));
    righe.push('');
    righe.push(`LINEA: ${l.nome} (${l.categoria}${l.comune ? `, ${l.comune}` : ''}${l.subappalto ? `, servizio ${l.committente ?? ''} svolto da Deangelisbus` : ''})`);
    if (l.info_pubblico) righe.push(`Info: ${l.info_pubblico}`);
    const periodi = orario.d.periodi.filter((p) => p.linea_id === l.id);
    const turni = periodi.filter((p) => p.solo_informativo);
    const limiti = periodi.filter((p) => !p.solo_informativo);
    if (limiti.length) righe.push(`Attiva solo nei periodi: ${limiti.map((p) => `${p.dal} → ${p.al}`).join('; ')}.`);
    if (turni.length && l.alternanza_con) righe.push(`Corse attive tutti i mesi con gli stessi orari. Mesi effettuati da Deangelisbus: ${turni.map((p) => `${p.dal} → ${p.al}`).join('; ')}; negli altri mesi le effettua ${l.alternanza_con} (consorzio Cotrab).`);
    if (!corse.length) { righe.push('Orari non ancora disponibili: contattare l\u2019ufficio.'); continue; }
    for (const c of corse) {
      const ps = orario.passaggi(c);
      const extra = [c.solo_giorni_scolastici && 'solo giorni di scuola', c.solo_giorni_non_scolastici && 'solo quando le scuole sono chiuse', c.stagionale && `stagionale ${c.stagionale}`, c.note].filter(Boolean).join(', ');
      const quando = `oggi ${orario.circola(c, oggi) ? 'sì' : 'no'}, domani ${orario.circola(c, domani) ? 'sì' : 'no'}`;
      righe.push(`- ${c.codice} | ${descriviGiorni(c.giorni)}${extra ? ` (${extra})` : ''} | [${quando}] | ` +
        ps.map((p) => `${p.fermata.comune} ${p.fermata.nome} ${p.confermato ? '' : '~'}${hhmm(p.minuto)}`).join(', '));
    }
    const cs = orario.tariffeLinea(l.id).filter((t) => t.tipo_codice === 1);
    if (cs.length) righe.push('Corsa semplice: ' + cs.map((t) => (t.da_zona === '*' ? `tariffa unica ${t.prezzo.toFixed(2)} €` : `${t.da_zona}-${t.a_zona} ${t.prezzo.toFixed(2)} €`)).join('; '));
    const abb = orario.tariffeLinea(l.id).filter((t) => t.tipo_codice === 3 && (t.da_zona === '*' || t.da_zona === 'GROTTOLE'));
    if (abb.length) righe.push('Abbonamento mensile: ' + abb.map((t) => (t.da_zona === '*' ? `${t.prezzo.toFixed(2)} €` : `${t.da_zona}-${t.a_zona} ${t.prezzo.toFixed(2)} €`)).join('; '));
  }

  const sosp = orario.d.sospensioni.filter((s) => s.al >= isoData(oggi));
  if (sosp.length) { righe.push(''); righe.push('SOSPENSIONI: ' + sosp.map((s) => `${s.dal} → ${s.al} ${s.ambito}${s.descrizione ? ` (${s.descrizione})` : ''}`).join('; ')); }
  const avvisi = orario.novitaVisibili(oggi).filter((n) => n.tipo !== 'viaggio');
  if (avvisi.length) { righe.push(''); righe.push('NOVITA E AVVISI: ' + avvisi.map((n) => `${n.titolo}${n.data_evento ? ` (${n.data_evento})` : ''}${n.testo ? `: ${n.testo}` : ''}`).join(' | ')); }
  righe.push('');
  righe.push('TERRITORIO (sezione "Scopri il territorio" in Home):');
  for (const p of PAESI) {
    const g = (orario.d.gusto ?? []).filter((x) => x.paese === p.id && x.visibile);
    const piatti = g.filter((x) => x.tipo === 'piatto').map((x) => x.nome).join(', ');
    const rist = g.filter((x) => x.tipo === 'ristorante').map((x) => `${x.nome}${x.indirizzo ? ` (${x.indirizzo})` : ''}`).join(', ');
    righe.push(`${p.nome} – ${p.motto}: ${p.luoghi.map((l) => `${l.nome} (${l.testo})`).join('; ')}${p.evento ? `. Evento: ${p.evento}` : ''}${piatti ? `. Piatti tipici: ${piatti}` : ''}${rist ? `. Ristoranti consigliati: ${rist}` : ''}`);
  }
  return righe.join('\n');
}

/** Giorno e ora attuali (inviati a parte, cosi' il resto del contesto resta uguale e costa meno). */
export function adesso(): string {
  const ora = new Date();
  return `Adesso: ${fmtGiorno.format(ora)}, ore ${hhmm(ora.getHours() * 60 + ora.getMinutes())}.`;
}

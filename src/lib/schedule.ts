import type { Corsa, Dati, Fermata, Linea, Passaggio, Tariffa } from './types';

export const oggi = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };
export const addGiorni = (d: Date, n: number) => { const x = new Date(d); x.setDate(x.getDate() + n); return x; };
export const isoData = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
export const isoDow = (d: Date) => ((d.getDay() + 6) % 7) + 1;
export const minutoAdesso = () => { const n = new Date(); return n.getHours() * 60 + n.getMinutes(); };
export const hhmm = (m: number) => {
  const x = ((m % 1440) + 1440) % 1440;
  return `${String(Math.floor(x / 60)).padStart(2, '0')}:${String(x % 60).padStart(2, '0')}`;
};
const minuti = (t: string) => { const [h, m] = t.split(':').map(Number); return h * 60 + m; };

export const GIORNI_BREVI = ['', 'lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];

export function descriviGiorni(g: number[]): string {
  const s = [...g].sort().join(',');
  if (s === '1,2,3,4,5,6,7') return 'tutti i giorni';
  if (s === '1,2,3,4,5,6') return 'dal lunedì al sabato';
  if (s === '1,2,3,4,5') return 'dal lunedì al venerdì';
  return g.map((x) => GIORNI_BREVI[x]).join(', ');
}

/** Indici veloci costruiti una volta per dataset. */
export class Orario {
  fermate = new Map<number, Fermata>();
  linee = new Map<string, Linea>();
  sequenze = new Map<string, { fermata_id: number; ordine: number; off: number; conf: boolean }[]>();

  constructor(public d: Dati) {
    d.fermate.forEach((f) => this.fermate.set(f.id, f));
    d.linee.forEach((l) => this.linee.set(l.id, l));
    const perP = new Map<string, typeof d.percorsi_fermate>();
    d.percorsi_fermate.forEach((pf) => {
      if (!perP.has(pf.percorso_id)) perP.set(pf.percorso_id, []);
      perP.get(pf.percorso_id)!.push(pf);
    });
    perP.forEach((lista, id) => {
      lista.sort((a, b) => a.ordine - b.ordine);
      this.sequenze.set(id, lista.map((pf) => ({
        fermata_id: pf.fermata_id, ordine: pf.ordine,
        off: pf.minuti ?? pf.minuti_stimati ?? 0,
        conf: pf.minuti != null || pf.ordine === 1,
      })));
    });
  }

  lineeOrdinate() {
    return [...this.d.linee].filter((l) => l.attiva !== false).sort((a, b) => a.ordine - b.ordine);
  }

  /** Stessa logica della funzione SQL orari_corsa_attiva. */
  circola(c: Corsa, giorno: Date): boolean {
    if (!c.attiva) return false;
    const data = isoData(giorno);
    if (!c.giorni.includes(isoDow(giorno))) return false;
    if (c.valido_dal && data < c.valido_dal) return false;
    if (c.valido_al && data > c.valido_al) return false;
    const periodi = this.d.periodi.filter((p) => p.linea_id === c.linea_id);
    if (periodi.length && !periodi.some((p) => data >= p.dal && data <= p.al)) return false;
    const sosp = this.d.sospensioni.filter((s) =>
      data >= s.dal && data <= s.al && (!s.linea_id || s.linea_id === c.linea_id));
    if (sosp.some((s) => s.ambito === 'tutti' || c.solo_giorni_scolastici)) return false;
    if (c.solo_giorni_non_scolastici && !sosp.some((s) => s.ambito === 'scolastico')) return false;
    return true;
  }

  passaggi(c: Corsa): Passaggio[] {
    const p0 = minuti(c.partenza);
    return (this.sequenze.get(c.percorso_id) ?? []).map((s) => ({
      fermata: this.fermate.get(s.fermata_id)!, ordine: s.ordine, minuto: p0 + s.off, confermato: s.conf,
    })).filter((p) => p.fermata);
  }

  corseDelGiorno(lineaId: string, direzione: 'A' | 'R', giorno: Date) {
    return this.d.corse
      .filter((c) => c.linea_id === lineaId && c.direzione === direzione && this.circola(c, giorno))
      .sort((a, b) => a.partenza.localeCompare(b.partenza));
  }

  /** Partenze da una fermata in un giorno (esclusi i capolinea di arrivo). */
  partenze(fermataId: number, giorno: Date) {
    const out: { corsa: Corsa; linea: Linea; passaggio: Passaggio; capolinea: Fermata }[] = [];
    for (const c of this.d.corse) {
      if (!this.circola(c, giorno)) continue;
      const ps = this.passaggi(c);
      const i = ps.findIndex((p) => p.fermata.id === fermataId);
      if (i < 0 || i === ps.length - 1) continue;
      const linea = this.linee.get(c.linea_id);
      if (!linea || linea.attiva === false) continue;
      out.push({ corsa: c, linea, passaggio: ps[i], capolinea: ps[ps.length - 1].fermata });
    }
    return out.sort((a, b) => a.passaggio.minuto - b.passaggio.minuto);
  }

  /** Corse che vanno da una fermata all'altra (nell'ordine giusto). */
  viaggi(daId: number, aId: number, giorno: Date) {
    const out: { corsa: Corsa; linea: Linea; da: Passaggio; a: Passaggio }[] = [];
    for (const c of this.d.corse) {
      if (!this.circola(c, giorno)) continue;
      const ps = this.passaggi(c);
      const i = ps.findIndex((p) => p.fermata.id === daId);
      const j = ps.findIndex((p, k) => k > i && p.fermata.id === aId);
      if (i < 0 || j < 0) continue;
      const linea = this.linee.get(c.linea_id);
      if (linea && linea.attiva !== false) out.push({ corsa: c, linea, da: ps[i], a: ps[j] });
    }
    return out.sort((a, b) => a.da.minuto - b.da.minuto);
  }

  tariffa(lineaId: string, da: Fermata, a: Fermata, tipo = 1): Tariffa | undefined {
    const t = this.d.tariffe.filter((x) => x.linea_id === lineaId && x.tipo_codice === tipo);
    const unica = t.find((x) => x.da_zona === '*');
    if (unica) return unica;
    if (!da.zona_tariffaria || !a.zona_tariffaria) return undefined;
    if (da.zona_tariffaria === a.zona_tariffaria) return undefined;
    return t.find((x) =>
      (x.da_zona === da.zona_tariffaria && x.a_zona === a.zona_tariffaria) ||
      (x.da_zona === a.zona_tariffaria && x.a_zona === da.zona_tariffaria));
  }

  tariffeLinea(lineaId: string) {
    return this.d.tariffe.filter((x) => x.linea_id === lineaId);
  }

  /** Fermate servite da almeno una corsa attiva. */
  fermateServite() {
    const usate = new Set<number>();
    this.d.corse.filter((c) => c.attiva).forEach((c) =>
      (this.sequenze.get(c.percorso_id) ?? []).forEach((s) => usate.add(s.fermata_id)));
    return this.d.fermate.filter((f) => usate.has(f.id))
      .sort((a, b) => a.comune.localeCompare(b.comune) || a.nome.localeCompare(b.nome));
  }

  lineeDellaFermata(fermataId: number) {
    const ids = new Set<string>();
    this.d.corse.forEach((c) => {
      if ((this.sequenze.get(c.percorso_id) ?? []).some((s) => s.fermata_id === fermataId)) ids.add(c.linea_id);
    });
    return [...ids].map((id) => this.linee.get(id)!).filter(Boolean);
  }

  novitaVisibili(giorno: Date) {
    const data = isoData(giorno);
    return (this.d.novita ?? [])
      .filter((n) => n.visibile_dal <= data && (!n.visibile_al || n.visibile_al >= data))
      .sort((a, b) => Number(b.in_evidenza) - Number(a.in_evidenza) || b.creato_il.localeCompare(a.creato_il));
  }

  /** Viaggi di gruppo Ridola Viaggi ancora da partire, dal più vicino. */
  viaggiInProgramma(giorno: Date) {
    const data = isoData(giorno);
    return this.novitaVisibili(giorno)
      .filter((n) => n.tipo === 'viaggio' && (!n.data_evento || n.data_evento >= data))
      .sort((a, b) => (a.data_evento ?? '9999').localeCompare(b.data_evento ?? '9999'));
  }

  avvisiAttivi(giorno: Date) {
    const data = isoData(giorno);
    return this.d.avvisi.filter((a) => (!a.dal || a.dal <= data) && (!a.al || a.al >= data));
  }
}

export const euro = (n: number) => n.toLocaleString('it-IT', { style: 'currency', currency: 'EUR' });
export const nomeFermata = (f: Fermata) => (f.nome.toLowerCase().startsWith(f.comune.toLowerCase()) ? f.nome : `${f.comune} – ${f.nome}`);

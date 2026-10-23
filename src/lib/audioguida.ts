import type { TappaAudioguida } from './types';

/** Audioguida GPS: lingue, testi dell'interfaccia e lettore (file mp3 oppure voce del telefono). */

export const LINGUE = [
  { id: 'it', nome: 'Italiano', voce: 'it-IT' },
  { id: 'en', nome: 'English', voce: 'en-GB' },
  { id: 'de', nome: 'Deutsch', voce: 'de-DE' },
  { id: 'fr', nome: 'Français', voce: 'fr-FR' },
  { id: 'es', nome: 'Español', voce: 'es-ES' },
] as const;
export type Lingua = (typeof LINGUE)[number]['id'];

export const PERCORSI: Record<string, { titolo: Record<Lingua, string> }> = {
  'panoramico-matera': {
    titolo: {
      it: 'Bus panoramico dei Sassi', en: 'Sassi panoramic bus', de: 'Panoramabus durch die Sassi',
      fr: 'Bus panoramique des Sassi', es: 'Autobús panorámico de los Sassi',
    },
  },
  'grottole-pisticci': {
    titolo: {
      it: 'Linea Grottole – Miglionico – Pisticci', en: 'Grottole – Miglionico – Pisticci line', de: 'Linie Grottole – Miglionico – Pisticci',
      fr: 'Ligne Grottole – Miglionico – Pisticci', es: 'Línea Grottole – Miglionico – Pisticci',
    },
  },
};

type Chiave =
  | 'titolo' | 'lingua' | 'avvia' | 'ferma' | 'pausa' | 'riprendi' | 'salta' | 'inAscolto' | 'tappe'
  | 'ascoltata' | 'tocca' | 'cercoGps' | 'gpsNegato' | 'gpsErrore' | 'consiglio' | 'automatico'
  | 'senzaVoce' | 'attiva' | 'attesa' | 'vuota' | 'collegamento' | 'ricomincia';

const T: Record<Lingua, Record<Chiave, string>> = {
  it: {
    titolo: 'Audioguida', lingua: 'Lingua', avvia: 'Avvia l\u2019audioguida', ferma: 'Ferma', pausa: 'Pausa', riprendi: 'Riprendi',
    salta: 'Salta', inAscolto: 'In ascolto', tappe: 'Le tappe', ascoltata: 'ascoltata', tocca: 'Tocca una tappa per ascoltarla subito.',
    cercoGps: 'Cerco la tua posizione\u2026', gpsNegato: 'Per far partire i racconti da soli serve il permesso alla posizione. Puoi comunque toccare le tappe per ascoltarle.',
    gpsErrore: 'Posizione non disponibile al momento. Puoi toccare le tappe per ascoltarle.',
    consiglio: 'Metti le cuffie e tieni lo schermo acceso con l\u2019app aperta.',
    automatico: 'Il racconto parte da solo quando il bus si avvicina a ogni luogo.',
    senzaVoce: 'Su questo telefono la lettura vocale non \u00e8 disponibile: il racconto compare qui sotto da leggere.',
    attiva: 'Audioguida attiva', attesa: 'In attesa del prossimo luogo\u2026', vuota: 'L\u2019audioguida \u00e8 in preparazione. Torna a trovarci presto!',
    collegamento: 'racconto', ricomincia: 'Ricomincia da capo',
  },
  en: {
    titolo: 'Audio guide', lingua: 'Language', avvia: 'Start the audio guide', ferma: 'Stop', pausa: 'Pause', riprendi: 'Resume',
    salta: 'Skip', inAscolto: 'Now playing', tappe: 'Stops', ascoltata: 'played', tocca: 'Tap a stop to listen to it now.',
    cercoGps: 'Finding your position\u2026', gpsNegato: 'Location permission is needed for the stories to start automatically. You can still tap the stops to listen.',
    gpsErrore: 'Location not available right now. You can tap the stops to listen.',
    consiglio: 'Put on your headphones and keep the screen on with the app open.',
    automatico: 'Each story starts by itself as the bus approaches the place.',
    senzaVoce: 'Voice reading is not available on this phone: the story is shown below to read.',
    attiva: 'Audio guide on', attesa: 'Waiting for the next place\u2026', vuota: 'The audio guide is being prepared. Come back soon!',
    collegamento: 'story', ricomincia: 'Start again',
  },
  de: {
    titolo: 'Audioguide', lingua: 'Sprache', avvia: 'Audioguide starten', ferma: 'Stopp', pausa: 'Pause', riprendi: 'Weiter',
    salta: '\u00dcberspringen', inAscolto: 'L\u00e4uft gerade', tappe: 'Stationen', ascoltata: 'geh\u00f6rt', tocca: 'Tippen Sie auf eine Station, um sie sofort zu h\u00f6ren.',
    cercoGps: 'Position wird gesucht\u2026', gpsNegato: 'Damit die Erz\u00e4hlungen automatisch starten, wird die Standortberechtigung ben\u00f6tigt. Sie k\u00f6nnen die Stationen auch antippen.',
    gpsErrore: 'Standort gerade nicht verf\u00fcgbar. Tippen Sie auf die Stationen, um sie zu h\u00f6ren.',
    consiglio: 'Setzen Sie Kopfh\u00f6rer auf und lassen Sie den Bildschirm mit ge\u00f6ffneter App an.',
    automatico: 'Jede Erz\u00e4hlung startet von selbst, wenn sich der Bus dem Ort n\u00e4hert.',
    senzaVoce: 'Die Sprachausgabe ist auf diesem Telefon nicht verf\u00fcgbar: Die Erz\u00e4hlung erscheint unten zum Lesen.',
    attiva: 'Audioguide aktiv', attesa: 'Warten auf den n\u00e4chsten Ort\u2026', vuota: 'Die Audioguide wird gerade vorbereitet. Schauen Sie bald wieder vorbei!',
    collegamento: 'Erz\u00e4hlung', ricomincia: 'Von vorne beginnen',
  },
  fr: {
    titolo: 'Audioguide', lingua: 'Langue', avvia: 'Lancer l\u2019audioguide', ferma: 'Arr\u00eater', pausa: 'Pause', riprendi: 'Reprendre',
    salta: 'Passer', inAscolto: 'En cours', tappe: '\u00c9tapes', ascoltata: '\u00e9cout\u00e9e', tocca: 'Touchez une \u00e9tape pour l\u2019\u00e9couter tout de suite.',
    cercoGps: 'Recherche de votre position\u2026', gpsNegato: 'L\u2019autorisation de localisation est n\u00e9cessaire pour que les r\u00e9cits d\u00e9marrent seuls. Vous pouvez aussi toucher les \u00e9tapes.',
    gpsErrore: 'Position indisponible pour le moment. Touchez les \u00e9tapes pour les \u00e9couter.',
    consiglio: 'Mettez vos \u00e9couteurs et gardez l\u2019\u00e9cran allum\u00e9 avec l\u2019application ouverte.',
    automatico: 'Chaque r\u00e9cit d\u00e9marre tout seul quand le bus approche du lieu.',
    senzaVoce: 'La lecture vocale n\u2019est pas disponible sur ce t\u00e9l\u00e9phone : le r\u00e9cit s\u2019affiche ci-dessous.',
    attiva: 'Audioguide activ\u00e9', attesa: 'En attente du prochain lieu\u2026', vuota: 'L\u2019audioguide est en pr\u00e9paration. Revenez bient\u00f4t !',
    collegamento: 'r\u00e9cit', ricomincia: 'Recommencer',
  },
  es: {
    titolo: 'Audiogu\u00eda', lingua: 'Idioma', avvia: 'Iniciar la audiogu\u00eda', ferma: 'Detener', pausa: 'Pausa', riprendi: 'Continuar',
    salta: 'Saltar', inAscolto: 'Reproduciendo', tappe: 'Paradas', ascoltata: 'escuchada', tocca: 'Toca una parada para escucharla ahora.',
    cercoGps: 'Buscando tu posici\u00f3n\u2026', gpsNegato: 'Se necesita el permiso de ubicaci\u00f3n para que los relatos empiecen solos. Tambi\u00e9n puedes tocar las paradas.',
    gpsErrore: 'Ubicaci\u00f3n no disponible ahora. Toca las paradas para escucharlas.',
    consiglio: 'Ponte los auriculares y mant\u00e9n la pantalla encendida con la app abierta.',
    automatico: 'Cada relato empieza solo cuando el autob\u00fas se acerca al lugar.',
    senzaVoce: 'La lectura por voz no est\u00e1 disponible en este tel\u00e9fono: el relato aparece abajo para leerlo.',
    attiva: 'Audiogu\u00eda activa', attesa: 'Esperando el pr\u00f3ximo lugar\u2026', vuota: 'La audiogu\u00eda est\u00e1 en preparaci\u00f3n. \u00a1Vuelve pronto!',
    collegamento: 'relato', ricomincia: 'Empezar de nuevo',
  },
};

export const tr = (l: Lingua, k: Chiave) => T[l][k];

const CHIAVE_LINGUA = 'audioguida_lingua';

/** Lingua salvata, altrimenti quella del telefono, altrimenti inglese per gli stranieri. */
export function linguaIniziale(): Lingua {
  try {
    const s = localStorage.getItem(CHIAVE_LINGUA);
    if (s && LINGUE.some((l) => l.id === s)) return s as Lingua;
  } catch { /* ignora */ }
  const tel = (navigator.language || 'it').slice(0, 2).toLowerCase();
  return (LINGUE.find((l) => l.id === tel)?.id ?? 'en') as Lingua;
}
export function salvaLingua(l: Lingua) { try { localStorage.setItem(CHIAVE_LINGUA, l); } catch { /* ignora */ } }

/** Testo della tappa nella lingua scelta (se manca: inglese, poi italiano). */
export function testoTappa(t: TappaAudioguida, l: Lingua): string {
  const k = (x: Lingua) => (t[`testo_${x}` as const] ?? '').trim();
  return k(l) || k('en') || k('it');
}

/** Indirizzo pubblico del file mp3 della tappa, se c'è. */
export function audioTappa(t: TappaAudioguida, l: Lingua, supabaseUrl: string | undefined): string | null {
  const p = t[`audio_${l}` as const];
  if (!p) return null;
  if (/^https?:\/\//.test(p)) return p;
  return supabaseUrl ? `${supabaseUrl}/storage/v1/object/public/audioguida/${p.replace(/^\/+/, '')}` : null;
}

export const vocePresente = typeof window !== 'undefined' && 'speechSynthesis' in window && typeof SpeechSynthesisUtterance !== 'undefined';

function scegliVoce(tag: string): SpeechSynthesisVoice | null {
  if (!vocePresente) return null;
  const voci = window.speechSynthesis.getVoices();
  const norm = (s: string) => s.replace('_', '-').toLowerCase();
  return voci.find((v) => norm(v.lang) === tag.toLowerCase())
    ?? voci.find((v) => norm(v.lang).startsWith(tag.slice(0, 2).toLowerCase()))
    ?? null;
}

/** Divide il testo in frasi: le voci del telefono leggono meglio i pezzi brevi (e la pausa riparte dalla frase). */
function frasi(testo: string): string[] {
  const pezzi = testo.match(/[^.!?]+[.!?]+["'»“”)]*\s*|[^.!?]+$/g) ?? [testo];
  return pezzi.map((s) => s.trim()).filter(Boolean);
}

export interface Lettore {
  suona: (testo: string, voce: string, audio: string | null, quandoFinisce: () => void) => void;
  pausa: () => void;
  riprendi: () => void;
  ferma: () => void;
  annuncia: (testo: string, voce: string) => void;
}

/** Lettore unico: prima il file mp3 (se c'è), poi la voce del telefono, altrimenti solo testo a tempo. */
export function creaLettore(): Lettore {
  let audio: HTMLAudioElement | null = null;
  let pezzi: string[] = [];
  let i = 0;
  let tag = 'it-IT';
  let fine: (() => void) | null = null;
  let giro = 0;        // invalida i richiami vecchi dopo pausa/stop
  let timer = 0;
  let solotesto = false;
  let restoMs = 0;
  let inizioMs = 0;

  const termina = () => { const f = fine; fine = null; f?.(); };

  const parla = () => {
    const mio = giro;
    if (i >= pezzi.length) { termina(); return; }
    const u = new SpeechSynthesisUtterance(pezzi[i]);
    u.lang = tag;
    const v = scegliVoce(tag);
    if (v) u.voice = v;
    u.rate = 0.95;
    const partita = Date.now();
    // Se la voce non funziona (manca la lingua sul telefono, errore) il racconto resta a schermo per il tempo di lettura
    const ripiega = () => {
      solotesto = true;
      const resto = pezzi.slice(i).join(' ');
      aTempo(Math.max(6000, (resto.split(/\s+/).length / 2.5) * 1000));
    };
    u.onend = () => {
      if (mio !== giro) return;
      if (Date.now() - partita < 300 && pezzi[i].length > 20) { ripiega(); return; }
      i += 1; parla();
    };
    u.onerror = () => { if (mio === giro) ripiega(); };
    window.speechSynthesis.speak(u);
  };

  const aTempo = (ms: number) => {
    const mio = giro;
    restoMs = ms; inizioMs = Date.now();
    timer = window.setTimeout(() => { if (mio === giro) termina(); }, ms);
  };

  const avviaVoce = (testo: string) => {
    pezzi = frasi(testo); i = 0;
    if (vocePresente) { window.speechSynthesis.cancel(); parla(); return; }
    // Niente voce: il testo resta a schermo per il tempo di lettura (circa 2,5 parole al secondo)
    solotesto = true;
    aTempo(Math.max(8000, (testo.split(/\s+/).length / 2.5) * 1000));
  };

  const pulisci = () => {
    giro += 1;
    window.clearTimeout(timer);
    if (audio) { audio.onended = null; audio.onerror = null; audio.pause(); audio = null; }
    if (vocePresente) window.speechSynthesis.cancel();
  };

  return {
    suona(testo, voce, url, quandoFinisce) {
      pulisci();
      solotesto = false;
      tag = voce;
      fine = quandoFinisce;
      if (url) {
        const a = new Audio(url);
        audio = a;
        const mio = giro;
        a.onended = () => { if (mio === giro) termina(); };
        a.onerror = () => { if (mio === giro) { audio = null; avviaVoce(testo); } };
        a.play().catch(() => { if (mio === giro) { audio = null; avviaVoce(testo); } });
      } else {
        avviaVoce(testo);
      }
    },
    pausa() {
      if (audio) { audio.pause(); return; }
      giro += 1;
      if (solotesto) { window.clearTimeout(timer); restoMs = Math.max(0, restoMs - (Date.now() - inizioMs)); return; }
      if (vocePresente) window.speechSynthesis.cancel();
    },
    riprendi() {
      if (audio) { audio.play().catch(() => undefined); return; }
      giro += 1;
      if (solotesto) { aTempo(restoMs); return; }
      if (vocePresente) parla();   // riparte dall'inizio della frase interrotta
    },
    ferma() { fine = null; pulisci(); },
    annuncia(testo, voce) {
      // Frase breve all'avvio: sblocca l'audio del telefono (serve un tocco dell'utente) e conferma che funziona
      if (!vocePresente) return;
      window.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(testo);
      u.lang = voce;
      const v = scegliVoce(voce);
      if (v) u.voice = v;
      window.speechSynthesis.speak(u);
    },
  };
}

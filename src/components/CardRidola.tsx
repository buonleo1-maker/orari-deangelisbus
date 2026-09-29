import logoRidola from '../assets/logo-ridola.png';
import { URL_RIDOLA } from '../lib/servizi';

/** Card che rimanda al sito dell'agenzia Ridola Viaggi (viaggi di gruppo in evidenza). */
export default function CardRidola() {
  return (
    <a className="ridola" href={URL_RIDOLA} target="_blank" rel="noreferrer" aria-label="Viaggi di gruppo con Ridola Viaggi, apre il sito ridolaviaggi.com">
      <div className="ridola-testa">
        <span className="ridola-logo"><img src={logoRidola} alt="Ridola Viaggi" width="64" height="45" /></span>
        <span>
          <strong>Viaggi di gruppo</strong>
          <small>con l'agenzia Ridola Viaggi</small>
        </span>
      </div>
      <p className="ridola-vuoto">Tour, gite e viaggi organizzati in bus: scopri i viaggi in programma e le ultime proposte.</p>
      <span className="ridola-link">Scopri i viaggi su ridolaviaggi.com →</span>
    </a>
  );
}

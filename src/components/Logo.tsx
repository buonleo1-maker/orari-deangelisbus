import bianco from '../assets/marchio-bianco.png';
import blu from '../assets/marchio-blu.png';

/**
 * Logo De Angelis Bus: marchio + scritta.
 * variante "chiaro" per fondi blu, "scuro" per fondi bianchi, "auto" segue il tema del telefono.
 */
export default function Logo({ variante = 'auto', motto, dimensione = 'media' }: {
  variante?: 'chiaro' | 'scuro' | 'auto'; motto?: boolean; dimensione?: 'media' | 'grande';
}) {
  return (
    <span className={`logo logo-${variante} logo-${dimensione}`} role="img" aria-label="deAngelis bus">
      <img className="marchio marchio-bianco" src={bianco} alt="" />
      <img className="marchio marchio-blu" src={blu} alt="" />
      <span className="logo-scritte">
        <span className="logo-nome">deAngelis bus</span>
        {motto && <span className="logo-motto">Insieme in viaggio</span>}
      </span>
    </span>
  );
}

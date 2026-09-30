import { useState } from 'react';
import type { Nav } from '../App';
import Lightbox from '../components/Lightbox';
import Presentazione from '../components/Presentazione';
import Testata from '../components/Testata';
import { fotoOrdinate, urlFoto } from '../lib/foto';
import type { Orario } from '../lib/schedule';

/** Galleria "In giro con noi": foto dei nostri viaggi, con presentazione e musica. */
export default function Galleria({ orario, nav }: { orario: Orario; nav: Nav }) {
  const [aperta, setAperta] = useState<number | null>(null);
  const [show, setShow] = useState(false);
  const foto = fotoOrdinate(orario.d.foto);
  return (
    <>
      <Testata titolo="In giro con noi" sotto="Foto dai nostri viaggi" onIndietro={nav.indietro} />
      {foto.length === 0 ? (
        <p className="vuoto">Le foto arriveranno presto.</p>
      ) : (
        <>
          <button className="gal-show" onClick={() => setShow(true)}>
            <span aria-hidden="true">▶</span> Guarda la presentazione
          </button>
          <div className="gal-griglia">
            {foto.map((f, i) => (
              <button key={f.id} onClick={() => setAperta(i)} aria-label={f.didascalia ?? 'Foto'}>
                <img src={urlFoto(f)} alt="" loading="lazy" />
                {f.didascalia && <span>{f.didascalia}</span>}
              </button>
            ))}
          </div>
        </>
      )}
      {aperta != null && <Lightbox foto={foto} indice={aperta} onCambia={setAperta} onChiudi={() => setAperta(null)} />}
      {show && <Presentazione foto={foto} onChiudi={() => setShow(false)} />}
    </>
  );
}

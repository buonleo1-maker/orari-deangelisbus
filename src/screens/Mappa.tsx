import { useEffect, useRef } from 'react';
import L from 'leaflet';
import type { Nav } from '../App';
import type { Orario } from '../lib/schedule';

export default function Mappa({ orario, nav }: { orario: Orario; nav: Nav }) {
  const box = useRef<HTMLDivElement>(null);
  const conCoordinate = orario.fermateServite().filter((f) => f.lat != null && f.lon != null);
  const senza = orario.fermateServite().length - conCoordinate.length;

  useEffect(() => {
    if (!box.current) return;
    const map = L.map(box.current, { zoomControl: false, attributionControl: true });
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18, attribution: '© OpenStreetMap',
    }).addTo(map);
    L.control.zoom({ position: 'bottomright' }).addTo(map);
    const punti: L.LatLngExpression[] = [];
    conCoordinate.forEach((f) => {
      const ll: L.LatLngExpression = [f.lat!, f.lon!];
      punti.push(ll);
      const linee = orario.lineeDellaFermata(f.id);
      const m = L.circleMarker(ll, {
        radius: 8, weight: 3, color: '#020a5d', fillColor: linee[0]?.colore ?? '#FFC628', fillOpacity: 1,
      }).addTo(map);
      const div = document.createElement('div');
      div.className = 'popup';
      div.innerHTML = `<strong></strong><span></span><button>Vedi partenze</button>`;
      div.querySelector('strong')!.textContent = f.nome;
      div.querySelector('span')!.textContent = f.comune;
      div.querySelector('button')!.addEventListener('click', () => nav.apri({ tipo: 'fermata', id: f.id }));
      m.bindPopup(div);
    });
    if (punti.length) map.fitBounds(L.latLngBounds(punti), { padding: [30, 30] });
    else map.setView([40.6, 16.4], 10);
    return () => { map.remove(); };
  }, [orario]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="mappa-pagina">
      <div ref={box} className="mappa" />
      {senza > 0 && <p className="mappa-nota">{senza} fermate non sono ancora sulla mappa: le trovi negli orari delle linee.</p>}
    </div>
  );
}

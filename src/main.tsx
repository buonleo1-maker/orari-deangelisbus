import React from 'react';
import ReactDOM from 'react-dom/client';
import '@fontsource/barlow/400.css';
import '@fontsource/barlow/600.css';
import '@fontsource/barlow-semi-condensed/600.css';
import '@fontsource/barlow-semi-condensed/700.css';
import 'leaflet/dist/leaflet.css';
import './styles.css';
import { Capacitor } from '@capacitor/core';
import App from './App';

// Versione web: registra il service worker (installazione e uso offline)
if (!Capacitor.isNativePlatform() && 'serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', () => { navigator.serviceWorker.register('./sw.js').catch(() => {}); });
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode><App /></React.StrictMode>,
);

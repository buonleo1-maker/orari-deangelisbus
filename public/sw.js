// Service worker: rende l'app installabile e usabile anche senza rete.
const CACHE = 'orari-v2';
const BASE = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(BASE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((k) => Promise.all(k.filter((x) => x !== CACHE).map((x) => caches.delete(x))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== self.location.origin) return; // Supabase, mappe: sempre dalla rete

  // Pagina: prima la rete (per avere sempre l'ultima versione), poi la copia salvata
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req).then((r) => { caches.open(CACHE).then((c) => c.put('./index.html', r.clone())); return r; })
        .catch(() => caches.match('./index.html')),
    );
    return;
  }
  // File dell'app (hanno nomi con impronta, non cambiano): prima la copia salvata
  e.respondWith(
    caches.match(req).then((hit) => hit || fetch(req).then((r) => {
      if (r.ok) { const copia = r.clone(); caches.open(CACHE).then((c) => c.put(req, copia)); }
      return r;
    })),
  );
});

// Notifiche push (inviate dal gestionale tramite la funzione "invia-notifica")
self.addEventListener('push', (e) => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch { d = { body: e.data ? e.data.text() : '' }; }
  e.waitUntil(self.registration.showNotification(d.title || 'Orari Deangelisbus', {
    body: d.body || '', icon: './icon-192.png', badge: './icon-192.png',
    tag: d.tag || 'novita', renotify: true, data: { url: d.url || './?apri=novita' },
  }));
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const url = new URL((e.notification.data && e.notification.data.url) || './?apri=novita', self.location.href).href;
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((finestre) => {
    for (const f of finestre) {
      if (new URL(f.url).origin === self.location.origin && 'focus' in f) { f.postMessage({ apri: 'novita' }); return f.focus(); }
    }
    return self.clients.openWindow(url);
  }));
});

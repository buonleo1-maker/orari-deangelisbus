import { Capacitor } from '@capacitor/core';
import { supabase } from './data';

/** Notifiche push (Web Push) dell'app installata dal browser. */
export type StatoPush = 'non-supportate' | 'installa-prima' | 'bloccate' | 'attive' | 'spente';

const isIos = () => /iphone|ipad|ipod/i.test(navigator.userAgent);
const installata = () => window.matchMedia?.('(display-mode: standalone)').matches || (navigator as unknown as { standalone?: boolean }).standalone === true;

export async function statoPush(): Promise<StatoPush> {
  if (Capacitor.isNativePlatform() || !supabase) return 'non-supportate';
  if (isIos() && !installata()) return 'installa-prima'; // su iPhone servono l'app aggiunta alla Home e iOS 16.4+
  if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) return 'non-supportate';
  if (Notification.permission === 'denied') return 'bloccate';
  const reg = await navigator.serviceWorker.getRegistration();
  const sub = await reg?.pushManager.getSubscription();
  return sub && Notification.permission === 'granted' ? 'attive' : 'spente';
}

const daB64u = (s: string) => {
  const p = s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4);
  return Uint8Array.from(atob(p), (c) => c.charCodeAt(0));
};
const aB64u = (b: ArrayBuffer | null) => (b ? btoa(String.fromCharCode(...new Uint8Array(b))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '') : '');

/** Chiede il permesso, iscrive il telefono e lo registra sul database. */
export async function attivaPush(): Promise<StatoPush> {
  if (!supabase) return 'non-supportate';
  const permesso = await Notification.requestPermission();
  if (permesso !== 'granted') return permesso === 'denied' ? 'bloccate' : 'spente';
  const reg = await navigator.serviceWorker.ready;
  const { data, error } = await supabase.functions.invoke('invia-notifica', { body: { azione: 'chiave' } });
  if (error || !data?.chiave) throw new Error('Servizio notifiche non disponibile');
  const sub = (await reg.pushManager.getSubscription()) ?? await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: daB64u(data.chiave) });
  const r = await supabase.rpc('push_iscrivi', {
    p_endpoint: sub.endpoint, p_p256dh: aB64u(sub.getKey('p256dh')), p_auth: aB64u(sub.getKey('auth')),
    p_piattaforma: isIos() ? 'ios' : /android/i.test(navigator.userAgent) ? 'android' : 'altro',
  });
  if (r.error) throw new Error(r.error.message);
  return 'attive';
}

export async function disattivaPush(): Promise<StatoPush> {
  const reg = await navigator.serviceWorker.getRegistration();
  const sub = await reg?.pushManager.getSubscription();
  if (sub) { await supabase?.rpc('push_disiscrivi', { p_endpoint: sub.endpoint }); await sub.unsubscribe(); }
  return 'spente';
}

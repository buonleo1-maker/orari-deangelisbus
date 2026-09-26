import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'it.deangelisbus.orari',
  appName: 'Orari De Angelis Bus',
  webDir: 'dist',
  android: {
    backgroundColor: '#020a5d',
    // Android 15+: l'app non va più sotto la barra di stato e quella dei gesti
    adjustMarginsForEdgeToEdge: 'force',
  },
};

export default config;

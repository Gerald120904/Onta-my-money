// Service Worker Offline-First para "¿Dónde se fue mi plata?"
const CACHE_VERSION = 'v1.0.1';
const CACHE_NAME = `plata-cache-${CACHE_VERSION}`;

// Recursos iniciales esenciales para abrir offline
const PRECACHE_URLS = [
  './',
  'index.html',
  'manifest.json',
  'version.json',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'sqlite3.wasm',
  'drift_worker.js',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return Promise.all(
        PRECACHE_URLS.map((url) => {
          return fetch(url).then((res) => {
            if (res.ok) return cache.put(url, res);
          }).catch((err) => console.warn('Precache skip', url, err));
        })
      );
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name.startsWith('plata-cache-') && name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);

  // NO interceptar peticiones a la API backend ni llamadas que no sean GET
  if (request.method !== 'GET' || url.pathname.startsWith('/api/')) {
    return;
  }

  // Estrategia Network First con fallback a Cache para navegación y Stale-While-Revalidate para estáticos
  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(request).then((cachedResponse) => {
        const fetchPromise = fetch(request)
          .then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
              cache.put(request, networkResponse.clone());
            }
            return networkResponse;
          })
          .catch(() => {
            // Sin conexión a Internet
            return cachedResponse;
          });

        return cachedResponse || fetchPromise;
      });
    })
  );
});

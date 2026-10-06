// Bump CACHE_VERSION whenever any shell file changes so phones pick up the update.
const CACHE_VERSION = "gym-v1";

const SHELL = [
  "./",
  "index.html",
  "styles.css",
  "app.js",
  "store.js",
  "seed.js",
  "db.js",
  "manifest.webmanifest",
  "icons/apple-touch-icon.png",
  "icons/icon-192.png",
  "icons/icon-512.png",
  "icons/icon-maskable-512.png",
  "images/cross-trainer.jpg",
  "images/wall-angels.jpg",
  "images/shoulder-dislocates.jpg",
  "images/bodyweight-squats.jpg",
  "images/leg-extension.jpg",
  "images/leg-press.jpg",
  "images/seated-leg-curl.jpg",
  "images/calf-press.jpg",
  "images/assisted-chin-up.jpg",
  "images/cable-row.jpg",
  "images/overhead-press.jpg",
  "images/diverging-lat-pulldown.jpg",
  "images/cable-tricep-pulldowns.jpg",
  "images/dumbbell-curls.jpg",
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_VERSION).then((cache) => cache.addAll(SHELL)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE_VERSION).map((key) => caches.delete(key)))
    )
  );
  self.clients.claim();
});

// Cache-first: the app must work in a gym with no signal.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  event.respondWith(
    caches.match(event.request, { ignoreSearch: true }).then(
      (cached) =>
        cached ||
        fetch(event.request).then((response) => {
          if (response.ok && new URL(event.request.url).origin === self.location.origin) {
            const copy = response.clone();
            caches.open(CACHE_VERSION).then((cache) => cache.put(event.request, copy));
          }
          return response;
        })
    )
  );
});

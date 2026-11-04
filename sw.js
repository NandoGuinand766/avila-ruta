// Guarda la app completa (mapa, rutas, íconos) en el teléfono para que funcione sin señal.
const CACHE="avila-ruta-v1";
const FILES=["./","index.html","manifest.webmanifest","icon-192.png","icon-512.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES)).then(()=>self.skipWaiting()))});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!=CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
// primero lo guardado; si hay señal, se actualiza en segundo plano para la próxima vez
self.addEventListener("fetch",e=>{if(e.request.method!="GET")return;
 e.respondWith(caches.match(e.request,{ignoreSearch:true}).then(hit=>{const net=fetch(e.request).then(r=>{if(r.ok&&new URL(e.request.url).origin==location.origin){const cp=r.clone();caches.open(CACHE).then(c=>c.put(e.request,cp))}return r}).catch(()=>hit);return hit||net}))});

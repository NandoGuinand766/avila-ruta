// Guarda la app completa (mapa, rutas, íconos) en el teléfono para que funcione sin señal.
const CACHE="avila-ruta-v2";
const FILES=["./","index.html","manifest.webmanifest","icon-192.png","icon-512.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES)).then(()=>self.skipWaiting()))});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!=CACHE&&k!="avila-compartido").map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
self.addEventListener("fetch",e=>{const u=new URL(e.request.url);
 // Android: una actividad compartida desde la app del reloj llega aquí; se guarda y se abre la app para transferirla
 if(e.request.method=="POST"&&u.pathname.endsWith("/compartir")){e.respondWith((async()=>{const f=(await e.request.formData()).get("actividad");
  if(f){const c=await caches.open("avila-compartido");await c.put("archivo",new Response(f,{headers:{"x-nombre":f.name||"actividad.fit"}}))}
  return Response.redirect("./?compartido=1",303)})());return}
 if(e.request.method!="GET")return;
 // primero lo guardado; si hay señal, se actualiza en segundo plano para la próxima vez
 e.respondWith(caches.match(e.request,{ignoreSearch:true}).then(hit=>{const net=fetch(e.request).then(r=>{if(r.ok&&u.origin==location.origin){const cp=r.clone();caches.open(CACHE).then(c=>c.put(e.request,cp))}return r}).catch(()=>hit);return hit||net}))});

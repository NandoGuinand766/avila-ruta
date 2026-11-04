# Ávila Ruta

App de senderismo para el Parque Nacional Waraira Repano (El Ávila), en Caracas.

**Abrir la app:** https://nandoguinand766.github.io/avila-ruta/

- Mapa real de los senderos que funciona sin señal: botón **Descargar mapa** para guardarlo todo de una vez.
- Rutas a un destino, rutas mixtas y conexión entre destinos, con tiempos y desnivel.
- Navegación con GPS: flecha, voz y vibración en cada bifurcación, y aviso si te sales de la ruta.
- Clima por altura: cima, Hotel Humboldt, Naiguatá y entrada de Sabas Nieves.
- **Reloj:** botón *Transferir datos* (archivos .fit, .gpx, .tcx o .zip; en Android también desde *Compartir* en la app del reloj), con datos de rendimiento (pulso, velocidades, ritmo de subida, parciales por km) y el recorrido recreado en el mapa.
- Perfil con estadísticas, retos y medallas.

## Instalar en el teléfono

- **Android (Chrome):** abre el enlace → menú ⋮ → *Instalar app*.
- **iPhone (Safari):** abre el enlace → *Compartir* → *Agregar a pantalla de inicio*.

Ábrela una vez con señal para que guarde el mapa.

## App nativa de iPhone

En `ios/` está la app nativa (Capacitor). Además de todo lo de la app web, en el iPhone:

- **GPS con la pantalla bloqueada** durante la navegación, con avisos por voz y vibración en cada cruce.
- **Transferir datos desde Apple Salud:** Apple Watch y las apps que guardan ahí el recorrido (por ejemplo Garmin Connect), con pulso.
- La pantalla se mantiene encendida mientras navegas.

Cada cambio se compila en un Mac de GitHub (pestaña **Actions → App de iPhone**). Para instalarla en un iPhone o publicarla en el App Store hace falta una cuenta de Apple Developer.

Para compilar en un Mac:

```bash
npm ci
npm run ios
open ios/App/App.xcodeproj
```

## Datos

- Senderos y puntos de interés: © colaboradores de [OpenStreetMap](https://www.openstreetmap.org/copyright), licencia ODbL.
- Relieve y alturas: SRTM (vía AWS Terrain Tiles).
- Clima: [Open-Meteo](https://open-meteo.com) y [MET Norway](https://api.met.no).

Antes de salir, confirma con Inparques el estado de los accesos al parque.

## Código

La app se arma desde `src/` (plantilla, datos del mapa y fuentes):

```bash
python3 src/build.py
```

Eso regenera `index.html`.

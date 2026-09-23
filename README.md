# Autoalojado (sin CDN externas)

Dos scripts, independientes entre sí. Cada uno edita `index.html`, `sw.js` y `_headers` por vos
(con respaldo `.bak`) y es seguro de correr más de una vez (no duplica nada la segunda vez).
Corré ambos desde tu ordenador (necesitan internet), parado en la carpeta del proyecto:

```
sh selfhost/descargar-vendor.sh      # Leaflet (mapa) + jsQR + qrcode.js
sh selfhost/autoalojar-fuentes.sh    # Geist Mono (necesita Node/npm)
```

Después: repasá los `diff archivo.bak archivo`, probá la app en local, y desplegá como siempre.

`head-vendor-snippet.html` es solo la referencia de lo que el primer script escribe en `index.html`,
por si alguna vez lo necesitás a mano.

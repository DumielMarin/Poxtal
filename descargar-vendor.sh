#!/bin/sh
# Autoaloja jsQR, qrcode.js y Leaflet (mapas/QR) y EDITA el proyecto por vos: index.html, sw.js
# y _headers quedan listos, sin pasos manuales. Ejecutalo UNA vez en tu ordenador (con internet),
# desde la carpeta donde están index.html, sw.js y _headers:
#   sh selfhost/descargar-vendor.sh
#
# Qué hace:
#  1. Descarga los archivos a js/vendor/ y css/vendor/.
#  2. Comprueba que cada uno pesa lo esperado (para no guardar una página de error de la CDN
#     disfrazada de archivo — por eso el peso mínimo por archivo).
#  3. Reemplaza las 4 etiquetas <script>/<link> de cdnjs en index.html por las locales.
#  4. Agrega los 8 archivos nuevos al precache de sw.js (offline) y sube su versión.
#  5. Quita cdnjs.cloudflare.com del Content-Security-Policy en _headers.
# Nada de esto se sube solo: seguís necesitando desplegar el proyecto como siempre.
#
# Licencias (quedan igual, solo cambia dónde se sirven): Leaflet — BSD-2-Clause · jsQR — Apache-2.0
# · qrcode.js — MIT. Revisa que cada una siga vigente si actualizas las versiones más adelante.
set -e
B=https://cdnjs.cloudflare.com/ajax/libs
mkdir -p js/vendor css/vendor/images

fetch_check(){ # fetch_check <url> <destino> <bytes_minimos>
  curl -fsSL "$1" -o "$2"
  size=$(wc -c < "$2" | tr -d ' ')
  if [ "$size" -lt "$3" ]; then
    echo "✗ $2 pesa solo $size bytes (se esperaban ≥$3) — la CDN devolvió otra cosa. Abortado, no se tocó el proyecto." >&2
    exit 1
  fi
  echo "✓ $2 ($size bytes)"
}

fetch_check "$B/leaflet/1.9.4/leaflet.min.js"   js/vendor/leaflet.min.js    100000
fetch_check "$B/leaflet/1.9.4/leaflet.min.css"  css/vendor/leaflet.min.css   10000
for f in marker-icon.png marker-icon-2x.png marker-shadow.png layers.png layers-2x.png; do
  fetch_check "$B/leaflet/1.9.4/images/$f" "css/vendor/images/$f" 100
done
fetch_check "$B/jsQR/1.4.0/jsQR.js"             js/vendor/jsQR.js          150000
fetch_check "$B/qrcodejs/1.0.0/qrcode.min.js"   js/vendor/qrcode.min.js       2000

if [ ! -f index.html ] || [ ! -f sw.js ] || [ ! -f _headers ]; then
  echo "⚠️  No encuentro index.html, sw.js o _headers en esta carpeta — los archivos ya se descargaron" >&2
  echo "   a js/vendor y css/vendor, pero tenés que editar esos 3 a mano (ver selfhost/head-vendor-snippet.html)." >&2
  exit 0
fi

cp index.html index.html.bak
perl -0pi -e 's{<script src="https://cdnjs\.cloudflare\.com/ajax/libs/jsQR/1\.4\.0/jsQR\.js"></script>\n<script src="https://cdnjs\.cloudflare\.com/ajax/libs/qrcodejs/1\.0\.0/qrcode\.min\.js"></script>\n<link rel="stylesheet" href="https://cdnjs\.cloudflare\.com/ajax/libs/leaflet/1\.9\.4/leaflet\.min\.css">\n<script src="https://cdnjs\.cloudflare\.com/ajax/libs/leaflet/1\.9\.4/leaflet\.min\.js"></script>}{<link rel="stylesheet" href="css/vendor/leaflet.min.css">\n<script src="js/vendor/leaflet.min.js"></script>\n<script src="js/vendor/jsQR.js"></script>\n<script src="js/vendor/qrcode.min.js"></script>}' index.html
if diff -q index.html index.html.bak >/dev/null; then
  echo "⚠️  index.html no cambió (¿ya estaba autoalojado, o alguien tocó esas 4 líneas?). Revisalo a mano." >&2
else
  echo "✓ index.html actualizado (respaldo en index.html.bak)"
fi

if grep -q "js/vendor/leaflet.min.js" sw.js; then
  echo "= sw.js ya tenía los archivos autoalojados en su precache — no se tocó de nuevo."
else
  cp sw.js sw.js.bak
  perl -0pi -e "s{const CACHE_VERSION = 'poxtal-v(\\d+)';}{my \$n=\$1+1; \"const CACHE_VERSION = 'poxtal-v\$n';\"}e" sw.js
  perl -0pi -e "s{(const PRECACHE = \\[\\n)}{\$1  './js/vendor/leaflet.min.js',\n  './js/vendor/jsQR.js',\n  './js/vendor/qrcode.min.js',\n  './css/vendor/leaflet.min.css',\n  './css/vendor/images/marker-icon.png',\n  './css/vendor/images/marker-icon-2x.png',\n  './css/vendor/images/marker-shadow.png',\n  './css/vendor/images/layers.png',\n  './css/vendor/images/layers-2x.png',\n}" sw.js
  echo "✓ sw.js actualizado y con la versión subida (respaldo en sw.js.bak)"
fi

if grep -q "cdnjs.cloudflare.com" _headers; then
  cp _headers _headers.bak
  sed -i.tmp "s/ https:\/\/cdnjs\.cloudflare\.com;/;/g" _headers && rm -f _headers.tmp
  echo "✓ _headers actualizado — cdnjs.cloudflare.com quitado del CSP (respaldo en _headers.bak)"
else
  echo "= _headers ya no tenía cdnjs.cloudflare.com — no se tocó de nuevo."
fi

echo
echo "Listo. Repasá los cambios (diff index.html.bak index.html, etc.), probá la app en local y"
echo "despliega como siempre. Si algo no cuadra, restaurá desde los .bak."

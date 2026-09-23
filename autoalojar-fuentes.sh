#!/bin/sh
# Autoaloja Geist Mono y EDITA el proyecto por vos (index.html, sw.js, _headers). Ejecutalo UNA
# vez en tu ordenador (con internet), desde la carpeta donde están index.html, sw.js y _headers:
#   sh selfhost/autoalojar-fuentes.sh
#
# Requiere Node/npm instalados. Usa el paquete @fontsource/geist-mono (SIL Open Font License,
# igual que la fuente original) en vez de servirla desde Google Fonts.
set -e
if ! command -v npm >/dev/null 2>&1; then
  echo "✗ Necesitás Node/npm instalados para este paso (fontsource se instala con npm)." >&2
  exit 1
fi

TMP=$(mktemp -d)
( cd "$TMP" && npm init -y >/dev/null 2>&1 && npm i @fontsource/geist-mono >/dev/null 2>&1 )
SRC="$TMP/node_modules/@fontsource/geist-mono/files"
if [ ! -d "$SRC" ]; then
  echo "✗ No se pudo instalar @fontsource/geist-mono — revisá tu conexión y volvé a intentar." >&2
  exit 1
fi

mkdir -p fonts
for w in 400 500 600 700 800; do
  f="geist-mono-latin-$w-normal.woff2"
  cp "$SRC/$f" "fonts/$f"
  size=$(wc -c < "fonts/$f" | tr -d ' ')
  if [ "$size" -lt 1000 ]; then
    echo "✗ fonts/$f pesa solo $size bytes — algo salió mal. Abortado, no se tocó el proyecto." >&2
    exit 1
  fi
  echo "✓ fonts/$f ($size bytes)"
done
rm -rf "$TMP"

mkdir -p css
cat > css/fonts.css <<'CSS'
/* Geist Mono autoalojada (antes: Google Fonts). SIL Open Font License, igual que el original. */
@font-face{font-family:'Geist Mono';font-weight:400;font-style:normal;font-display:swap;src:url('../fonts/geist-mono-latin-400-normal.woff2') format('woff2');}
@font-face{font-family:'Geist Mono';font-weight:500;font-style:normal;font-display:swap;src:url('../fonts/geist-mono-latin-500-normal.woff2') format('woff2');}
@font-face{font-family:'Geist Mono';font-weight:600;font-style:normal;font-display:swap;src:url('../fonts/geist-mono-latin-600-normal.woff2') format('woff2');}
@font-face{font-family:'Geist Mono';font-weight:700;font-style:normal;font-display:swap;src:url('../fonts/geist-mono-latin-700-normal.woff2') format('woff2');}
@font-face{font-family:'Geist Mono';font-weight:800;font-style:normal;font-display:swap;src:url('../fonts/geist-mono-latin-800-normal.woff2') format('woff2');}
CSS
echo "✓ css/fonts.css creado"

if [ ! -f index.html ] || [ ! -f sw.js ] || [ ! -f _headers ]; then
  echo "⚠️  No encuentro index.html, sw.js o _headers en esta carpeta — la fuente ya quedó lista" >&2
  echo "   en fonts/ y css/fonts.css, pero tenés que editar esos 3 archivos a mano." >&2
  exit 0
fi

if grep -q "fonts.googleapis.com" index.html; then
  cp index.html index.html.fonts.bak
  perl -0pi -e 's{<link rel="preconnect" href="https://fonts\.googleapis\.com">\n<link href="https://fonts\.googleapis\.com/css2\?family=Geist\+Mono:wght\@400;500;600;700;800&display=swap" rel="stylesheet">}{<link rel="stylesheet" href="css/fonts.css">}' index.html
  if grep -q "fonts.googleapis.com" index.html; then
    echo "⚠️  No pude reemplazar el <link> de Google Fonts automáticamente (¿lo editaste vos antes?). Hacelo a mano." >&2
  else
    echo "✓ index.html actualizado (respaldo en index.html.fonts.bak)"
  fi
else
  echo "= index.html ya no tenía el <link> de Google Fonts — no se tocó de nuevo."
fi

if grep -q "css/fonts.css" sw.js; then
  echo "= sw.js ya tenía css/fonts.css y las fuentes en su precache — no se tocó de nuevo."
else
  cp sw.js sw.js.fonts.bak
  perl -0pi -e "s{const CACHE_VERSION = 'poxtal-v(\\d+)';}{my \$n=\$1+1; \"const CACHE_VERSION = 'poxtal-v\$n';\"}e" sw.js
  perl -0pi -e "s{(const PRECACHE = \\[\\n)}{\$1  './css/fonts.css',\n  './fonts/geist-mono-latin-400-normal.woff2',\n  './fonts/geist-mono-latin-500-normal.woff2',\n  './fonts/geist-mono-latin-600-normal.woff2',\n  './fonts/geist-mono-latin-700-normal.woff2',\n  './fonts/geist-mono-latin-800-normal.woff2',\n}" sw.js
  echo "✓ sw.js actualizado y con la versión subida (respaldo en sw.js.fonts.bak)"
fi

if grep -q "fonts.googleapis.com" _headers; then
  cp _headers _headers.fonts.bak
  sed -i.tmp "s/ https:\/\/fonts\.googleapis\.com//g; s/ https:\/\/fonts\.gstatic\.com//g" _headers && rm -f _headers.tmp
  echo "✓ _headers actualizado — Google Fonts quitado del CSP (respaldo en _headers.fonts.bak)"
else
  echo "= _headers ya no tenía Google Fonts en el CSP — no se tocó de nuevo."
fi

echo
echo "Listo. Repasá los cambios (diff index.html.fonts.bak index.html, etc.), probá la app en local"
echo "y desplegá como siempre. Si algo no cuadra, restaurá desde los .bak."

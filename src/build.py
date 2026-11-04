"""Arma la app a partir de app.html, los datos del mapa y las fuentes.

Uso:  python3 src/build.py             -> index.html en la raíz (la app web de GitHub Pages)
      python3 src/build.py --www www   -> además la carpeta www/ para la app nativa de iPhone (Capacitor)
      python3 src/build.py --demo X    -> además X, la vista previa sin la app instalable
"""
import pathlib, shutil, sys

SRC = pathlib.Path(__file__).resolve().parent
ROOT = SRC.parent
HEAD = ('<link rel="manifest" href="manifest.webmanifest"><meta name="theme-color" content="#0a0a0a">'
        '<link rel="icon" href="icon-192.png"><link rel="apple-touch-icon" href="icon-192.png">'
        '<meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black">'
        '<meta name="apple-mobile-web-app-title" content="Ávila Ruta">')
# en la app nativa, el puente de Capacitor da acceso al GPS en segundo plano, Apple Salud, vibración y voz
NATIVE_HEAD = '<script src="capacitor.js"></script>'


def arg(name):
    return pathlib.Path(sys.argv[sys.argv.index(name) + 1]) if name in sys.argv else None


page = (SRC / 'app.html').read_text()
page = page.replace('/*FONTS*/', (SRC / 'fuentes.css').read_text()).replace('/*DATA*/', (SRC / 'mapa.json').read_text())
(ROOT / 'index.html').write_text(page.replace('<!--HEAD-->', HEAD))

www = arg('--www')
if www:
    www = ROOT / www if not www.is_absolute() else www
    www.mkdir(exist_ok=True)
    (www / 'index.html').write_text(page.replace('<!--HEAD-->', NATIVE_HEAD))
    shutil.copy(ROOT / 'node_modules/@capacitor/core/dist/capacitor.js', www / 'capacitor.js')
    for f in ('icon-192.png', 'icon-512.png'):
        shutil.copy(ROOT / f, www / f)

demo = arg('--demo')
if demo:
    demo.write_text(page.replace('<!--HEAD-->', '').replace('<title>Ávila Ruta</title>', '<title>Ávila Ruta – Prototipo</title>'))

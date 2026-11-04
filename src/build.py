"""Arma index.html (la app publicada) a partir de app.html, los datos del mapa y las fuentes.

Uso:  python3 src/build.py            -> escribe index.html en la raíz del repositorio
      python3 src/build.py --demo X   -> además escribe X, la versión de vista previa sin la app instalable
"""
import pathlib, sys

SRC = pathlib.Path(__file__).resolve().parent
ROOT = SRC.parent
HEAD = ('<link rel="manifest" href="manifest.webmanifest"><meta name="theme-color" content="#0a0a0a">'
        '<link rel="icon" href="icon-192.png"><link rel="apple-touch-icon" href="icon-192.png">'
        '<meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black">'
        '<meta name="apple-mobile-web-app-title" content="Ávila Ruta">')

page = (SRC / 'app.html').read_text()
page = page.replace('/*FONTS*/', (SRC / 'fuentes.css').read_text()).replace('/*DATA*/', (SRC / 'mapa.json').read_text())
(ROOT / 'index.html').write_text(page.replace('<!--HEAD-->', HEAD))
if '--demo' in sys.argv:
    out = pathlib.Path(sys.argv[sys.argv.index('--demo') + 1])
    out.write_text(page.replace('<!--HEAD-->', '').replace('<title>Ávila Ruta</title>', '<title>Ávila Ruta – Prototipo</title>'))

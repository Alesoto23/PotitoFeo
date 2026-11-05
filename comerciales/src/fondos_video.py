"""Arma los cuadros de fondo (1280x720, 30 fps) de cada escena a partir de los videos de las laptops.

- ThinkPad, Legion y Yoga: su propio video (con ajuste de color o recorte de subtítulos).
- LOQ: se le quita el fondo blanco y se monta sobre el setup gamer del video de Legion.
- IdeaPad: se le quita el fondo turquesa y se monta sobre la habitación del video de Yoga.
Uso: python3 fondos_video.py [escena ...] [--prueba]
"""
import os, subprocess, sys, shutil, tempfile
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

V = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'vid')
W, H, FPS = 1280, 720, 30
ESC = {  # duración de la escena en el comercial y tramos (inicio, fin, velocidad) del video original
    'thinkpad': dict(dur=6.6, seg=[(1.0, 6.0, 0.76)],
                     vf='hue=s=0.45,eq=brightness=-0.03:contrast=1.06,colorbalance=bs=0.08:bm=0.04'),
    'legion':   dict(dur=6.4, seg=[(0.0, 0.65, 0.5), (6.0, 7.3, 0.5), (7.3, 7.95, 0.25)]),
    'loq':      dict(dur=5.6, seg=[(19.4, 22.0, 0.47)], key='blanco',
                     plato=('legion', 7.6), lado='izq'),
    'yoga':     dict(dur=6.2, seg=[(4.15, 8.0, 0.62)],
                     vf='crop=iw/1.18:ih/1.18:(iw-iw/1.18)/2:0'),
    'ideapad':  dict(dur=5.8, seg=[(13.1, 17.6, 0.78)], key='turquesa',
                     plato=('yoga', 12.2), lado='izq'),
}

def extraer(n, a, b, vel, vf, out):
    filtros = [f'setpts=PTS/{vel}', f'minterpolate=fps={FPS}:mi_mode=blend'] + ([vf] if vf else []) + [f'scale={W}:{H}']
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(a), '-to', str(b), '-i', f'{V}/{n}_src.mp4',
                    '-vf', ','.join(filtros), '-q:v', '2', f'{out}/%05d.jpg'], check=True)

def plato(n, t):  # fondo de ambiente desenfocado y oscurecido
    tmp = tempfile.mktemp(suffix='.png')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(t), '-i', f'{V}/{n}_src.mp4', '-frames:v', '1',
                    '-vf', f'crop=iw:ih*0.86:0:0,scale={W}:{H}', tmp], check=True)
    im = Image.open(tmp).convert('RGB').filter(ImageFilter.GaussianBlur(9)); os.remove(tmp)
    return np.asarray(im).astype(np.float32) * 0.62

def recortar(f, modo):  # alfa del laptop y alfa de sombra
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    mx, mn = f.max(-1), f.min(-1); lum = 0.3 * r + 0.59 * g + 0.11 * b
    sat = (mx - mn) / (mx + 1e-3)
    if modo == 'blanco':
        fondo = np.clip((lum - 150) / 30, 0, 1) * np.clip((0.12 - sat) / 0.06, 0, 1)
        sombra = fondo * np.clip((215 - lum) / 70, 0, 1) * 0.75
    else:  # turquesa: tono entre verde y cian, saturado
        hue = np.degrees(np.arctan2(np.sqrt(3) * (g - b), 2 * r - g - b)) % 360
        fondo = np.clip((sat - 0.16) / 0.1, 0, 1) * np.clip((hue - 120) / 15, 0, 1) * np.clip((203 - hue) / 8, 0, 1)
        fondo[int(H * 0.88):, int(W * 0.8):] = 1  # tapa el logo de AMD
        sombra = np.zeros_like(fondo)
    # solo es fondo lo que está conectado con el borde del cuadro: lo de dentro del laptop no se borra
    lap = ndimage.binary_fill_holes(ndimage.binary_opening(fondo < 0.5, iterations=2))
    lab, nlab = ndimage.label(lap)
    if nlab > 1:  # se queda con la pieza más grande (el laptop)
        tam = ndimage.sum(lap, lab, range(1, nlab + 1)); lap = lab == (np.argmax(tam) + 1)
    lap = ndimage.binary_fill_holes(lap)
    a = np.where(lap, np.maximum(1 - fondo, ndimage.binary_erosion(lap, iterations=3)), 0).astype(np.float32)
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255
    sombra = np.asarray(Image.fromarray((sombra * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(8))).astype(np.float32) / 255
    # se desvanece hacia los bordes del cuadro para que no se note el rectángulo
    yy, xx = np.mgrid[0:H, 0:W]
    borde = np.clip(np.minimum.reduce([xx, W - 1 - xx, yy, H - 1 - yy]) / 60, 0, 1)
    return a * borde, sombra * borde

def construir(n, prueba=False):
    c = ESC[n]; out = f'{V}/frames/{n}'
    shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
    tmp = tempfile.mkdtemp(); k = 0
    for i, (a, b, vel) in enumerate(c['seg']):
        d = f'{tmp}/{i}'; os.makedirs(d); extraer(n, a, b, vel, c.get('vf'), d)
        for f in sorted(os.listdir(d)):
            shutil.move(f'{d}/{f}', f'{tmp}/{k:05d}.jpg'); k += 1
    total = int(round(c['dur'] * FPS)) + 2
    fuentes = [f'{tmp}/{min(i, k - 1):05d}.jpg' for i in range(total)]
    if prueba: fuentes = fuentes[::max(1, total // 6)][:6]
    base = plato(*c['plato']) if 'key' in c else None
    for i, src in enumerate(fuentes):
        f = np.asarray(Image.open(src).convert('RGB')).astype(np.float32)
        if base is not None:
            a, sh = recortar(f, c['key'])
            # el laptop se corre a la izquierda y se achica para dejar sitio al texto
            esc, dx = 0.78, -int(W * 0.12)
            lap = Image.fromarray(f.astype(np.uint8)); al = Image.fromarray((a * 255).astype(np.uint8)); sm = Image.fromarray((sh * 255).astype(np.uint8))
            nw, nh = int(W * esc), int(H * esc); ox, oy = (W - nw) // 2 + dx, (H - nh) // 2 + int(H * 0.04)
            capa = lambda im, fill: (lambda c_: (c_.paste(im.resize((nw, nh)), (ox, oy)), c_)[1])(Image.new(im.mode, (W, H), fill))
            L = np.asarray(capa(lap, (0, 0, 0))).astype(np.float32)
            A = np.asarray(capa(al, 0)).astype(np.float32)[..., None] / 255
            S = np.asarray(capa(sm, 0)).astype(np.float32)[..., None] / 255
            z = 1 + 0.05 * i / total  # leve zoom del ambiente
            bg = np.asarray(Image.fromarray(base.astype(np.uint8)).resize((int(W * z), int(H * z))).crop(
                (int(W * (z - 1) / 2), int(H * (z - 1) / 2), int(W * (z - 1) / 2) + W, int(H * (z - 1) / 2) + H))).astype(np.float32)
            bg = bg * (1 - S)
            f = L * A + bg * (1 - A)
        Image.fromarray(np.clip(f, 0, 255).astype(np.uint8)).save(f'{out}/{i:04d}.jpg', quality=90)
    shutil.rmtree(tmp)
    print(n, len(fuentes), 'cuadros')

if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')] or list(ESC)
    for n in args: construir(n, '--prueba' in sys.argv)

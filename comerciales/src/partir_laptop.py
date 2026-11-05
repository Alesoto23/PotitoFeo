"""Corta cada foto en base y tapa por la línea de la bisagra, y crea la cara trasera de la tapa."""
import json, numpy as np
from PIL import Image
# Puntos en píxeles de la foto: H1/H2 bisagra (izq/der), O1/O2 esquinas superiores de la tapa,
# F1/F2 esquinas delanteras de la base (donde descansa la tapa cerrada). color = tapa trasera.
L = {
 'thinkpad': dict(H1=[77,344], H2=[509,344], O1=[77,53],  O2=[509,53],  F1=[30,522],  F2=[556,522], color=[28,28,30]),
 'legion':   dict(H1=[30,248], H2=[253,252], O1=[35,23],  O2=[258,52],  F1=[130,472], F2=[352,418], color=[40,42,48]),
 'loq':      dict(H1=[146,253],H2=[385,297], O1=[198,93], O2=[438,100], F1=[5,290],   F2=[255,375], color=[110,113,118]),
 'yoga':     dict(H1=[92,300], H2=[272,197], O1=[17,82],  O2=[232,39],  F1=[275,408], F2=[432,252], color=[140,142,146]),
 'ideapad':  dict(H1=[68,314], H2=[392,292], O1=[62,27],  O2=[393,60],  F1=[172,555], F2=[522,485], color=[118,120,126]),
}
for n, p in L.items():
    im = np.array(Image.open(f'img/{n}.png').convert('RGBA')).astype(np.float32)
    h, w = im.shape[:2]; yy, xx = np.mgrid[0:h, 0:w]
    (x1, y1), (x2, y2) = p['H1'], p['H2']
    side = lambda X, Y: (x2 - x1) * (Y - y1) - (y2 - y1) * (X - x1)
    s_lid = np.sign(side(*p['O1']))
    d = side(xx, yy) * s_lid / np.hypot(x2 - x1, y2 - y1)   # distancia con signo (positivo = tapa)
    a_lid = np.clip(d + 0.5, 0, 1)
    base = im.copy(); base[..., 3] *= 1 - a_lid
    lid = im.copy(); lid[..., 3] *= a_lid
    back = lid.copy()
    lum = 0.85 + 0.3 * (yy / h)[..., None]  # leve degradado
    back[..., :3] = np.clip(np.array(p['color'])[None, None, :] * lum, 0, 255)
    for nom, arr in [('base', base), ('tapa', lid), ('tapa_atras', back)]:
        Image.fromarray(arr.astype(np.uint8)).save(f'img/{n}_{nom}.png')
    p['W'], p['H'] = w, h
json.dump(L, open('img/laptops.json', 'w'))
print(json.dumps({k: (v['W'], v['H']) for k, v in L.items()}))

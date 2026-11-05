"""Pone la foto real de la tapa (vista trasera) como cara trasera de la tapa animada."""
import json, numpy as np
from PIL import Image
# Esquinas de la tapa en las fotos traseras: arriba-izq, arriba-der, abajo-der, abajo-izq (vista desde atrás)
R = {
 'legion':   [(87, 23), (371, 48), (371, 247), (88, 258)],
 'loq':      [(32, 67), (261, 14), (314, 180), (116, 266)],
 'thinkpad': [(110, 110), (393, 143), (523, 362), (262, 442)],
 'yoga':     [(113, 130), (420, 157), (563, 390), (277, 433)],
 'ideapad':  [(65, 72), (232, 67), (312, 205), (159, 258)],
}
def homog(src, dst):  # matriz que lleva src -> dst
    A, b = [], []
    for (x, y), (u, v) in zip(src, dst):
        A += [[x, y, 1, 0, 0, 0, -u*x, -u*y], [0, 0, 0, x, y, 1, -v*x, -v*y]]; b += [u, v]
    return np.linalg.solve(np.array(A, float), np.array(b, float))
def encoger(q, f=0.015):  # evita tomar el borde/fondo de la foto
    c = np.mean(q, 0); return [tuple(c + (np.array(p) - c) * (1 - f)) for p in q]
L = json.load(open('img/laptops.json'))
for n, q in R.items():
    tl, tr, br, bl = encoger(q, 0.035 if n in ('loq', 'yoga', 'ideapad') else 0.015)
    p = L[n]
    # vista trasera: su izquierda es el lado derecho de la laptop
    dst = [p['H1'], p['H2'], p['O2'], p['O1']]
    src = [br, bl, tl, tr]
    coef = homog(dst, src)  # PIL pide la transformación salida -> entrada
    foto = Image.open(f'img/{n}_tapa_real_src.png').convert('RGB')
    tex = foto.transform((p['W'], p['H']), Image.PERSPECTIVE, tuple(coef), Image.BICUBIC)
    alpha = Image.open(f'img/{n}_tapa.png').getchannel('A')
    tex.putalpha(alpha); tex.save(f'img/{n}_tapa_atras.png')
print('ok')

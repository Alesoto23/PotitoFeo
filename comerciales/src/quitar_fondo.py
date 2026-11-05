"""Quita el fondo blanco de las fotos (relleno desde los bordes) y guarda PNG transparente."""
import sys
from PIL import Image, ImageDraw, ImageFilter
src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGBA')
if im.getpixel((2, 2))[3] < 10:  # ya es transparente
    im.save(dst); sys.exit()
rgb = im.convert('RGB'); w, h = rgb.size
mask = Image.new('L', (w, h), 0)
marca = rgb.copy()
for x, y in [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1), (w//2, 0), (w//2, h-1), (0, h//2), (w-1, h//2)]:
    if sum(marca.getpixel((x, y))) > 3 * 238:
        ImageDraw.floodfill(marca, (x, y), (255, 0, 255), thresh=int(sys.argv[3]) if len(sys.argv) > 3 else 28)
px = marca.load(); m = mask.load()
for y in range(h):
    for x in range(w):
        m[x, y] = 0 if px[x, y] == (255, 0, 255) else 255
mask = mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
im.putalpha(mask); im.save(dst)

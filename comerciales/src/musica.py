"""Genera las pistas de música de los comerciales (síntesis simple con numpy)."""
import numpy as np, wave, sys
SR = 44100
def n2f(n): return 440 * 2 ** ((n - 69) / 12)
def env(N, a=0.01, r=0.3):
    t = np.arange(N) / SR; e = np.minimum(1, t / a); rel = int(r * SR)
    if rel < N: e[-rel:] *= np.linspace(1, 0, rel)
    return e
def osc(f, dur, kind='saw', harm=8):
    t = np.arange(int(dur * SR)) / SR
    if kind == 'sine': return np.sin(2 * np.pi * f * t)
    if kind == 'tri': return 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * t))
    if kind == 'square': return sum(np.sin(2 * np.pi * f * k * t) / k for k in range(1, harm * 2, 2))
    return sum(np.sin(2 * np.pi * f * k * t) / k for k in range(1, harm + 1))
def add(buf, x, at):
    i = int(at * SR); j = min(len(buf), i + len(x))
    if j > i: buf[i:j] += x[:j - i]
def kick(): t = np.arange(int(.35 * SR)) / SR; return np.sin(2*np.pi*(50 + 120*np.exp(-t*30))*t) * np.exp(-t*9)
def hat(rng): n = rng.standard_normal(int(.06 * SR)); n = np.diff(n, prepend=0); return n * np.exp(-np.arange(len(n)) / SR * 70) * .25
def save(buf, name):
    buf = buf / (np.max(np.abs(buf)) + 1e-9) * 0.85
    fade = int(1.5 * SR); buf[-fade:] *= np.linspace(1, 0, fade)
    st = np.stack([buf, np.roll(buf, 220)], 1)  # leve estéreo
    with wave.open(name, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((st * 32767).astype(np.int16).tobytes())

def lenovo(out, D=45):
    rng = np.random.default_rng(1); buf = np.zeros(int(D * SR)); bpm = 112; b = 60 / bpm
    prog = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]  # Am F C G
    for bar in range(int(D / (4 * b)) + 1):
        ch = prog[bar % 4]; at = bar * 4 * b
        for n in ch: add(buf, osc(n2f(n), 4 * b, 'saw', 6) * env(int(4*b*SR), .3, .8) * .05, at)
        for k in range(8):  # bajo pulsante en corcheas
            add(buf, osc(n2f(ch[0] - 24), b / 2, 'square', 4) * env(int(b/2*SR), .005, .1) * .12, at + k * b / 2)
        if at > 4.4:  # entra la batería tras la apertura
            for k in range(4): add(buf, kick() * .6, at + k * b)
            for k in range(8): add(buf, hat(rng), at + k * b / 2 + b / 4)
        if 15 < at < 27:  # arpegio gamer (Legion / LOQ)
            for k in range(16):
                n = ch[k % 3] + 12 * (1 + (k // 3) % 2)
                add(buf, osc(n2f(n), b / 4, 'square', 3) * env(int(b/4*SR), .002, .08) * .05, at + k * b / 4)
    for at in [0.3, 38.4]:  # golpe de logo
        add(buf, sum(osc(n2f(n), 3, 'sine') for n in [69, 76, 81]) * env(3 * SR, .005, 2.5) * .25, at)
    save(buf, out)

def donofrio(out, D=40.5):
    rng = np.random.default_rng(2); buf = np.zeros(int(D * SR)); bpm = 96; b = 60 / bpm
    prog = [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]]  # C Am F G
    mel = [76, 79, 77, 76, 74, 72, 74, 76, 72, 74, 76, 79, 81, 79, 77, 74]
    for bar in range(int(D / (4 * b)) + 1):
        ch = prog[bar % 4]; at = bar * 4 * b
        for n in ch: add(buf, osc(n2f(n), 4 * b, 'tri') * env(int(4*b*SR), .2, 1) * .09, at)
        add(buf, osc(n2f(ch[0] - 24), 2 * b, 'sine') * env(int(2*b*SR), .01, .5) * .25, at)
        add(buf, osc(n2f(ch[2] - 24), 2 * b, 'sine') * env(int(2*b*SR), .01, .5) * .25, at + 2 * b)
        if at > 5:  # melodía tipo marimba
            for k in range(4):
                n = mel[(bar * 4 + k) % len(mel)]
                add(buf, osc(n2f(n), b, 'sine') * np.exp(-np.arange(int(b*SR))/SR*6) * .18, at + k * b)
        if 5 < at < 12:  # campanitas navideñas
            for k in range(8):
                add(buf, (osc(n2f(96), .15, 'sine') + rng.standard_normal(int(.15*SR)) * .3) * np.exp(-np.arange(int(.15*SR))/SR*40) * .08, at + k * b / 2)
        if 19 < at < 27:  # ritmo veraniego
            for k in range(8): add(buf, hat(rng) * 1.3, at + k * b / 2)
    for at in [21.3, 23.0]:  # corneta del heladero
        for i, n in enumerate([79, 79]):
            add(buf, osc(n2f(n), .45, 'square', 5) * env(int(.45*SR), .02, .1) * .22, at + i * .55)
    save(buf, out)

if __name__ == '__main__':
    {'lenovo': lenovo, 'donofrio': donofrio}[sys.argv[1]](sys.argv[2])

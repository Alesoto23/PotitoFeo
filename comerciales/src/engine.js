// Motor de animación determinista: render(t) dibuja el cuadro del segundo t.
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const ease = x => 1 - Math.pow(1 - clamp(x), 3);
function render(t) {
  document.querySelectorAll('.scene').forEach(s => {
    const st = +s.dataset.start, en = +s.dataset.end, f = 0.45;
    const o = clamp((t - st) / f) * clamp((en - t) / f);
    s.style.opacity = o;
    s.style.visibility = o > 0 ? 'visible' : 'hidden';
    if (o <= 0) return;
    const lt = t - st;
    const bg = s.querySelector('.bg');
    if (bg) bg.style.transform = `scale(${1 + 0.06 * lt / (en - st)})`;
    s.querySelectorAll('[data-d]').forEach(el => {
      const p = ease((lt - +el.dataset.d) / (+el.dataset.dur || 0.7));
      const ty = el.dataset.t || 'up';
      let tr = '';
      if (ty === 'up') tr = `translateY(${(1 - p) * 40}px)`;
      if (ty === 'left') tr = `translateX(${(1 - p) * -120}px)`;
      if (ty === 'right') tr = `translateX(${(1 - p) * 120}px)`;
      if (ty === 'scale') tr = `scale(${0.7 + 0.3 * p})`;
      if (ty === 'wipe') { el.style.clipPath = `inset(0 ${(1 - p) * 100}% 0 0)`; el.style.opacity = 1; }
      else el.style.opacity = p;
      el.style.transform = tr;
    });
  });
  if (window.custom) window.custom(t);
}
window.render = render;

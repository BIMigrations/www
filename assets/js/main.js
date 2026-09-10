(function () {
  'use strict';

  var root = document.documentElement;

  /* ---------- Theme ---------- */
  function currentTheme() { return root.getAttribute('data-theme') || 'light'; }
  function updateThemeLabel() {
    var label = document.getElementById('theme-label');
    if (label) label.textContent = currentTheme() === 'dark' ? 'Light' : 'Dark';
  }
  function setTheme(t) {
    root.setAttribute('data-theme', t);
    try { localStorage.setItem('theme', t); } catch (e) {}
    updateThemeLabel();
  }
  window.BIToggleTheme = function () {
    setTheme(currentTheme() === 'dark' ? 'light' : 'dark');
  };

  /* ---------- Hover styles (port of design's style-hover) ---------- */
  function wireHovers() {
    var els = document.querySelectorAll('[data-hover]');
    els.forEach(function (el) {
      var hover = el.getAttribute('data-hover');
      el.addEventListener('mouseenter', function () {
        el._origStyle = el.getAttribute('style') || '';
        el.setAttribute('style', el._origStyle + ';' + hover);
      });
      el.addEventListener('mouseleave', function () {
        el.setAttribute('style', el._origStyle || '');
      });
    });
  }

  /* ---------- Seeded PRNG (stable decorative grids) ---------- */
  function rnd(seed) { var s = seed * 9301 + 49297; return ((s % 233280) / 233280); }

  function fill(id, styles) {
    var host = document.getElementById(id);
    if (!host) return;
    var frag = document.createDocumentFragment();
    styles.forEach(function (s) {
      var d = document.createElement('div');
      d.setAttribute('style', s);
      frag.appendChild(d);
    });
    host.appendChild(frag);
  }

  function buildGrids() {
    var chaos = [];
    for (var i = 0; i < 48; i++) {
      var a = rnd(i * 3 + 2), b = rnd(i * 5 + 4), c = rnd(i * 11 + 6);
      var span = a > 0.8 ? 2 : 1, rows = b > 0.85 ? 2 : 1;
      var tone = c > 0.55 ? 'var(--amber)' : c > 0.25 ? 'var(--ink2)' : 'var(--muted)';
      chaos.push('grid-column:span ' + span + ';grid-row:span ' + rows +
        ';border:1px solid ' + tone + ';border-radius:' + (a > 0.5 ? 3 : 8) + 'px' +
        ';opacity:' + (0.35 + b * 0.6) +
        ';transform:rotate(' + ((c - 0.5) * 9) + 'deg) translate(' + ((a - 0.5) * 8) + 'px,' + ((b - 0.5) * 8) + 'px)' +
        ';background:' + (c > 0.75 ? 'color-mix(in srgb,var(--amber) 22%,transparent)' : 'transparent'));
    }
    fill('chaos-grid', chaos);

    var order = [];
    for (var j = 0; j < 48; j++) {
      var k = j % 12, filled = (j % 7 === 0) || (j % 11 === 3);
      order.push('border:1px solid var(--teal);border-radius:4px;opacity:' + (0.35 + (k / 12) * 0.6) +
        ';background:' + (filled ? 'var(--teal)' : 'color-mix(in srgb,var(--teal) 10%,transparent)'));
    }
    fill('order-grid', order);

    var artScan = [];
    for (var m = 0; m < 32; m++) {
      var hot = [3, 9, 14, 20, 27].indexOf(m) !== -1, warm = [5, 11, 22].indexOf(m) !== -1;
      var size = hot ? 14 : warm ? 10 : 6;
      artScan.push('width:' + size + 'px;height:' + size + 'px;border-radius:999px;background:' +
        (hot ? 'var(--amber)' : warm ? 'var(--ink)' : 'var(--line2)'));
    }
    fill('art-scan', artScan);

    var artGen = [];
    for (var n = 0; n < 18; n++) {
      var f = [0, 1, 6, 8, 13, 15, 16].indexOf(n) !== -1;
      artGen.push('border-radius:5px;background:' + (f ? 'var(--teal)' : 'transparent') +
        ';border:1.5px solid var(--teal);opacity:' + (f ? 0.95 : 0.55));
    }
    fill('art-gen', artGen);
  }

  /* ---------- Platform marquee ---------- */
  function buildMarquee() {
    var host = document.getElementById('marquee');
    if (!host) return;
    var names = ['Domo', 'Qlik Sense', 'Tableau', 'Looker', 'MicroStrategy', 'Cognos', 'QlikView', 'Power BI', 'Sigma', 'Superset'];
    var track = document.createElement('div');
    track.setAttribute('style', 'display:flex;width:max-content;animation:marquee 46s linear infinite');
    names.concat(names).forEach(function (name) {
      var span = document.createElement('span');
      span.setAttribute('style', 'display:inline-flex;align-items:center;gap:22px;padding:0 22px;font-size:15px;font-weight:600;letter-spacing:.14em;text-transform:uppercase;color:var(--ink2);white-space:nowrap');
      span.textContent = name;
      var arrow = document.createElement('span');
      arrow.setAttribute('style', 'color:var(--teal)');
      arrow.textContent = '→';
      span.appendChild(arrow);
      track.appendChild(span);
    });
    host.appendChild(track);
  }

  /* ---------- Before / after slider ---------- */
  function wireSlider() {
    var range = document.getElementById('split-range');
    var after = document.getElementById('after-clip');
    var divider = document.getElementById('divider');
    if (!range || !after || !divider) return;
    function apply(s) {
      after.style.clipPath = 'inset(0 0 0 ' + s + '%)';
      divider.style.left = s + '%';
    }
    range.addEventListener('input', function (e) { apply(+e.target.value); });
    apply(+range.value);
  }

  /* ---------- Hero particle field ---------- */
  function startField() {
    var c = document.getElementById('hero-field');
    if (!c || !c.getContext) return;
    var ctx = c.getContext('2d');
    var N = 320;
    var P = [];
    for (var i = 0; i < N; i++) {
      P.push({
        t: rnd(i * 7 + 1), lane: rnd(i * 13 + 3), speed: 0.0009 + rnd(i * 17 + 5) * 0.0016,
        w: 3 + rnd(i * 19 + 7) * 9, h: 3 + rnd(i * 23 + 9) * 5, wob: rnd(i * 29 + 11) * Math.PI * 2
      });
    }
    var W = 0, H = 0, raf;
    function resize() {
      var r = c.getBoundingClientRect();
      var dpr = Math.min(2, window.devicePixelRatio || 1);
      W = r.width; H = r.height; c.width = W * dpr; c.height = H * dpr; ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    resize();
    if (window.ResizeObserver) { var ro = new ResizeObserver(resize); ro.observe(c); }
    else { window.addEventListener('resize', resize); }

    var mouse = { x: -1e4, y: -1e4 };
    var parent = c.parentElement;
    parent.addEventListener('pointermove', function (e) {
      var r = c.getBoundingClientRect(); mouse.x = e.clientX - r.left; mouse.y = e.clientY - r.top;
    });
    parent.addEventListener('pointerleave', function () { mouse.x = -1e4; });

    function hex(v) { return getComputedStyle(root).getPropertyValue(v).trim(); }
    function toRGB(h) { var m = h.replace('#', ''); return [0, 2, 4].map(function (i) { return parseInt(m.slice(i, i + 2), 16); }); }
    var amber = toRGB(hex('--amber')), teal = toRGB(hex('--teal')), tick = 0;

    function draw(now) {
      if ((tick++ & 63) === 0) { amber = toRGB(hex('--amber')); teal = toRGB(hex('--teal')); }
      ctx.clearRect(0, 0, W, H);
      var cy = H * 0.42, spreadIn = H * 0.36, spreadOut = H * 0.14;
      for (var p, idx = 0; idx < P.length; idx++) {
        p = P[idx];
        p.t += p.speed; if (p.t > 1.08) { p.t = -0.08; p.lane = Math.random(); }
        var t = Math.min(1, Math.max(0, p.t));
        var e = t * t * (3 - 2 * t);
        var x = -40 + p.t * (W + 80);
        var spread = spreadIn + (spreadOut - spreadIn) * e;
        var yBase = cy + (p.lane - 0.5) * 2 * spread * (1 - e) + (p.lane - 0.5) * 2 * spreadOut * e;
        var wob = Math.sin(now * 0.0012 + p.wob + x * 0.01) * 10 * (1 - e);
        var y = yBase + wob;
        var dx = x - mouse.x, dy = y - mouse.y, d2 = dx * dx + dy * dy;
        if (d2 < 22000) { var force = (1 - d2 / 22000) * 34; y += (dy / Math.sqrt(d2 + 1)) * force; }
        var r = Math.round(amber[0] + (teal[0] - amber[0]) * e);
        var g = Math.round(amber[1] + (teal[1] - amber[1]) * e);
        var b = Math.round(amber[2] + (teal[2] - amber[2]) * e);
        var alpha = 0.25 + 0.65 * (1 - Math.abs(0.5 - t) * 1.2);
        ctx.fillStyle = 'rgba(' + r + ',' + g + ',' + b + ',' + alpha + ')';
        var w = p.w * (1 - e * 0.35), h = p.h;
        ctx.save(); ctx.translate(x, y); ctx.rotate((1 - e) * (p.lane - 0.5) * 0.9); ctx.fillRect(-w / 2, -h / 2, w, h); ctx.restore();
      }
      ctx.strokeStyle = 'rgba(' + teal[0] + ',' + teal[1] + ',' + teal[2] + ',0.08)'; ctx.lineWidth = 1;
      for (var li = 0; li < 6; li++) {
        var ly = cy + (li - 2.5) * spreadOut * 0.5;
        ctx.beginPath(); ctx.moveTo(W * 0.55, ly); ctx.lineTo(W, ly); ctx.stroke();
      }
      raf = requestAnimationFrame(draw);
    }
    raf = requestAnimationFrame(draw);
  }

  /* ---------- Init ---------- */
  function init() {
    updateThemeLabel();
    wireHovers();
    buildGrids();
    buildMarquee();
    wireSlider();
    startField();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

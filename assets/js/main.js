(function () {
  'use strict';

  var root = document.documentElement;
  var mqMobile = window.matchMedia('(max-width: 760px)');
  var mqReduce = window.matchMedia('(prefers-reduced-motion: reduce)');
  var THEME_COLORS = { light: '#F1EEE6', dark: '#05070A' };

  function onChange(mq, fn) {
    if (mq.addEventListener) mq.addEventListener('change', fn); else if (mq.addListener) mq.addListener(fn);
  }

  /* ---------- Theme ---------- */
  function currentTheme() { return root.getAttribute('data-theme') || 'light'; }
  function syncThemeUI() {
    var t = currentTheme();
    var label = document.getElementById('theme-label');
    if (label) label.textContent = t === 'dark' ? 'Light' : 'Dark';
    document.querySelectorAll('[data-set-theme]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-theme') === t));
    });
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', THEME_COLORS[t] || THEME_COLORS.light);
  }
  function setTheme(t) {
    root.setAttribute('data-theme', t);
    try { localStorage.setItem('theme', t); } catch (e) {}
    syncThemeUI();
  }
  window.BIToggleTheme = function () { setTheme(currentTheme() === 'dark' ? 'light' : 'dark'); };

  function wireThemeSwitch() {
    document.querySelectorAll('[data-set-theme]').forEach(function (b) {
      b.addEventListener('click', function () { setTheme(b.getAttribute('data-set-theme')); });
    });
  }

  /* ---------- Mobile menu ---------- */
  function wireMenu() {
    var btn = document.querySelector('.menu-btn');
    var menu = document.getElementById('menu');
    if (!btn || !menu) return;
    function set(open) {
      root.classList.toggle('menu-open', open);
      btn.setAttribute('aria-expanded', String(open));
      btn.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
      menu.setAttribute('aria-hidden', String(!open));
      if ('inert' in menu) menu.inert = !open;
      document.dispatchEvent(new CustomEvent('bi:menu', { detail: open }));
    }
    set(false);
    btn.addEventListener('click', function () { set(!root.classList.contains('menu-open')); });
    menu.addEventListener('click', function (e) { if (e.target.closest('a')) set(false); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') set(false); });
    onChange(window.matchMedia('(min-width: 1001px)'), function (e) { if (e.matches) set(false); });
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
    track.className = 'marquee-track';
    names.concat(names).forEach(function (name, i) {
      var item = document.createElement('span');
      item.className = 'marquee-item';
      if (i >= names.length) item.setAttribute('aria-hidden', 'true');
      item.textContent = name;
      var arrow = document.createElement('span');
      arrow.setAttribute('aria-hidden', 'true');
      arrow.textContent = '→';
      item.appendChild(arrow);
      track.appendChild(item);
    });
    host.appendChild(track);
  }

  /* ---------- Before / after compare ---------- */
  function wireCompare() {
    var box = document.getElementById('compare');
    var range = document.getElementById('split-range');
    var after = document.getElementById('after-clip');
    var divider = document.getElementById('divider');
    if (!box || !range || !after || !divider) return;

    var touched = false, sweepRaf = 0;
    function apply(s) {
      s = Math.max(0, Math.min(100, s));
      after.style.clipPath = 'inset(0 0 0 ' + s + '%)';
      divider.style.left = s + '%';
      range.value = s;
    }
    function fromX(x) { var r = box.getBoundingClientRect(); apply((x - r.left) / r.width * 100); }
    function touch() {
      if (touched) return;
      touched = true;
      box.classList.add('is-touched');
      cancelAnimationFrame(sweepRaf);
    }

    // Mouse drags immediately; touch waits for a clearly horizontal gesture so
    // vertical page scrolling through the box never nudges the divider.
    var drag = null;
    box.addEventListener('pointerdown', function (e) {
      if (e.button > 0) return;
      drag = { id: e.pointerId, x: e.clientX, y: e.clientY, active: e.pointerType === 'mouse' };
      if (drag.active) { touch(); fromX(e.clientX); try { box.setPointerCapture(e.pointerId); } catch (_) {} }
    });
    box.addEventListener('pointermove', function (e) {
      if (!drag || drag.id !== e.pointerId) return;
      if (!drag.active) {
        var dx = Math.abs(e.clientX - drag.x), dy = Math.abs(e.clientY - drag.y);
        if (dx > 6 && dx > dy) { drag.active = true; touch(); try { box.setPointerCapture(e.pointerId); } catch (_) {} }
        else return;
      }
      fromX(e.clientX);
    });
    box.addEventListener('pointerup', function (e) {
      if (drag && !drag.active && e.pointerType !== 'mouse') { touch(); fromX(e.clientX); } // tap to position
      drag = null;
    });
    box.addEventListener('pointercancel', function () { drag = null; });
    range.addEventListener('input', function (e) { touch(); apply(+e.target.value); });
    apply(50);

    // On phones, sweep once when the box scrolls into view to show it's interactive.
    function sweep() {
      var start = performance.now(), dur = 2400, keys = [50, 18, 82, 50];
      function frame(now) {
        if (touched) return;
        var p = Math.min(1, (now - start) / dur), seg = p * 3, i = Math.min(2, Math.floor(seg)), k = seg - i;
        var e = k * k * (3 - 2 * k);
        apply(keys[i] + (keys[i + 1] - keys[i]) * e);
        if (p < 1) sweepRaf = requestAnimationFrame(frame);
      }
      sweepRaf = requestAnimationFrame(frame);
    }
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting && !touched && mqMobile.matches && !mqReduce.matches) { io.disconnect(); sweep(); }
        });
      }, { threshold: 0.6 });
      io.observe(box);
    }
  }

  /* ---------- Manifesto swipe cards (mobile) ---------- */
  function wirePillars() {
    var track = document.getElementById('pillars');
    var dots = Array.prototype.slice.call(document.querySelectorAll('.pillar-dots button'));
    if (!track || !dots.length) return;
    var cards = Array.prototype.slice.call(track.querySelectorAll('.pillar'));
    function update() {
      var best = 0;
      if (track.scrollLeft + track.clientWidth >= track.scrollWidth - 4) best = cards.length - 1;
      else {
        var bd = Infinity;
        cards.forEach(function (c, i) { var d = Math.abs(c.offsetLeft - track.scrollLeft - 20); if (d < bd) { bd = d; best = i; } });
      }
      dots.forEach(function (d, i) { d.classList.toggle('is-active', i === best); });
    }
    var ticking = false;
    track.addEventListener('scroll', function () {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(function () { ticking = false; update(); });
    }, { passive: true });
    dots.forEach(function (d, i) {
      d.addEventListener('click', function () { track.scrollTo({ left: cards[i].offsetLeft - 20, behavior: 'smooth' }); });
    });
    update();
  }

  /* ---------- Floating scan dock (mobile) ---------- */
  function wireDock() {
    var dock = document.getElementById('dock');
    if (!dock || !('IntersectionObserver' in window)) return;
    // Hidden while the hero CTAs, the scan form or the footer are on screen, or the menu is open.
    var state = { ctas: true, scan: false, foot: false, menu: false };
    var targets = [
      [document.querySelector('.hero-ctas'), 'ctas'],
      [document.getElementById('scan'), 'scan'],
      [document.querySelector('.site-footer'), 'foot']
    ];
    function render() {
      var show = !state.ctas && !state.scan && !state.foot && !state.menu;
      dock.classList.toggle('is-visible', show);
      dock.setAttribute('aria-hidden', String(!show));
      dock.tabIndex = show ? 0 : -1;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        targets.forEach(function (t) { if (t[0] === en.target) state[t[1]] = en.isIntersecting; });
      });
      render();
    });
    targets.forEach(function (t) { if (t[0]) io.observe(t[0]); });
    document.addEventListener('bi:menu', function (e) { state.menu = e.detail; render(); });
  }

  /* ---------- Hero particle field ----------
     Desktop: particles stream left→right into the target on the right.
     Mobile:  particles rain top→bottom and converge into the teal "Anywhere" dot. */
  function startField() {
    var c = document.getElementById('hero-field');
    if (!c || !c.getContext) return;
    var hero = c.parentElement;
    var ctx = c.getContext('2d');
    var P = [];
    for (var i = 0; i < 320; i++) {
      P.push({
        t: rnd(i * 7 + 1), lane: rnd(i * 13 + 3), speed: 0.0009 + rnd(i * 17 + 5) * 0.0016,
        w: 3 + rnd(i * 19 + 7) * 9, h: 3 + rnd(i * 23 + 9) * 5, wob: rnd(i * 29 + 11) * Math.PI * 2
      });
    }
    var W = 0, H = 0, tx = 0, ty = 0, mobile = mqMobile.matches;

    function measure() {
      var r = c.getBoundingClientRect();
      var dpr = Math.min(2, window.devicePixelRatio || 1);
      W = r.width; H = r.height; c.width = W * dpr; c.height = H * dpr; ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      mobile = mqMobile.matches;
      var dot = hero.querySelector('.hero-kicker .dot-teal');
      if (mobile && dot) {
        // offset* ignores the kicker's entrance transform, so the target is stable mid-animation
        var x = dot.offsetWidth / 2, y = dot.offsetHeight / 2, el = dot;
        while (el && el !== hero) { x += el.offsetLeft; y += el.offsetTop; el = el.offsetParent; }
        tx = x; ty = y;
        hero.style.setProperty('--tx', tx + 'px');
        hero.style.setProperty('--ty', ty + 'px');
      }
    }

    var mouse = { x: -1e4, y: -1e4 };
    hero.addEventListener('pointermove', function (e) {
      var r = c.getBoundingClientRect(); mouse.x = e.clientX - r.left; mouse.y = e.clientY - r.top;
    });
    hero.addEventListener('pointerleave', function () { mouse.x = -1e4; });

    function hex(v) { return getComputedStyle(root).getPropertyValue(v).trim(); }
    function toRGB(h) { var m = h.replace('#', ''); return [0, 2, 4].map(function (k) { return parseInt(m.slice(k, k + 2), 16); }); }
    var amber = toRGB(hex('--amber')), teal = toRGB(hex('--teal')), tick = 0;

    function drawHorizontal(now, advance) {
      var cy = H * 0.42, spreadIn = H * 0.36, spreadOut = H * 0.14;
      for (var idx = 0; idx < P.length; idx++) {
        var p = P[idx];
        if (advance) { p.t += p.speed; if (p.t > 1.08) { p.t = -0.08; p.lane = Math.random(); } }
        var t = Math.min(1, Math.max(0, p.t));
        var e = t * t * (3 - 2 * t);
        var x = -40 + p.t * (W + 80);
        var spread = spreadIn + (spreadOut - spreadIn) * e;
        var y = cy + (p.lane - 0.5) * 2 * spread * (1 - e) + (p.lane - 0.5) * 2 * spreadOut * e;
        y += Math.sin(now * 0.0012 + p.wob + x * 0.01) * 10 * (1 - e);
        var dx = x - mouse.x, dy = y - mouse.y, d2 = dx * dx + dy * dy;
        if (d2 < 22000) { y += (dy / Math.sqrt(d2 + 1)) * (1 - d2 / 22000) * 34; }
        paint(x, y, p.w * (1 - e * 0.35), p.h, (1 - e) * (p.lane - 0.5) * 0.9, e, 0.25 + 0.65 * (1 - Math.abs(0.5 - t) * 1.2));
      }
      ctx.strokeStyle = 'rgba(' + teal[0] + ',' + teal[1] + ',' + teal[2] + ',0.08)'; ctx.lineWidth = 1;
      for (var li = 0; li < 6; li++) {
        var ly = cy + (li - 2.5) * spreadOut * 0.5;
        ctx.beginPath(); ctx.moveTo(W * 0.55, ly); ctx.lineTo(W, ly); ctx.stroke();
      }
    }

    function drawVertical(now, advance) {
      var L = ty + 40, spreadIn = W * 0.62, spreadOut = W * 0.03;
      for (var idx = 0; idx < 200; idx++) {
        var p = P[idx];
        if (advance) { p.t += p.speed * 1.6; if (p.t > 1.08) { p.t = -0.08; p.lane = Math.random(); } }
        var t = Math.min(1, Math.max(0, p.t));
        var e = t * t * (3 - 2 * t);
        var y = -40 + p.t * L;
        var spread = spreadIn + (spreadOut - spreadIn) * e;
        var cx = W * 0.5 + (tx - W * 0.5) * e; // enter centred, sweep diagonally into the target
        var x = cx + (p.lane - 0.5) * 2 * spread * (1 - e) + (p.lane - 0.5) * 2 * spreadOut * e;
        x += Math.sin(now * 0.0012 + p.wob + y * 0.01) * 8 * (1 - e);
        var dx = x - mouse.x, dy = y - mouse.y, d2 = dx * dx + dy * dy;
        if (d2 < 16000) { x += (dx / Math.sqrt(d2 + 1)) * (1 - d2 / 16000) * 30; }
        var alpha = 0.25 + 0.65 * (1 - Math.abs(0.5 - t) * 1.2);
        if (p.t > 1) alpha *= Math.max(0, 1 - (p.t - 1) / 0.08);
        paint(x, y, p.w * 0.85 * (1 - e * 0.35), p.h * 0.85, Math.PI / 2 + (1 - e) * (p.lane - 0.5) * 0.9, e, alpha);
      }
      // funnel hairlines + halo around the target dot
      ctx.strokeStyle = 'rgba(' + teal[0] + ',' + teal[1] + ',' + teal[2] + ',0.12)'; ctx.lineWidth = 1;
      var hx = W * 0.5 + (tx - W * 0.5) * 0.4;
      for (var li = 0; li < 6; li++) {
        ctx.beginPath(); ctx.moveTo(hx + (li - 2.5) * 26, ty * 0.42); ctx.lineTo(tx + (li - 2.5) * 3, ty - 12); ctx.stroke();
      }
      ctx.fillStyle = 'rgba(' + teal[0] + ',' + teal[1] + ',' + teal[2] + ',0.07)';
      ctx.beginPath(); ctx.arc(tx, ty, 34, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = 'rgba(' + teal[0] + ',' + teal[1] + ',' + teal[2] + ',0.16)';
      ctx.beginPath(); ctx.arc(tx, ty, 19, 0, Math.PI * 2); ctx.fill();
    }

    function paint(x, y, w, h, rot, e, alpha) {
      var r = Math.round(amber[0] + (teal[0] - amber[0]) * e);
      var g = Math.round(amber[1] + (teal[1] - amber[1]) * e);
      var b = Math.round(amber[2] + (teal[2] - amber[2]) * e);
      ctx.fillStyle = 'rgba(' + r + ',' + g + ',' + b + ',' + alpha + ')';
      ctx.save(); ctx.translate(x, y); ctx.rotate(rot); ctx.fillRect(-w / 2, -h / 2, w, h); ctx.restore();
    }

    function render(now, advance) {
      if ((tick++ & 63) === 0) { amber = toRGB(hex('--amber')); teal = toRGB(hex('--teal')); if (mobile) measure(); }
      ctx.clearRect(0, 0, W, H);
      if (mobile) drawVertical(now, advance); else drawHorizontal(now, advance);
    }

    // Only animate while the hero is on screen; draw a single still frame for reduced motion.
    var visible = true, running = false;
    function loop(now) {
      if (!visible || mqReduce.matches) { running = false; return; }
      render(now, true);
      requestAnimationFrame(loop);
    }
    function kick() {
      if (mqReduce.matches) { render(0, false); return; }
      if (visible && !running) { running = true; requestAnimationFrame(loop); }
    }

    measure();
    if (window.ResizeObserver) new ResizeObserver(function () { measure(); if (mqReduce.matches) render(0, false); }).observe(c);
    else window.addEventListener('resize', measure);
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(measure);
    onChange(mqMobile, measure);
    onChange(mqReduce, kick);
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries) { visible = entries[0].isIntersecting; kick(); }).observe(hero);
    }
    kick();
  }

  /* ---------- Init ---------- */
  function init() {
    syncThemeUI();
    wireThemeSwitch();
    wireMenu();
    buildGrids();
    buildMarquee();
    wireCompare();
    wirePillars();
    wireDock();
    startField();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();

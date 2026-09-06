/* Summit Solar — interactions */
(function () {
  'use strict';

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var $  = function (s, c) { return (c || document).querySelector(s); };
  var $$ = function (s, c) { return Array.prototype.slice.call((c || document).querySelectorAll(s)); };

  /* ---- header state ------------------------------------- */
  var hdr = $('#hdr');
  var onScroll = function () { hdr.classList.toggle('is-stuck', window.scrollY > 24); };
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  /* ---- mobile nav --------------------------------------- */
  var burger = $('#burger'), nav = $('#nav');
  burger.addEventListener('click', function () {
    var open = nav.classList.toggle('is-open');
    burger.setAttribute('aria-expanded', String(open));
  });
  nav.addEventListener('click', function (e) {
    if (e.target.tagName === 'A') {
      nav.classList.remove('is-open');
      burger.setAttribute('aria-expanded', 'false');
    }
  });

  /* ---- videos: attach source and play only while in view -- */
  var vids = $$('.lazyvid');
  var onPhone = window.matchMedia('(max-width:680px)').matches;
  var attach = function (v) {
    if (v.src) { return; }
    if (onPhone && v.dataset.srcSm) {
      v.src = v.dataset.srcSm;
      if (v.dataset.posterSm) { v.poster = v.dataset.posterSm; }
    } else if (v.dataset.src) {
      v.src = v.dataset.src;
    }
  };
  if ('IntersectionObserver' in window) {
    var vio = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        var v = en.target;
        if (en.isIntersecting) {
          attach(v);
          if (!reduced) { var p = v.play(); if (p && p.catch) { p.catch(function () {}); } }
        } else if (!v.paused) {
          v.pause();
        }
      });
    }, { rootMargin: '200px 0px', threshold: 0.01 });
    vids.forEach(function (v) { vio.observe(v); });
  } else {
    vids.forEach(function (v) { attach(v); v.play(); });
  }

  /* ---- reveal on scroll --------------------------------- */
  var revealables = $$('.reveal');
  if (reduced || !('IntersectionObserver' in window)) {
    revealables.forEach(function (el) { el.classList.add('is-in'); });
  } else {
    var rio = new IntersectionObserver(function (entries) {
      entries.forEach(function (en, i) {
        if (!en.isIntersecting) { return; }
        var el = en.target;
        el.style.transitionDelay = Math.min(i * 70, 280) + 'ms';
        el.classList.add('is-in');
        rio.unobserve(el);
      });
    }, { rootMargin: '0px 0px -8%', threshold: 0.12 });
    revealables.forEach(function (el) { rio.observe(el); });
  }

  /* ---- stat counters ------------------------------------ */
  var counters = $$('.stats dt');
  if (!reduced && 'IntersectionObserver' in window) {
    var cio = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) { return; }
        var el = en.target;
        cio.unobserve(el);
        var target = parseFloat(el.dataset.count);
        var suffix = el.dataset.suffix || '';
        var t0 = null;
        var step = function (ts) {
          if (t0 === null) { t0 = ts; }
          var k = Math.min((ts - t0) / 1400, 1);
          var eased = 1 - Math.pow(1 - k, 3);
          el.textContent = Math.round(target * eased) + suffix;
          if (k < 1) { requestAnimationFrame(step); }
        };
        requestAnimationFrame(step);
      });
    }, { threshold: 0.5 });
    counters.forEach(function (el) { cio.observe(el); });
  }

  /* ---- hero dots: track the 12s background-video loop ---- */
  var dots = $$('#heroDots span');
  if (dots.length && !reduced) {
    var idx = 0;
    setInterval(function () {
      dots[idx].classList.remove('is-on');
      idx = (idx + 1) % dots.length;
      dots[idx].classList.add('is-on');
    }, 4000);
  }

  /* ---- savings calculator ------------------------------- */
  var inr = new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 });
  var form = $('#calcform'), out = $('#calcout'), bill = $('#bill');

  bill.addEventListener('blur', function () {
    var n = parseInt(String(bill.value).replace(/[^\d]/g, ''), 10);
    bill.value = isNaN(n) || n <= 0 ? '₹3000' : '₹' + inr.format(n);
  });

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    var n = parseInt(String(bill.value).replace(/[^\d]/g, ''), 10);
    if (isNaN(n) || n <= 0) {
      out.hidden = false;
      out.textContent = 'Please enter your average monthly electricity bill.';
      return;
    }

    var type = $('#ptype').value;
    var city = ($('#city').value || 'Bikaner').trim();

    var TARIFF = 8;      // ₹ per unit
    var PER_KW = 120;    // units generated per kW each month
    var SAVE   = 0.9;    // up to 90% of the bill, per the panel above

    var kw       = Math.max(1, Math.round((n / TARIFF / PER_KW) * 10) / 10);
    var monthly  = Math.round(n * SAVE);
    var yearly   = monthly * 12;
    var lifetime = yearly * 25;

    out.hidden = false;
    out.innerHTML =
      'A <strong>' + kw + ' kW</strong> ' + type.toLowerCase() + ' system in ' + city +
      ' could save about <strong>₹' + inr.format(monthly) + '</strong> a month — ' +
      'around <strong>₹' + inr.format(yearly) + '</strong> a year, and roughly <strong>₹' +
      inr.format(lifetime) + '</strong> across the 25-year panel warranty.' +
      '<br><span style="opacity:.7;font-size:13px">Indicative estimate. Book a free site survey for an exact quote.</span>';
    out.scrollIntoView({ behavior: reduced ? 'auto' : 'smooth', block: 'nearest' });
  });
})();

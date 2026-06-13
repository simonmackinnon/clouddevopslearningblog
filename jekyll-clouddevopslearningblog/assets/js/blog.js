(function () {
  // Reading progress bar
  var bar = document.getElementById('reading-progress');
  if (bar) {
    window.addEventListener('scroll', function () {
      var article = document.getElementById('post-content');
      if (!article) return;
      var total = article.offsetHeight - window.innerHeight;
      var scrolled = Math.max(0, window.scrollY - article.offsetTop);
      bar.style.width = Math.min(100, (scrolled / total) * 100) + '%';
    }, { passive: true });
  }

  // Auto-generate TOC from h2/h3 headings
  var content = document.getElementById('post-content');
  var tocList = document.getElementById('toc-list');
  if (!content || !tocList) return;

  var headings = content.querySelectorAll('h2, h3');
  if (headings.length < 2) {
    var tocEl = document.getElementById('post-toc');
    if (tocEl) tocEl.style.display = 'none';
    return;
  }

  headings.forEach(function (h, i) {
    if (!h.id) h.id = 'heading-' + i;
    var li = document.createElement('li');
    li.className = h.tagName === 'H3' ? 'toc-h3' : '';
    var a = document.createElement('a');
    a.href = '#' + h.id;
    a.textContent = h.textContent;
    li.appendChild(a);
    tocList.appendChild(li);
  });

  // Highlight active heading on scroll
  var tocLinks = tocList.querySelectorAll('a');
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        tocLinks.forEach(function (a) { a.classList.remove('active'); });
        var active = tocList.querySelector('a[href="#' + entry.target.id + '"]');
        if (active) active.classList.add('active');
      }
    });
  }, { rootMargin: '-15% 0px -75% 0px' });

  headings.forEach(function (h) { observer.observe(h); });
})();

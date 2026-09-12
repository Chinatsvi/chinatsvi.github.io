(function () {
  const content = window.AGRIBASE_CONTENT || { articles: [] };
  const nav = [
    ['Home', '/'], ['Farming Guides', '/guides/'], ['Calculators', '/calculators/'],
    ['Crop Calendar', '/calendar/'], ['Resources', '/resources/'], ['Academy', '/academy/'],
    ['Community App', '/community/'], ['Questions', '/faq/'], ['About', '/about/'], ['Contact', '/contact/']
  ];

  function renderHeader() {
    const host = document.querySelector('[data-site-header]');
    if (!host) return;
    host.innerHTML = '<nav class="site-nav"><div class="nav-inner"><a class="brand" href="/"><img src="/favicon-256.png" alt="AgriBase">AgriBase</a><button class="nav-toggle" aria-label="Open navigation"><span></span><span></span><span></span></button><div class="nav-links">' +
      nav.map(item => '<a href="' + item[1] + '">' + item[0] + '</a>').join('') +
      '</div></div></nav>';
    host.querySelector('.nav-toggle').onclick = () => host.querySelector('.nav-links').classList.toggle('open');
  }

  function renderFooter() {
    const host = document.querySelector('[data-site-footer]');
    if (!host) return;
    host.innerHTML = '<footer><div class="container footer-grid"><div><h3>AgriBase</h3><p>Practical farming knowledge, planning tools and community resources for farmers.</p></div><div><h3>Learn</h3><a href="/guides/">Farming Guides</a><a href="/academy/">Farming Academy</a><a href="/calendar/">Crop Calendar</a></div><div><h3>Tools</h3><a href="/calculators/">Farm Calculators</a><a href="/resources/">Resources</a><a href="/community/">Community App</a></div><div><h3>Trust</h3><a href="/about/">About</a><a href="/contact/">Contact</a><a href="/privacy/">Privacy Policy</a><a href="/terms/">Terms of Use</a><a href="/disclaimer/">Disclaimer</a></div></div><div class="container copyright">Â© 2026 AgriBase. Educational information; adapt decisions to local conditions.</div></footer>';
  }

  function articleCards(items) {
    return items.map(article => '<article class="card"><div class="meta">' + article.category + '</div><h3>' + article.title + '</h3><p>' + article.description + '</p><a class="link" href="/guides/' + article.slug + '.html">Read guide â†’</a></article>').join('');
  }

  function renderArticles() {
    const list = document.querySelector('[data-articles]');
    if (list) list.innerHTML = articleCards(content.articles);
    const search = document.querySelector('[data-search]');
    if (search && list) {
      search.oninput = () => {
        const query = search.value.toLowerCase();
        list.innerHTML = articleCards(content.articles.filter(article => (article.title + article.description + article.category).toLowerCase().includes(query)));
      };
    }
    const articleHost = document.querySelector('[data-article]');
    if (!articleHost) return;
    const slug = location.pathname.split('/').pop().replace('.html', '');
    const article = content.articles.find(item => item.slug === slug) || content.articles[0];
    document.title = article.title + ' | AgriBase';
    const articleMain = articleHost.closest('main');
    if (articleMain) articleMain.classList.remove('section');
    articleHost.outerHTML = '<header class="page-hero article-page-hero"><div class="container"><div class="breadcrumb"><a href="/">Home</a> / <a href="/guides/">Farming Guides</a> / ' + article.title + '</div><div class="eyebrow">' + article.category + '</div><h1>' + article.title + '</h1><p class="lead">' + article.description + '</p></div></header><section class="section"><div class="container article">' + article.body + '<h2>Related Farming Guides</h2><div class="grid">' + articleCards(content.articles.filter(item => item.slug !== article.slug).slice(0, 3)) + '</div><div class="notice">Recommendations vary with soil, climate, crop variety, water supply and farming system. Use local extension advice and product labels where applicable.</div></div></section>';
  }

  function renderCalculator() {
    const calculator = document.querySelector('[data-calculator]');
    if (!calculator) return;
    const type = calculator.dataset.calculator;
    const value = id => parseFloat(document.getElementById(id).value);
    const output = document.querySelector('.result');
    document.querySelector('[data-calculate]').onclick = () => {
      let text = '';
      if (type === 'population' || type === 'spacing') {
        const row = value('row') / 100;
        const plant = value('plant') / 100;
        const area = type === 'population' ? value('area') * (document.getElementById('unit').value === 'acres' ? 0.404686 : 1) : 1;
        text = Math.round(10000 / (row * plant) * area).toLocaleString() + (type === 'population' ? ' plants' : ' plants per hectare');
      }
      if (type === 'profit') {
        const revenue = value('yield') * value('price');
        const profit = revenue - value('cost');
        text = profit.toFixed(2) + (profit >= 0 ? ' estimated profit' : ' estimated loss') + ' | Revenue: ' + revenue.toFixed(2) + ' | Margin: ' + (revenue ? (profit / revenue * 100).toFixed(1) : 0) + '%';
      }
      if (type === 'break-even') {
        const units = Math.ceil(value('cost') / value('price'));
        text = units + ' units to cover costs; break-even sales: ' + (units * value('price')).toFixed(2);
      }
      if (type === 'irrigation') {
        const net = Math.max(0, value('eto') * value('kc') - value('rain'));
        const gross = net / (value('eff') / 100);
        const area = value('area') * (document.getElementById('unit').value === 'acres' ? 0.404686 : 1);
        const litres = gross * area * 10000;
        text = Math.round(litres).toLocaleString() + ' litres (' + (litres / 1000).toFixed(1) + ' mÂ³) | Gross depth: ' + gross.toFixed(2) + ' mm';
      }
      if (type === 'fertilizer') text = (value('rate') * value('area')).toFixed(2) + ' kg of product';
      output.querySelector('strong').textContent = text;
      output.classList.add('show');
    };
    document.querySelector('[data-reset]').onclick = () => {
      document.querySelectorAll('input').forEach(input => { input.value = ''; });
      output.classList.remove('show');
    };
  }

  function start() {
    renderHeader();
    renderFooter();
    renderArticles();
    renderCalculator();
  }

  document.addEventListener('DOMContentLoaded', () => {
    if (content.articles.length < 20 && !document.querySelector('script[src$="content-more.js"]')) {
      const extension = document.createElement('script');
      extension.src = '/assets/content-more.js';
      extension.onload = start;
      extension.onerror = start;
      document.head.appendChild(extension);
    } else {
      start();
    }
  });
})();


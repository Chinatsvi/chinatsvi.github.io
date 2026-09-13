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
    if (/^\/about\/?$/.test(location.pathname)) {
      const about = document.querySelector('main .article');
      if (about && !about.querySelector('[data-author-bio]')) {
        about.insertAdjacentHTML('beforeend', '<section class="notice" data-author-bio><h2>About the author</h2><p><strong>Enock Chinatsvi</strong> is an agriculture diploma graduate of Chibhero Agricultural College in Zimbabwe, where he studied from 2015 to 2018. He is the founder of AgriBase and builds practical farming guidebooks, calculators and digital tools for farmers across Africa.</p><p>Enock is based in Zimbabwe and combines agricultural training with hands-on digital product development. <a href="https://github.com/Chinatsvi" target="_blank" rel="noopener">GitHub profile</a> | <a href="https://www.facebook.com/agrochinatsvi" target="_blank" rel="noopener">Facebook profile</a></p></section>');
      }
    }
    const articleHost = document.querySelector('[data-article]');
    if (!articleHost) return;
    const slug = location.pathname.split('/').pop().replace('.html', '');
    const article = content.articles.find(item => item.slug === slug) || content.articles[0];
    document.title = article.title + ' | AgriBase';
    const articleMain = articleHost.closest('main');
    if (articleMain) articleMain.classList.remove('section');
    articleHost.outerHTML = '<header class="page-hero article-page-hero"><div class="container"><div class="breadcrumb"><a href="/">Home</a> / <a href="/guides/">Farming Guides</a> / ' + article.title + '</div><div class="eyebrow">' + article.category + '</div><h1>' + article.title + '</h1><p class="lead">' + article.description + '</p></div></header><section class="section"><div class="container article">' + article.body + '<section class="notice"><h2>About the author</h2><p>This guide was written and reviewed by <strong>Enock Chinatsvi</strong>, an agriculture diploma graduate of Chibhero Agricultural College in Zimbabwe (2015-2018) and founder of AgriBase. Enock builds practical digital farming tools and guidebooks for farmers across Africa.</p><p><a href="/about/">Read the full author bio</a> | <a href="https://github.com/Chinatsvi" target="_blank" rel="noopener">View the author on GitHub</a> | <a href="https://www.facebook.com/agrochinatsvi" target="_blank" rel="noopener">Facebook</a></p></section><section class="references"><h2>References and further reading</h2><p>This guide provides general educational information. Use current local extension recommendations, soil and water test results, and product labels for decisions specific to your farm.</p><ul><li><a href="https://www.fao.org/soils-portal/en/" target="_blank" rel="noopener">FAO Soils Portal</a> - soil health, fertility and land management resources.</li><li><a href="https://www.fao.org/land-water/water/water-efficiency/en/" target="_blank" rel="noopener">FAO Land and Water</a> - irrigation, water efficiency and farm water management.</li><li><a href="https://www.nrcs.usda.gov/conservation-basics/soil-health" target="_blank" rel="noopener">USDA NRCS Soil Health</a> - practical soil health principles and conservation guidance.</li></ul></section><h2>Related Farming Guides</h2><div class="grid">' + articleCards(content.articles.filter(item => item.slug !== article.slug).slice(0, 3)) + '</div><div class="notice">Recommendations vary with soil, climate, crop variety, water supply and farming system. Use local extension advice and product labels where applicable.</div></div></section>';
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
    loadAdSense();
  }

  function loadAdSense() {
    if (document.querySelector('script[src$="/assets/adsense.js"]')) return;
    const script = document.createElement('script');
    script.src = '/assets/adsense.js';
    script.async = true;
    document.body.appendChild(script);
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


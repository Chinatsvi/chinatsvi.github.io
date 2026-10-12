const AdSenseManager = {
  config: {
    adClientId: 'ca-pub-2606126305565597',
    adSlotId: '7638324548'
  },

  init: function() {
    if (this.isExcludedPage()) return;
    this.ensureStylesheet();
    this.ensureAutomaticSlots();
    const existing = document.querySelector('script[src*="adsbygoogle.js"]');
    if (existing) {
      this.initializeAdSlots();
      return;
    }
    const script = document.createElement('script');
    script.async = true;
    script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + this.config.adClientId;
    script.crossOrigin = 'anonymous';
    script.onload = () => this.initializeAdSlots();
    document.head.appendChild(script);
  },

  ensureStylesheet: function() {
    if (document.querySelector('link[href$="/assets/adsense.css"]')) return;
    const stylesheet = document.createElement('link');
    stylesheet.rel = 'stylesheet';
    stylesheet.href = '/assets/adsense.css';
    document.head.appendChild(stylesheet);
  },

  ensureAutomaticSlots: function() {
    if (document.querySelector('[data-ad-slot], .adsbygoogle')) return;
    const hero = document.querySelector('.hero, .page-hero');
    const footer = document.querySelector('[data-site-footer], footer');
    const main = document.querySelector('main');
    const topSlot = this.createAutomaticSlot();
    const bottomSlot = this.createAutomaticSlot();
    if (hero) hero.insertAdjacentElement('afterend', topSlot);
    else if (main) main.insertAdjacentElement('beforebegin', topSlot);
    if (footer) footer.insertAdjacentElement('beforebegin', bottomSlot);
  },

  createAutomaticSlot: function() {
    const wrapper = document.createElement('div');
    wrapper.className = 'container ad-container ad-responsive';
    wrapper.innerHTML = '<span class="ad-label">Advertisement</span><div data-ad-slot="inContent"></div>';
    return wrapper;
  },

  isExcludedPage: function() {
    return /\/(privacy|terms|disclaimer|contact|404)(\/|\.html|$)/i.test(location.pathname);
  },

  initializeAdSlots: function() {
    window.adsbygoogle = window.adsbygoogle || [];
    document.querySelectorAll('[data-ad-slot]').forEach(container => {
      if (container.dataset.adInitialized === 'true') return;

      const ad = document.createElement('ins');
      ad.className = 'adsbygoogle';
      ad.style.display = 'block';
      ad.dataset.adClient = this.config.adClientId;
      ad.dataset.adSlot = this.config.adSlotId;
      ad.dataset.adFormat = 'auto';
      ad.dataset.fullWidthResponsive = 'true';
      container.replaceChildren(ad);
      container.dataset.adInitialized = 'true';

      try {
        window.adsbygoogle.push({});
      } catch (error) {
        container.dataset.adInitialized = 'false';
      }
    });
  }
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => AdSenseManager.init());
} else {
  AdSenseManager.init();
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = AdSenseManager;
}

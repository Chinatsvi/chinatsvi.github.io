// AdSense Management - Test Advertisement System
// This file manages test advertisements and will be replaced with real AdSense code

const AdSenseManager = {
  // Configuration
  config: {
    testMode: true, // Set to false when using real AdSense
    adClientId: 'ca-pub-XXXXXXXXXXXXXXXX', // Replace with your AdSense client ID
    enableLazyLoading: true,
    adBlockDetection: true
  },

  // Ad slot definitions - Replace with your real AdSense slot IDs
  adSlots: {
    leaderboard: 'div-gpt-ad-1234567890-0',      // 728x90
    rectangle: 'div-gpt-ad-1234567890-1',        // 336x280
    mediumRectangle: 'div-gpt-ad-1234567890-2',  // 300x250
    square: 'div-gpt-ad-1234567890-3',          // 250x250
    halfPage: 'div-gpt-ad-1234567890-4',         // 300x600
    mobileBanner: 'div-gpt-ad-1234567890-5',     // 320x50
    inContent: 'div-gpt-ad-1234567890-6',        // Responsive
    sidebar: 'div-gpt-ad-1234567890-7'           // 300x250
  },

  // Initialize AdSense
  init: function() {
    if (this.config.testMode) {
      console.log('AdSense running in TEST MODE - Using placeholder ads');
      this.loadTestAds();
    } else {
      console.log('AdSense running in PRODUCTION MODE - Using real AdSense');
      this.loadRealAdSense();
    }
  },

  // Load test advertisements
  loadTestAds: function() {
    // Find all ad containers and insert test ads
    const adContainers = document.querySelectorAll('[data-ad-slot]');
    
    adContainers.forEach(container => {
      const slotType = container.getAttribute('data-ad-slot');
      const testAd = this.createTestAd(slotType);
      container.innerHTML = testAd;
    });
  },

  // Create test advertisement HTML
  createTestAd: function(slotType) {
    const adConfig = this.getAdConfig(slotType);
    
    return `
      <div class="test-ad ${adConfig.cssClass}">
        <div class="test-ad-content">
          <div class="test-ad-title">${adConfig.title}</div>
          <div class="test-ad-description">${adConfig.description}</div>
          <a href="#" class="test-ad-cta">Learn More</a>
        </div>
      </div>
    `;
  },

  // Get advertisement configuration based on slot type
  getAdConfig: function(slotType) {
    const configs = {
      leaderboard: {
        cssClass: 'ad-leaderboard',
        title: 'Farm Equipment & Supplies',
        description: 'Quality tools for modern farming'
      },
      rectangle: {
        cssClass: 'ad-rectangle',
        title: 'Agricultural Services',
        description: 'Expert farming consultation and support'
      },
      mediumRectangle: {
        cssClass: 'ad-medium-rectangle',
        title: 'Crop Protection Solutions',
        description: 'Protect your investment with proven solutions'
      },
      square: {
        cssClass: 'ad-square',
        title: 'Farming Resources',
        description: 'Tools and guides for better yields'
      },
      halfPage: {
        cssClass: 'ad-half-page',
        title: 'Market Insights',
        description: 'Stay ahead with agricultural market trends'
      },
      mobileBanner: {
        cssClass: 'ad-mobile-banner',
        title: 'Mobile Farming App',
        description: 'Manage your farm from anywhere'
      },
      inContent: {
        cssClass: 'ad-responsive',
        title: 'Sustainable Farming',
        description: 'Build a profitable, eco-friendly farm'
      },
      sidebar: {
        cssClass: 'ad-sidebar',
        title: 'Farmer Community',
        description: 'Connect with fellow farmers'
      }
    };

    return configs[slotType] || configs.inContent;
  },

  // Load real AdSense (to be implemented with real AdSense code)
  loadRealAdSense: function() {
    // This will be replaced with actual AdSense implementation
    // Example structure:
    /*
    (function() {
      var script = document.createElement('script');
      script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js';
      script.async = true;
      document.head.appendChild(script);
      
      // Initialize ads after script loads
      script.onload = function() {
        AdSenseManager.initializeAdSlots();
      };
    })();
    */
    console.log('Real AdSense integration not yet implemented');
  },

  // Initialize individual ad slots (for real AdSense)
  initializeAdSlots: function() {
    const adContainers = document.querySelectorAll('[data-ad-slot]');
    
    adContainers.forEach(container => {
      const slotType = container.getAttribute('data-ad-slot');
      const slotId = this.adSlots[slotType];
      
      if (slotId) {
        // Real AdSense implementation would go here
        // (adsbygoogle = window.adsbygoogle || []).push({});
      }
    });
  },

  // Lazy load advertisements
  lazyLoadAds: function() {
    if (!this.config.enableLazyLoading) return;

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const container = entry.target;
          const slotType = container.getAttribute('data-ad-slot');
          
          if (this.config.testMode) {
            const testAd = this.createTestAd(slotType);
            container.innerHTML = testAd;
          }
          
          observer.unobserve(container);
        }
      });
    }, {
      rootMargin: '100px'
    });

    document.querySelectorAll('[data-ad-slot][data-lazy="true"]').forEach(container => {
      observer.observe(container);
    });
  },

  // Detect ad blockers
  detectAdBlocker: function() {
    if (!this.config.adBlockDetection) return;

    const testAd = document.createElement('div');
    testAd.innerHTML = '&nbsp;';
    testAd.className = 'adsbox ad-banner-ad';
    document.body.appendChild(testAd);
    
    setTimeout(() => {
      const isBlocked = testAd.offsetHeight === 0;
      document.body.removeChild(testAd);
      
      if (isBlocked) {
        console.log('Ad blocker detected');
        this.handleAdBlocker();
      }
    }, 100);
  },

  // Handle ad blocker detection
  handleAdBlocker: function() {
    // Show alternative content or message
    const adContainers = document.querySelectorAll('[data-ad-slot]');
    
    adContainers.forEach(container => {
      container.innerHTML = `
        <div class="ad-blocked-message">
          <p>Please support our farming community by disabling your ad blocker.</p>
        </div>
      `;
    });
  },

  // Refresh advertisements
  refreshAds: function() {
    if (this.config.testMode) {
      this.loadTestAds();
    } else {
      // Real AdSense refresh implementation
      // (adsbygoogle = window.adsbygoogle || []).push({});
    }
  }
};

// Initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    AdSenseManager.init();
  });
} else {
  AdSenseManager.init();
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
  module.exports = AdSenseManager;
}
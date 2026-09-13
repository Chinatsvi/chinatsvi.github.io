# AdSense Implementation Guide

## Overview
Test AdSense advertisements have been implemented across the AgriBase website. This document explains the current setup and how to replace with real AdSense code.

## Files Created

### 1. `/assets/adsense.css`
Contains styling for all advertisement types and placements:
- Leaderboard ads (728x90)
- Rectangle ads (336x280)
- Medium rectangle ads (300x250)
- Square ads (250x250)
- Half page ads (300x600)
- Mobile banner ads (320x50)
- Responsive ads
- Various positioning classes

### 2. `/assets/adsense.js`
JavaScript management system for advertisements:
- Test mode currently enabled
- Placeholder ad generation
- Configuration for real AdSense integration
- Ad slot management
- Lazy loading support
- Ad blocker detection

## Current Ad Placements

### Homepage (`index.html`)
- Leaderboard below hero section
- In-content ad between decision tools and additional resources sections
- Medium rectangle between additional resources and featured handbooks
- Leaderboard before footer

### Decision Tools Pages
- **Main index**: Leaderboard below hero, leaderboard before footer
- **Crop Selection Tool**: Leaderboard below hero, medium rectangle between start and money section, rectangle before final results

### Calculators Pages
- **Main index**: Leaderboard below hero, leaderboard before footer
- **Individual calculators**: Leaderboard below hero, medium rectangle in content, leaderboard before footer

### Guides Pages
- **Main index**: Leaderboard below hero, leaderboard before footer
- **Individual guides**: Leaderboard below header, medium rectangle in content, leaderboard before footer

### Community Page
- Leaderboard below hero, medium rectangle in content, leaderboard before footer

## How to Replace with Real AdSense

### Step 1: Get Your AdSense Account
1. Sign up for Google AdSense at https://www.google.com/adsense/
2. Add your website and get approval
3. Get your AdSense client ID (format: `ca-pub-XXXXXXXXXXXXXXXX`)

### Step 2: Create Ad Units
1. In your AdSense dashboard, create ad units for each size you need:
   - Leaderboard (728x90)
   - Medium Rectangle (300x250)
   - Large Rectangle (336x280)
   - Responsive (for mobile)

2. Copy the ad unit IDs for each created unit

### Step 3: Update Configuration
Edit `/assets/adsense.js` and update the configuration:

```javascript
const AdSenseManager = {
  config: {
    testMode: false, // Change from true to false
    adClientId: 'ca-pub-XXXXXXXXXXXXXXXX', // Replace with your real client ID
    enableLazyLoading: true,
    adBlockDetection: true
  },

  adSlots: {
    leaderboard: 'div-gpt-ad-XXXXXXXXXX-0',      // Replace with real ad slot IDs
    rectangle: 'div-gpt-ad-XXXXXXXXXX-1',        // Replace with real ad slot IDs
    mediumRectangle: 'div-gpt-ad-XXXXXXXXXX-2',  // Replace with real ad slot IDs
    square: 'div-gpt-ad-XXXXXXXXXX-3',          // Replace with real ad slot IDs
    halfPage: 'div-gpt-ad-XXXXXXXXXX-4',         // Replace with real ad slot IDs
    mobileBanner: 'div-gpt-ad-XXXXXXXXXX-5',     // Replace with real ad slot IDs
    inContent: 'div-gpt-ad-XXXXXXXXXX-6',        // Replace with real ad slot IDs
    sidebar: 'div-gpt-ad-XXXXXXXXXX-7'           // Replace with real ad slot IDs
  },
```

### Step 4: Update Real AdSense Integration
In `/assets/adsense.js`, uncomment and implement the real AdSense loading in the `loadRealAdSense` function:

```javascript
loadRealAdSense: function() {
  // Add AdSense script
  (function() {
    var script = document.createElement('script');
    script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js';
    script.async = true;
    document.head.appendChild(script);
    
    script.onload = function() {
      AdSenseManager.initializeAdSlots();
    };
  })();
},

initializeAdSlots: function() {
  const adContainers = document.querySelectorAll('[data-ad-slot]');
  
  adContainers.forEach(container => {
    const slotType = container.getAttribute('data-ad-slot');
    const slotId = this.adSlots[slotType];
    
    if (slotId) {
      // Create real AdSense ad
      const adIns = document.createElement('ins');
      adIns.className = 'adsbygoogle';
      adIns.style.display = 'block';
      adIns.setAttribute('data-ad-client', this.config.adClientId);
      adIns.setAttribute('data-ad-slot', slotId);
      adIns.setAttribute('data-ad-format', 'auto');
      adIns.setAttribute('data-full-width-responsive', 'true');
      
      container.innerHTML = '';
      container.appendChild(adIns);
      
      (adsbygoogle = window.adsbygoogle || []).push({});
    }
  });
}
```

### Step 5: Remove Test Ad Styling (Optional)
If you want to remove the test ad styling, you can delete or comment out the test ad CSS in `/assets/adsense.css`:

```css
/* Remove or comment out these sections when using real ads */
.test-ad { ... }
.test-ad-content { ... }
.test-ad-title { ... }
/* etc */
```

## Ad Placement Best Practices

### Current Placements Are Optimized For:
1. **User Experience**: Ads don't interfere with main content
2. **Visibility**: Placed in high-traffic areas
3. **Performance**: Responsive design for mobile devices
4. **Compliance**: Follows AdSense placement policies

### Recommended Ad Sizes:
- **Leaderboard (728x90)**: Top of pages, above content
- **Medium Rectangle (300x250)**: In-content, sidebars
- **Large Rectangle (336x280)**: In-content, sidebars
- **Responsive**: Automatically adjusts for mobile

## Testing

### Test Mode
Currently the system is in test mode (`testMode: true`). To test real ads:
1. Set `testMode: false` in configuration
2. Use your real AdSense client ID
3. Ads will display in test mode (no revenue) until approved

### Validation
1. Check browser console for any errors
2. Ensure ads display correctly on different screen sizes
3. Verify mobile responsiveness
4. Test ad blocker detection if enabled

## Maintenance

### Regular Tasks:
- Monitor ad performance in AdSense dashboard
- Update ad placements based on performance data
- Ensure compliance with AdSense policies
- Test new ad sizes and placements

### Troubleshooting:
- If ads don't appear: Check browser console for errors
- If layout breaks: Verify CSS conflicts
- If revenue is low: Experiment with different placements

## Compliance Notes

- Ad placements follow Google AdSense policies
- Ads are clearly distinguishable from content
- No deceptive placement practices
- Mobile-friendly ad implementations
- Respect user experience and page load times

## Files Modified

### Added:
- `/assets/adsense.css` - Advertisement styling
- `/assets/adsense.js` - Advertisement management

### Modified:
- `index.html` - Homepage ads
- `decision-tools/index.html` - Decision tools page ads
- `decision-tools/crop-selection/index.html` - Crop selection tool ads
- `calculators/index.html` - Calculators page ads
- `calculators/plant-population.html` - Plant population calculator ads
- `calculators/crop-spacing.html` - Crop spacing calculator ads
- `calculators/farm-budget.html` - Farm budget calculator ads
- `guides/index.html` - Guides page ads
- `guides/beginner-irrigation-guide.html` - Irrigation guide ads
- `guides/pest-disease-management.html` - Pest management guide ads
- `guides/plan-fertilizer-application.html` - Fertilizer guide ads
- `community/index.html` - Community page ads

## Next Steps

1. **Get AdSense Approval**: Apply and get approved for AdSense
2. **Create Ad Units**: Set up ad units in your AdSense dashboard
3. **Update Configuration**: Replace test configuration with real AdSense data
4. **Test Thoroughly**: Ensure ads display correctly across all pages
5. **Monitor Performance**: Track ad performance and optimize placements
6. **Compliance Check**: Regular review of AdSense policy compliance

## Support

For AdSense-specific issues, refer to:
- Google AdSense Help Center: https://support.google.com/adsense/
- AdSense Policy Guidelines: https://support.google.com/adsense/answer/48182?hl=en

For implementation issues with this setup, check the browser console for JavaScript errors and verify that all files are properly linked.
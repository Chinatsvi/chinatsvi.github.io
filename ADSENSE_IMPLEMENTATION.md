# AdSense Implementation Guide

## Overview
AgriBase uses responsive Google AdSense units on the home page, guides, calculators, community page, and decision tools. The shared loader uses publisher `ca-pub-2606126305565597` and ad unit `7638324548`, reserves space to reduce layout shift, and initializes each slot once.

## Files Created

### 1. `/assets/adsense.css`
Contains styling for shared advertisement containers and placements:
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
- Loads the AdSense library when a page does not already load it
- Creates responsive production units from `data-ad-slot` containers
- Prevents duplicate initialization
- Leaves slots unobtrusive when ads are unavailable or blocked

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

## AdSense Configuration

The current production configuration is in `/assets/adsense.js`:

```js
adClientId: 'ca-pub-2606126305565597',
adSlotId: '7638324548'
```

Change these values only when the AdSense account or ad unit changes. The `ads.txt` entry must continue to use the same publisher ID.

### Account and ad unit setup
1. Sign up for Google AdSense at https://www.google.com/adsense/
2. Add your website and get approval
3. Get your AdSense client ID (format: `ca-pub-XXXXXXXXXXXXXXXX`)

### Create additional ad units
1. In your AdSense dashboard, create ad units for each size you need:
   - Leaderboard (728x90)
   - Medium Rectangle (300x250)
   - Large Rectangle (336x280)
   - Responsive (for mobile)

2. Copy the ad unit IDs for each created unit

### Remove old test styling (Optional)
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
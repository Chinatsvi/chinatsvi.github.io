/**
 * AgriBase Crop Calendar UI & Interactive Controller
 * Connects CropCalendarEngine & Datasets to HTML UI
 */

document.addEventListener('DOMContentLoaded', function() {
  const data = window.HorticulturalCropsData;
  const zones = window.RegionalAgroZonesData;
  const engine = window.CropCalendarEngine;

  if (!data || !zones || !engine) {
    console.error('Crop Calendar dependencies not found');
    return;
  }

  // Elements
  const tabBtnPlan = document.getElementById('tab-btn-plan');
  const tabBtnSaved = document.getElementById('tab-btn-saved');
  const viewPlanTab = document.getElementById('view-plan-tab');
  const viewSavedTab = document.getElementById('view-saved-tab');

  const countrySelect = document.getElementById('calendar-country');
  const regionSelect = document.getElementById('calendar-region');
  const climateInfoBox = document.getElementById('climate-info-box');

  const cropSelect = document.getElementById('calendar-crop');
  const varietySelect = document.getElementById('calendar-variety');
  const cropDescriptionBox = document.getElementById('crop-description-box');

  const prodSystemSelect = document.getElementById('calendar-production-system');
  const waterSourceSelect = document.getElementById('calendar-water-source');
  const plantingDateInput = document.getElementById('calendar-planting-date');
  const soilTestCheck = document.getElementById('calendar-soil-test');

  const btnGeneratePlan = document.getElementById('btn-generate-plan');
  const resultsContainer = document.getElementById('results-container');
  const savedListContainer = document.getElementById('saved-plans-list');

  // Set default date to today
  if (plantingDateInput && !plantingDateInput.value) {
    const today = new Date().toISOString().split('T')[0];
    plantingDateInput.value = today;
  }

  // 1. Populate Country & Region
  function initLocations() {
    if (!countrySelect) return;
    const countries = Array.from(new Set(zones.presetLocations.map(l => l.country))).sort();
    
    countrySelect.innerHTML = '<option value="">-- Select Country --</option>';
    countries.forEach(c => {
      const opt = document.createElement('option');
      opt.value = c;
      opt.textContent = c;
      countrySelect.appendChild(opt);
    });

    // Default to Zimbabwe or first
    countrySelect.value = 'Zimbabwe';
    onCountryChanged();
  }

  function onCountryChanged() {
    const country = countrySelect.value;
    regionSelect.innerHTML = '<option value="">-- Select Region / District --</option>';
    
    let matching = zones.presetLocations.filter(l => l.country === country);
    if (matching.length === 0) {
      // Fallback
      matching = [zones.getDefaultSouthernProfile()];
    }

    matching.forEach(loc => {
      const opt = document.createElement('option');
      opt.value = loc.district || loc.region;
      opt.textContent = `${loc.district || loc.region} (${loc.climateZone})`;
      opt.dataset.profile = JSON.stringify(loc);
      regionSelect.appendChild(opt);
    });

    if (regionSelect.options.length > 1) {
      regionSelect.selectedIndex = 1;
    }
    onRegionChanged();
  }

  function onRegionChanged() {
    const selectedOpt = regionSelect.options[regionSelect.selectedIndex];
    if (selectedOpt && selectedOpt.dataset.profile) {
      const profile = JSON.parse(selectedOpt.dataset.profile);
      climateInfoBox.style.display = 'block';
      climateInfoBox.innerHTML = `
        <strong>${profile.climateZone}</strong> (Elev. ${profile.elevationMeters || 1000}m)<br>
        <small style="color: var(--muted);">${profile.seasonalNotes}</small>
      `;
    } else {
      climateInfoBox.style.display = 'none';
    }
  }

  if (countrySelect) countrySelect.addEventListener('change', onCountryChanged);
  if (regionSelect) regionSelect.addEventListener('change', onRegionChanged);

  // 2. Populate Crops & Varieties
  function initCrops() {
    if (!cropSelect) return;
    cropSelect.innerHTML = '<option value="">-- Select Crop --</option>';

    data.allCrops.forEach(c => {
      const opt = document.createElement('option');
      opt.value = c.id;
      opt.textContent = `${c.iconEmoji} ${c.name}`;
      cropSelect.appendChild(opt);
    });

    cropSelect.value = 'tomato';
    onCropChanged();
  }

  function onCropChanged() {
    const cropId = cropSelect.value;
    const crop = data.allCrops.find(c => c.id === cropId);
    varietySelect.innerHTML = '<option value="">-- Standard / Variety --</option>';

    if (crop) {
      cropDescriptionBox.style.display = 'block';
      cropDescriptionBox.innerHTML = `
        <strong>${crop.name}</strong> (<em>${crop.scientificName}</em>)<br>
        <small style="color: var(--muted);">${crop.generalDescription}</small><br>
        <span class="chip-sm">Maturity: ${crop.standardMaturityDaysMin}–${crop.standardMaturityDaysMax} days</span>
        <span class="chip-sm">Temp: ${crop.optimalTempMin}–${crop.optimalTempMax}°C</span>
        <span class="chip-sm">pH: ${crop.soilPhRange}</span>
      `;

      if (crop.varieties && crop.varieties.length > 0) {
        crop.varieties.forEach(v => {
          const opt = document.createElement('option');
          opt.value = v.id;
          opt.textContent = `${v.name} (${v.maturityDaysMin}–${v.maturityDaysMax} days)`;
          varietySelect.appendChild(opt);
        });
      }
    } else {
      cropDescriptionBox.style.display = 'none';
    }
  }

  if (cropSelect) cropSelect.addEventListener('change', onCropChanged);

  // Initialize dropdowns
  initLocations();
  initCrops();

  // 3. Tab Switcher
  if (tabBtnPlan && tabBtnSaved) {
    tabBtnPlan.addEventListener('click', () => {
      tabBtnPlan.classList.add('active');
      tabBtnSaved.classList.remove('active');
      viewPlanTab.style.display = 'block';
      viewSavedTab.style.display = 'none';
    });

    tabBtnSaved.addEventListener('click', () => {
      tabBtnSaved.classList.add('active');
      tabBtnPlan.classList.remove('active');
      viewSavedTab.style.display = 'block';
      viewPlanTab.style.display = 'none';
      renderSavedPlans();
    });
  }

  // 4. Generate Recommendation Handler
  if (btnGeneratePlan) {
    btnGeneratePlan.addEventListener('click', function(e) {
      e.preventDefault();

      const cropId = cropSelect.value;
      const crop = data.allCrops.find(c => c.id === cropId);
      if (!crop) return;

      const selectedOpt = regionSelect.options[regionSelect.selectedIndex];
      let locationProfile = selectedOpt && selectedOpt.dataset.profile ? JSON.parse(selectedOpt.dataset.profile) : zones.getDefaultSouthernProfile();

      const varietyId = varietySelect.value;
      const variety = crop.varieties ? crop.varieties.find(v => v.id === varietyId) : null;

      const prodSystem = prodSystemSelect.value;
      const waterSource = waterSourceSelect.value;
      const plantingDate = plantingDateInput.value ? new Date(plantingDateInput.value) : new Date();
      const soilTest = soilTestCheck ? soilTestCheck.checked : false;

      const recommendation = engine.generateRecommendation({
        crop: crop,
        variety: variety,
        location: locationProfile,
        productionSystem: prodSystem,
        waterSource: waterSource,
        plantingDate: plantingDate,
        soilTestAvailable: soilTest
      });

      renderResults(recommendation);
    });
  }

  // 5. Render Results View
  function renderResults(rec) {
    resultsContainer.style.display = 'block';

    const confidenceBadgeClass = rec.confidence === 'high' ? 'badge-high' : rec.confidence === 'moderate' ? 'badge-med' : 'badge-low';

    // Risk alerts HTML
    let alertsHtml = '';
    rec.riskAlerts.forEach(alert => {
      const alertClass = alert.severity === 'danger' ? 'alert-danger' : alert.severity === 'warning' ? 'alert-warning' : 'alert-info';
      alertsHtml += `
        <div class="alert-box ${alertClass}">
          <div class="alert-icon">${alert.iconEmoji}</div>
          <div class="alert-body">
            <strong>${alert.title}</strong>
            <p>${alert.description}</p>
          </div>
        </div>
      `;
    });

    // Timeline Milestones HTML
    let milestonesHtml = '';
    rec.timelineMilestones.forEach((m, idx) => {
      const statusClass = m.isCompleted ? 'milestone-completed' : m.isCurrent ? 'milestone-current' : 'milestone-upcoming';
      const statusTag = m.isCompleted ? '<span class="status-tag tag-done">Completed</span>' : m.isCurrent ? '<span class="status-tag tag-active">NOW ACTIVE</span>' : '';

      const stage = m.stage;
      let monitorsHtml = '';
      if (stage.whatToMonitor && stage.whatToMonitor.length > 0) {
        monitorsHtml = '<ul class="stage-monitor-list">';
        stage.whatToMonitor.forEach(mon => {
          const warnBadge = mon.isWarning ? '<span class="warn-pill">⚠️ Risk</span>' : '';
          monitorsHtml += `<li><strong>${mon.title}</strong> ${warnBadge}<br><small>${mon.detail}</small></li>`;
        });
        monitorsHtml += '</ul>';
      }

      milestonesHtml += `
        <div class="milestone-card ${statusClass}">
          <div class="milestone-header">
            <div class="milestone-num">${idx + 1}</div>
            <div class="milestone-title-wrap">
              <h4>${stage.title || stage.name} ${statusTag}</h4>
              <div class="milestone-date">${m.dateDisplay}</div>
            </div>
          </div>
          <p class="milestone-desc">${stage.description}</p>
          <div class="milestone-why"><strong>Why it matters:</strong> ${stage.whyItMatters}</div>
          ${monitorsHtml}
          ${stage.nutrientGuidance ? `<div class="stage-guide-box"><strong>🌱 Fertilizer & Nutrients:</strong> ${stage.nutrientGuidance}</div>` : ''}
          ${stage.weedingGuidance ? `<div class="stage-guide-box"><strong>🧹 Weed Management:</strong> ${stage.weedingGuidance}</div>` : ''}
          ${stage.warnings ? `<div class="stage-warn-box"><strong>⚠️ Warning:</strong> ${stage.warnings}</div>` : ''}
        </div>
      `;
    });

    // Factors List HTML
    let factorsHtml = '<ul>';
    rec.recommendationFactors.forEach(f => {
      factorsHtml += `<li>${f}</li>`;
    });
    factorsHtml += '</ul>';

    resultsContainer.innerHTML = `
      <div class="results-card">
        <div class="results-header">
          <div class="crop-header-icon">${rec.crop.iconEmoji}</div>
          <div>
            <h2>${rec.crop.name} ${rec.selectedVariety ? `— ${rec.selectedVariety.name}` : ''}</h2>
            <p class="subtitle">Location: ${rec.location.district || rec.location.region}, ${rec.location.country}</p>
          </div>
        </div>

        <div class="summary-banner-grid">
          <div class="summary-metric">
            <span class="label">Estimated Harvest Window</span>
            <span class="value gold-text">${rec.harvestWindowDisplay}</span>
          </div>
          <div class="summary-metric">
            <span class="label">Recommended Planting Window</span>
            <span class="value">${rec.recommendedWindow.label} (${rec.recommendedWindow.periodDescription})</span>
          </div>
          <div class="summary-metric">
            <span class="label">Confidence Level</span>
            <span class="badge ${confidenceBadgeClass}">${rec.confidence.toUpperCase()}</span>
          </div>
        </div>

        <div class="confidence-explain-box">
          <p>ℹ️ ${rec.confidenceExplanation}</p>
        </div>

        ${alertsHtml ? `<div class="alerts-section"><h3>Climate Safety & Advisory Alerts</h3>${alertsHtml}</div>` : ''}

        <div class="timeline-section">
          <h3>Growth Stage Milestones & Management</h3>
          <p class="lead-sm">Follow step-by-step management from planting through harvest.</p>
          <div class="milestones-list">${milestonesHtml}</div>
        </div>

        <div class="calc-links-bar">
          <strong>Next Farm Tools:</strong>
          <a class="button button-sm" href="/calculators/fertilizer.html">Open Fertilizer Calculator →</a>
          <a class="button button-sm secondary" href="/calculators/irrigation.html">Open Irrigation Calculator →</a>
        </div>

        <details class="factors-details">
          <summary>Why am I seeing this? (Recommendation Factors)</summary>

          <div class="factors-body">
            ${factorsHtml}
            <p><small>Data Source: ${rec.dataSources}</small></p>
          </div>
        </details>

        <div class="save-action-wrap">
          <button class="button button-lg" id="btn-save-plan">💾 Save to My Farm Calendars</button>
        </div>
      </div>
    `;

    // Smooth scroll to results
    resultsContainer.scrollIntoView({ behavior: 'smooth' });

    // Save plan button click listener
    const btnSavePlan = document.getElementById('btn-save-plan');
    if (btnSavePlan) {
      btnSavePlan.addEventListener('click', () => {
        const savedPlan = {
          id: 'plan_' + Date.now(),
          cropId: rec.crop.id,
          cropName: rec.crop.name,
          cropEmoji: rec.crop.iconEmoji,
          varietyName: rec.selectedVariety ? rec.selectedVariety.name : 'Standard',
          location: rec.location,
          plantingDate: rec.plantingDate,
          estimatedHarvestStart: rec.estimatedHarvestStart,
          estimatedHarvestEnd: rec.estimatedHarvestEnd,
          harvestWindowDisplay: rec.harvestWindowDisplay,
          confidence: rec.confidence,
          milestonesCount: rec.timelineMilestones.length,
          createdAt: new Date().toISOString()
        };

        if (engine.saveCropPlan(savedPlan)) {
          alert(`✅ Saved "${rec.crop.name}" calendar to your local farm plans!`);
          tabBtnSaved.click();
        }
      });
    }
  }

  // 6. Render Saved Plans Tab
  function renderSavedPlans() {
    if (!savedListContainer) return;
    const plans = engine.getSavedCropPlans();

    if (plans.length === 0) {
      savedListContainer.innerHTML = `
        <div class="empty-saved-state">
          <div class="icon">📅</div>
          <h3>No Saved Crop Calendars Yet</h3>
          <p>Plan a new crop season above and click "Save to My Farm Calendars" to track harvest dates and growth stages.</p>
          <button class="button secondary" onclick="document.getElementById('tab-btn-plan').click()">Plan a New Crop Now</button>
        </div>
      `;
      return;
    }

    let html = '';
    plans.forEach(plan => {
      const plantDate = new Date(plan.plantingDate).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });

      html += `
        <div class="saved-plan-card">
          <div class="saved-plan-header">
            <div class="crop-icon">${plan.cropEmoji}</div>
            <div class="saved-plan-title">
              <h3>${plan.cropName} <small>(${plan.varietyName})</small></h3>
              <p>📍 ${plan.location.district || plan.location.region}, ${plan.location.country}</p>
            </div>
            <button class="btn-delete-plan" data-id="${plan.id}" title="Delete Plan">🗑️</button>
          </div>
          <div class="saved-plan-details">
            <div><strong>Planting Date:</strong> ${plantDate}</div>
            <div><strong>Harvest Window:</strong> ${plan.harvestWindowDisplay}</div>
            <div><strong>Milestones:</strong> ${plan.milestonesCount || 5} stages tracked</div>
          </div>
        </div>
      `;
    });

    savedListContainer.innerHTML = html;

    // Attach delete handlers
    const deleteBtns = savedListContainer.querySelectorAll('.btn-delete-plan');
    deleteBtns.forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.target.dataset.id;
        if (confirm('Delete this saved crop calendar?')) {
          engine.deleteSavedCropPlan(id);
          renderSavedPlans();
        }
      });
    });
  }
});

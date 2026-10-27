/**
 * D & C - AGRIBASE AGRICULTURAL CONSULTANCY AND FARM ADVISORY SERVICES
 * Core Client-Side Storage, Service Catalogue & Business Logic Engine
 *
 * Designed for reliability, mobile accessibility, and offline resilience on GitHub Pages.
 * All customer data is maintained with strict client-side integrity and exportable to CSV/JSON.
 */
(function(window) {
  'use strict';

  var AgriConsult = window.AgriConsult || {};

  // Default Business Settings (Owner configurable via Admin Dashboard)
  var DEFAULT_SETTINGS = {
    companyName: 'D & C – AgriBase',
    tradeName: 'D & C Agricultural Consultancy and Farm Advisory Services',
    tagline: 'Practical Farming Knowledge. Professional Advice. Better Farming Decisions.',
    founderName: 'Enock Chinatsvi',
    founderTitle: 'Founder & Principal Agricultural Consultant',
    founderBio: 'Agriculture diploma graduate from Chibhero Agricultural College (2015-2018) with hands-on field advisory experience across crop production, irrigation scheduling, plant nutrition, pest management, and digital farming tools.',
    primaryPhone: '+27 74 902 2044', // Display formatted
    rawPhone: '2774902204',          // For wa.me / tel links
    primaryEmail: 'chinatsvieno@gmail.com',
    whatsappNumber: '2774902204',
    currency: 'USD',
    currencySymbol: '$',
    travelRatePerKm: 0.65, // in currency units per km (e.g. $0.65/km)
    baseCalloutFee: 5.00,
    serviceArea: 'Mashonaland East, West, Central, Harare, Midlands & surrounding agricultural districts (Cross-border advisory available online)',
    businessHours: 'Monday – Saturday: 07:30 – 17:30 (CAT / GMT+2)',
    communityAppUrl: 'https://www.mediafire.com/file/mg78viqjikkerc1/farmers.v1.0.1.apk/file',
    websiteUrl: 'https://chinatsvi.github.io/',
    registrationNote: 'Company is in preparatory establishment. Official registration and accreditation will be updated upon formal completion.',
    noticeResponseTime: 'Within 24 to 48 business hours'
  };

  // Seed Service Catalogue
  var DEFAULT_SERVICES = [
    {
      id: 'srv-crop-inspect',
      category: 'Physical farm visits',
      categoryKey: 'farm-visit',
      name: 'On-Farm Crop Inspection & Agronomic Health Check',
      shortDesc: 'Comprehensive in-field inspection of crop stands, nutrient deficiencies, pest pressure, and plant vigor.',
      detailedDesc: 'Our principal consultant visits your farm to conduct a thorough physical walk-through. We evaluate plant population, soil structure, leaf tissue condition, irrigation uniformity, and early disease signals, followed by practical corrective steps.',
      deliveryMethod: 'Physical farm visit',
      duration: '2 - 4 hours on-site',
      pricingType: 'quote', // 'free', 'fixed', 'quote'
      basePrice: 5.00,
      requiresAdvancePayment: true,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'Regional farm visits within service area',
      active: true
    },
    {
      id: 'srv-soil-fert',
      category: 'Soil fertility and fertiliser management',
      categoryKey: 'soil-fertility',
      name: 'Soil Fertility Assessment & Fertiliser Programme',
      shortDesc: 'Interpretation of soil texture, pH issues, and custom basal/top-dressing fertiliser schedules.',
      detailedDesc: 'Avoid wasting expensive fertilisers. We analyze your soil history, test reports (if available), or field symptoms to develop crop-specific, stage-by-stage fertiliser programmes (basal, fertigation, top-dressing, and foliar micronutrients).',
      deliveryMethod: 'Online or Farm Visit',
      duration: 'Written programme + 45 min consultation',
      pricingType: 'fixed',
      basePrice: 10.00,
      requiresAdvancePayment: true,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'All regions (Online) / Regional (On-farm)',
      active: true
    },
    {
      id: 'srv-pest-disease',
      category: 'Pest and disease management',
      categoryKey: 'pest-disease',
      name: 'Pest & Disease Field Assessment & IPM Strategy',
      shortDesc: 'Identification of insect pests, fungal blights, bacterial wilts, and economic threshold spraying advice.',
      detailedDesc: 'Accurate pest scouting and disease identification. We formulate an Integrated Pest Management (IPM) plan covering cultural controls, chemical rotations to prevent resistance, safe withholding periods, and scouting schedules.',
      deliveryMethod: 'Farm Visit or Online Urgent Review',
      duration: '1.5 - 3 hours on-site or 40 min online',
      pricingType: 'quote',
      basePrice: 5.00,
      requiresAdvancePayment: false,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'Service area',
      active: true
    },
    {
      id: 'srv-irrigation',
      category: 'Irrigation and water management',
      categoryKey: 'irrigation',
      name: 'Irrigation & Farm Water Management Audit',
      shortDesc: 'Drip, sprinkler, or furrow water scheduling, pump sizing verification, and water saving optimization.',
      detailedDesc: 'Evaluation of your irrigation layout, emitter discharge rates, crop evapotranspiration (ETc) requirements, and irrigation scheduling based on soil water holding capacity to prevent crop water stress and energy waste.',
      deliveryMethod: 'Physical farm visit',
      duration: 'Half-day audit',
      pricingType: 'quote',
      basePrice: 5.00,
      requiresAdvancePayment: true,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'Regional farm visits',
      active: true
    },
    {
      id: 'srv-online-consult',
      category: 'Online agricultural consultations',
      categoryKey: 'online-consult',
      name: '1-on-1 Online Agricultural Video / Phone Consultation',
      shortDesc: 'Direct 45-minute discussion via WhatsApp call or video to review crop symptoms, photos, and season plans.',
      detailedDesc: 'Connect directly with Enock Chinatsvi from anywhere. Share field photos, soil reports, or nursery questions ahead of the call for rapid, structured feedback and actionable next steps.',
      deliveryMethod: 'WhatsApp Call / Video / Phone',
      duration: '45 minutes',
      pricingType: 'fixed',
      basePrice: 5.00,
      requiresAdvancePayment: true,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'Global / All farming regions',
      active: true
    },
    {
      id: 'srv-question-enquiry',
      category: 'Online agricultural consultations',
      categoryKey: 'ask-question',
      name: 'Single Farming Question Review & Advisory Response',
      shortDesc: 'Submit a specific farming challenge with photos for structured written advisory review.',
      detailedDesc: 'Have a quick question about leaf curl, seedling damping-off, or fertiliser timing? Submit your enquiry online with photos. Our agronomy team reviews your situation and provides a concise advisory answer.',
      deliveryMethod: 'WhatsApp / Email Written Feedback',
      duration: 'Written review within 24-48 hrs',
      pricingType: 'free',
      basePrice: 0.00,
      requiresAdvancePayment: false,
      reportIncluded: false,
      followUpIncluded: false,
      availableLocations: 'All regions',
      active: true
    },
    {
      id: 'srv-livestock',
      category: 'Livestock production',
      categoryKey: 'livestock',
      name: 'Livestock Production & Pasture/Feed Advisory',
      shortDesc: 'Cattle, sheep, goat, pig, and broiler/layer feed formulation and routine health management guidance.',
      detailedDesc: 'Guidance on feed ration formulations, nutritional requirements across growth phases, brooding management, biosecurity protocols, and seasonal pasture supplementation.',
      deliveryMethod: 'Online or Farm Visit',
      duration: '2 - 3 hours',
      pricingType: 'quote',
      basePrice: 5.00,
      requiresAdvancePayment: false,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'Regional / Online',
      active: true
    },
    {
      id: 'srv-farm-planning',
      category: 'Farm planning and management',
      categoryKey: 'farm-planning',
      name: 'Whole-Farm Production Planning & Crop Rotation',
      shortDesc: 'Field zoning, seasonal cropping calendars, input procurement timelines, and rotational planning.',
      detailedDesc: 'Turn land potential into an orderly, efficient enterprise. We help map farm blocks, select appropriate varieties for your climate, plan succession planting to stabilize market flow, and maximize farm resource utilization.',
      deliveryMethod: 'Farm Visit & Remote Planning',
      duration: '1-day on-site + Full Planning Document',
      pricingType: 'quote',
      basePrice: 20.00,
      requiresAdvancePayment: true,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'Service area',
      active: true
    },
    {
      id: 'srv-agribusiness',
      category: 'Agricultural business planning',
      categoryKey: 'agribusiness',
      name: 'Agricultural Feasibility & Cashflow Budgeting',
      shortDesc: 'Gross margin budgets, break-even unit yields, and capital requirements for agricultural projects.',
      detailedDesc: 'Realistic farm enterprise budgeting. We help commercial growers, diaspora investors, and emerging farmers develop realistic input-output models, cashflow projections, and risk mitigation strategies before breaking ground.',
      deliveryMethod: 'Online or In-Person Session',
      duration: 'Comprehensive Financial Model + 2 Sessions',
      pricingType: 'quote',
      basePrice: 20.00,
      requiresAdvancePayment: true,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'All regions',
      active: true
    },
    {
      id: 'srv-training',
      category: 'Farmer training and workshops',
      categoryKey: 'training',
      name: 'Practical Farm Worker & Supervisor Group Training',
      shortDesc: 'Hands-on practical training on knapsack sprayer calibration, nursery grafting, scouting, and trellising.',
      detailedDesc: 'Upskill your farm workforce. Practical modules taught on your farm covering: safe chemical handling and calibration, accurate drip emitter inspection, greenhouse hygiene, pruning, harvesting standards, and daily farm record-keeping.',
      deliveryMethod: 'On-Farm Workshop',
      duration: 'Full Day Workshop (Up to 12 participants)',
      pricingType: 'quote',
      basePrice: 20.00,
      requiresAdvancePayment: true,
      reportIncluded: true,
      followUpIncluded: true,
      availableLocations: 'Service area',
      active: true
    }
  ];

  // Storage Keys
  var KEYS = {
    SETTINGS: 'agribase_consult_settings',
    SERVICES: 'agribase_consult_services',
    ENQUIRIES: 'agribase_consult_enquiries',
    BOOKINGS: 'agribase_consult_bookings',
    QUOTATIONS: 'agribase_consult_quotations',
    REPORTS: 'agribase_consult_reports',
    CUSTOMERS: 'agribase_consult_customers',
    ADMIN_SESSION: 'agribase_consult_admin_session'
  };

  // Helper: Read JSON from storage
  function getStorage(key, defaultValue) {
    try {
      var raw = localStorage.getItem(key);
      if (!raw) return defaultValue;
      return JSON.parse(raw);
    } catch (e) {
      console.warn('Storage read failed for ' + key, e);
      return defaultValue;
    }
  }

  // Helper: Write JSON to storage
  function setStorage(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch (e) {
      console.error('Storage write failed for ' + key, e);
      return false;
    }
  }

  // Generate Reference Numbers
  function generateReference(prefix) {
    var now = new Date();
    var year = now.getFullYear().toString().substr(-2);
    var month = ('0' + (now.getMonth() + 1)).slice(-2);
    var randomStr = Math.random().toString(36).substring(2, 6).toUpperCase();
    return (prefix || 'DC') + '-' + year + month + '-' + randomStr;
  }

  // Get Settings
  AgriConsult.getSettings = function() {
    var stored = getStorage(KEYS.SETTINGS, null);
    if (!stored) {
      setStorage(KEYS.SETTINGS, DEFAULT_SETTINGS);
      return JSON.parse(JSON.stringify(DEFAULT_SETTINGS));
    }
    if (stored.baseCalloutFee === 25.00) {
      stored.baseCalloutFee = DEFAULT_SETTINGS.baseCalloutFee;
      setStorage(KEYS.SETTINGS, stored);
    }
    // Merge any missing defaults
    for (var k in DEFAULT_SETTINGS) {
      if (stored[k] === undefined) stored[k] = DEFAULT_SETTINGS[k];
    }
    return stored;
  };

  // Update Settings
  AgriConsult.saveSettings = function(newSettings) {
    return setStorage(KEYS.SETTINGS, newSettings);
  };

  // Get Services
  AgriConsult.getServices = function(onlyActive) {
    var stored = getStorage(KEYS.SERVICES, null);
    if (!stored || !stored.length) {
      setStorage(KEYS.SERVICES, DEFAULT_SERVICES);
      stored = JSON.parse(JSON.stringify(DEFAULT_SERVICES));
    } else {
      var previousDefaultPrices = {
        'srv-crop-inspect': 60.00,
        'srv-soil-fert': 40.00,
        'srv-pest-disease': 50.00,
        'srv-irrigation': 75.00,
        'srv-online-consult': 20.00,
        'srv-livestock': 50.00,
        'srv-farm-planning': 120.00,
        'srv-agribusiness': 150.00,
        'srv-training': 200.00
      };
      var pricesUpdated = false;
      stored.forEach(function(service) {
        var oldDefaultPrice = previousDefaultPrices[service.id];
        var currentDefault = DEFAULT_SERVICES.find(function(defaultService) {
          return defaultService.id === service.id;
        });
        if (oldDefaultPrice !== undefined && currentDefault && service.basePrice === oldDefaultPrice) {
          service.basePrice = currentDefault.basePrice;
          pricesUpdated = true;
        }
      });
      if (pricesUpdated) setStorage(KEYS.SERVICES, stored);
    }
    if (onlyActive) {
      return stored.filter(function(s) { return s.active !== false; });
    }
    return stored;
  };

  // Save Services list
  AgriConsult.saveServices = function(servicesList) {
    return setStorage(KEYS.SERVICES, servicesList);
  };

  // Enquiries Management
  AgriConsult.getEnquiries = function() {
    return getStorage(KEYS.ENQUIRIES, []);
  };

  AgriConsult.saveEnquiry = function(enquiryData) {
    var enquiries = AgriConsult.getEnquiries();
    var ref = generateReference('ENQ');
    var timestamp = new Date().toISOString();

    var record = {
      id: 'enq-' + Date.now(),
      reference: ref,
      createdAt: timestamp,
      status: 'NEW', // 'NEW', 'UNDER_REVIEW', 'AWAITING_INFO', 'ANSWERED', 'CLOSED'
      farmerName: (enquiryData.farmerName || '').trim(),
      phone: (enquiryData.phone || '').trim(),
      email: (enquiryData.email || '').trim(),
      country: enquiryData.country || 'Zimbabwe',
      location: (enquiryData.location || '').trim(),
      farmName: (enquiryData.farmName || '').trim(),
      category: enquiryData.category || 'General',
      enterpriseType: enquiryData.enterpriseType || 'crop', // crop, livestock, mixed, other
      cropOrLivestock: (enquiryData.cropOrLivestock || '').trim(),
      varietyOrBreed: (enquiryData.varietyOrBreed || '').trim(),
      problemObservedDate: enquiryData.problemObservedDate || '',
      farmSize: (enquiryData.farmSize || '').trim(),
      symptoms: (enquiryData.symptoms || '').trim(),
      previousActions: (enquiryData.previousActions || '').trim(),
      questionDescription: (enquiryData.questionDescription || '').trim(),
      preferredContact: enquiryData.preferredContact || 'WhatsApp',
      attachments: enquiryData.attachments || [], // array of { name, size, type, dataUrl }
      internalNotes: '',
      officialResponse: '',
      assignedTo: 'Enock Chinatsvi (Principal Consultant)'
    };

    enquiries.unshift(record);
    setStorage(KEYS.ENQUIRIES, enquiries);
    AgriConsult.upsertCustomer(record.farmerName, record.phone, record.email, record.location, record.farmName);
    return record;
  };

  AgriConsult.updateEnquiry = function(id, updateFields) {
    var list = AgriConsult.getEnquiries();
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id || list[i].reference === id) {
        for (var key in updateFields) {
          list[i][key] = updateFields[key];
        }
        list[i].updatedAt = new Date().toISOString();
        setStorage(KEYS.ENQUIRIES, list);
        return list[i];
      }
    }
    return null;
  };

  // Bookings Management (Farm Visits & Online Consultations)
  AgriConsult.getBookings = function() {
    return getStorage(KEYS.BOOKINGS, []);
  };

  AgriConsult.saveBooking = function(bookingData) {
    var bookings = AgriConsult.getBookings();
    var isFarmVisit = bookingData.type === 'farm-visit';
    var prefix = isFarmVisit ? 'VISIT' : 'CONS';
    var ref = generateReference(prefix);
    var timestamp = new Date().toISOString();

    var record = {
      id: 'bkg-' + Date.now(),
      reference: ref,
      createdAt: timestamp,
      type: bookingData.type || 'farm-visit', // 'farm-visit', 'online-consultation', 'training'
      status: 'REQUEST_RECEIVED', // 'REQUEST_RECEIVED', 'UNDER_REVIEW', 'AWAITING_INFO', 'QUOTATION_PENDING', 'QUOTATION_SENT', 'AWAITING_ACCEPTANCE', 'AWAITING_PAYMENT', 'CONFIRMED', 'RESCHEDULED', 'COMPLETED', 'CANCELLED', 'DECLINED'
      farmerName: (bookingData.farmerName || '').trim(),
      phone: (bookingData.phone || '').trim(),
      email: (bookingData.email || '').trim(),
      farmName: (bookingData.farmName || '').trim(),
      country: bookingData.country || 'Zimbabwe',
      province: (bookingData.province || '').trim(),
      district: (bookingData.district || '').trim(),
      nearestTown: (bookingData.nearestTown || '').trim(),
      farmAddress: (bookingData.farmAddress || '').trim(),
      gpsCoordinates: (bookingData.gpsCoordinates || '').trim(),
      serviceId: bookingData.serviceId || '',
      serviceName: (bookingData.serviceName || '').trim(),
      cropOrEnterprise: (bookingData.cropOrEnterprise || '').trim(),
      farmSize: (bookingData.farmSize || '').trim(),
      preferredDate: bookingData.preferredDate || '',
      alternativeDate: bookingData.alternativeDate || '',
      preferredTime: bookingData.preferredTime || '',
      communicationMethod: bookingData.communicationMethod || (isFarmVisit ? 'In-Person Farm Visit' : 'WhatsApp Call'),
      timeZone: bookingData.timeZone || 'CAT (GMT+2)',
      description: (bookingData.description || '').trim(),
      accessArrangements: (bookingData.accessArrangements || '').trim(),
      writtenSummaryRequested: !!bookingData.writtenSummaryRequested,
      attachments: bookingData.attachments || [],
      quotationRef: null,
      internalNotes: '',
      confirmedDate: null,
      confirmedTime: null,
      assignedConsultant: 'Enock Chinatsvi (Founder & Principal Consultant)'
    };

    bookings.unshift(record);
    setStorage(KEYS.BOOKINGS, bookings);
    AgriConsult.upsertCustomer(record.farmerName, record.phone, record.email, record.nearestTown || record.district, record.farmName);
    return record;
  };

  AgriConsult.updateBooking = function(id, updateFields) {
    var list = AgriConsult.getBookings();
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id || list[i].reference === id) {
        for (var key in updateFields) {
          list[i][key] = updateFields[key];
        }
        list[i].updatedAt = new Date().toISOString();
        setStorage(KEYS.BOOKINGS, list);
        return list[i];
      }
    }
    return null;
  };

  // Quotations Management
  AgriConsult.getQuotations = function() {
    return getStorage(KEYS.QUOTATIONS, []);
  };

  AgriConsult.saveQuotation = function(quoteData) {
    var quotations = AgriConsult.getQuotations();
    var ref = generateReference('QT');
    var timestamp = new Date().toISOString();

    var serviceFee = parseFloat(quoteData.serviceFee) || 0;
    var travelDistanceKm = parseFloat(quoteData.travelDistanceKm) || 0;
    var travelRate = parseFloat(quoteData.travelRate) || 0;
    var travelFee = parseFloat(quoteData.travelFee) || (travelDistanceKm * travelRate);
    var additionalCharges = parseFloat(quoteData.additionalCharges) || 0;
    var discount = parseFloat(quoteData.discount) || 0;
    var subtotal = serviceFee + travelFee + additionalCharges;
    var total = Math.max(0, subtotal - discount);

    var record = {
      id: 'qt-' + Date.now(),
      reference: ref,
      createdAt: timestamp,
      bookingRef: quoteData.bookingRef || '',
      farmerName: (quoteData.farmerName || '').trim(),
      phone: (quoteData.phone || '').trim(),
      email: (quoteData.email || '').trim(),
      farmName: (quoteData.farmName || '').trim(),
      farmLocation: (quoteData.farmLocation || '').trim(),
      serviceName: (quoteData.serviceName || '').trim(),
      proposedDate: quoteData.proposedDate || '',
      currency: quoteData.currency || 'USD',
      serviceFee: serviceFee,
      travelDistanceKm: travelDistanceKm,
      travelRate: travelRate,
      travelFee: travelFee,
      additionalChargesDescription: quoteData.additionalChargesDescription || '',
      additionalCharges: additionalCharges,
      discount: discount,
      totalAmount: total,
      expiryDate: quoteData.expiryDate || '',
      paymentTerms: quoteData.paymentTerms || '50% advance deposit to secure date, balance on completion of farm assessment',
      notes: quoteData.notes || 'Quotation valid for 14 days. Travel charge based on standard estimated round-trip road distance.',
      status: 'SENT', // 'DRAFT', 'SENT', 'ACCEPTED', 'DECLINED', 'EXPIRED'
      acceptedDate: null,
      clientFeedback: ''
    };

    quotations.unshift(record);
    setStorage(KEYS.QUOTATIONS, quotations);

    // If linked to booking, update booking status
    if (record.bookingRef) {
      AgriConsult.updateBooking(record.bookingRef, {
        quotationRef: record.reference,
        status: 'QUOTATION_SENT'
      });
    }

    return record;
  };

  AgriConsult.updateQuotation = function(id, updateFields) {
    var list = AgriConsult.getQuotations();
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id || list[i].reference === id) {
        for (var key in updateFields) {
          list[i][key] = updateFields[key];
        }
        list[i].updatedAt = new Date().toISOString();
        setStorage(KEYS.QUOTATIONS, list);
        return list[i];
      }
    }
    return null;
  };

  // Farm Visit Reports Management
  AgriConsult.getReports = function() {
    return getStorage(KEYS.REPORTS, []);
  };

  AgriConsult.saveReport = function(reportData) {
    var reports = AgriConsult.getReports();
    var ref = generateReference('REP');
    var timestamp = new Date().toISOString();

    var record = {
      id: 'rep-' + Date.now(),
      reference: ref,
      createdAt: timestamp,
      bookingRef: reportData.bookingRef || '',
      customerName: (reportData.customerName || '').trim(),
      farmName: (reportData.farmName || '').trim(),
      farmLocation: (reportData.farmLocation || '').trim(),
      visitDate: reportData.visitDate || '',
      enterprise: (reportData.enterprise || '').trim(),
      purposeOfAssessment: (reportData.purposeOfAssessment || '').trim(),
      observations: (reportData.observations || '').trim(),
      reportedSymptoms: (reportData.reportedSymptoms || '').trim(),
      findingsEvidence: (reportData.findingsEvidence || '').trim(),
      contributingFactors: (reportData.contributingFactors || '').trim(),
      recommendations: (reportData.recommendations || '').trim(),
      actionPriorities: (reportData.actionPriorities || '').trim(),
      testingReferrals: (reportData.testingReferrals || '').trim(),
      followUpArrangements: (reportData.followUpArrangements || '').trim(),
      assessmentLimitations: reportData.assessmentLimitations || 'This report is based on physical field observations made on the date of inspection. Subsoil microbiology, chemical residue, and latent pathogens require accredited laboratory testing.',
      consultantName: reportData.consultantName || 'Enock Chinatsvi',
      consultantTitle: reportData.consultantTitle || 'Principal Agricultural Consultant',
      status: reportData.status || 'DRAFT' // 'DRAFT', 'FINALISED'
    };

    reports.unshift(record);
    setStorage(KEYS.REPORTS, reports);
    return record;
  };

  AgriConsult.updateReport = function(id, updateFields) {
    var list = AgriConsult.getReports();
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id || list[i].reference === id) {
        for (var key in updateFields) {
          list[i][key] = updateFields[key];
        }
        list[i].updatedAt = new Date().toISOString();
        setStorage(KEYS.REPORTS, list);
        return list[i];
      }
    }
    return null;
  };

  // Customer Management
  AgriConsult.getCustomers = function() {
    return getStorage(KEYS.CUSTOMERS, []);
  };

  AgriConsult.upsertCustomer = function(name, phone, email, location, farmName) {
    if (!name && !phone) return null;
    var list = AgriConsult.getCustomers();
    var cleanPhone = (phone || '').replace(/[^0-9]/g, '');
    var existingIndex = -1;

    for (var i = 0; i < list.length; i++) {
      var itemCleanPhone = (list[i].phone || '').replace(/[^0-9]/g, '');
      if ((cleanPhone && itemCleanPhone === cleanPhone) ||
          (email && list[i].email && list[i].email.toLowerCase() === email.toLowerCase())) {
        existingIndex = i;
        break;
      }
    }

    var record;
    if (existingIndex >= 0) {
      record = list[existingIndex];
      if (name) record.name = name;
      if (email && !record.email) record.email = email;
      if (location && !record.location) record.location = location;
      if (farmName && !record.farmName) record.farmName = farmName;
      record.lastActive = new Date().toISOString();
      record.interactionCount = (record.interactionCount || 1) + 1;
    } else {
      record = {
        id: 'cust-' + Date.now(),
        name: name,
        phone: phone,
        email: email || '',
        location: location || '',
        farmName: farmName || '',
        firstSeen: new Date().toISOString(),
        lastActive: new Date().toISOString(),
        interactionCount: 1,
        notes: ''
      };
      list.unshift(record);
    }

    setStorage(KEYS.CUSTOMERS, list);
    return record;
  };

  // Export all company records for easy local backup
  AgriConsult.exportAllData = function() {
    return {
      exportedAt: new Date().toISOString(),
      settings: AgriConsult.getSettings(),
      services: AgriConsult.getServices(),
      enquiries: AgriConsult.getEnquiries(),
      bookings: AgriConsult.getBookings(),
      quotations: AgriConsult.getQuotations(),
      reports: AgriConsult.getReports(),
      customers: AgriConsult.getCustomers()
    };
  };

  // Helper: Format currency
  AgriConsult.formatMoney = function(amount, currency) {
    var num = parseFloat(amount) || 0;
    var settings = AgriConsult.getSettings();
    var cur = currency || settings.currency || 'USD';
    return cur + ' ' + num.toFixed(2);
  };

  // Helper: Format nice date
  AgriConsult.formatDate = function(isoStr) {
    if (!isoStr) return 'N/A';
    try {
      var d = new Date(isoStr);
      if (isNaN(d.getTime())) return isoStr;
      return d.toLocaleDateString('en-GB', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
      });
    } catch(e) {
      return isoStr;
    }
  };

  // Admin Session Simulation (Safe client side PIN/role system)
  AgriConsult.getAdminSession = function() {
    return getStorage(KEYS.ADMIN_SESSION, null);
  };

  AgriConsult.setAdminSession = function(sessionData) {
    return setStorage(KEYS.ADMIN_SESSION, sessionData);
  };

  AgriConsult.clearAdminSession = function() {
    try {
      localStorage.removeItem(KEYS.ADMIN_SESSION);
      return true;
    } catch(e) {
      return false;
    }
  };

  window.AgriConsult = AgriConsult;
})(window);

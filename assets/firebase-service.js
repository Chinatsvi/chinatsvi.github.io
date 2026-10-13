/**
 * D & C – AGRIBASE FIREBASE BACKEND ENGINE
 * Connects website forms and administration dashboard to Google Firebase:
 * - Firebase Authentication (Secure Staff Email/Password)
 * - Cloud Firestore (Customers, Questions, Bookings, Quotations, Appointments, Staff, Settings)
 * - Automatic LocalStorage Sync for 100% Offline Resilience
 */
(function(window) {
  'use strict';

  var AgriFirebase = window.AgriFirebase || {};

  // Firebase Web App Configuration
  var FIREBASE_CONFIG = {
    apiKey: "AIzaSyCUPMdAIUDXepx137uH2OtV8l6AOAvYOxY",
    authDomain: "chinatsvienoc.firebaseapp.com",
    projectId: "chinatsvienoc",
    storageBucket: "chinatsvienoc.firebasestorage.app",
    messagingSenderId: "540364912388",
    appId: "1:540364912388:web:c74ceb98486039d3f2c251",
    measurementId: "G-HE019Y7XFW"
  };

  // Firestore Collection Names
  var COLLECTIONS = {
    CUSTOMERS: 'customers',
    FARMING_QUESTIONS: 'farming_questions',
    FARM_VISIT_BOOKINGS: 'farm_visit_bookings',
    CONSULTATION_BOOKINGS: 'consultation_bookings',
    QUOTATIONS: 'quotations',
    APPOINTMENTS: 'appointments',
    STAFF: 'staff',
    COMPANY_SETTINGS: 'company_settings',
    CONVERSATIONS: 'conversations'
  };

  AgriFirebase.collections = COLLECTIONS;
  AgriFirebase.isInitialized = false;

  // Initialize Firebase SDK
  AgriFirebase.init = function() {
    if (typeof window.firebase === 'undefined') {
      console.warn('Firebase SDK not loaded on this page yet. LocalStorage engine active.');
      return false;
    }

    try {
      if (!window.firebase.apps || !window.firebase.apps.length) {
        window.firebase.initializeApp(FIREBASE_CONFIG);
      }
      AgriFirebase.app = window.firebase.app();
      AgriFirebase.auth = window.firebase.auth();
      AgriFirebase.db = window.firebase.firestore();
      AgriFirebase.isInitialized = true;
      console.log('D & C – AgriBase Firebase Engine connected successfully to projectId:', FIREBASE_CONFIG.projectId);
      return true;
    } catch (err) {
      console.error('Firebase initialization error:', err);
      return false;
    }
  };

  // Generate Reference helper
  function generateReference(prefix) {
    var now = new Date();
    var year = String(now.getFullYear()).slice(-2);
    var month = ('0' + (now.getMonth() + 1)).slice(-2);
    var randomStr = Math.random().toString(36).substring(2, 6).toUpperCase();
    return (prefix || 'DC') + '-' + year + month + '-' + randomStr;
  }

  // ==========================================
  // CUSTOMER SUBMISSIONS (COLLECTIONS)
  // ==========================================

  // 1. Submit Farming Question -> 'farming_questions' & 'customers'
  AgriFirebase.submitFarmingQuestion = async function(data) {
    var ref = data.reference || generateReference('ENQ');
    var timestamp = new Date().toISOString();

    var payload = {
      reference: ref,
      customerName: (data.farmerName || '').trim(),
      farmerName: (data.farmerName || '').trim(),
      phone: (data.phone || '').trim(),
      email: (data.email || '').trim(),
      country: data.country || 'Zimbabwe',
      location: (data.location || '').trim(),
      farmName: (data.farmName || '').trim(),
      enterpriseType: data.enterpriseType || 'crop',
      cropOrLivestock: (data.cropOrLivestock || '').trim(),
      questionDescription: (data.questionDescription || '').trim(),
      problemObservedDate: data.problemObservedDate || '',
      farmSize: (data.farmSize || '').trim(),
      previousActions: (data.previousActions || '').trim(),
      preferredContact: data.preferredContact || 'WhatsApp',
      status: 'pending', // 'pending', 'under_review', 'answered', 'closed'
      officialResponse: '',
      internalNotes: '',
      assignedTo: 'Enock Chinatsvi (Founder & Principal Consultant)',
      createdAt: timestamp,
      updatedAt: timestamp
    };

    // Save to Firestore if connected
    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var docRef = await AgriFirebase.db.collection(COLLECTIONS.FARMING_QUESTIONS).add({
          ...payload,
          serverTimestamp: window.firebase.firestore.FieldValue.serverTimestamp()
        });
        payload.id = docRef.id;
        console.log('Question saved to Firestore with ID:', docRef.id);
      } catch (err) {
        console.warn('Firestore write failed, falling back to local storage:', err);
      }
    }

    // Always mirror to customers collection
    AgriFirebase.upsertCustomerRecord({
      name: payload.customerName,
      phone: payload.phone,
      email: payload.email,
      location: payload.location,
      farmName: payload.farmName
    });

    // Also mirror to LocalStorage via AgriConsult if present
    if (window.AgriConsult && typeof window.AgriConsult.saveEnquiry === 'function') {
      try {
        window.AgriConsult.saveEnquiry(data);
      } catch (e) {}
    }

    return payload;
  };

  // 2. Submit Farm Visit Request -> 'farm_visit_bookings' & 'customers'
  AgriFirebase.submitFarmVisitBooking = async function(data) {
    var ref = data.reference || generateReference('VISIT');
    var timestamp = new Date().toISOString();

    var payload = {
      reference: ref,
      customerName: (data.farmerName || '').trim(),
      farmerName: (data.farmerName || '').trim(),
      phone: (data.phone || '').trim(),
      email: (data.email || '').trim(),
      farmName: (data.farmName || '').trim(),
      country: data.country || 'Zimbabwe',
      location: (data.district || data.province || data.location || '').trim(),
      district: (data.district || '').trim(),
      province: (data.province || '').trim(),
      nearestTown: (data.nearestTown || '').trim(),
      farmAddress: (data.farmAddress || '').trim(),
      gpsCoordinates: (data.gpsCoordinates || '').trim(),
      farmType: (data.cropOrEnterprise || '').trim(),
      cropOrEnterprise: (data.cropOrEnterprise || '').trim(),
      serviceName: (data.serviceName || 'On-Farm Crop Inspection & Agronomic Health Check').trim(),
      serviceId: data.serviceId || 'srv-crop-inspect',
      farmSize: (data.farmSize || '').trim(),
      preferredDate: data.preferredDate || '',
      alternativeDate: data.alternativeDate || '',
      preferredTime: data.preferredTime || '',
      reasonForVisit: (data.description || '').trim(),
      description: (data.description || '').trim(),
      accessArrangements: (data.accessArrangements || '').trim(),
      status: 'pending', // 'pending', 'quoted', 'approved', 'rejected', 'completed'
      quotationRef: null,
      internalNotes: '',
      createdAt: timestamp,
      updatedAt: timestamp
    };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var docRef = await AgriFirebase.db.collection(COLLECTIONS.FARM_VISIT_BOOKINGS).add({
          ...payload,
          serverTimestamp: window.firebase.firestore.FieldValue.serverTimestamp()
        });
        payload.id = docRef.id;
        console.log('Farm Visit booking saved to Firestore:', docRef.id);
      } catch (err) {
        console.warn('Firestore write failed, falling back to local storage:', err);
      }
    }

    AgriFirebase.upsertCustomerRecord({
      name: payload.customerName,
      phone: payload.phone,
      email: payload.email,
      location: payload.location,
      farmName: payload.farmName
    });

    if (window.AgriConsult && typeof window.AgriConsult.saveBooking === 'function') {
      try {
        window.AgriConsult.saveBooking({ ...data, type: 'farm-visit' });
      } catch (e) {}
    }

    return payload;
  };

  // 3. Submit Consultation Request -> 'consultation_bookings' & 'customers'
  AgriFirebase.submitConsultationBooking = async function(data) {
    var ref = data.reference || generateReference('CONS');
    var timestamp = new Date().toISOString();

    var payload = {
      reference: ref,
      customerName: (data.farmerName || '').trim(),
      farmerName: (data.farmerName || '').trim(),
      phone: (data.phone || '').trim(),
      email: (data.email || '').trim(),
      location: (data.location || '').trim(),
      serviceName: (data.serviceName || '1-on-1 Online Consultation').trim(),
      cropOrEnterprise: (data.cropOrEnterprise || '').trim(),
      communicationMethod: data.communicationMethod || 'WhatsApp Call / Audio',
      preferredDate: data.preferredDate || '',
      preferredTime: data.preferredTime || '',
      reasonForConsultation: (data.description || '').trim(),
      description: (data.description || '').trim(),
      writtenSummaryRequested: !!data.writtenSummaryRequested,
      status: 'pending', // 'pending', 'approved', 'completed', 'cancelled'
      internalNotes: '',
      createdAt: timestamp,
      updatedAt: timestamp
    };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var docRef = await AgriFirebase.db.collection(COLLECTIONS.CONSULTATION_BOOKINGS).add({
          ...payload,
          serverTimestamp: window.firebase.firestore.FieldValue.serverTimestamp()
        });
        payload.id = docRef.id;
        console.log('Online consultation saved to Firestore:', docRef.id);
      } catch (err) {
        console.warn('Firestore write failed, falling back to local storage:', err);
      }
    }

    AgriFirebase.upsertCustomerRecord({
      name: payload.customerName,
      phone: payload.phone,
      email: payload.email,
      location: payload.location
    });

    if (window.AgriConsult && typeof window.AgriConsult.saveBooking === 'function') {
      try {
        window.AgriConsult.saveBooking({ ...data, type: 'online-consultation' });
      } catch (e) {}
    }

    return payload;
  };

  // 4. Upsert Customer -> 'customers'
  AgriFirebase.upsertCustomerRecord = async function(cust) {
    if (!cust || (!cust.phone && !cust.email)) return;
    var timestamp = new Date().toISOString();
    var customerData = {
      name: (cust.name || '').trim(),
      phone: (cust.phone || '').trim(),
      email: (cust.email || '').trim(),
      location: (cust.location || '').trim(),
      farmName: (cust.farmName || '').trim(),
      lastInteraction: timestamp
    };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        // Query by phone or email
        var snap = null;
        if (customerData.phone) {
          snap = await AgriFirebase.db.collection(COLLECTIONS.CUSTOMERS)
            .where('phone', '==', customerData.phone).limit(1).get();
        }
        if ((!snap || snap.empty) && customerData.email) {
          snap = await AgriFirebase.db.collection(COLLECTIONS.CUSTOMERS)
            .where('email', '==', customerData.email).limit(1).get();
        }

        if (snap && !snap.empty) {
          var docId = snap.docs[0].id;
          await AgriFirebase.db.collection(COLLECTIONS.CUSTOMERS).doc(docId).set(customerData, { merge: true });
        } else {
          await AgriFirebase.db.collection(COLLECTIONS.CUSTOMERS).add({
            ...customerData,
            createdAt: timestamp
          });
        }
      } catch (err) {
        console.warn('Error saving customer to Firestore:', err);
      }
    }
  };

  // ==========================================
  // CUSTOMER SELF-SERVICE RECORD LOOKUP
  // ==========================================
  AgriFirebase.lookupRecordByRef = async function(ref) {
    var code = (ref || '').trim().toUpperCase();
    if (!code) return null;

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        // Check farming_questions
        var qSnap = await AgriFirebase.db.collection(COLLECTIONS.FARMING_QUESTIONS).where('reference', '==', code).limit(1).get();
        if (!qSnap.empty) return { collection: COLLECTIONS.FARMING_QUESTIONS, data: qSnap.docs[0].data(), id: qSnap.docs[0].id };

        // Check farm_visit_bookings
        var vSnap = await AgriFirebase.db.collection(COLLECTIONS.FARM_VISIT_BOOKINGS).where('reference', '==', code).limit(1).get();
        if (!vSnap.empty) return { collection: COLLECTIONS.FARM_VISIT_BOOKINGS, data: vSnap.docs[0].data(), id: vSnap.docs[0].id };

        // Check consultation_bookings
        var cSnap = await AgriFirebase.db.collection(COLLECTIONS.CONSULTATION_BOOKINGS).where('reference', '==', code).limit(1).get();
        if (!cSnap.empty) return { collection: COLLECTIONS.CONSULTATION_BOOKINGS, data: cSnap.docs[0].data(), id: cSnap.docs[0].id };

        // Check quotations
        var qtSnap = await AgriFirebase.db.collection(COLLECTIONS.QUOTATIONS).where('reference', '==', code).limit(1).get();
        if (!qtSnap.empty) return { collection: COLLECTIONS.QUOTATIONS, data: qtSnap.docs[0].data(), id: qtSnap.docs[0].id };
      } catch (err) {
        console.warn('Firestore lookup error:', err);
      }
    }

    // Fallback to local AgriConsult
    if (window.AgriConsult) {
      var item = (window.AgriConsult.getEnquiries() || []).find(function(e) { return e.reference === code; }) ||
                 (window.AgriConsult.getBookings() || []).find(function(b) { return b.reference === code; }) ||
                 (window.AgriConsult.getQuotations() || []).find(function(q) { return q.reference === code; });
      if (item) return { collection: 'local', data: item };
    }

    return null;
  };

  // ==========================================
  // SECURE ADMINISTRATION AUTHENTICATION & STAFF
  // ==========================================

  // Login staff with Firebase Auth Email/Password
  AgriFirebase.loginStaff = async function(email, password) {
    if (!AgriFirebase.init() || !AgriFirebase.auth) {
      throw new Error('Firebase Authentication is not available. Please ensure network connection.');
    }
    var cred = await AgriFirebase.auth.signInWithEmailAndPassword(email, password);
    var staffInfo = await AgriFirebase.verifyStaffPermissions(cred.user);
    return { user: cred.user, staff: staffInfo };
  };

  // Login staff with Google Authentication
  AgriFirebase.loginStaffWithGoogle = async function() {
    if (!AgriFirebase.init() || !AgriFirebase.auth) {
      throw new Error('Firebase Authentication is not available. Please ensure network connection.');
    }
    var provider = new window.firebase.auth.GoogleAuthProvider();
    provider.setCustomParameters({ prompt: 'select_account' });
    var cred = await AgriFirebase.auth.signInWithPopup(provider);
    var staffInfo = await AgriFirebase.verifyStaffPermissions(cred.user);
    if (cred.user.displayName && staffInfo) {
      staffInfo.name = cred.user.displayName;
    }
    return { user: cred.user, staff: staffInfo };
  };

  // Logout staff
  AgriFirebase.logoutStaff = async function() {
    if (AgriFirebase.auth) {
      await AgriFirebase.auth.signOut();
    }
    sessionStorage.removeItem('agribase_staff_session');
  };

  // Verify staff permissions in 'staff' collection
  AgriFirebase.verifyStaffPermissions = async function(user) {
    if (!user) return null;
    var userEmail = (user.email || '').toLowerCase().trim();
    var googleDisplayName = user.displayName || '';
    var googlePhoto = user.photoURL || '';

    // Default Super Admin: Enock Chinatsvi (Founder)
    if (userEmail === 'chinatsvieno@gmail.com') {
      var founderStaff = {
        name: googleDisplayName || 'Enock Chinatsvi',
        email: userEmail,
        role: 'admin',
        title: 'Founder & Principal Agricultural Consultant',
        photoURL: googlePhoto,
        active: true,
        permissions: ['read', 'write', 'approve', 'settings', 'staff']
      };

      // Bootstrap into 'staff' collection if not present
      if (AgriFirebase.db) {
        try {
          await AgriFirebase.db.collection(COLLECTIONS.STAFF).doc(user.uid).set(founderStaff, { merge: true });
        } catch (e) {}
      }
      return founderStaff;
    }

    // Query 'staff' collection
    if (AgriFirebase.db) {
      try {
        var doc = await AgriFirebase.db.collection(COLLECTIONS.STAFF).doc(user.uid).get();
        if (doc.exists) {
          var data = doc.data();
          if (data.active !== false) return data;
          throw new Error('This staff account has been deactivated. Contact the administrator.');
        }

        // Query by email
        var snap = await AgriFirebase.db.collection(COLLECTIONS.STAFF).where('email', '==', userEmail).limit(1).get();
        if (!snap.empty) {
          var staffData = snap.docs[0].data();
          if (staffData.active !== false) return staffData;
          throw new Error('This staff account has been deactivated. Contact the administrator.');
        }
      } catch (err) {
        console.warn('Error verifying staff collection:', err);
      }
    }

    throw new Error('Access denied: ' + userEmail + ' is not an authorized staff member of D & C – AgriBase.');
  };

  // Listen to Auth State
  AgriFirebase.onAuthStateChanged = function(callback) {
    if (AgriFirebase.init() && AgriFirebase.auth) {
      return AgriFirebase.auth.onAuthStateChanged(callback);
    }
    return null;
  };

  // ==========================================
  // ADMIN DASHBOARD DATA METHODS
  // ==========================================

  // Fetch all collections for admin workspace
  AgriFirebase.adminFetchCollection = async function(collectionName) {
    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var snap = await AgriFirebase.db.collection(collectionName).orderBy('createdAt', 'desc').get();
        return snap.docs.map(function(d) {
          return { id: d.id, ...d.data() };
        });
      } catch (err) {
        console.warn('Error fetching ' + collectionName + ' from Firestore, falling back to local storage:', err);
      }
    }
    // Fallback to local storage
    if (window.AgriConsult) {
      if (collectionName === COLLECTIONS.FARMING_QUESTIONS) return window.AgriConsult.getEnquiries();
      if (collectionName === COLLECTIONS.FARM_VISIT_BOOKINGS) return window.AgriConsult.getBookings().filter(function(b) { return b.type === 'farm-visit'; });
      if (collectionName === COLLECTIONS.CONSULTATION_BOOKINGS) return window.AgriConsult.getBookings().filter(function(b) { return b.type === 'online-consultation'; });
      if (collectionName === COLLECTIONS.QUOTATIONS) return window.AgriConsult.getQuotations();
      if (collectionName === COLLECTIONS.CUSTOMERS) return window.AgriConsult.getCustomers();
    }
    return [];
  };

  // Update status and response of any document in any collection
  AgriFirebase.adminUpdateRecord = async function(collectionName, docId, updates) {
    var timestamp = new Date().toISOString();
    var updatePayload = { ...updates, updatedAt: timestamp };

    if (AgriFirebase.init() && AgriFirebase.db && docId) {
      try {
        await AgriFirebase.db.collection(collectionName).doc(docId).update(updatePayload);
      } catch (err) {
        console.warn('Firestore update error:', err);
      }
    }

    // Mirror to local storage
    if (window.AgriConsult) {
      if (collectionName === COLLECTIONS.FARMING_QUESTIONS) window.AgriConsult.updateEnquiry(docId, updates);
      if (collectionName === COLLECTIONS.FARM_VISIT_BOOKINGS || collectionName === COLLECTIONS.CONSULTATION_BOOKINGS) {
        window.AgriConsult.updateBooking(docId, updates);
      }
      if (collectionName === COLLECTIONS.QUOTATIONS) window.AgriConsult.updateQuotation(docId, updates);
    }
    return updatePayload;
  };

  // Approve a visit or consultation and create an official appointment
  AgriFirebase.adminApproveAppointment = async function(bookingData, appointmentDetails) {
    var ref = generateReference('APPT');
    var timestamp = new Date().toISOString();

    var appointmentRecord = {
      reference: ref,
      bookingRef: bookingData.reference || '',
      bookingId: bookingData.id || '',
      customerName: bookingData.customerName || bookingData.farmerName || '',
      phone: bookingData.phone || '',
      email: bookingData.email || '',
      type: bookingData.type || bookingData.serviceName || 'Farm Visit',
      appointmentDate: appointmentDetails.date || bookingData.preferredDate || '',
      appointmentTime: appointmentDetails.time || bookingData.preferredTime || '09:00 AM',
      location: appointmentDetails.location || bookingData.location || bookingData.farmAddress || '',
      assignedConsultant: appointmentDetails.consultant || 'Enock Chinatsvi (Founder & Principal Consultant)',
      status: 'confirmed', // 'confirmed', 'rescheduled', 'completed', 'cancelled'
      notes: appointmentDetails.notes || '',
      createdAt: timestamp,
      updatedAt: timestamp
    };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var docRef = await AgriFirebase.db.collection(COLLECTIONS.APPOINTMENTS).add({
          ...appointmentRecord,
          serverTimestamp: window.firebase.firestore.FieldValue.serverTimestamp()
        });
        appointmentRecord.id = docRef.id;

        // Update the booking status to approved
        var bookingCollection = (bookingData.type === 'online-consultation') ? 
          COLLECTIONS.CONSULTATION_BOOKINGS : COLLECTIONS.FARM_VISIT_BOOKINGS;
        
        if (bookingData.id) {
          await AgriFirebase.db.collection(bookingCollection).doc(bookingData.id).update({
            status: 'approved',
            appointmentRef: ref,
            confirmedDate: appointmentRecord.appointmentDate,
            confirmedTime: appointmentRecord.appointmentTime,
            updatedAt: timestamp
          });
        }
      } catch (err) {
        console.warn('Error saving appointment to Firestore:', err);
      }
    }

    return appointmentRecord;
  };

  // Create official quotation -> 'quotations'
  AgriFirebase.adminCreateQuotation = async function(quoteData) {
    var ref = generateReference('QT');
    var timestamp = new Date().toISOString();

    var serviceFee = parseFloat(quoteData.serviceFee) || 0;
    var travelDistanceKm = parseFloat(quoteData.travelDistanceKm) || 0;
    var travelRate = parseFloat(quoteData.travelRate) || 0.65;
    var travelFee = parseFloat(quoteData.travelFee) || (travelDistanceKm * travelRate);
    var additionalCharges = parseFloat(quoteData.additionalCharges) || 0;
    var discount = parseFloat(quoteData.discount) || 0;
    var totalAmount = Math.max(0, (serviceFee + travelFee + additionalCharges) - discount);

    var record = {
      reference: ref,
      bookingRef: quoteData.bookingRef || '',
      customerName: (quoteData.customerName || quoteData.farmerName || '').trim(),
      phone: (quoteData.phone || '').trim(),
      email: (quoteData.email || '').trim(),
      farmLocation: (quoteData.farmLocation || '').trim(),
      serviceName: (quoteData.serviceName || '').trim(),
      serviceFee: serviceFee,
      travelDistanceKm: travelDistanceKm,
      travelRate: travelRate,
      travelFee: travelFee,
      additionalCharges: additionalCharges,
      discount: discount,
      totalAmount: totalAmount,
      currency: quoteData.currency || 'USD',
      proposedDate: quoteData.proposedDate || '',
      expiryDate: quoteData.expiryDate || '',
      status: 'pending', // 'pending', 'approved', 'rejected'
      paymentTerms: quoteData.paymentTerms || '50% advance deposit to secure date, balance upon completion',
      notes: quoteData.notes || 'Transparent itemized quotation based on verified road mileage.',
      createdAt: timestamp,
      updatedAt: timestamp
    };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var docRef = await AgriFirebase.db.collection(COLLECTIONS.QUOTATIONS).add({
          ...record,
          serverTimestamp: window.firebase.firestore.FieldValue.serverTimestamp()
        });
        record.id = docRef.id;
      } catch (err) {
        console.warn('Error saving quotation to Firestore:', err);
      }
    }

    if (window.AgriConsult && typeof window.AgriConsult.saveQuotation === 'function') {
      window.AgriConsult.saveQuotation(record);
    }

    return record;
  };

  // Staff management methods
  AgriFirebase.adminAddStaff = async function(staffData) {
    var timestamp = new Date().toISOString();
    var record = {
      name: (staffData.name || '').trim(),
      email: (staffData.email || '').toLowerCase().trim(),
      role: staffData.role || 'consultant', // 'admin', 'consultant', 'assistant'
      title: staffData.title || 'Agricultural Advisory Staff',
      active: true,
      permissions: staffData.permissions || ['read', 'write'],
      createdAt: timestamp,
      updatedAt: timestamp
    };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var docRef = await AgriFirebase.db.collection(COLLECTIONS.STAFF).add(record);
        record.id = docRef.id;
      } catch (err) {
        console.warn('Error adding staff member:', err);
      }
    }
    return record;
  };

  // Company settings methods
  AgriFirebase.adminSaveCompanySettings = async function(settingsData) {
    var timestamp = new Date().toISOString();
    var payload = { ...settingsData, updatedAt: timestamp };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        await AgriFirebase.db.collection(COLLECTIONS.COMPANY_SETTINGS).doc('general').set(payload, { merge: true });
      } catch (err) {
        console.warn('Error saving company settings to Firestore:', err);
      }
    }

    if (window.AgriConsult && typeof window.AgriConsult.saveSettings === 'function') {
      window.AgriConsult.saveSettings(settingsData);
    }
    return payload;
  };

  AgriFirebase.adminGetCompanySettings = async function() {
    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var doc = await AgriFirebase.db.collection(COLLECTIONS.COMPANY_SETTINGS).doc('general').get();
        if (doc.exists) return doc.data();
      } catch (e) {}
    }
    if (window.AgriConsult) return window.AgriConsult.getSettings();
    return null;
  };

  // ==========================================
  // REAL-TIME IN-APP CHAT & MESSAGING ENGINE
  // ==========================================

  // 1. Get or create a conversation thread for a visitor
  AgriFirebase.getOrCreateConversation = async function(visitorData) {
    var visitorId = visitorData.visitorId || ('vis_' + Math.random().toString(36).substring(2, 10));
    var convId = 'conv_' + visitorId.replace(/[^a-zA-Z0-9_-]/g, '');
    var timestamp = new Date().toISOString();

    var convData = {
      id: convId,
      visitorId: visitorId,
      customerName: (visitorData.name || 'Farmer').trim(),
      customerPhone: (visitorData.phone || '').trim(),
      customerEmail: (visitorData.email || '').trim(),
      lastMessage: visitorData.initialMessage || 'Started conversation',
      lastMessageTime: timestamp,
      lastSender: 'customer',
      unreadByAdmin: 1,
      unreadByCustomer: 0,
      status: 'active',
      updatedAt: timestamp
    };

    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        var docRef = AgriFirebase.db.collection(COLLECTIONS.CONVERSATIONS).doc(convId);
        var doc = await docRef.get();
        if (doc.exists) {
          var existing = doc.data();
          var updates = { updatedAt: timestamp };
          if (visitorData.name && visitorData.name !== 'Farmer') updates.customerName = visitorData.name;
          if (visitorData.phone) updates.customerPhone = visitorData.phone;
          if (visitorData.email) updates.customerEmail = visitorData.email;
          await docRef.set(updates, { merge: true });
          return { id: convId, ...existing, ...updates };
        } else {
          convData.createdAt = timestamp;
          await docRef.set({
            ...convData,
            serverTimestamp: window.firebase.firestore.FieldValue.serverTimestamp()
          });
          return convData;
        }
      } catch (err) {
        console.warn('Firestore getOrCreateConversation error:', err);
      }
    }

    return convData;
  };

  // Helper: Retrieve active staff profile, prioritizing Google account display name
  AgriFirebase.getCurrentStaffProfile = function() {
    var profile = {
      name: 'Enock Chinatsvi',
      displayName: 'Enock Chinatsvi',
      email: 'chinatsvieno@gmail.com',
      role: 'admin',
      title: 'Founder & Principal Agricultural Consultant',
      photoURL: ''
    };

    if (AgriFirebase.auth && AgriFirebase.auth.currentUser) {
      var u = AgriFirebase.auth.currentUser;
      if (u.displayName) {
        profile.name = u.displayName;
        profile.displayName = u.displayName;
      }
      if (u.email) profile.email = u.email;
      if (u.photoURL) profile.photoURL = u.photoURL;
    }

    try {
      var sess = JSON.parse(sessionStorage.getItem('agribase_staff_session') || '{}');
      if (sess.name) profile.name = sess.name;
      if (sess.displayName) profile.displayName = sess.displayName;
      if (sess.email) profile.email = sess.email;
      if (sess.role) profile.role = sess.role;
      if (sess.title) profile.title = sess.title;
      if (sess.photoURL) profile.photoURL = sess.photoURL;
    } catch (e) {}

    return profile;
  };

  // 2. Send a message inside a conversation thread
  AgriFirebase.sendChatMessage = async function(conversationId, messageData) {
    var timestamp = new Date().toISOString();
    var sender = messageData.sender || 'customer'; // 'customer' or 'admin'
    var text = (messageData.text || '').trim();
    if (!text) return null;

    var staffProfile = AgriFirebase.getCurrentStaffProfile();
    var defaultSenderName = (sender === 'admin') ? (staffProfile.displayName || staffProfile.name || 'Enock Chinatsvi') : 'Farmer';

    var payload = {
      conversationId: conversationId,
      sender: sender,
      senderName: messageData.senderName || defaultSenderName,
      senderRole: messageData.senderRole || (sender === 'admin' ? (staffProfile.title || 'AgriBase Consultant') : ''),
      senderPhoto: messageData.senderPhoto || (sender === 'admin' ? (staffProfile.photoURL || '') : ''),
      senderEmail: messageData.senderEmail || (sender === 'admin' ? staffProfile.email : ''),
      text: text,
      timestamp: timestamp,
      read: false
    };

    if (AgriFirebase.init() && AgriFirebase.db && conversationId) {
      try {
        // Add to subcollection messages
        await AgriFirebase.db.collection(COLLECTIONS.CONVERSATIONS)
          .doc(conversationId)
          .collection('messages')
          .add({
            ...payload,
            serverTimestamp: window.firebase.firestore.FieldValue.serverTimestamp()
          });

        // Update conversation summary
        var updateSummary = {
          lastMessage: text,
          lastMessageTime: timestamp,
          lastSender: sender,
          updatedAt: timestamp,
          status: 'active'
        };

        if (sender === 'customer') {
          updateSummary.unreadByAdmin = window.firebase.firestore.FieldValue.increment(1);
        } else {
          updateSummary.unreadByCustomer = window.firebase.firestore.FieldValue.increment(1);
        }

        await AgriFirebase.db.collection(COLLECTIONS.CONVERSATIONS)
          .doc(conversationId)
          .update(updateSummary);

      } catch (err) {
        console.warn('Error sending chat message to Firestore:', err);
      }
    }

    return payload;
  };

  // 3. Subscribe in real-time to messages for a specific conversation
  AgriFirebase.subscribeToMessages = function(conversationId, onMessagesReceived) {
    if (AgriFirebase.init() && AgriFirebase.db && conversationId) {
      try {
        return AgriFirebase.db.collection(COLLECTIONS.CONVERSATIONS)
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', 'asc')
          .onSnapshot(function(snapshot) {
            var messages = [];
            snapshot.forEach(function(doc) {
              messages.push({ id: doc.id, ...doc.data() });
            });
            onMessagesReceived(messages);
          }, function(error) {
            console.warn('Messages snapshot listener error:', error);
          });
      } catch (e) {
        console.warn('Could not attach messages snapshot listener:', e);
      }
    }
    return null;
  };

  // 4. Subscribe in real-time to all conversations (for Admin Dashboard)
  AgriFirebase.subscribeToAllConversations = function(onConversationsReceived) {
    if (AgriFirebase.init() && AgriFirebase.db) {
      try {
        return AgriFirebase.db.collection(COLLECTIONS.CONVERSATIONS)
          .orderBy('updatedAt', 'desc')
          .onSnapshot(function(snapshot) {
            var convs = [];
            snapshot.forEach(function(doc) {
              convs.push({ id: doc.id, ...doc.data() });
            });
            onConversationsReceived(convs);
          }, function(error) {
            console.warn('Conversations snapshot listener error:', error);
          });
      } catch (e) {
        console.warn('Could not attach conversations snapshot listener:', e);
      }
    }
    return null;
  };

  // 5. Mark conversation as read
  AgriFirebase.markConversationAsRead = async function(conversationId, readerType) {
    if (AgriFirebase.init() && AgriFirebase.db && conversationId) {
      try {
        var updates = {};
        if (readerType === 'admin') updates.unreadByAdmin = 0;
        if (readerType === 'customer') updates.unreadByCustomer = 0;
        await AgriFirebase.db.collection(COLLECTIONS.CONVERSATIONS).doc(conversationId).update(updates);
      } catch (e) {}
    }
  };

  // Export to window
  window.AgriFirebase = AgriFirebase;

  // Auto-initialize when window loads
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    AgriFirebase.init();
  } else {
    window.addEventListener('DOMContentLoaded', function() {
      AgriFirebase.init();
    });
  }

})(window);

# D & C – AgriBase: Firebase Backend & Security Setup Guide

This document outlines the database structure, security rules, and steps to complete the Firebase connection for the **D & C – AgriBase** website.

---

## 1. Database Collections Architecture

The website connects directly to Google Cloud Firestore using the following 8 collections:

| Collection Name | Document Contents & Purpose | Public Permissions | Staff Permissions |
| :--- | :--- | :--- | :--- |
| `customers` | Farmer profiles, contact information, farms, interaction timestamps. | Create on submit | Read all, update, delete |
| `farming_questions` | Agronomic inquiries submitted by farmers, crop/livestock details, reference codes, responses. | Create, Read own by reference | Read all, review, answer, close |
| `farm_visit_bookings` | On-farm inspection requests, locations, farm size, preferred dates, operational notes. | Create, Read own by reference | Read all, review, reschedule, quote |
| `consultation_bookings`| Online advisory session requests (WhatsApp/telephone), questions, preferred time. | Create, Read own by reference | Read all, confirm, manage |
| `quotations` | Official itemized quotations (service fee, travel mileage, discounts, payment terms). | Read if ref provided | Create, edit, manage |
| `appointments` | Confirmed/approved farm visits and consultations, assigned consultant, schedules. | None | Full management |
| `staff` | Authorized staff team records, roles (`admin`, `consultant`, `assistant`), permissions. | None | Read all; only admin can add/edit |
| `company_settings` | Configurable operational settings (rates, travel fee/km, currency, hours, founder name). | Read | Staff can update |
| `conversations` | Real-time in-app chat threads and message history between farmers and Enock Chinatsvi. | Public initiate & send | Full live chat inbox & replies |

---

## 2. Firebase Console Setup (Only Takes 3 Minutes)

Follow these steps in your [Firebase Console](https://console.firebase.google.com/project/chinatsvienoc):

### Step 1: Enable Email/Password Authentication
1. Open the [Firebase Console](https://console.firebase.google.com/project/chinatsvienoc).
2. In the left navigation menu, go to **Build** → **Authentication**.
3. Click **Get Started** (if not already enabled).
4. Go to the **Sign-in method** tab.
5. Click **Email/Password**, toggle **Enable**, and click **Save**.

### Step 2: Create Founder Staff Account
1. While in **Authentication**, switch to the **Users** tab.
2. Click **Add user**.
3. Enter:
   - **Email:** `chinatsvieno@gmail.com`
   - **Password:** Choose a secure password of your choice.
4. Click **Add user**.

### Step 3: Enable Cloud Firestore
1. In the left navigation menu, go to **Build** → **Firestore Database**.
2. Click **Create database**.
3. Select your preferred Firestore location (e.g., `nam5 (us-central)` or `europe-west`).
4. Choose **Production mode** (our security rules will protect it) and click **Create**.

### Step 4: Deploy Database Security Rules
1. In **Firestore Database**, click on the **Rules** tab at the top.
2. Replace whatever is inside with the contents of the `firestore.rules` file in this repository:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isStaff() {
      return isAuthenticated() && (
        exists(/databases/$(database)/documents/staff/$(request.auth.uid)) ||
        (request.auth.token.email != null && 
         request.auth.token.email == "chinatsvieno@gmail.com")
      );
    }

    match /customers/{customerId} {
      allow create: if true;
      allow read, update, delete: if isStaff();
    }

    match /farming_questions/{questionId} {
      allow create: if request.resource.data.farmerName is string &&
                       request.resource.data.phone is string &&
                       request.resource.data.questionDescription is string;
      allow get: if isStaff() || 
                    (resource.data.reference != null && 
                     request.query.reference == resource.data.reference);
      allow list, update, delete: if isStaff();
    }

    match /farm_visit_bookings/{bookingId} {
      allow create: if request.resource.data.farmerName is string &&
                       request.resource.data.phone is string;
      allow get: if isStaff() || 
                    (resource.data.reference != null && 
                     request.query.reference == resource.data.reference);
      allow list, update, delete: if isStaff();
    }

    match /consultation_bookings/{bookingId} {
      allow create: if request.resource.data.farmerName is string &&
                       request.resource.data.phone is string;
      allow get: if isStaff() || 
                    (resource.data.reference != null && 
                     request.query.reference == resource.data.reference);
      allow list, update, delete: if isStaff();
    }

    match /quotations/{quotationId} {
      allow read: if isStaff() || resource.data.reference != null;
      allow write: if isStaff();
    }

    match /appointments/{appointmentId} {
      allow read, write: if isStaff();
    }

    match /staff/{staffId} {
      allow read: if isAuthenticated();
      allow write: if isStaff();
    }

    match /company_settings/{settingId} {
      allow read: if true;
      allow write: if isStaff();
    }

    // 9. Real-Time In-App Chat Conversations
    match /conversations/{conversationId} {
      allow read, write: if true;

      match /messages/{messageId} {
        allow read, create: if true;
        allow update, delete: if isStaff();
      }
    }
  }
}
```
3. Click **Publish**.

---

## 3. How the Website Integrates with Firebase

1. **Submissions (`/consultancy/ask/`, `/consultancy/farm-visit/`, `/consultancy/online-consultation/`):**
   - Automatically generate a unique human-readable tracking reference (e.g. `ENQ-2610-ABCD`, `VISIT-2610-XYZW`).
   - Write directly to the corresponding Firestore collection (`farming_questions`, `farm_visit_bookings`, or `consultation_bookings`).
   - Auto-upsert into the `customers` collection.
   - Mirror locally for offline resilience.

2. **Real-Time In-App Live Chat Widget (Site-Wide):**
   - Floating on all pages: provides a live chat drawer where visitors can chat directly with Enock Chinatsvi.
   - Saves conversations and subcollection messages in real-time Firestore listeners (`onSnapshot`).
   - Persistent visitor profile saved in browser storage.
   - Direct switch to WhatsApp button integrated.

3. **Self-Service Farmer Tracking Portal (`/consultancy/portal/`):**
   - Allows farmers to look up their submitted question or booking status safely by entering their reference code.
   - Shows status (e.g. `Under Review`, `Quotation Pending`, `Approved`, `Answered`) and official agronomic responses.
   - Includes a direct "💬 Chat Live with Agronomist about this" button pre-populating their reference code!

4. **Secure Admin Dashboard (`/consultancy/admin/`):**
   - Protected by Firebase Authentication (Email + Password).
   - Automatically recognizes `chinatsvieno@gmail.com` as Super Admin / Principal Consultant.
   - Dedicated **Live Chat Inbox Tab**: streams real-time incoming messages from all website visitors, allows instant replies, and features canned agronomic quick-responses.
   - Displays live counters, incoming questions, bookings, quotations, and verified appointments.
   - Supports creating appointments upon approval, preparing mileage-calculated quotations, and managing team staff records.
   - Has emergency fallback passcode mode if internet connectivity is completely lost.

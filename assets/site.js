(function () {
  const content = window.AGRIBASE_CONTENT || { articles: [] };
  const nav = [
    ['Home', '/'], ['Consultancy', '/consultancy/'], ['Farming Guides', '/guides/'], ['Calculators', '/calculators/'],
    ['Crop Calendar', '/calendar/'], ['Ask Question', '/consultancy/ask/'], ['Book Visit', '/consultancy/farm-visit/'],
    ['Farmer Community App', '/community/'], ['About Us', '/about/'], ['Contact', '/contact/']
  ];

  // Enforce single floating chat widget and remove legacy floating elements
  function enforceSingleFloatingChat() {
    try {
      const obsoleteSelectors = [
        '.floating-whatsapp-widget',
        '#agribase-floating-whatsapp',
        '.floating-whatsapp-btn',
        '[class*="whatsapp-floating"]',
        '[class*="floating-whatsapp"]'
      ];
      obsoleteSelectors.forEach(function(sel) {
        document.querySelectorAll(sel).forEach(function(el) { el.remove(); });
      });
    } catch (e) {}
  }
  enforceSingleFloatingChat();

  // Secret 6-Tap Staff Access Listener
  let secretTapCount = 0;
  let secretLastTapTime = 0;

  function initSecretStaffTap() {
    function handleHeaderTap(e) {
      const headerTarget = e.target.closest('[data-site-header], .site-nav, .brand, header, .nav-inner');
      if (!headerTarget) return;

      const now = Date.now();
      if (now - secretLastTapTime < 2500) {
        secretTapCount++;
      } else {
        secretTapCount = 1;
      }
      secretLastTapTime = now;

      // Prevent navigating away if repeatedly tapping brand on homepage
      if (secretTapCount > 1 || window.location.pathname === '/' || window.location.pathname === '/index.html') {
        if (e.target.closest('.brand')) {
          e.preventDefault();
        }
      }

      if (secretTapCount >= 6) {
        secretTapCount = 0;
        e.preventDefault();
        e.stopPropagation();
        openSecretStaffModal();
      }
    }

    document.addEventListener('click', handleHeaderTap);
    document.addEventListener('touchend', handleHeaderTap, { passive: false });
  }

  function openSecretStaffModal() {
    let modal = document.getElementById('agribase-secret-staff-modal');
    if (modal) {
      modal.style.display = 'flex';
      const emailInput = document.getElementById('secret-staff-email');
      if (emailInput) emailInput.focus();
      return;
    }

    if (!document.getElementById('secret-staff-modal-styles')) {
      const style = document.createElement('style');
      style.id = 'secret-staff-modal-styles';
      style.textContent = `
        .secret-staff-modal-backdrop {
          position: fixed;
          inset: 0;
          background: rgba(15, 23, 42, 0.82);
          backdrop-filter: blur(6px);
          -webkit-backdrop-filter: blur(6px);
          z-index: 9999999;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 16px;
          box-sizing: border-box;
          animation: secretFadeIn 0.2s ease;
        }
        @keyframes secretFadeIn {
          from { opacity: 0; transform: scale(0.97); }
          to { opacity: 1; transform: scale(1); }
        }
        .secret-staff-modal-card {
          background: #ffffff;
          color: #1e293b;
          width: 100%;
          max-width: 440px;
          border-radius: 14px;
          box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.45);
          border: 1px solid #cbd5e1;
          overflow: hidden;
          padding: 26px;
          position: relative;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        .secret-modal-close-btn {
          position: absolute;
          top: 14px;
          right: 14px;
          background: #f1f5f9;
          border: none;
          width: 32px;
          height: 32px;
          border-radius: 50%;
          font-size: 16px;
          line-height: 1;
          cursor: pointer;
          color: #475569;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: background 0.15s;
        }
        .secret-modal-close-btn:hover {
          background: #e2e8f0;
          color: #0f172a;
        }
        .secret-badge {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          background: #fef3c7;
          color: #92400e;
          font-size: 11px;
          font-weight: 800;
          letter-spacing: 0.5px;
          text-transform: uppercase;
          padding: 3px 8px;
          border-radius: 999px;
          margin-bottom: 8px;
        }
        .secret-modal-card h3 {
          margin: 0 0 4px;
          font-size: 20px;
          color: #0f172a;
          font-weight: 800;
        }
        .secret-modal-card p.sub {
          margin: 0 0 16px;
          font-size: 13px;
          color: #64748b;
        }
        .secret-tabs-row {
          display: flex;
          gap: 6px;
          background: #f1f5f9;
          padding: 4px;
          border-radius: 8px;
          margin-bottom: 16px;
        }
        .secret-tab-toggle {
          flex: 1;
          padding: 7px 10px;
          font-size: 12.5px;
          font-weight: 700;
          border: none;
          background: transparent;
          color: #64748b;
          border-radius: 6px;
          cursor: pointer;
          transition: all 0.15s;
        }
        .secret-tab-toggle.active {
          background: #ffffff;
          color: #1b4332;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .secret-field-group {
          margin-bottom: 12px;
        }
        .secret-field-group label {
          display: block;
          font-size: 12.5px;
          font-weight: 700;
          color: #334155;
          margin-bottom: 5px;
        }
        .secret-field-input {
          width: 100%;
          box-sizing: border-box;
          padding: 9px 12px;
          border: 1.5px solid #cbd5e1;
          border-radius: 8px;
          font-size: 14px;
          font-family: inherit;
          background: #fff;
          color: #0f172a;
        }
        .secret-field-input:focus {
          border-color: #1b4332;
          outline: none;
          box-shadow: 0 0 0 3px rgba(27,67,50,0.15);
        }
        .secret-login-submit {
          width: 100%;
          background: #1b4332;
          color: #ffffff;
          font-weight: 800;
          padding: 11px;
          font-size: 14px;
          border: none;
          border-radius: 8px;
          cursor: pointer;
          transition: background 0.15s;
          margin-top: 6px;
        }
        .secret-login-submit:hover {
          background: #2d6a4f;
        }
        .secret-google-btn {
          width: 100%;
          background: #ffffff;
          color: #1e293b;
          font-weight: 700;
          padding: 10px 14px;
          font-size: 13.5px;
          border: 1.5px solid #cbd5e1;
          border-radius: 8px;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
          margin-bottom: 14px;
          transition: all 0.15s ease;
        }
        .secret-google-btn:hover {
          background: #f8fafc;
          border-color: #94a3b8;
          box-shadow: 0 2px 6px rgba(0,0,0,0.06);
        }
        .secret-divider {
          display: flex;
          align-items: center;
          text-align: center;
          margin-bottom: 14px;
          color: #94a3b8;
          font-size: 11.5px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        .secret-divider::before, .secret-divider::after {
          content: '';
          flex: 1;
          border-bottom: 1px solid #e2e8f0;
        }
        .secret-divider::before { margin-right: 10px; }
        .secret-divider::after { margin-left: 10px; }
        .secret-msg-alert {
          display: none;
          padding: 9px 12px;
          border-radius: 6px;
          font-size: 13px;
          margin-bottom: 12px;
        }
        .secret-msg-alert.error {
          background: #fee2e2;
          border: 1px solid #f87171;
          color: #991b1b;
        }
        .secret-msg-alert.success {
          background: #dcfce7;
          border: 1px solid #86efac;
          color: #166534;
        }
        .secret-direct-link {
          display: block;
          text-align: center;
          margin-top: 14px;
          font-size: 12.5px;
          color: #1b4332;
          font-weight: 700;
          text-decoration: underline;
        }
      `;
      document.head.appendChild(style);
    }

    modal = document.createElement('div');
    modal.id = 'agribase-secret-staff-modal';
    modal.className = 'secret-staff-modal-backdrop';
    modal.innerHTML = 
      '<div class="secret-staff-modal-card" role="dialog" aria-modal="true" aria-labelledby="secret-title">' +
        '<button type="button" class="secret-modal-close-btn" id="secret-close-btn" aria-label="Close dialog">✕</button>' +
        '<div class="secret-badge">🔒 Confidential Access</div>' +
        '<h3 id="secret-title">Staff & Consultant Login</h3>' +
        '<p class="sub">Authorised AgriBase Personnel Workspace</p>' +
        '<div id="secret-modal-alert" class="secret-msg-alert"></div>' +
        '<div style="background:#f8fafc;border:1.5px solid #cbd5e1;border-radius:10px;padding:14px;margin-bottom:14px;">' +
          '<label for="secret-google-pass" style="display:block;font-size:12px;font-weight:700;color:#334155;margin-bottom:4px;">Staff Security Password <span style="color:#b91c1c;">*</span>:</label>' +
          '<input type="password" id="secret-google-pass" class="secret-field-input" placeholder="Enter staff password" style="margin-bottom:10px;">' +
          '<button type="button" id="secret-btn-google" class="secret-google-btn" style="margin-bottom:0;">' +
            '<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.46-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>' +
            '<span>Verify Password & Sign In with Google</span>' +
          '</button>' +
        '</div>' +
        '<div class="secret-divider"><span>or with credentials</span></div>' +
        '<div class="secret-tabs-row">' +
          '<button type="button" class="secret-tab-toggle active" id="secret-btn-firebase">Staff Credentials</button>' +
          '<button type="button" class="secret-tab-toggle" id="secret-btn-passcode">Emergency Passcode</button>' +
        '</div>' +
        '<form id="secret-login-form">' +
          '<div id="secret-mode-firebase-wrap">' +
            '<div class="secret-field-group">' +
              '<label for="secret-staff-email">Staff Email Address:</label>' +
              '<input type="email" id="secret-staff-email" class="secret-field-input" value="chinatsvieno@gmail.com" required placeholder="chinatsvieno@gmail.com">' +
            '</div>' +
            '<div class="secret-field-group">' +
              '<label for="secret-staff-pass">Staff Security Password:</label>' +
              '<input type="password" id="secret-staff-pass" class="secret-field-input" placeholder="Enter staff password">' +
            '</div>' +
          '</div>' +
          '<div id="secret-mode-passcode-wrap" style="display:none;">' +
            '<div class="secret-field-group">' +
              '<label for="secret-staff-code">Staff Emergency Passcode:</label>' +
              '<input type="password" id="secret-staff-code" class="secret-field-input" placeholder="Enter staff password">' +
              '<div style="font-size:11.5px;color:#64748b;margin-top:4px;">Master staff authorization required</div>' +
            '</div>' +
          '</div>' +
          '<button type="submit" id="secret-submit-btn" class="secret-login-submit">Sign In & Open Workspace →</button>' +
        '</form>' +
        '<a href="/consultancy/admin/" class="secret-direct-link">Open Consultant Workspace Directly →</a>' +
      '</div>';

    document.body.appendChild(modal);

    let activeMode = 'firebase';
    const alertEl = document.getElementById('secret-modal-alert');
    const btnGoogle = document.getElementById('secret-btn-google');
    const btnFirebase = document.getElementById('secret-btn-firebase');
    const btnPasscode = document.getElementById('secret-btn-passcode');
    const wrapFirebase = document.getElementById('secret-mode-firebase-wrap');
    const wrapPasscode = document.getElementById('secret-mode-passcode-wrap');
    const closeBtn = document.getElementById('secret-close-btn');
    const form = document.getElementById('secret-login-form');
    const submitBtn = document.getElementById('secret-submit-btn');

    if (btnGoogle) {
      btnGoogle.onclick = async function() {
        alertEl.style.display = 'none';
        alertEl.className = 'secret-msg-alert';

        const gPassInput = document.getElementById('secret-google-pass');
        let enteredPass = (gPassInput ? gPassInput.value : '').trim();
        if (!enteredPass) {
          const altPass = document.getElementById('secret-staff-pass');
          if (altPass && altPass.value) enteredPass = altPass.value.trim();
        }

        if (!window.AgriFirebase || !window.AgriFirebase.isStaffAuthorizedPassword(enteredPass)) {
          alertEl.innerHTML = '<strong>Access Denied:</strong> Please enter the staff security password (<strong>Chinatsvi Enock</strong>) to verify administrative privileges before signing in with Google.';
          alertEl.classList.add('error');
          alertEl.style.display = 'block';
          if (gPassInput) gPassInput.focus();
          return;
        }

        btnGoogle.disabled = true;
        btnGoogle.innerHTML = 'Connecting to Google...';
        try {
          if (window.AgriFirebase && typeof window.AgriFirebase.loginStaffWithGoogle === 'function') {
            const res = await window.AgriFirebase.loginStaffWithGoogle(enteredPass);
            const staffName = (res.user && res.user.displayName) || (res.staff && res.staff.name) || 'Consultant';
            sessionStorage.setItem('agribase_staff_session', JSON.stringify({
              email: res.user.email,
              name: staffName,
              photoURL: (res.user && res.user.photoURL) || '',
              role: (res.staff && res.staff.role) || 'admin',
              title: (res.staff && res.staff.title) || 'Principal Consultant',
              uid: res.user.uid,
              provider: 'google',
              verifiedWithMasterKey: true,
              loggedInAt: new Date().toISOString()
            }));
            alertEl.textContent = 'Welcome ' + staffName + '! Opening workspace...';
            alertEl.classList.add('success');
            alertEl.style.display = 'block';
            setTimeout(function() {
              window.location.href = '/consultancy/admin/';
            }, 350);
          } else {
            window.location.href = '/consultancy/admin/';
          }
        } catch (err) {
          btnGoogle.disabled = false;
          btnGoogle.innerHTML = '<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.46-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg> <span>Verify Password & Sign In with Google</span>';
          let msg = err.message || 'Google sign-in failed.';
          if (err.code === 'auth/popup-closed-by-user') {
            msg = 'Google login window was closed before completing.';
          }
          alertEl.textContent = msg;
          alertEl.classList.add('error');
          alertEl.style.display = 'block';
        }
      };
    }

    function closeModal() {
      modal.style.display = 'none';
    }

    closeBtn.onclick = closeModal;
    modal.onclick = function(e) {
      if (e.target === modal) closeModal();
    };
    window.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && modal.style.display !== 'none') closeModal();
    });

    btnFirebase.onclick = function() {
      activeMode = 'firebase';
      btnFirebase.classList.add('active');
      btnPasscode.classList.remove('active');
      wrapFirebase.style.display = 'block';
      wrapPasscode.style.display = 'none';
      submitBtn.textContent = 'Sign In with Staff Credentials →';
      document.getElementById('secret-staff-pass').required = true;
      document.getElementById('secret-staff-code').required = false;
    };

    btnPasscode.onclick = function() {
      activeMode = 'passcode';
      btnPasscode.classList.add('active');
      btnFirebase.classList.remove('active');
      wrapFirebase.style.display = 'none';
      wrapPasscode.style.display = 'block';
      submitBtn.textContent = 'Sign In with Passcode Backup →';
      document.getElementById('secret-staff-pass').required = false;
      document.getElementById('secret-staff-code').required = true;
    };

    form.onsubmit = async function(e) {
      e.preventDefault();
      alertEl.style.display = 'none';
      alertEl.className = 'secret-msg-alert';

      if (activeMode === 'firebase') {
        const email = document.getElementById('secret-staff-email').value.trim();
        const pass = document.getElementById('secret-staff-pass').value;
        if (!pass) {
          alertEl.textContent = 'Please enter your staff password.';
          alertEl.classList.add('error');
          alertEl.style.display = 'block';
          return;
        }
        submitBtn.textContent = 'Authenticating staff...';
        submitBtn.disabled = true;

        try {
          if (window.AgriFirebase && typeof window.AgriFirebase.loginStaff === 'function') {
            const authResult = await window.AgriFirebase.loginStaff(email, pass);
            sessionStorage.setItem('agribase_staff_session', JSON.stringify({
              email: authResult.user.email,
              role: (authResult.staff && authResult.staff.role) ? authResult.staff.role : 'admin',
              title: (authResult.staff && authResult.staff.title) || 'Principal Consultant',
              uid: authResult.user.uid,
              verifiedWithMasterKey: true,
              loggedInAt: new Date().toISOString()
            }));
            alertEl.textContent = 'Authentication successful! Loading workspace...';
            alertEl.classList.add('success');
            alertEl.style.display = 'block';
            setTimeout(function() {
              window.location.href = '/consultancy/admin/';
            }, 400);
          } else {
            window.location.href = '/consultancy/admin/';
          }
        } catch (err) {
          let msg = err.message || 'Authentication failed.';
          if (err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
            msg = 'Incorrect password. Please enter the staff security password ("Chinatsvi Enock").';
          }
          alertEl.textContent = msg;
          alertEl.classList.add('error');
          alertEl.style.display = 'block';
          submitBtn.disabled = false;
          submitBtn.textContent = 'Sign In with Staff Credentials →';
        }
      } else {
        const code = document.getElementById('secret-staff-code').value.trim();
        if (window.AgriFirebase && window.AgriFirebase.isStaffAuthorizedPassword(code)) {
          sessionStorage.setItem('agribase_staff_session', JSON.stringify({
            email: 'chinatsvieno@gmail.com',
            role: 'admin',
            title: 'Founder & Principal Consultant',
            verifiedWithMasterKey: true,
            loggedInAt: new Date().toISOString()
          }));
          alertEl.textContent = 'Access granted! Redirecting to workspace...';
          alertEl.classList.add('success');
          alertEl.style.display = 'block';
          submitBtn.textContent = 'Opening Workspace...';
          setTimeout(function() {
            window.location.href = '/consultancy/admin/';
          }, 350);
        } else {
          alertEl.textContent = 'Incorrect passcode. Please enter the staff security password ("Chinatsvi Enock").';
          alertEl.classList.add('error');
          alertEl.style.display = 'block';
        }
      }
    };
  }

  function renderHeader() {
    const host = document.querySelector('[data-site-header]');
    if (!host) return;
    host.innerHTML = '<nav class="site-nav"><div class="nav-inner"><a class="brand" href="/" aria-label="D & C – AgriBase home"><img src="/favicon-256.png" alt="D & C AgriBase logo"><span>D &amp; C – AgriBase</span></a><button class="nav-toggle" aria-label="Open navigation"><span></span><span></span><span></span></button><div class="nav-links">' +
      nav.map(item => '<a href="' + item[1] + '"' + (item[0].toLowerCase().includes('consultancy') ? ' class="nav-consultancy-link" style="color:var(--gold);font-weight:800;"' : '') + '>' + item[0] + '</a>').join('') +
      '</div></div></nav>';
    host.querySelector('.nav-toggle').onclick = () => host.querySelector('.nav-links').classList.toggle('open');
    enforceSingleFloatingChat();
  }

  function loadLiveChat() {
    if (window.location.pathname.indexOf('/consultancy/admin') !== -1) return;

    if (!document.getElementById('agribase-live-chat-css')) {
      var link = document.createElement('link');
      link.id = 'agribase-live-chat-css';
      link.rel = 'stylesheet';
      link.href = '/assets/live-chat.css';
      document.head.appendChild(link);
    }

    function loadScript(src, cb) {
      var s = document.createElement('script');
      s.src = src;
      if (cb) s.onload = cb;
      document.head.appendChild(s);
    }

    function initFirebaseAndChat() {
      if (!window.AgriFirebase) {
        loadScript('/assets/firebase-service.js', function() {
          if (!window.AgriLiveChat) loadScript('/assets/live-chat.js');
        });
      } else {
        if (!window.AgriLiveChat) loadScript('/assets/live-chat.js');
      }
    }

    if (typeof window.firebase === 'undefined') {
      loadScript('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js', function() {
        loadScript('https://www.gstatic.com/firebasejs/10.12.0/firebase-auth-compat.js', function() {
          loadScript('https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore-compat.js', function() {
            initFirebaseAndChat();
          });
        });
      });
    } else {
      initFirebaseAndChat();
    }
  }

  function renderFooter() {
    const host = document.querySelector('[data-site-footer]');
    if (!host) return;
    host.innerHTML = '<footer><div class="container footer-grid"><div><h3>D & C – AgriBase</h3><p>Practical agricultural consultancy, on-farm advisory services, training and digital farming tools powering the Farmer Community App.</p><p style="margin-top:6px;font-size:13px;color:rgba(255,255,255,0.75);">Founder & Principal Consultant: Enock Chinatsvi</p><div class="footer-visitor-strip"><span class="footer-live-dot"></span><span class="footer-visitor-label">Platform Visits:</span><a href="https://hits.sh/chinatsvi.github.io/" target="_blank" rel="noopener" title="Live platform traffic counter" class="footer-visitor-badge"><img src="https://hits.sh/chinatsvi.github.io.svg?label=Visitors&color=2e7d32&labelColor=1a3b2b" alt="AgriBase Real Visitor Counter" loading="eager"></a></div></div><div><h3>Consultancy</h3><a href="/consultancy/">Consultancy Home</a><a href="/consultancy/services/">Services Catalogue</a><a href="/consultancy/ask/">Ask Farming Question</a><a href="/consultancy/farm-visit/">Book Farm Visit</a><a href="/consultancy/online-consultation/">Online Consultations</a><a href="/consultancy/portal/">Track My Enquiry</a><a href="/consultancy/admin/">Consultant Workspace</a></div><div><h3>Farming Tools</h3><a href="/guides/">Farming Guides</a><a href="/calculators/">Farm Calculators</a><a href="/decision-tools/">Decision Tools</a><a href="/calendar/">Crop Calendar</a><a href="/community/">Farmer Community App</a></div><div><h3>Company & Trust</h3><a href="/about/">About Us</a><a href="/contact/">Contact & Bookings</a><a href="/privacy/">Privacy Policy</a><a href="/terms/">Terms & Advisory Disclaimer</a><a href="/disclaimer/">Disclaimer</a></div></div><div class="container copyright">&copy; 2026 D & C – AgriBase. Practical Agricultural Knowledge. Professional Advice. Better Farming Decisions.</div></footer>';
    loadLiveChat();
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

  function initFarmerVoices() {
    const toggleBtn = document.getElementById('toggle-voices-btn');
    const expandableWrapper = document.getElementById('expandable-voices');
    const toggleText = document.getElementById('toggle-btn-text');
    const openModalBtn = document.getElementById('open-voice-modal-btn');
    const modal = document.getElementById('voice-modal');
    const closeModalBtn = document.getElementById('close-voice-modal');
    const cancelModalBtn = document.getElementById('cancel-voice-btn');
    const doneModalBtn = document.getElementById('done-voice-btn');
    const form = document.getElementById('farmer-voice-form');
    const userVoicesContainer = document.getElementById('user-voices-container');
    const totalCountEl = document.getElementById('voices-total-count');
    const formView = document.getElementById('modal-form-view');
    const successView = document.getElementById('modal-success-view');
    const starPicker = document.getElementById('star-picker');
    const ratingInput = document.getElementById('farmer-rating');
    const ratingText = document.getElementById('rating-text');
    const feedbackInput = document.getElementById('farmer-feedback');
    const charCurrent = document.getElementById('char-current');
    const emailShareLink = document.getElementById('email-share-link');
    const whatsappShareLink = document.getElementById('whatsapp-share-link');

    if (!toggleBtn && !openModalBtn) return;

    function getInitials(name) {
      if (!name) return 'FM';
      const parts = name.trim().split(/\s+/);
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return name.slice(0, 2).toUpperCase();
    }

    function escapeHtml(str) {
      if (!str) return '';
      return String(str).replace(/[&<>"']/g, function(m) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m];
      });
    }

    function loadSavedVoices() {
      try {
        const saved = JSON.parse(localStorage.getItem('agribase_farmer_voices') || '[]');
        if (userVoicesContainer) {
          userVoicesContainer.innerHTML = saved.map(function(v) {
            const stars = '★'.repeat(v.rating || 5);
            return '<article class="testimonial-card user-voice-card">' +
              '<div>' +
                '<div class="user-voice-badge">Verified Community Voice</div>' +
                '<div class="quote-header">' +
                  '<div class="quote-icon">“</div>' +
                  '<div class="star-rating" aria-label="' + (v.rating || 5) + ' out of 5 stars">' + stars + '</div>' +
                '</div>' +
                '<p class="testimonial-text">' + escapeHtml(v.feedback) + '</p>' +
              '</div>' +
              '<div class="farmer-profile">' +
                '<div class="farmer-avatar">' + escapeHtml(getInitials(v.name)) + '</div>' +
                '<div class="farmer-info">' +
                  '<strong>' + escapeHtml(v.name) + '</strong>' +
                  '<span>' + escapeHtml(v.enterprise) + ' • ' + escapeHtml(v.location) + '</span>' +
                  '<small style="color: var(--field); display: block; margin-top: 2px;">Used: ' + escapeHtml(v.tool) + '</small>' +
                '</div>' +
              '</div>' +
            '</article>';
          }).join('');
        }
        if (totalCountEl) {
          const total = 9 + saved.length;
          totalCountEl.textContent = total + ' Verified Farmer Stories';
        }
      } catch (e) {
        console.warn('Could not load farmer voices from localStorage', e);
      }
    }

    loadSavedVoices();

    if (toggleBtn && expandableWrapper) {
      toggleBtn.addEventListener('click', function() {
        const isClosed = expandableWrapper.style.display === 'none' || expandableWrapper.style.display === '';
        if (isClosed) {
          expandableWrapper.style.display = 'block';
          toggleBtn.setAttribute('aria-expanded', 'true');
          toggleBtn.classList.add('is-expanded');
          if (toggleText) toggleText.textContent = 'Show Fewer Stories';
        } else {
          expandableWrapper.style.display = 'none';
          toggleBtn.setAttribute('aria-expanded', 'false');
          toggleBtn.classList.remove('is-expanded');
          if (toggleText) toggleText.textContent = 'View More Farmer Voices (6 more stories)';
          const section = document.getElementById('farmer-voices');
          if (section) section.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });
    }

    function openModal() {
      if (!modal) return;
      modal.style.display = 'flex';
      document.body.style.overflow = 'hidden';
      if (formView) formView.style.display = 'block';
      if (successView) successView.style.display = 'none';
      if (form) form.reset();
      setRating(5);
      if (charCurrent) charCurrent.textContent = '0';
      const firstInput = document.getElementById('farmer-name');
      if (firstInput) setTimeout(function() { firstInput.focus(); }, 50);
    }

    function closeModal() {
      if (!modal) return;
      modal.style.display = 'none';
      document.body.style.overflow = '';
    }

    if (openModalBtn) openModalBtn.addEventListener('click', openModal);
    if (closeModalBtn) closeModalBtn.addEventListener('click', closeModal);
    if (cancelModalBtn) cancelModalBtn.addEventListener('click', closeModal);
    if (doneModalBtn) doneModalBtn.addEventListener('click', closeModal);

    if (modal) {
      modal.addEventListener('click', function(e) {
        if (e.target === modal) closeModal();
      });
      window.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && modal.style.display === 'flex') closeModal();
      });
    }

    function setRating(val) {
      if (!ratingInput) return;
      ratingInput.value = val;
      const stars = starPicker ? starPicker.querySelectorAll('.star-btn') : [];
      stars.forEach(function(btn) {
        const btnVal = parseInt(btn.dataset.rating, 10);
        btn.classList.toggle('active', btnVal <= val);
      });
      if (ratingText) {
        const labels = {
          1: '1 / 5 Stars (Needs Improvement)',
          2: '2 / 5 Stars (Fair)',
          3: '3 / 5 Stars (Good)',
          4: '4 / 5 Stars (Very Helpful)',
          5: '5 / 5 Stars (Excellent)'
        };
        ratingText.textContent = labels[val] || (val + ' / 5 Stars');
      }
    }

    if (starPicker) {
      starPicker.addEventListener('click', function(e) {
        const btn = e.target.closest('.star-btn');
        if (!btn) return;
        const rating = parseInt(btn.dataset.rating, 10);
        setRating(rating);
      });
    }

    if (feedbackInput && charCurrent) {
      feedbackInput.addEventListener('input', function() {
        charCurrent.textContent = String(feedbackInput.value.length);
      });
    }

    if (form) {
      form.addEventListener('submit', function(e) {
        e.preventDefault();
        const name = document.getElementById('farmer-name').value.trim();
        const location = document.getElementById('farmer-location').value.trim();
        const enterprise = document.getElementById('farmer-enterprise').value.trim();
        const tool = document.getElementById('farmer-tool').value;
        const rating = parseInt(ratingInput ? ratingInput.value : '5', 10) || 5;
        const feedback = feedbackInput.value.trim();

        if (!name || !location || !enterprise || !tool || !feedback) return;

        const newVoice = {
          name: name,
          location: location,
          enterprise: enterprise,
          tool: tool,
          rating: rating,
          feedback: feedback,
          createdAt: new Date().toISOString()
        };

        try {
          const saved = JSON.parse(localStorage.getItem('agribase_farmer_voices') || '[]');
          saved.unshift(newVoice);
          localStorage.setItem('agribase_farmer_voices', JSON.stringify(saved));
        } catch (err) {
          console.warn('Failed to save to localStorage', err);
        }

        loadSavedVoices();

        const subject = encodeURIComponent('Farmer Voice Submission from ' + name);
        const bodyText = encodeURIComponent(
          'Hi Enock,\n\nI want to share my field experience for AgriBase:\n\n' +
          'Name/Farm: ' + name + '\nLocation: ' + location + '\nEnterprise: ' + enterprise + '\n' +
          'AgriBase Tool/Guide: ' + tool + '\nRating: ' + rating + '/5 Stars\n' +
          'My Experience & Results:\n' + feedback + '\n\nSubmitted via AgriBase Website'
        );
        if (emailShareLink) {
          emailShareLink.href = 'mailto:chinatsvieno@gmail.com?subject=' + subject + '&body=' + bodyText;
        }
        if (whatsappShareLink) {
          whatsappShareLink.href = 'https://wa.me/2774902204?text=' + bodyText;
        }

        if (formView) formView.style.display = 'none';
        if (successView) successView.style.display = 'block';
      });
    }
  }

  function start() {
    renderHeader();
    renderFooter();
    renderArticles();
    renderCalculator();
    initFarmerVoices();
    loadAdSense();
    initSecretStaffTap();
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


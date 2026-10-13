/**
 * D & C – AGRIBASE IN-APP LIVE CHAT ENGINE
 * Direct real-time bidirectional messaging between Farmers and Enock Chinatsvi (Principal Consultant)
 * Powered by Google Cloud Firestore (Conversations & Messages collections)
 */
(function(window) {
  'use strict';

  var STORAGE_KEY_USER = 'agribase_chat_user';
  var STORAGE_KEY_CONV = 'agribase_chat_conv_id';

  // Get or initialize visitor identity
  function getVisitorData() {
    try {
      var data = JSON.parse(localStorage.getItem(STORAGE_KEY_USER));
      if (data && data.visitorId) return data;
    } catch (e) {}

    var newId = 'vis_' + Math.random().toString(36).substring(2, 10) + Date.now().toString(36);
    var initUser = {
      visitorId: newId,
      name: '',
      phone: '',
      email: ''
    };
    try { localStorage.setItem(STORAGE_KEY_USER, JSON.stringify(initUser)); } catch (e) {}
    return initUser;
  }

  function saveVisitorData(userData) {
    try {
      localStorage.setItem(STORAGE_KEY_USER, JSON.stringify(userData));
    } catch (e) {}
  }

  var visitor = getVisitorData();
  var activeConversationId = null;
  var messageUnsubscribe = null;
  var isChatOpen = false;
  var unreadCount = 0;

  // Initialize and inject Chat UI
  function initLiveChat() {
    // Avoid double injection
    if (document.getElementById('agribase-chat-widget-root')) return;

    var root = document.createElement('div');
    root.id = 'agribase-chat-widget-root';

    root.innerHTML = 
      '<div class="agribase-floating-dock">' +
        '<button id="agribase-livechat-toggle" class="floating-livechat-btn" aria-label="Live Chat with Agronomist">' +
          '<span class="chat-pulse-dot"></span>' +
          '<span style="font-size:18px;">💬</span>' +
          '<span class="chat-btn-text">' +
            '<strong>Live Agronomist Chat</strong>' +
            '<small>Instant in-app advisory</small>' +
          '</span>' +
          '<span id="chat-unread-badge" class="chat-unread-badge" style="display:none;">0</span>' +
        '</button>' +
      '</div>' +

      '<div id="agribase-chat-window" class="agribase-chat-window">' +
        '<!-- Header -->' +
        '<div class="agribase-chat-header">' +
          '<div class="chat-header-profile">' +
            '<div class="chat-header-avatar">EC</div>' +
            '<div class="chat-header-info">' +
              '<span class="chat-header-name">Enock Chinatsvi</span>' +
              '<span class="chat-header-status"><span class="chat-pulse-dot"></span> Online • Principal Consultant</span>' +
            '</div>' +
          '</div>' +
          '<div class="chat-header-actions">' +
            '<a href="https://wa.me/2774902204?text=Hello%20Enock%2C%20I%20am%20chatting%20on%20AgriBase%20and%20would%20like%20to%20continue%20on%20WhatsApp" target="_blank" rel="noopener" class="chat-header-btn" title="Switch to WhatsApp" style="text-decoration:none;">📲</a>' +
            '<button id="agribase-chat-close-btn" class="chat-header-btn" title="Close Chat">&times;</button>' +
          '</div>' +
        '</div>' +

        '<!-- Body -->' +
        '<div id="agribase-chat-messages" class="agribase-chat-body">' +
          '<div class="chat-intro-banner">' +
            '<strong>🌾 Welcome to D & C – AgriBase Live Advisory</strong>' +
            'Direct agronomic assistance with crops, pest identification, soil management, or on-farm visit requests.' +
          '</div>' +
          '<div id="chat-id-container"></div>' +
          '<div id="chat-messages-stream"></div>' +
        '</div>' +

        '<!-- Quick Suggestions -->' +
        '<div style="padding:4px 14px;background:#f1f5f9;border-top:1px solid #e2e8f0;">' +
          '<div class="chat-quick-topics">' +
            '<button type="button" class="chat-topic-chip" onclick="window.AgriLiveChat.sendQuickTag(\'I have a crop disease issue and need help identifying it.\')">🌱 Crop disease help</button>' +
            '<button type="button" class="chat-topic-chip" onclick="window.AgriLiveChat.sendQuickTag(\'How do I calculate fertilizer rates for my field?\')">🧪 Fertilizer advice</button>' +
            '<button type="button" class="chat-topic-chip" onclick="window.AgriLiveChat.sendQuickTag(\'I would like to book an on-farm inspection visit.\')">🚜 Book farm visit</button>' +
          '</div>' +
        '</div>' +

        '<!-- Footer -->' +
        '<form id="agribase-chat-form" class="agribase-chat-footer" onsubmit="window.AgriLiveChat.handleSendMessage(event)">' +
          '<input type="text" id="agribase-chat-input" class="chat-input-field" placeholder="Type your farming question..." autocomplete="off">' +
          '<button type="submit" id="agribase-chat-send" class="chat-send-btn" title="Send message">➤</button>' +
        '</form>' +
      '</div>';

    document.body.appendChild(root);

    // Wire events
    document.getElementById('agribase-livechat-toggle').addEventListener('click', toggleChatWindow);
    document.getElementById('agribase-chat-close-btn').addEventListener('click', toggleChatWindow);

    renderIdPrompt();
    connectToConversation();
  }

  function toggleChatWindow() {
    isChatOpen = !isChatOpen;
    var win = document.getElementById('agribase-chat-window');
    if (!win) return;

    if (isChatOpen) {
      win.classList.add('open');
      unreadCount = 0;
      updateBadge();
      if (activeConversationId && window.AgriFirebase && typeof window.AgriFirebase.markConversationAsRead === 'function') {
        window.AgriFirebase.markConversationAsRead(activeConversationId, 'customer');
      }
      setTimeout(function() {
        var input = document.getElementById('agribase-chat-input');
        if (input) input.focus();
        scrollToBottom();
      }, 100);
    } else {
      win.classList.remove('open');
    }
  }

  function updateBadge() {
    var badge = document.getElementById('chat-unread-badge');
    if (!badge) return;
    if (unreadCount > 0 && !isChatOpen) {
      badge.textContent = unreadCount;
      badge.style.display = 'flex';
    } else {
      badge.style.display = 'none';
    }
  }

  function renderIdPrompt() {
    var container = document.getElementById('chat-id-container');
    if (!container) return;

    if (visitor.name && visitor.phone) {
      container.innerHTML = 
        '<div style="font-size:11.5px;color:#64748b;padding:4px 0;display:flex;justify-content:space-between;align-items:center;">' +
          '<span>Chatting as: <strong>' + escapeHtml(visitor.name) + '</strong> (' + escapeHtml(visitor.phone) + ')</span>' +
          '<a href="javascript:void(0)" onclick="window.AgriLiveChat.resetIdentity()" style="color:#2e7d32;text-decoration:none;">Edit</a>' +
        '</div>';
    } else {
      container.innerHTML = 
        '<div class="chat-id-prompt">' +
          '<h4>👋 Introduce Yourself</h4>' +
          '<p>Please enter your name and phone/WhatsApp so Enock can address your farming query accurately.</p>' +
          '<div class="chat-id-form">' +
            '<input type="text" id="chat-intro-name" class="chat-id-input" placeholder="Your Full Name (e.g. John Moyo)" value="' + escapeHtml(visitor.name || '') + '">' +
            '<input type="tel" id="chat-intro-phone" class="chat-id-input" placeholder="Phone / WhatsApp Number" value="' + escapeHtml(visitor.phone || '') + '">' +
            '<button type="button" class="chat-id-submit" onclick="window.AgriLiveChat.saveIdentity()">Confirm & Continue Chat →</button>' +
          '</div>' +
        '</div>';
    }
  }

  async function connectToConversation() {
    if (!window.AgriFirebase || !window.AgriFirebase.init()) {
      setTimeout(connectToConversation, 800);
      return;
    }

    try {
      var conv = await window.AgriFirebase.getOrCreateConversation(visitor);
      if (conv && conv.id) {
        activeConversationId = conv.id;
        localStorage.setItem(STORAGE_KEY_CONV, conv.id);

        // Listen in real-time to messages
        if (messageUnsubscribe) messageUnsubscribe();
        messageUnsubscribe = window.AgriFirebase.subscribeToMessages(conv.id, function(messages) {
          renderMessages(messages);
        });
      }
    } catch (e) {
      console.warn('Chat connection error:', e);
    }
  }

  function renderMessages(messages) {
    var container = document.getElementById('chat-messages-stream');
    if (!container) return;

    if (!messages || !messages.length) {
      container.innerHTML = 
        '<div class="chat-msg msg-admin" style="margin-top:10px;">' +
          '<div class="msg-bubble">' +
            'Hello! I am Enock Chinatsvi. Please describe your crop or livestock question, or specify what farming challenge you are facing right now.' +
          '</div>' +
          '<div class="msg-meta">Enock Chinatsvi • Just now</div>' +
        '</div>';
      return;
    }

    // Check for newly arrived admin messages when closed
    var latest = messages[messages.length - 1];
    if (latest && latest.sender === 'admin' && !latest.read && !isChatOpen) {
      unreadCount++;
      updateBadge();
    }

    var html = messages.map(function(m) {
      var isMe = (m.sender === 'customer');
      var timeStr = m.timestamp ? formatChatTime(m.timestamp) : '';
      var senderLabel = isMe ? 'You' : (m.senderName || 'Enock Chinatsvi');
      return '<div class="chat-msg ' + (isMe ? 'msg-customer' : 'msg-admin') + '">' +
        '<div class="msg-bubble">' + escapeHtml(m.text) + '</div>' +
        '<div class="msg-meta">' + senderLabel + (timeStr ? ' • ' + timeStr : '') + '</div>' +
      '</div>';
    }).join('');

    container.innerHTML = html;
    scrollToBottom();

    if (isChatOpen && activeConversationId && window.AgriFirebase) {
      window.AgriFirebase.markConversationAsRead(activeConversationId, 'customer');
    }
  }

  function scrollToBottom() {
    var body = document.getElementById('agribase-chat-messages');
    if (body) {
      body.scrollTop = body.scrollHeight;
    }
  }

  function formatChatTime(ts) {
    try {
      var d = new Date(ts);
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
      return '';
    }
  }

  function escapeHtml(text) {
    if (!text) return '';
    return String(text)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  // Public Interface
  window.AgriLiveChat = {
    toggle: toggleChatWindow,

    saveIdentity: function() {
      var nameInput = document.getElementById('chat-intro-name');
      var phoneInput = document.getElementById('chat-intro-phone');
      if (!nameInput || !phoneInput) return;

      var name = nameInput.value.trim();
      var phone = phoneInput.value.trim();

      if (!name) {
        alert('Please enter your name.');
        return;
      }
      if (!phone) {
        alert('Please enter your phone number.');
        return;
      }

      visitor.name = name;
      visitor.phone = phone;
      saveVisitorData(visitor);
      renderIdPrompt();

      // Update conversation in Firestore
      connectToConversation();
    },

    resetIdentity: function() {
      visitor.name = '';
      visitor.phone = '';
      saveVisitorData(visitor);
      renderIdPrompt();
    },

    sendQuickTag: function(tagText) {
      var input = document.getElementById('agribase-chat-input');
      if (input) {
        input.value = tagText;
        input.focus();
      }
    },

    handleSendMessage: async function(e) {
      if (e) e.preventDefault();
      var input = document.getElementById('agribase-chat-input');
      if (!input) return;

      var text = input.value.trim();
      if (!text) return;

      // Ensure identity exists
      if (!visitor.name || !visitor.phone) {
        var nameField = document.getElementById('chat-intro-name');
        if (nameField && nameField.value.trim()) {
          visitor.name = nameField.value.trim();
          visitor.phone = (document.getElementById('chat-intro-phone') ? document.getElementById('chat-intro-phone').value.trim() : '') || 'Not provided';
          saveVisitorData(visitor);
          renderIdPrompt();
        } else {
          alert('Please enter your name and phone number above before sending your question.');
          if (nameField) nameField.focus();
          return;
        }
      }

      input.value = '';
      var sendBtn = document.getElementById('agribase-chat-send');
      if (sendBtn) sendBtn.disabled = true;

      try {
        if (!activeConversationId) {
          var conv = await window.AgriFirebase.getOrCreateConversation(visitor);
          activeConversationId = conv.id;
        }

        await window.AgriFirebase.sendChatMessage(activeConversationId, {
          sender: 'customer',
          senderName: visitor.name || 'Farmer',
          text: text
        });
      } catch (err) {
        console.warn('Error sending message:', err);
      } finally {
        if (sendBtn) sendBtn.disabled = false;
        if (input) input.focus();
      }
    }
  };

  // Auto-boot when document is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLiveChat);
  } else {
    initLiveChat();
  }

})(window);

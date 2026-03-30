/**
 * Ignite.js — Frontend glue for Ignite LiveView.
 *
 * Uses morphdom for efficient DOM patching:
 * - Instead of replacing innerHTML (which destroys focus, animations, etc.),
 *   morphdom compares the old and new HTML and only updates what changed.
 *
 * Protocol:
 * - On mount: server sends {s: [...statics], d: [...dynamics]}
 * - On update: server sends {d: [...dynamics]}
 * - JS zips statics + dynamics, then morphdom patches the DOM
 */

/**
 * Supported attributes:
 * - ignite-click="event"    — sends a click event to the server
 * - ignite-change="event"   — sends a change event to the server
 * - ignite-submit="event"   — sends a form submission to the server
 * - ignite-value="val"      — optional static value sent with click events
 * - ignite-navigate="/path" — client-side LiveView navigation (no full page reload)
 * - ignite-hook="HookName"  — attach a JS Hook for client-side interop
 * - ignite-upload="name"   — file input connected to LiveView upload
 * - ignite-drop-target="name" — drag-and-drop zone for LiveView upload
 */

(function () {
  "use strict";

  // --- Configuration ---
  var APP_CONTAINER_ID = "ignite-app";
  var appContainer = document.getElementById(APP_CONTAINER_ID);
  var liveRoutesStr = appContainer ? appContainer.getAttribute("data-live-routes") : "{}";
  var liveRoutes = JSON.parse(liveRoutesStr);
  var statusEl = document.getElementById("ignite-status");

  function setStatus(text, className) {
    if (statusEl) {
      statusEl.textContent = text;
      statusEl.className = "status " + (className || "");
    }
  }

  var reconnectDelay = 200;
  var MAX_DELAY = 5000;
  var reconnectTimer = null;
  var navigating = false;

  // Statics are saved from the first message and reused for every update
  var statics = null;
  // Dynamics are updated via sparse diffs from the server
  var dynamics = [];

  // Track active JS Hook instances by their element ID
  var mountedHooks = {};

  // --- WebSocket Connection ---
  var protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  var socket = null;

  function connect(livePath) {
    if (socket) {
      destroyAllHooks();
      socket.close();
    }
    
    // Reset state for new view
    statics = null;
    dynamics = [];
    if (appContainer && appContainer.firstElementChild) {
       // We can blank the container while loading or just wait for the new HTML
    }

    socket = new WebSocket(protocol + "//" + window.location.host + livePath);
  }

  function scheduleReconnect() {
    if (reconnectTimer) return;
    var currentPath = (appContainer && appContainer.dataset.livePath) || initialLivePath;
    reconnectTimer = setTimeout(function () {
      reconnectTimer = null;
      connect(currentPath);
      reconnectDelay = Math.min(reconnectDelay * 2, MAX_DELAY);
      setupSocketHandlers();
    }, reconnectDelay);
  }

  // --- Client-Side Navigation ---
  function navigate(url, livePath) {
    if (!livePath) {
      livePath = liveRoutes[url];
    }
    
    if (livePath) {
      // Update browser URL without reloading
      navigating = true;
      history.pushState({url: url, livePath: livePath}, "", url);
      connect(livePath);
      setupSocketHandlers();
      navigating = false;
    } else {
      // Fallback if route not known
      window.location.href = url;
    }
  }

  window.addEventListener("popstate", function(event) {
    if (event.state && event.state.livePath) {
      connect(event.state.livePath);
      setupSocketHandlers();
    }
  });

  // --- Reconstruct HTML from statics + dynamics ---
  function buildHtml(statics, dynamics) {
    var html = "";
    for (var i = 0; i < statics.length; i++) {
      html += statics[i];
      if (i < dynamics.length) {
        html += dynamics[i];
      }
    }
    return html;
  }

  // --- Apply update to DOM ---
  // Uses morphdom if available, falls back to innerHTML
  function applyUpdate(container, newHtml) {
    if (typeof morphdom === "function") {
      // Create a temporary wrapper to parse the new HTML
      var wrapper = document.createElement("div");
      wrapper.innerHTML = newHtml;

      // The server sends the full component (e.g. <div id="counter">)
      // We need to morph the existing component, which is the FIRST child of the container
      var fromNode = container.firstElementChild;
      var toNode = wrapper.firstElementChild;

      if (fromNode && toNode) {
        morphdom(fromNode, toNode, {
          // Preserve input elements safely
          onBeforeElUpdated: function (fromEl, toEl) {
            // Skip file inputs — browsers don't allow setting their value
            if (fromEl.type === "file") {
              return false;
            }
            // Keep the user's current typed value in all inputs (even if they tabbed away)
            if (fromEl.tagName === "INPUT") {
              toEl.value = fromEl.value;
            }
            return true;
          },
        });
      } else {
        // First render, just set it
        container.innerHTML = newHtml;
      }
    } else {
      // Fallback: replace entire content
      container.innerHTML = newHtml;
    }

    // JS Hooks Lifecycle
    cleanupHooks(container);
    mountHooks(container);
    updateHooks(container);
  }

  // --- JS Hooks Management ---

  function sendEvent(event, params) {
    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify({ event: event, params: params || {} }));
    }
  }

  function createHookInstance(hookDef, el) {
    var instance = Object.create(hookDef);
    instance.el = el;
    instance.pushEvent = function (event, params) {
      sendEvent(event, params);
    };
    return instance;
  }

  function mountHooks(container) {
    container.querySelectorAll("[ignite-hook]").forEach(function (el) {
      var hookName = el.getAttribute("ignite-hook");
      var id = el.id;

      if (!id) {
        console.warn("[Ignite] Element with ignite-hook must have an id", el);
        return;
      }

      var hookDef = window.IgniteHooks && window.IgniteHooks[hookName];
      if (hookDef && !mountedHooks[id]) {
        var instance = createHookInstance(hookDef, el);
        mountedHooks[id] = instance;
        if (instance.mounted) instance.mounted();
      }
    });
  }

  function updateHooks(container) {
    container.querySelectorAll("[ignite-hook]").forEach(function (el) {
      var id = el.id;
      var instance = mountedHooks[id];
      if (instance) {
        instance.el = el; // Refresh the element reference after morphdom update
        if (instance.updated) instance.updated();
      }
    });
  }

  function cleanupHooks(container) {
    // If an ID is in our mountedHooks but NO LONGER in the DOM, destroy it
    Object.keys(mountedHooks).forEach(function (id) {
      if (!document.getElementById(id)) {
        var instance = mountedHooks[id];
        if (instance.destroyed) instance.destroyed();
        delete mountedHooks[id];
      }
    });
  }

  function destroyAllHooks() {
    Object.keys(mountedHooks).forEach(function (id) {
      var instance = mountedHooks[id];
      if (instance.destroyed) instance.destroyed();
      delete mountedHooks[id];
    });
  }

  // --- Upload System ---
  // Tracks pending file uploads: ref → { file, uploadName }
  var pendingUploads = {};

  // Initialize a file input with [ignite-upload] to handle file selection
  function initUploadInput(input) {
    if (input._igniteUploadInit) return;
    input._igniteUploadInit = true;

    var uploadName = input.getAttribute("ignite-upload");
    if (!uploadName) return;

    input.addEventListener("change", function () {
      var files = Array.from(input.files);
      if (files.length === 0) return;

      // Clear previous pending uploads for this upload name
      for (var ref in pendingUploads) {
        if (pendingUploads[ref].uploadName === uploadName) {
          delete pendingUploads[ref];
        }
      }

      var entries = [];
      for (var i = 0; i < files.length; i++) {
        var ref = uploadName + "-" + i + "-" + Date.now();
        pendingUploads[ref] = { file: files[i], uploadName: uploadName };
        entries.push({
          ref: ref,
          name: files[i].name,
          type: files[i].type,
          size: files[i].size,
        });
      }

      // Send validation event to server
      sendEvent("__upload_validate__", {
        name: uploadName,
        entries: entries,
      });
    });
  }

  // Chunk a file and send binary frames over WebSocket
  function startChunkedUpload(ref, chunkSize) {
    var pending = pendingUploads[ref];
    if (!pending) return;

    var file = pending.file;
    var offset = 0;

    function sendNextChunk() {
      if (offset >= file.size) {
        // All chunks sent — signal completion
        sendEvent("__upload_complete__", {
          name: pending.uploadName,
          ref: ref,
        });
        delete pendingUploads[ref];
        return;
      }

      var end = Math.min(offset + chunkSize, file.size);
      var slice = file.slice(offset, end);
      var reader = new FileReader();

      reader.onload = function () {
        var chunkData = new Uint8Array(reader.result);
        var refBytes = new TextEncoder().encode(ref);
        var refLen = refBytes.length;

        // Build binary frame: [2 bytes refLen][refLen bytes ref][chunk data]
        var frame = new Uint8Array(2 + refLen + chunkData.length);
        frame[0] = (refLen >> 8) & 0xff;
        frame[1] = refLen & 0xff;
        frame.set(refBytes, 2);
        frame.set(chunkData, 2 + refLen);

        if (socket && socket.readyState === WebSocket.OPEN) {
          socket.send(frame.buffer);
        }

        offset = end;
        // Small delay to avoid flooding the WebSocket
        setTimeout(sendNextChunk, 10);
      };

      reader.readAsArrayBuffer(slice);
    }

    sendNextChunk();
  }

  // Scan for upload inputs after DOM updates and initialize them
  function initUploadInputs(container) {
    var inputs = container.querySelectorAll("[ignite-upload]");
    for (var i = 0; i < inputs.length; i++) {
      initUploadInput(inputs[i]);
    }
  }

  // --- Drag and Drop Upload ---
  document.addEventListener("dragover", function (e) {
    var target = e.target;
    while (target && target !== document) {
      if (target.getAttribute && target.getAttribute("ignite-drop-target")) {
        e.preventDefault();
        e.stopPropagation();
        target.style.outline = "2px dashed #3498db";
        target.style.outlineOffset = "-2px";
        return;
      }
      target = target.parentElement;
    }
  });

  document.addEventListener("dragleave", function (e) {
    var target = e.target;
    while (target && target !== document) {
      if (target.getAttribute && target.getAttribute("ignite-drop-target")) {
        target.style.outline = "";
        target.style.outlineOffset = "";
        return;
      }
      target = target.parentElement;
    }
  });

  document.addEventListener("drop", function (e) {
    var target = e.target;
    while (target && target !== document) {
      var uploadName = target.getAttribute
        ? target.getAttribute("ignite-drop-target")
        : null;
      if (uploadName) {
        e.preventDefault();
        e.stopPropagation();
        target.style.outline = "";
        target.style.outlineOffset = "";

        var files = Array.from(e.dataTransfer.files);
        if (files.length === 0) return;

        // Clear previous pending uploads for this upload name
        for (var ref in pendingUploads) {
          if (pendingUploads[ref].uploadName === uploadName) {
            delete pendingUploads[ref];
          }
        }

        var entries = [];
        for (var i = 0; i < files.length; i++) {
          var ref = uploadName + "-" + i + "-" + Date.now();
          pendingUploads[ref] = { file: files[i], uploadName: uploadName };
          entries.push({
            ref: ref,
            name: files[i].name,
            type: files[i].type,
            size: files[i].size,
          });
        }

        sendEvent("__upload_validate__", {
          name: uploadName,
          entries: entries,
        });
        return;
      }
      target = target.parentElement;
    }
  });

  // --- Streams Management ---

  function applyStreamOps(streams) {
    for (var streamName in streams) {
      var ops = streams[streamName];
      var container = document.querySelector('[ignite-stream="' + streamName + '"]');

      if (!container) {
        console.warn("[Ignite] Stream container not found for: " + streamName);
        continue;
      }

      // 1. Reset
      if (ops.reset) {
        while (container.firstChild) {
          container.removeChild(container.firstChild);
        }
      }

      // 2. Deletes
      if (ops.deletes) {
        for (var i = 0; i < ops.deletes.length; i++) {
          var el = document.getElementById(ops.deletes[i]);
          if (el) el.parentNode.removeChild(el);
        }
      }

      // 3. Inserts
      if (ops.inserts) {
        for (var j = 0; j < ops.inserts.length; j++) {
          var entry = ops.inserts[j];
          var temp = document.createElement("div");
          temp.innerHTML = entry.html.trim();
          var newEl = temp.firstElementChild;

          if (entry.at === 0) {
            container.insertBefore(newEl, container.firstChild);
          } else {
            container.appendChild(newEl);
          }
        }
      }
    }
  }

  // --- Receive updates from server ---
  function setupSocketHandlers() {
    socket.onmessage = function (event) {
      var data = JSON.parse(event.data);
      if (!appContainer) return;

      // Server instructed a client-side redirect
      if (data.redirect && data.redirect.url) {
        navigate(data.redirect.url);
        return;
      }

      // First message includes statics — save them
      if (data.s) {
        statics = data.s;
      }

      // Reconstruct HTML and patch the DOM
      if (statics && data.d) {
        if (Array.isArray(data.d)) {
          // Full dynamics replacement
          dynamics = data.d;
        } else {
          // Sparse dynamics update (data.d is an object like {"0": "new_val"})
          for (var key in data.d) {
            dynamics[parseInt(key, 10)] = data.d[key];
          }
        }

        var newHtml = buildHtml(statics, dynamics);
        applyUpdate(appContainer, newHtml);
      }

      // Handle stream operations (surgical DOM updates)
      if (data.streams) {
        applyStreamOps(data.streams);
      }

      // Initialize upload inputs (after DOM is updated so inputs exist)
      initUploadInputs(appContainer);

      // Handle upload config response (after validation)
      if (data.upload) {
        var uploadConfig = data.upload;
        var validEntries = uploadConfig.entries.filter(function (e) {
          return e.valid;
        });

        if (uploadConfig.auto_upload && validEntries.length > 0) {
          validEntries.forEach(function (entry) {
            startChunkedUpload(entry.ref, uploadConfig.chunk_size);
          });
        }
      }
    };

    socket.onopen = function () {
      reconnectDelay = 200;
      setStatus("Connected", "connected");
      console.log("[Ignite] LiveView connected to " + socket.url);
    };

    socket.onclose = function () {
      if (navigating) return;
      setStatus("Disconnected — reconnecting...", "disconnected");
      scheduleReconnect();
      console.log("[Ignite] WebSocket connection closed");
    };

    socket.onerror = function (error) {
      console.error("[Ignite] WebSocket error:", error);
    };
  }

  // --- Event Namespacing ---
  // If an element is inside an <div ignite-component="id">, we prefix the event name
  // so the server knows which component to route it to.
  function resolveEvent(eventName, target) {
    var el = target;
    while (el && el !== document) {
      var componentId = el.getAttribute("ignite-component");
      if (componentId) {
        return componentId + ":" + eventName;
      }
      el = el.parentElement;
    }
    return eventName;
  }

  // --- Send events and handle navigation ---
  if (appContainer) {
    // Click events (scoped to container)
    appContainer.addEventListener("click", function (e) {
      var navTarget = e.target.closest("[ignite-navigate]");
      if (navTarget) {
        e.preventDefault();
        navigate(navTarget.getAttribute("ignite-navigate"));
        return;
      }

      var target = e.target.closest("[ignite-click]");
      if (target) {
        e.preventDefault();
        var params = {};
        var value = target.getAttribute("ignite-value");
        if (value) params.value = value;
        sendEvent(resolveEvent(target.getAttribute("ignite-click"), target), params);
      }
    });

    // Input change events (scoped to container)
    appContainer.addEventListener("change", function (e) {
      var target = e.target.closest("[ignite-change]");
      if (target) {
        var name = e.target.getAttribute("name") || "value";
        var params = {};
        params[name] = e.target.value;
        sendEvent(resolveEvent(target.getAttribute("ignite-change"), e.target), params);
      }
    });

    // Form submit events (scoped to container)
    appContainer.addEventListener("submit", function (e) {
      var form = e.target.closest("[ignite-submit]");
      if (form) {
        e.preventDefault();
        var params = {};
        var formData = new FormData(form);
        formData.forEach(function (value, key) {
          if (!(value instanceof File)) params[key] = value;
        });
        sendEvent(resolveEvent(form.getAttribute("ignite-submit"), form), params);
      }
    });

    // Keydown events (scoped to container)
    appContainer.addEventListener("keydown", function (e) {
      var target = e.target.closest("[ignite-keydown]");
      if (target) {
        var event = resolveEvent(target.getAttribute("ignite-keydown"), e.target);
        var name = e.target.getAttribute("name") || "value";
        var params = { key: e.key };
        params[name] = e.target.value;
        sendEvent(event, params);
      }
    });
  }

  // --- Initial Boot ---
  // Start the connection for the current page
  var initialLivePath = appContainer ? appContainer.getAttribute("data-live-path") : "/live";
  
  // Replace the current history state to include the livePath so back button works later
  history.replaceState({url: window.location.pathname, livePath: initialLivePath}, "", window.location.pathname);
  
  connect(initialLivePath);
  setupSocketHandlers();
})();

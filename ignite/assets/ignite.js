/**
 * Ignite.js — Frontend glue for Ignite LiveView.
 */

(function () {
  "use strict";

  // --- Configuration ---
  var APP_CONTAINER_ID = "ignite-app";

  var statics = null;
  var socket = null;
  var liveRoutes = {};

  // Step 20: Hook instances currently mounted in the DOM
  var mountedHooks = {};

  var appContainer = document.getElementById(APP_CONTAINER_ID);
  if (!appContainer) return;

  try {
    var routesJson = appContainer.dataset.liveRoutes;
    if (routesJson) liveRoutes = JSON.parse(routesJson);
  } catch (e) {}

  function sendEvent(event, params) {
    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify({ event: event, params: params }));
    }
  }

  // --- Step 20: JS Hooks System ---
  function getHookDefinitions() {
    return window.IgniteHooks || {};
  }

  function createHookInstance(hookDef, el) {
    var instance = Object.create(hookDef);
    instance.el = el;
    instance.pushEvent = function (event, params) {
      // Hooks use resolveEvent for component namespacing if needed
      sendEvent(resolveEvent(event, el), params || {});
    };
    return instance;
  }

  function mountHooks(container) {
    var hookDefs = getHookDefinitions();
    var elements = container.querySelectorAll("[ignite-hook]");

    for (var i = 0; i < elements.length; i++) {
      var el = elements[i];
      var hookName = el.getAttribute("ignite-hook");
      var elId = el.id;

      if (!elId || !hookName) continue;
      if (mountedHooks[elId]) continue;

      var def = hookDefs[hookName];
      if (!def) {
        console.warn("[Ignite] Hook '" + hookName + "' not found");
        continue;
      }

      var instance = createHookInstance(def, el);
      mountedHooks[elId] = { name: hookName, instance: instance };
      if (typeof instance.mounted === "function") instance.mounted();
    }
  }

  function updateHooks(container) {
    var elements = container.querySelectorAll("[ignite-hook]");
    for (var i = 0; i < elements.length; i++) {
      var el = elements[i];
      var elId = el.id;
      if (!elId) continue;

      var entry = mountedHooks[elId];
      if (entry) {
        entry.instance.el = el;
        if (typeof entry.instance.updated === "function") entry.instance.updated();
      }
    }
  }

  function cleanupHooks(container) {
    var currentIds = {};
    var elements = container.querySelectorAll("[ignite-hook]");
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].id) currentIds[elements[i].id] = true;
    }

    var toRemove = [];
    for (var id in mountedHooks) {
      if (!currentIds[id]) toRemove.push(id);
    }

    for (var j = 0; j < toRemove.length; j++) {
      var entry = mountedHooks[toRemove[j]];
      if (entry && typeof entry.instance.destroyed === "function") entry.instance.destroyed();
      delete mountedHooks[toRemove[j]];
    }
  }

  function destroyAllHooks() {
    for (var id in mountedHooks) {
      var entry = mountedHooks[id];
      if (entry && typeof entry.instance.destroyed === "function") entry.instance.destroyed();
    }
    mountedHooks = {};
  }

  function resolveEvent(eventName, target) {
    var el = target;
    while (el && el !== document) {
      var componentId = el.getAttribute("ignite-component");
      if (componentId) return componentId + ":" + eventName;
      el = el.parentElement;
    }
    return eventName;
  }

  function buildHtml(statics, dynamics) {
    var html = "";
    for (var i = 0; i < statics.length; i++) {
      html += statics[i];
      if (i < dynamics.length) html += dynamics[i];
    }
    return html;
  }

  function applyUpdate(container, newHtml) {
    if (typeof morphdom === "function") {
      var wrapper = document.createElement("div");
      wrapper.id = APP_CONTAINER_ID;
      if (container.dataset.livePath) wrapper.dataset.livePath = container.dataset.livePath;
      if (container.dataset.liveRoutes) wrapper.dataset.liveRoutes = container.dataset.liveRoutes;
      wrapper.innerHTML = newHtml;

      morphdom(container, wrapper, {
        onBeforeElUpdated: function (fromEl, toEl) {
          if (fromEl.type === "file") return false;
          if (fromEl === document.activeElement) {
            if (fromEl.tagName === "INPUT" || fromEl.tagName === "TEXTAREA") toEl.value = fromEl.value;
          }
          return true;
        },
      });
    } else {
      container.innerHTML = newHtml;
    }

    // Step 20: Run hook lifecycle
    cleanupHooks(container);
    mountHooks(container);
    updateHooks(container);
  }

  function connect(livePath) {
    if (socket) {
      socket.onclose = null;
      socket.close();
    }
    // Step 20: Destroy hooks on navigation
    destroyAllHooks();
    statics = null;

    var container = document.getElementById(APP_CONTAINER_ID);
    if (container) {
      container.innerHTML = "Connecting...";
      container.dataset.livePath = livePath;
    }

    var protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    socket = new WebSocket(protocol + "//" + window.location.host + livePath);

    socket.onmessage = function (event) {
      var data = JSON.parse(event.data);
      var el = document.getElementById(APP_CONTAINER_ID);
      if (!el) return;

      if (data.redirect) {
        navigate(data.redirect.url, data.redirect.live_path);
        return;
      }
      if (data.s) statics = data.s;
      if (statics && data.d) {
        var newHtml = buildHtml(statics, data.d);
        applyUpdate(el, newHtml);
      }
    };

    socket.onopen = function () {
      console.log("[Ignite] LiveView connected to " + livePath);
    };
    socket.onclose = function () {
      console.log("[Ignite] LiveView disconnected");
    };
  }

  function navigate(url, livePath) {
    if (!livePath && liveRoutes[url]) livePath = liveRoutes[url];
    if (!livePath) {
      window.location.href = url;
      return;
    }
    history.pushState({ url: url, livePath: livePath }, "", url);
    connect(livePath);
  }

  window.addEventListener("popstate", function (e) {
    if (e.state && e.state.livePath) connect(e.state.livePath);
    else window.location.reload();
  });

  var initialLivePath = (appContainer && appContainer.dataset.livePath) || "/live";
  history.replaceState({ url: window.location.pathname, livePath: initialLivePath }, "", window.location.pathname);

  document.addEventListener("click", function (e) {
    var target = e.target;
    while (target && target !== document) {
      var navPath = target.getAttribute("ignite-navigate");
      if (navPath) {
        e.preventDefault();
        navigate(navPath);
        return;
      }

      var eventName = target.getAttribute("ignite-click");
      if (eventName) {
        e.preventDefault();
        var params = {};
        var value = target.getAttribute("ignite-value");
        if (value) params.value = value;
        sendEvent(resolveEvent(eventName, target), params);
        return;
      }
      target = target.parentElement;
    }
  });

  document.addEventListener("input", function (e) {
    var target = e.target;
    var el = target;
    while (el && el !== document) {
      var eventName = el.getAttribute("ignite-change");
      if (eventName) {
        var params = { field: target.getAttribute("name") || "", value: target.value };
        sendEvent(resolveEvent(eventName, target), params);
        return;
      }
      el = el.parentElement;
    }
  });

  document.addEventListener("submit", function (e) {
    var form = e.target;
    var eventName = form.getAttribute("ignite-submit");
    if (eventName) {
      e.preventDefault();
      var params = {};
      var formData = new FormData(form);
      formData.forEach(function (value, key) {
        if (!(value instanceof File)) params[key] = value;
      });
      sendEvent(resolveEvent(eventName, form), params);
    }
  });

  connect(initialLivePath);
})();

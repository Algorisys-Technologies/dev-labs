(function () {
  "use strict";

  var APP_CONTAINER_ID = "ignite-root";
  var currentRendered = null;
  var socket = null;
  var liveRoutes = {};

  var appContainer = document.getElementById(APP_CONTAINER_ID);
  if (!appContainer) return;

  try {
    var routesJson = appContainer.dataset.liveRoutes;
    if (routesJson) liveRoutes = JSON.parse(routesJson);
  } catch (e) {
    console.error("[Ignite] Failed to parse live-routes", e);
  }

  function sendWS(topic, payload) {
    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify({ topic: topic, payload: payload }));
    }
  }

  window.sendEvent = function(event, params) {
    sendWS("lv:event", { event: event, params: params });
  };

  function patch(current, diff) {
    if (diff.s) return diff;
    
    for (var key in diff) {
      if (typeof diff[key] === "object" && current[key] && typeof current[key] === "object" && !diff[key].s) {
        current[key] = patch(current[key], diff[key]);
      } else {
        current[key] = diff[key];
      }
    }
    return current;
  }

  function render(rendered) {
    if (typeof rendered !== "object") return String(rendered);
    
    var html = "";
    var statics = rendered.s;
    for (var i = 0; i < statics.length; i++) {
      html += statics[i];
      if (rendered[i] !== undefined) {
        html += render(rendered[i]);
      }
    }
    return html;
  }

  function applyDiff(root, diff) {
    currentRendered = patch(currentRendered, diff);
    applyUpdate(root, render(currentRendered));
  }

  function applyStreamOps(data) {
    if (!data.streams) return;

    for (var streamName in data.streams) {
      var ops = data.streams[streamName];
      var container = document.querySelector('[ignite-stream="' + streamName + '"]');
      if (!container) continue;

      if (ops.reset) {
        while (container.firstChild) container.removeChild(container.firstChild);
      }

      if (ops.deletes) {
        for (var i = 0; i < ops.deletes.length; i++) {
          var el = document.getElementById(ops.deletes[i]);
          if (el) el.parentNode.removeChild(el);
        }
      }

      if (ops.inserts) {
        for (var j = 0; j < ops.inserts.length; j++) {
          var entry = ops.inserts[j];
          var temp = document.createElement("div");
          temp.innerHTML = entry.html.trim();
          var newEl = temp.firstChild;

          var existing = document.getElementById(entry.id);
          if (existing) {
            morphdom(existing, newEl);
          } else if (entry.at === 0) {
            container.insertBefore(newEl, container.firstChild);
          } else {
            container.appendChild(newEl);
          }
        }
      }
    }
  }

  function applyUpdate(container, newHtml) {
    if (typeof morphdom === "function") {
      var wrapper = document.createElement("div");
      wrapper.id = APP_CONTAINER_ID;
      wrapper.innerHTML = newHtml;

      morphdom(container, wrapper, {
        childrenOnly: true,
        onBeforeElUpdated: function (fromEl, toEl) {
          if (fromEl.hasAttribute("ignite-stream")) return false;
          if (fromEl.type === "file") return false;
          if (fromEl === document.activeElement) {
            if (fromEl.tagName === "INPUT" || fromEl.tagName === "TEXTAREA") {
              toEl.value = fromEl.value;
            }
          }
          return true;
        },
      });
    } else {
      container.innerHTML = newHtml;
    }
  }

  function connect() {
    var root = document.getElementById(APP_CONTAINER_ID);
    if (!root) return;

    var liveModule = root.dataset.module;
    var renderedScript = document.getElementById("ignite-rendered");
    if (renderedScript) {
      try {
        currentRendered = JSON.parse(renderedScript.textContent);
      } catch (e) {
        console.error("[Ignite] Failed to parse rendered state", e);
      }
    }

    if (socket) {
      socket.onclose = null;
      socket.close();
    }

    var protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    var wsUrl = protocol + "//" + window.location.host + "/live";
    
    socket = new WebSocket(wsUrl);

    socket.onopen = function() {
      console.log("[Ignite] Connected to WebSocket");
      sendWS("lv:join", { module: liveModule });
    };

    socket.onmessage = function(event) {
      var msg = JSON.parse(event.data);
      if (msg.topic === "lv:update") {
        applyDiff(root, msg.payload.diff);
        applyStreamOps(msg.payload);
        
        if (msg.payload.upload) {
          var config = msg.payload.upload;
          var input = document.querySelector('[ignite-upload="' + config.name + '"]');
          if (input && config.auto_upload) {
            uploadEntries(input, config);
          }
        }
        setupUploads();
      } else if (msg.topic === "lv:redirect") {
        navigate(msg.payload.url);
      }
    };

    socket.onclose = function() {
      setTimeout(connect, 5000);
    };

    setupUploads();
  }

  function navigate(url) {
    history.pushState({ url: url }, "", url);
    fetch(url)
      .then(response => response.text())
      .then(html => {
        var parser = new DOMParser();
        var doc = parser.parseFromString(html, "text/html");
        var newRoot = doc.getElementById(APP_CONTAINER_ID);
        var currentRoot = document.getElementById(APP_CONTAINER_ID);
        if (newRoot && currentRoot) {
          currentRoot.dataset.module = newRoot.dataset.module;
          
          // Update the script tag content for the new page
          var newScript = doc.getElementById("ignite-rendered");
          var currentScript = document.getElementById("ignite-rendered");
          if (newScript && currentScript) {
            currentScript.textContent = newScript.textContent;
          }
          
          connect();
        } else {
          window.location.href = url;
        }
      })
      .catch(() => window.location.href = url);
  }

  window.addEventListener("popstate", function (e) {
    window.location.reload();
  });

  function resolveEvent(eventName, target) {
    var el = target;
    while (el && el !== document) {
      var componentId = el.getAttribute("ignite-component");
      if (componentId) return componentId + ":" + eventName;
      el = el.parentElement;
    }
    return eventName;
  }

  function handleUploadValidate(input) {
    if (!input.files || input.files.length === 0) return;

    var name = input.getAttribute("ignite-upload");
    var entries = [];
    for (var i = 0; i < input.files.length; i++) {
      var file = input.files[i];
      // Assign a ref to each file if not present
      if (!file._ignite_ref) file._ignite_ref = String(Date.now() + i);
      
      entries.push({
        ref: file._ignite_ref,
        name: file.name,
        type: file.type || "application/octet-stream",
        size: file.size
      });
    }

    sendWS("lv:event", {
      event: "__upload_validate__",
      params: { name: name, entries: entries }
    });
  }

  function uploadEntries(input, config) {
    if (!input.files) return;

    for (var i = 0; i < input.files.length; i++) {
      var file = input.files[i];
      var entryConfig = config.entries.find(e => e.ref === file._ignite_ref);
      
      if (entryConfig && entryConfig.valid && !file._ignite_uploading) {
        uploadFile(file, config);
      }
    }
  }

  function uploadFile(file, config) {
    file._ignite_uploading = true;
    var ref = file._ignite_ref;
    var chunkSize = config.chunk_size || 64000;
    var offset = 0;

    function sendNextChunk() {
      var slice = file.slice(offset, offset + chunkSize);
      var reader = new FileReader();

      reader.onload = function(e) {
        var chunk = e.target.result;
        
        // Build binary frame: [2 bytes: ref_len][ref bytes: ref][chunk data]
        var refBytes = new TextEncoder().encode(ref);
        var header = new Uint8Array(2);
        header[0] = (refBytes.length >> 8) & 0xFF;
        header[1] = refBytes.length & 0xFF;
        
        var frame = new Uint8Array(header.length + refBytes.length + chunk.byteLength);
        frame.set(header, 0);
        frame.set(refBytes, 2);
        frame.set(new Uint8Array(chunk), 2 + refBytes.length);

        if (socket && socket.readyState === WebSocket.OPEN) {
          socket.send(frame.buffer);
          offset += chunkSize;

          if (offset < file.size) {
            setTimeout(sendNextChunk, 10);
          } else {
            sendWS("lv:event", {
              event: "__upload_complete__",
              params: { name: config.name, ref: ref }
            });
          }
        }
      };

      reader.readAsArrayBuffer(slice);
    }

    sendNextChunk();
  }

  function setupUploads() {
    document.querySelectorAll("[ignite-upload]").forEach(input => {
      if (input._ignite_setup) return;
      input._ignite_setup = true;

      input.addEventListener("change", function() {
        handleUploadValidate(input);
      });
    });

    document.querySelectorAll("[ignite-drop-target]").forEach(target => {
      if (target._ignite_setup) return;
      target._ignite_setup = true;

      target.addEventListener("dragover", e => {
        e.preventDefault();
        target.classList.add("ignite-dragover");
      });

      target.addEventListener("dragleave", e => {
        target.classList.remove("ignite-dragover");
      });

      target.addEventListener("drop", e => {
        e.preventDefault();
        target.classList.remove("ignite-dragover");
        var name = target.getAttribute("ignite-drop-target");
        var input = document.querySelector('[ignite-upload="' + name + '"]');
        if (input) {
          input.files = e.dataTransfer.files;
          handleUploadValidate(input);
        }
      });
    });
  }

  document.addEventListener("submit", function (e) {
    var target = e.target.closest("[ignite-submit]");
    if (!target) return;

    e.preventDefault();
    var event = target.getAttribute("ignite-submit");
    var formData = new FormData(target);
    var params = {};
    formData.forEach((value, key) => {
      params[key] = value;
    });
    sendWS("lv:event", { event: resolveEvent(event, target), params: params });
  });

  document.addEventListener("click", function (e) {
    var target = e.target.closest("[ignite-click], [ignite-navigate]");
    if (!target) return;

    var navPath = target.getAttribute("ignite-navigate");
    if (navPath) {
      e.preventDefault();
      navigate(navPath);
      return;
    }

    var event = target.getAttribute("ignite-click");
    if (event) {
      if (target.tagName === "BUTTON" && target.type === "submit") return; // Handled by submit listener

      var params = {};
      for (var i = 0; i < target.attributes.length; i++) {
        var attr = target.attributes[i];
        if (attr.name.startsWith("data-")) {
          params[attr.name.slice(5)] = attr.value;
        }
      }
      sendWS("lv:event", { event: resolveEvent(event, target), params: params });
    }
  });

  window.Ignite = { applyUpdate: applyUpdate };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", connect);
  } else {
    connect();
  }
})();

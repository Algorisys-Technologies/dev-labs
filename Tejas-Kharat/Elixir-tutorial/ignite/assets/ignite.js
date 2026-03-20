/**
 * Ignite.js — Frontend glue for Ignite LiveView.
 */

(function () {
    "use strict";

    // --- Configuration ---
    var APP_CONTAINER_ID = "ignite-app";

    // State
    var statics = null;
    var dynamics = null;
    var socket = null;
    var liveRoutes = {};

    // Hook Registry State
    var mountedHooks = {};

    // Upload State
    var uploads = {}; // name -> LiveUpload instance

    // --- Initialize ---
    var appContainer = document.getElementById(APP_CONTAINER_ID);
    if (!appContainer) return;

    try {
        var routesJson = appContainer.dataset.liveRoutes;
        if (routesJson) {
            liveRoutes = JSON.parse(routesJson);
        }
    } catch (e) { }

    // --- Helper: send event over WebSocket ---
    function sendEvent(event, params) {
        if (socket && socket.readyState === WebSocket.OPEN) {
            socket.send(JSON.stringify({ event: event, params: params }));
        }
    }

    // --- Hook Support ---

    function getHookDefinitions() {
        return window.IgniteHooks || {};
    }

    function createHookInstance(hookDef, el) {
        var instance = Object.create(hookDef);
        instance.el = el;
        instance.pushEvent = function (event, params) {
            // Hook events are not auto-namespaced like component events
            sendEvent(event, params || {});
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
                console.warn("[Ignite] Hook '" + hookName + "' not found in IgniteHooks");
                continue;
            }

            var instance = createHookInstance(def, el);
            mountedHooks[elId] = { name: hookName, instance: instance };

            if (typeof instance.mounted === "function") {
                instance.mounted();
            }
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
                if (typeof entry.instance.updated === "function") {
                    entry.instance.updated();
                }
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
            if (!currentIds[id]) {
                toRemove.push(id);
            }
        }

        for (var j = 0; j < toRemove.length; j++) {
            var id = toRemove[j];
            var entry = mountedHooks[id];
            if (entry && typeof entry.instance.destroyed === "function") {
                entry.instance.destroyed();
            }
            delete mountedHooks[id];
        }
    }

    function destroyAllHooks() {
        for (var id in mountedHooks) {
            var entry = mountedHooks[id];
            if (entry && typeof entry.instance.destroyed === "function") {
                entry.instance.destroyed();
            }
        }
        mountedHooks = {};
    }

    // --- HTML Build & Patch ---

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

    function applyUpdate(container, newHtml) {
        if (typeof morphdom === "function") {
            var wrapper = document.createElement("div");
            wrapper.id = APP_CONTAINER_ID;
            if (container.dataset.livePath) wrapper.dataset.livePath = container.dataset.livePath;
            if (container.dataset.liveRoutes) wrapper.dataset.liveRoutes = container.dataset.liveRoutes;
            wrapper.innerHTML = newHtml;

            morphdom(container, wrapper, {
                onBeforeElUpdated: function (fromEl, toEl) {
                    // Skip stream containers — their children are managed by applyStreamOps
                    if (fromEl.hasAttribute("ignite-stream")) {
                        return false;
                    }
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

        // Lifecycle integration
        cleanupHooks(container);
        mountHooks(container);
        updateHooks(container);

        container.querySelectorAll("input[ignite-upload]").forEach(function (el) {
            addUpload(el);
        });

        container.querySelectorAll("[ignite-drop-target]").forEach(function (el) {
            addDropTarget(el);
        });
    }

    // --- WebSocket & Navigation ---

    function connect(livePath) {
        if (socket) {
            socket.onclose = null;
            socket.close();
        }

        // Cleanup previous view hooks
        destroyAllHooks();
        statics = null;
        dynamics = null;

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

            if (data.upload) {
                var upload = uploads[data.upload.name];
                if (upload) {
                    upload.onConfig(data.upload);
                }
            }

            if (data.s) statics = data.s;

            if (data.d) {
                if (Array.isArray(data.d)) {
                    dynamics = data.d; // Full replacement
                } else {
                    for (var key in data.d) { // Sparse patch
                        dynamics[parseInt(key, 10)] = data.d[key];
                    }
                }
            }

            if (statics && dynamics) {
                applyUpdate(el, buildHtml(statics, dynamics));
            }

            if (data.streams) {
                applyStreamOps(data);
            }
        };

        socket.onclose = function () {
            console.log("[Ignite] Connection closed");
        };
    }

    function addUpload(el) {
        var name = el.getAttribute("ignite-upload");
        if (uploads[name]) return;
        uploads[name] = new LiveUpload(el);
    }

    function addDropTarget(el) {
        var name = el.getAttribute("ignite-drop-target");

        el.addEventListener("dragover", function (e) {
            e.preventDefault();
            el.classList.add("ignite-drag-over");
        });

        el.addEventListener("dragleave", function (e) {
            e.preventDefault();
            el.classList.remove("ignite-drag-over");
        });

        el.addEventListener("drop", function (e) {
            e.preventDefault();
            el.classList.remove("ignite-drag-over");

            var upload = uploads[name];
            if (upload) {
                upload.handleFiles(e.dataTransfer.files);
            }
        });
    }

    function LiveUpload(el) {
        this.el = el;
        this.name = el.getAttribute("ignite-upload");
        this.entries = {}; // ref -> { file, offset, chunkSize }

        var self = this;
        el.addEventListener("change", function (e) {
            self.handleFiles(e.target.files);
        });
    }

    LiveUpload.prototype.handleFiles = function (files) {
        var entries = [];
        for (var i = 0; i < files.length; i++) {
            var file = files[i];
            var ref = String(Math.random()).slice(2, 10);
            this.entries[ref] = { file: file, offset: 0 };
            entries.push({
                ref: ref,
                name: file.name,
                type: file.type,
                size: file.size,
            });
        }

        sendEvent("__upload_validate__", { name: this.name, entries: entries });
    };

    LiveUpload.prototype.onConfig = function (config) {
        var self = this;
        config.entries.forEach(function (entryConfig) {
            var entry = self.entries[entryConfig.ref];
            if (entry && entryConfig.valid) {
                entry.chunkSize = config.chunk_size;
                if (config.auto_upload) {
                    self.sendNextChunk(entryConfig.ref);
                }
            }
        });
    };

    LiveUpload.prototype.sendNextChunk = function (ref) {
        var entry = this.entries[ref];
        if (!entry) return;

        var self = this;
        var reader = new FileReader();
        var blob = entry.file.slice(
            entry.offset,
            entry.offset + entry.chunkSize
        );

        reader.onload = function (e) {
            var chunk = e.target.result;

            // Build binary frame: [2 bytes: ref_len][ref bytes: ref][chunk data]
            var refBytes = new TextEncoder().encode(ref);
            var header = new Uint8Array(2);
            header[0] = (refBytes.length >> 8) & 0xff;
            header[1] = refBytes.length & 0xff;

            var frame = new Uint8Array(
                header.length + refBytes.length + chunk.byteLength
            );
            frame.set(header, 0);
            frame.set(refBytes, 2);
            frame.set(new Uint8Array(chunk), 2 + refBytes.length);

            socket.send(frame.buffer);

            entry.offset += chunk.byteLength;

            if (entry.offset < entry.file.size) {
                // Throttle slightly to avoid flooding
                setTimeout(function () { self.sendNextChunk(ref); }, 10);
            } else {
                // Done!
                sendEvent("__upload_complete__", { name: self.name, ref: ref });
            }
        };

        reader.readAsArrayBuffer(blob);
    };

    function applyStreamOps(data) {
        if (!data.streams) return;

        for (var streamName in data.streams) {
            var ops = data.streams[streamName];
            var container = document.querySelector(
                '[ignite-stream="' + streamName + '"]'
            );
            if (!container) continue;

            // Reset: remove all children
            if (ops.reset) {
                while (container.firstChild) {
                    container.removeChild(container.firstChild);
                }
            }

            // Deletes: remove elements by DOM ID
            if (ops.deletes) {
                for (var i = 0; i < ops.deletes.length; i++) {
                    var el = document.getElementById(ops.deletes[i]);
                    if (el) el.parentNode.removeChild(el);
                }
            }

            // Inserts: add new elements (or upsert existing ones)
            if (ops.inserts) {
                for (var j = 0; j < ops.inserts.length; j++) {
                    var entry = ops.inserts[j];
                    var temp = document.createElement("div");
                    temp.innerHTML = entry.html.trim();
                    var newEl = temp.firstChild;

                    // Upsert: if element with this ID already exists, update it in-place
                    var existing = document.getElementById(entry.id);
                    if (existing) {
                        morphdom(existing, newEl);
                    } else if (entry.at === 0) {
                        container.insertBefore(newEl, container.firstChild); // Prepend
                    } else {
                        container.appendChild(newEl); // Append
                    }
                }
            }
        }
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

    // --- Component Utils ---

    function resolveEvent(eventName, target) {
        var el = target;
        while (el && el !== document) {
            var componentId = el.getAttribute("ignite-component");
            if (componentId) return componentId + ":" + eventName;
            el = el.parentElement;
        }
        return eventName;
    }

    // --- Handlers & Listeners ---

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
// Cache bust test

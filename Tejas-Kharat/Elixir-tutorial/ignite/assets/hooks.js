/**
 * IgniteHooks — Registry for client-side lifecycle callbacks.
 */

window.IgniteHooks = window.IgniteHooks || {};

// --- CopyToClipboard Hook ---
window.IgniteHooks.CopyToClipboard = {
    mounted: function () {
        var self = this;
        var btn = this.el.querySelector("#copy-btn");
        if (!btn) return;

        this._handler = function () {
            var text = self.el.getAttribute("data-text");
            if (!text) return;

            navigator.clipboard
                .writeText(text)
                .then(function () {
                    console.log("[Hook] Copied to clipboard:", text);
                    self.pushEvent("clipboard_result", { success: "true" });
                })
                .catch(function (err) {
                    console.error("[Hook] Copy failed:", err);
                    self.pushEvent("clipboard_result", { success: "false" });
                });
        };

        btn.addEventListener("click", this._handler);
        console.log("[Hook] CopyToClipboard mounted on #" + this.el.id);
    },
    destroyed: function () {
        // Event listeners are automatically cleaned up when the element is removed from DOM,
        // but explicit cleanup is good practice.
        console.log("[Hook] CopyToClipboard destroyed from #" + this.el.id);
    },
};

// --- LocalTime Hook ---
window.IgniteHooks.LocalTime = {
    mounted: function () {
        var self = this;
        var display = this.el.querySelector("#local-time-display");
        if (!display) return;

        // Update time every second on the client
        this._interval = setInterval(function () {
            display.textContent = new Date().toLocaleTimeString();
        }, 1000);

        // Initial value
        display.textContent = new Date().toLocaleTimeString();

        var btn = this.el.querySelector("#send-time-btn");
        if (btn) {
            btn.addEventListener("click", function () {
                self.pushEvent("local_time", { time: new Date().toLocaleTimeString() });
            });
        }

        console.log("[Hook] LocalTime mounted on #" + this.el.id);
    },
    updated: function () {
        console.log("[Hook] LocalTime updated on #" + this.el.id);
    },
    destroyed: function () {
        console.log("[Hook] LocalTime destroyed from #" + this.el.id);
        clearInterval(this._interval);
    },
};

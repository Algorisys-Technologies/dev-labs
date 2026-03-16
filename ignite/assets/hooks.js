/**
 * Custom JS Hooks for Ignite.
 */

window.IgniteHooks = window.IgniteHooks || {};

window.IgniteHooks.CopyToClipboard = {
  mounted: function () {
    var self = this;
    var btn = this.el.querySelector("#copy-btn");
    if (!btn) return;

    this._handler = function () {
      var text = self.el.getAttribute("data-text");
      navigator.clipboard
        .writeText(text)
        .then(function () {
          self.pushEvent("clipboard_result", { success: "true" });
        })
        .catch(function () {
          self.pushEvent("clipboard_result", { success: "false" });
        });
    };

    btn.addEventListener("click", this._handler);
    console.log("[Hook] CopyToClipboard mounted");
  },
  destroyed: function () {
    console.log("[Hook] CopyToClipboard destroyed");
  },
};

window.IgniteHooks.LocalTime = {
  mounted: function () {
    var self = this;
    var display = this.el.querySelector("#local-time-display");
    if (!display) return;

    this._interval = setInterval(function () {
      display.textContent = new Date().toLocaleTimeString();
    }, 1000);

    var btn = this.el.querySelector("#send-time-btn");
    if (btn) {
      btn.addEventListener("click", function () {
        self.pushEvent("local_time", { time: new Date().toLocaleTimeString() });
      });
    }
    console.log("[Hook] LocalTime mounted");
  },
  destroyed: function () {
    clearInterval(this._interval);
    console.log("[Hook] LocalTime destroyed");
  },
};

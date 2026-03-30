/**
 * Ignite JS Hooks — Example hooks for the hooks demo page.
 *
 * Register hooks by assigning to window.IgniteHooks before ignite.js loads.
 */

window.IgniteHooks = window.IgniteHooks || {};

/**
 * CopyToClipboard — copies text from data-text attribute on button click.
 * Pushes a "clipboard_result" event back to the server.
 */
window.IgniteHooks.CopyToClipboard = {
  mounted: function () {
    var self = this;
    var btn = this.el.querySelector("#copy-btn");
    if (!btn) return;

    this._handler = function () {
      var text = self.el.getAttribute("data-text") || "";
      if (navigator.clipboard) {
        navigator.clipboard
          .writeText(text)
          .then(function () {
            btn.textContent = "Copied!";
            setTimeout(function () {
              btn.textContent = "Copy";
            }, 2000);
            self.pushEvent("clipboard_result", { success: "true" });
          })
          .catch(function () {
            btn.textContent = "Failed";
            setTimeout(function () {
              btn.textContent = "Copy";
            }, 2000);
            self.pushEvent("clipboard_result", { success: "false" });
          });
      } else {
        self.pushEvent("clipboard_result", { success: "false" });
      }
    };

    btn.addEventListener("click", this._handler);
    console.log("[Hook] CopyToClipboard mounted on #" + this.el.id);
  },

  updated: function () {
    console.log("[Hook] CopyToClipboard updated on #" + this.el.id);
  },

  destroyed: function () {
    console.log("[Hook] CopyToClipboard destroyed on #" + this.el.id);
  },
};

/**
 * LocalTime — displays the client's local time and can push it to the server.
 * Demonstrates using setInterval in mounted() and cleaning up in destroyed().
 */
window.IgniteHooks.LocalTime = {
  mounted: function () {
    var self = this;
    var display = this.el.querySelector("#local-time-display");
    var btn = this.el.querySelector("#send-time-btn");

    // Update time display every second
    this._interval = setInterval(function () {
      if (display) {
        display.textContent = new Date().toLocaleTimeString();
      }
    }, 1000);

    // Immediately show the time
    if (display) {
      display.textContent = new Date().toLocaleTimeString();
    }

    // Button pushes current time to server
    if (btn) {
      this._btnHandler = function () {
        self.pushEvent("local_time", {
          time: new Date().toLocaleTimeString(),
        });
      };
      btn.addEventListener("click", this._btnHandler);
    }

    console.log("[Hook] LocalTime mounted on #" + this.el.id);
  },

  updated: function () {
    // Re-attach display reference after morphdom update
    var display = this.el.querySelector("#local-time-display");
    if (display) {
      display.textContent = new Date().toLocaleTimeString();
    }
    console.log("[Hook] LocalTime updated on #" + this.el.id);
  },

  destroyed: function () {
    // Clean up the interval to prevent memory leaks
    if (this._interval) {
      clearInterval(this._interval);
    }
    console.log("[Hook] LocalTime destroyed on #" + this.el.id);
  },
};

window.IgniteHooks = window.IgniteHooks || {};

window.IgniteHooks.CopyToClipboard = {
  mounted: function() {
    var self = this;
    var btn = this.el.querySelector("#copy-btn");

    this._handler = function() {
      var text = self.el.getAttribute("data-text");
      navigator.clipboard.writeText(text)
        .then(function() {
          self.pushEvent("clipboard_result", { success: "true" });
        })
        .catch(function() {
          self.pushEvent("clipboard_result", { success: "false" });
        });
    };

    btn.addEventListener("click", this._handler);
  },
  destroyed: function() {
    // Cleanup handled by DOM removal
  }
};

window.IgniteHooks.LocalTime = {
  mounted: function() {
    var self = this;
    var display = this.el.querySelector("#local-time-display");

    // Update every second — this runs purely on the client
    this._interval = setInterval(function() {
      display.textContent = new Date().toLocaleTimeString();
    }, 1000);

    // Button sends client time to server
    var btn = this.el.querySelector("#send-time-btn");
    btn.addEventListener("click", function() {
      self.pushEvent("local_time", { time: new Date().toLocaleTimeString() });
    });
  },
  destroyed: function() {
    // CRITICAL: clean up interval to prevent memory leaks
    clearInterval(this._interval);
  }
};

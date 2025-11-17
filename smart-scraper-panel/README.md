# SmartScraper Panel - Chrome Extension (iframe-based)

How it works:
- Click the extension icon (toolbar) to toggle a docked iframe in the current tab.
- The iframe loads `panel.html` (the extension UI) and communicates with `content.js` via `postMessage`.
- Click **Pick Element** inside the panel: the content script highlights elements on the page; click one to select.
- The selected CSS selector is sent back to the panel and populated in the input.
- Click **Scrape** to run simple heuristics and return JSON data for matching elements.
- Click **Export CSV** to download scraped data.

Install:
1. Unzip this package.
2. Open Chrome -> chrome://extensions -> Enable Developer mode -> Load unpacked -> choose the extracted folder.

Notes:
- If using local `file://` pages, enable "Allow access to file URLs" for this extension on chrome://extensions.
- The panel uses `web_accessible_resources` so it can be loaded inside page iframes.


Chatgpt reference
https://chatgpt.com/share/691a9be5-f708-8013-93e1-a19501dfadce
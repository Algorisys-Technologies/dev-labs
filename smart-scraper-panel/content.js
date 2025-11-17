/*
 content.js
 - listens for togglePanel from background
 - injects/removes iframe that loads extension's panel.html
 - mediates postMessage between iframe and page (picker & scraper)
*/

let panelIframe = null;
let pickMode = false;
let hoverBox = null;

function createPanel() {
  if (document.getElementById('smartScraperPanel')) return document.getElementById('smartScraperPanel');
  const iframe = document.createElement('iframe');
  iframe.id = 'smartScraperPanel';
  iframe.src = chrome.runtime.getURL('panel.html');
  Object.assign(iframe.style, {
    position: 'fixed',
    right: '0px',
    bottom: '0px',
    width: '420px',
    height: '45%',
    border: '1px solid #ddd',
    zIndex: 2147483647,
    boxShadow: '0 -2px 12px rgba(0,0,0,0.25)',
    background: '#fff'
  });
  document.documentElement.appendChild(iframe);
  panelIframe = iframe;
  return iframe;
}

function removePanel() {
  const el = document.getElementById('smartScraperPanel');
  if (el) el.remove();
  panelIframe = null;
  stopPick();
}

// handle messages from background (toggle)
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.action === 'togglePanel') {
    const exists = !!document.getElementById('smartScraperPanel');
    if (exists) removePanel();
    else createPanel();
  }
});

// receive messages from iframe via window.postMessage
window.addEventListener('message', (event) => {
  // Only accept messages from our iframe
  // event.source will equal panelIframe.contentWindow if from iframe
  if (!panelIframe) return;
  if (event.source !== panelIframe.contentWindow) return;
  const msg = event.data || {};
  if (msg.type === 'startPick') {
    startPick();
  } else if (msg.type === 'stopPick') {
    stopPick();
  } else if (msg.type === 'scrapeSelector') {
    const selector = msg.selector;
    const results = runScrape(selector);
    // send results back to iframe
    panelIframe.contentWindow.postMessage({ type: 'scrapeResult', results }, '*');
  } else if (msg.type === 'closePanel') {
    removePanel();
  }
});

// Picker logic
function startPick() {
  if (pickMode) return;
  pickMode = true;
  hoverBox = document.createElement('div');
  Object.assign(hoverBox.style, {
    position: 'fixed',
    pointerEvents: 'none',
    border: '3px solid #ff9800',
    zIndex: 2147483646,
    background: 'rgba(255,152,0,0.05)'
  });
  document.documentElement.appendChild(hoverBox);
  document.addEventListener('mousemove', onMouseMove, true);
  document.addEventListener('click', onClickPick, true);
  document.addEventListener('keydown', onKeyDown, true);
}

function stopPick() {
  pickMode = false;
  if (hoverBox) hoverBox.remove();
  hoverBox = null;
  document.removeEventListener('mousemove', onMouseMove, true);
  document.removeEventListener('click', onClickPick, true);
  document.removeEventListener('keydown', onKeyDown, true);
}

function onMouseMove(e) {
  if (!pickMode) return;
  const el = document.elementFromPoint(e.clientX, e.clientY);
  if (!el) return;
  const rect = el.getBoundingClientRect();
  Object.assign(hoverBox.style, {
    top: rect.top + 'px',
    left: rect.left + 'px',
    width: rect.width + 'px',
    height: rect.height + 'px'
  });
}

function onClickPick(e) {
  if (!pickMode) return;
  e.preventDefault(); e.stopPropagation();
  const el = document.elementFromPoint(e.clientX, e.clientY);
  if (!el) { stopPick(); return; }
  const selector = getCssPath(el);
  stopPick();
  // send selector back to iframe
  if (panelIframe && panelIframe.contentWindow) {
    panelIframe.contentWindow.postMessage({ type: 'selectorPicked', selector }, '*');
  } else {
    // fallback: store in chrome.storage
    chrome.storage.local.set({ lastPicked: selector });
  }
}

function onKeyDown(e) {
  if (e.key === 'Escape') stopPick();
}

// helper to compute readable selector
function getCssPath(el) {
  // alert(typeof el)
  if (!(el instanceof Element)) return '';
  const path = [];
  // alert(el.nodeType)
  while (el && el.nodeType === Node.ELEMENT_NODE) {
    let selector = el.nodeName.toLowerCase();
    if (el.id) {
      selector += `#${el.id}`;
      path.unshift(selector);
      break;
    } 
    else if (el.tagName.includes('-'))
    {
      selector = el.tagName; // `[is="${el.getAttribute('is')}"]`;
      path.unshift(selector);
      break;
    }
    else {
      let sib = el, nth = 1;
      while (sib = sib.previousElementSibling) nth++;
      selector += `:nth-of-type(${nth})`;
    }
    path.unshift(selector);
    el = el.parentElement;
  }
  return path.join(' > ');
}

// basic scraping logic to extract title/price/image/link heuristics
function runScrape(selector) {
  try {
    // alert('Scraping selector:', selector);
    const nodes = Array.from(document.querySelectorAll(selector || 'body'));
    // alert('Found nodes:', nodes);
    const results = nodes.map(node => {
      // alert('Scraping node:', node);
      const attrs = {}; for (let a of Array.from(node.attributes || [])) attrs[a.name]=a.value;
      const text = node.innerText ? node.innerText.trim() : '';
      const html = node.innerHTML ? node.innerHTML.trim() : '';
      const title = (node.querySelector && (node.querySelector('h1,h2,h3,.title,.product-title,[itemprop="name"]')?.innerText || node.querySelector('b,strong')?.innerText)) || (text.split('\n').map(s=>s.trim()).filter(Boolean)[0]||'');
      const price = (node.querySelector && (node.querySelector('.price,[itemprop="price"],.amount')?.innerText)) || (text.match(/(₹|Rs\.?|USD|US\$|\$|EUR|€|GBP|£)\s?\d[\d,\.\s]*/i)?.[0]||'');
      const image = (node.querySelector && (node.querySelector('img')?.src)) || '';
      const link = (node.querySelector && (node.querySelector('a[href]')?.href)) || '';
      return { title, price, image, link, text, html, attributes: attrs };
    });
    // alert('Scrape results:', results);
    return results;
  } catch (err) {
    return { error: String(err) };
  }
}


chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
    if (msg.action === "get_page_title") {
        sendResponse({ page_title: document.title });
    }
});
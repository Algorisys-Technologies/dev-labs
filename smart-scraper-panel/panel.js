/*
 panel.js - runs inside the iframe (panel.html)
 - sends postMessage to parent to request pick or scrape
 - receives selectorPicked and scrapeResult messages from parent
*/
const pickBtn = document.getElementById('pickBtn');
const stopPickBtn = document.getElementById('stopPickBtn');
const selectorInput = document.getElementById('selectorInput');
const scrapeBtn = document.getElementById('scrapeBtn');
const exportBtn = document.getElementById('exportBtn');
const preview = document.getElementById('preview');
const closeBtn = document.getElementById('closeBtn');

pickBtn.addEventListener('click', () => {
  window.parent.postMessage({ type: 'startPick' }, '*');
  pickBtn.disabled = true; stopPickBtn.disabled = false;
});

stopPickBtn.addEventListener('click', () => {
  window.parent.postMessage({ type: 'stopPick' }, '*');
  pickBtn.disabled = false; stopPickBtn.disabled = true;
});

closeBtn.addEventListener('click', () => {
  window.parent.postMessage({ type: 'closePanel' }, '*');
  try { window.close(); } catch(e) {}
});

// receive messages from parent (content script)
window.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.type === 'selectorPicked') {
    selectorInput.value = msg.selector;
    pickBtn.disabled = false; stopPickBtn.disabled = true;
  } else if (msg.type === 'scrapeResult') {
    const results = msg.results || [];
    preview.textContent = JSON.stringify(results, null, 2);
  }
});

scrapeBtn.addEventListener('click', () => {
  const selector = selectorInput.value.trim();
  if (!selector) return alert('Enter selector first');
  window.parent.postMessage({ type: 'scrapeSelector', selector }, '*');
});

exportBtn.addEventListener('click', () => {
  const text = preview.textContent;
  if (!text || text === '(no data)') return alert('No data to export');
  try {
    const data = JSON.parse(text);
    const csv = toCSV(data);
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'scrape.csv'; a.click();
    URL.revokeObjectURL(url);
  } catch (e) { alert('Invalid data'); }
});

function toCSV(arr) {
  if (!Array.isArray(arr) || arr.length===0) return '';
  const headers = Object.keys(arr[0]);
  const rows = arr.map(r => headers.map(h => JSON.stringify(r[h]||'')).join(','));
  return headers.join(',') + '\n' + rows.join('\n');
}

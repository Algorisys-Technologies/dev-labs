// /*
//  panel.js - runs inside the iframe (panel.html)
//  - sends postMessage to parent to request pick or scrape
//  - receives selectorPicked and scrapeResult messages from parent
// */
// const pickBtn = document.getElementById('pickBtn');
// const stopPickBtn = document.getElementById('stopPickBtn');
// const selectorInput = document.getElementById('selectorInput');
// const scrapeBtn = document.getElementById('scrapeBtn');
// const exportBtn = document.getElementById('exportBtn');
// const preview = document.getElementById('preview');
// const closeBtn = document.getElementById('closeBtn');

// pickBtn.addEventListener('click', () => {
//   window.parent.postMessage({ type: 'startPick' }, '*');
//   pickBtn.disabled = true; stopPickBtn.disabled = false;
// });

// stopPickBtn.addEventListener('click', () => {
//   window.parent.postMessage({ type: 'stopPick' }, '*');
//   pickBtn.disabled = false; stopPickBtn.disabled = true;
// });

// closeBtn.addEventListener('click', () => {
//   window.parent.postMessage({ type: 'closePanel' }, '*');
//   try { window.close(); } catch(e) {}
// });

// // receive messages from parent (content script)
// window.addEventListener('message', (event) => {
//   const msg = event.data || {};
//   if (msg.type === 'selectorPicked') {
//     selectorInput.value = msg.selector;
//     pickBtn.disabled = false; stopPickBtn.disabled = true;
//   } else if (msg.type === 'scrapeResult') {
//     const results = msg.results || [];
//     preview.textContent = JSON.stringify(results, null, 2);
//   }
// });

// scrapeBtn.addEventListener('click', () => {
//   const selector = selectorInput.value.trim();
//   if (!selector) return alert('Enter selector first');
//   window.parent.postMessage({ type: 'scrapeSelector', selector }, '*');
// });

// exportBtn.addEventListener('click', () => {
//   const text = preview.textContent;
//   if (!text || text === '(no data)') return alert('No data to export');
//   try {
//     const data = JSON.parse(text);
//     const csv = toCSV(data);
//     const blob = new Blob([csv], { type: 'text/csv' });
//     const url = URL.createObjectURL(blob);
//     const a = document.createElement('a'); a.href = url; a.download = 'scrape.csv'; a.click();
//     URL.revokeObjectURL(url);
//   } catch (e) { alert('Invalid data'); }
// });

// function toCSV(arr) {
//   if (!Array.isArray(arr) || arr.length===0) return '';
//   const headers = Object.keys(arr[0]);
//   const rows = arr.map(r => headers.map(h => JSON.stringify(r[h]||'')).join(','));
//   return headers.join(',') + '\n' + rows.join('\n');
// }



// /*
//  panel.js - runs inside the iframe (panel.html)
//  - sends postMessage to parent to request pick or scrape
//  - receives selectorPicked and scrapeResult messages from parent
// */
// const pickBtn = document.getElementById('pickBtn');
// const stopPickBtn = document.getElementById('stopPickBtn');
// const selectorInput = document.getElementById('selectorInput');
// const scrapeBtn = document.getElementById('scrapeBtn');
// const exportBtn = document.getElementById('exportBtn');
// const saveToDbBtn = document.getElementById('saveToDbBtn');
// const preview = document.getElementById('preview');
// const closeBtn = document.getElementById('closeBtn');
// const statusMessage = document.getElementById('statusMessage');

// let currentScrapedData = [];

// pickBtn.addEventListener('click', () => {
//   window.parent.postMessage({ type: 'startPick' }, '*');
//   pickBtn.disabled = true; 
//   stopPickBtn.disabled = false;
// });

// stopPickBtn.addEventListener('click', () => {
//   window.parent.postMessage({ type: 'stopPick' }, '*');
//   pickBtn.disabled = false; 
//   stopPickBtn.disabled = true;
// });

// closeBtn.addEventListener('click', () => {
//   window.parent.postMessage({ type: 'closePanel' }, '*');
//   try { window.close(); } catch(e) {}
// });

// // receive messages from parent (content script)
// window.addEventListener('message', (event) => {
//   const msg = event.data || {};
//   if (msg.type === 'selectorPicked') {
//     selectorInput.value = msg.selector;
//     pickBtn.disabled = false; 
//     stopPickBtn.disabled = true;
//   } else if (msg.type === 'scrapeResult') {
//     currentScrapedData = msg.results || [];
//     preview.textContent = JSON.stringify(currentScrapedData, null, 2);
//     showStatus(`Scraped ${currentScrapedData.length} items`, 'success');
//   }
// });

// scrapeBtn.addEventListener('click', () => {
//   const selector = selectorInput.value.trim();
//   if (!selector) return alert('Enter selector first');
//   window.parent.postMessage({ type: 'scrapeSelector', selector }, '*');
// });

// exportBtn.addEventListener('click', () => {
//   if (!currentScrapedData || currentScrapedData.length === 0) {
//     return alert('No data to export');
//   }
//   try {
//     const csv = toCSV(currentScrapedData);
//     const blob = new Blob([csv], { type: 'text/csv' });
//     const url = URL.createObjectURL(blob);
//     const a = document.createElement('a'); 
//     a.href = url; 
//     a.download = 'scrape.csv'; 
//     a.click();
//     URL.revokeObjectURL(url);
//     showStatus('CSV exported successfully', 'success');
//   } catch (e) { 
//     showStatus('Error exporting CSV: ' + e.message, 'error');
//   }
// });

// saveToDbBtn.addEventListener('click', async () => {
//   if (!currentScrapedData || currentScrapedData.length === 0) {
//     return alert('No data to save');
//   }
  
//   try {
//     showStatus('Saving to database...', 'info');
    
//     const pageTitle = document.title || 'Scraped Page';
//     const dataToSave = {
//       page_title: pageTitle,
//       products: currentScrapedData
//     };
    
//     const response = await fetch('http://localhost:5000/api/scrape/save', {
//       method: 'POST',
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: JSON.stringify(dataToSave)
//     });
    
//     if (!response.ok) {
//       throw new Error(`HTTP error! status: ${response.status}`);
//     }
    
//     const result = await response.json();
//     showStatus(`Successfully saved ${result.total_processed} products to database`, 'success');
    
//   } catch (error) {
//     console.error('Error saving to database:', error);
//     showStatus('Error saving to database: ' + error.message, 'error');
//   }
// });

// function toCSV(arr) {
//   if (!Array.isArray(arr) || arr.length === 0) return '';
  
//   // Get all unique keys from all objects
//   const headers = [...new Set(arr.flatMap(obj => Object.keys(obj)))];
  
//   const rows = arr.map(obj => {
//     return headers.map(header => {
//       const value = obj[header];
//       if (value === null || value === undefined) return '';
//       // Handle nested objects and arrays
//       if (typeof value === 'object') {
//         return JSON.stringify(value);
//       }
//       return `"${String(value).replace(/"/g, '""')}"`;
//     }).join(',');
//   });
  
//   return headers.join(',') + '\n' + rows.join('\n');
// }

// function showStatus(message, type = 'info') {
//   statusMessage.textContent = message;
//   statusMessage.className = `status-message ${type}`;
//   setTimeout(() => {
//     statusMessage.textContent = '';
//     statusMessage.className = 'status-message';
//   }, 5000);
// }



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
const saveToDbBtn = document.getElementById('saveToDbBtn');
const preview = document.getElementById('preview');
const closeBtn = document.getElementById('closeBtn');
const statusMessage = document.getElementById('statusMessage');
const statistics = document.getElementById('statistics');
const totalProducts = document.getElementById('totalProducts');
const savedProducts = document.getElementById('savedProducts');
const downloadedImages = document.getElementById('downloadedImages');
const previewCount = document.getElementById('previewCount');
const progressContainer = document.getElementById('progressContainer');
const progressFill = document.getElementById('progressFill');
const progressPercent = document.getElementById('progressPercent');
const progressDetails = document.getElementById('progressDetails');

let currentScrapedData = [];
let isSaving = false;

// Initialize
updateStatistics();

pickBtn.addEventListener('click', () => {
  window.parent.postMessage({ type: 'startPick' }, '*');
  pickBtn.disabled = true; 
  stopPickBtn.disabled = false;
  showStatus('Click on any element on the page to select it', 'info');
});

stopPickBtn.addEventListener('click', () => {
  window.parent.postMessage({ type: 'stopPick' }, '*');
  pickBtn.disabled = false; 
  stopPickBtn.disabled = true;
  showStatus('Element picking stopped', 'info');
});

closeBtn.addEventListener('click', () => {
  window.parent.postMessage({ type: 'closePanel' }, '*');
  try { window.close(); } catch(e) {}
});

// Receive messages from parent (content script)
window.addEventListener('message', (event) => {
  const msg = event.data || {};
  
  if (msg.type === 'selectorPicked') {
    selectorInput.value = msg.selector;
    pickBtn.disabled = false; 
    stopPickBtn.disabled = true;
    showStatus(`Selected: ${msg.selector}`, 'success');
    
  } else if (msg.type === 'scrapeResult') {
    currentScrapedData = msg.results || [];
    preview.textContent = JSON.stringify(currentScrapedData, null, 2);
    updateStatistics();
    showStatus(`✅ Successfully scraped ${currentScrapedData.length} items`, 'success');
  }
});

scrapeBtn.addEventListener('click', () => {
  const selector = selectorInput.value.trim();
  if (!selector) {
    showStatus('Please enter a CSS selector first', 'warning');
    return;
  }
  
  showStatus('Scraping in progress...', 'info');
  window.parent.postMessage({ type: 'scrapeSelector', selector }, '*');
});

exportBtn.addEventListener('click', () => {
  if (!currentScrapedData || currentScrapedData.length === 0) {
    showStatus('No data to export. Please scrape some data first.', 'warning');
    return;
  }
  
  try {
    const csv = toCSV(currentScrapedData);
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); 
    a.href = url; 
    a.download = `scraped_data_${new Date().toISOString().slice(0, 10)}.csv`; 
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showStatus('📊 CSV file downloaded successfully!', 'success');
  } catch (e) { 
    showStatus('❌ Error exporting CSV: ' + e.message, 'error');
  }
});

saveToDbBtn.addEventListener('click', async () => {
  if (!currentScrapedData || currentScrapedData.length === 0) {
    showStatus('No data to save. Please scrape some data first.', 'warning');
    return;
  }
  
  if (isSaving) {
    showStatus('Save operation already in progress...', 'info');
    return;
  }
  
  try {
    isSaving = true;
    saveToDbBtn.disabled = true;
    
    showProgress(0, 'Preparing to save...');
    
    const pageTitle = document.title || 'Scraped Page';
    const dataToSave = {
      page_title: pageTitle,
      products: currentScrapedData
    };
    
    showProgress(10, 'Sending data to server...');
    
    const response = await fetch('http://localhost:5000/api/scrape/save', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(dataToSave)
    });
    
    showProgress(30, 'Processing data...');
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Server error: ${response.status} - ${errorText}`);
    }
    
    showProgress(70, 'Saving to database...');
    
    const result = await response.json();
    
    showProgress(100, 'Complete!');
    
    // Update statistics with the response data
    updateStatistics(result);
    
    // Show success message with details
    const successMessage = `
      ✅ Successfully saved ${result.total_processed} products to database!
      📸 ${result.images_downloaded} images downloaded
      💾 Session ID: ${result.session_id}
    `.trim();
    
    showStatus(successMessage, 'success');
    
    // Auto-hide progress after success
    setTimeout(() => {
      hideProgress();
    }, 3000);
    
  } catch (error) {
    console.error('Error saving to database:', error);
    hideProgress();
    showStatus(`❌ Error saving to database: ${error.message}`, 'error');
  } finally {
    isSaving = false;
    saveToDbBtn.disabled = false;
  }
});

function toCSV(arr) {
  if (!Array.isArray(arr) || arr.length === 0) return '';
  
  // Get all unique keys from all objects
  const headers = [...new Set(arr.flatMap(obj => Object.keys(obj)))];
  
  const rows = arr.map(obj => {
    return headers.map(header => {
      const value = obj[header];
      if (value === null || value === undefined) return '';
      // Handle nested objects and arrays
      if (typeof value === 'object') {
        return JSON.stringify(value);
      }
      return `"${String(value).replace(/"/g, '""')}"`;
    }).join(',');
  });
  
  return headers.join(',') + '\n' + rows.join('\n');
}

function showStatus(message, type = 'info') {
  statusMessage.textContent = message;
  statusMessage.className = `status-message ${type}`;
  statusMessage.classList.remove('hidden');
  
  // Auto-hide info messages after 5 seconds, keep success/error visible
  if (type === 'info') {
    setTimeout(() => {
      statusMessage.classList.add('hidden');
    }, 5000);
  }
}

function hideStatus() {
  statusMessage.classList.add('hidden');
}

function showProgress(percent, details = '') {
  progressContainer.classList.remove('hidden');
  progressFill.style.width = `${percent}%`;
  progressPercent.textContent = `${percent}%`;
  progressDetails.textContent = details;
}

function hideProgress() {
  progressContainer.classList.add('hidden');
  progressFill.style.width = '0%';
  progressPercent.textContent = '0%';
  progressDetails.textContent = '';
}

function updateStatistics(result = null) {
  const total = currentScrapedData.length;
  
  totalProducts.textContent = total;
  previewCount.textContent = `${total} item${total !== 1 ? 's' : ''}`;
  
  if (result) {
    savedProducts.textContent = result.total_processed || 0;
    downloadedImages.textContent = result.images_downloaded || 0;
  } else {
    savedProducts.textContent = '0';
    downloadedImages.textContent = '0';
  }
  
  // Show/hide statistics based on whether we have data
  if (total > 0) {
    statistics.classList.remove('hidden');
  } else {
    statistics.classList.add('hidden');
  }
  
  // Show/hide action buttons based on data availability
  exportBtn.disabled = total === 0;
  saveToDbBtn.disabled = total === 0;
}

// Keyboard shortcuts
document.addEventListener('keydown', (e) => {
  if (e.ctrlKey || e.metaKey) {
    switch(e.key) {
      case 's':
        e.preventDefault();
        if (!saveToDbBtn.disabled) saveToDbBtn.click();
        break;
      case 'e':
        e.preventDefault();
        if (!exportBtn.disabled) exportBtn.click();
        break;
      case 'p':
        e.preventDefault();
        pickBtn.click();
        break;
    }
  }
});

// Initialize tooltips for buttons
function initTooltips() {
  const buttons = document.querySelectorAll('button');
  buttons.forEach(btn => {
    const title = btn.getAttribute('title');
    if (title) {
      btn.addEventListener('mouseenter', (e) => {
        // You could add a custom tooltip implementation here
      });
    }
  });
}

// Add titles for better UX
pickBtn.title = 'Pick elements from the page (Ctrl+P)';
scrapeBtn.title = 'Scrape data using the selector';
exportBtn.title = 'Export as CSV file (Ctrl+E)';
saveToDbBtn.title = 'Save to database (Ctrl+S)';
closeBtn.title = 'Close panel';

// Initialize
initTooltips();
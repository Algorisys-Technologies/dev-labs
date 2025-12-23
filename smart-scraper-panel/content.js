// /*
//  content.js
//  - listens for togglePanel from background
//  - injects/removes iframe that loads extension's panel.html
//  - mediates postMessage between iframe and page (picker & scraper)
// */

// let panelIframe = null;
// let pickMode = false;
// let hoverBox = null;

// function createPanel() {
//   if (document.getElementById('smartScraperPanel')) return document.getElementById('smartScraperPanel');
//   const iframe = document.createElement('iframe');
//   iframe.id = 'smartScraperPanel';
//   iframe.src = chrome.runtime.getURL('panel.html');
//   Object.assign(iframe.style, {
//     position: 'fixed',
//     right: '0px',
//     bottom: '0px',
//     width: '420px',
//     height: '45%',
//     border: '1px solid #ddd',
//     zIndex: 2147483647,
//     boxShadow: '0 -2px 12px rgba(0,0,0,0.25)',
//     background: '#fff'
//   });
//   document.documentElement.appendChild(iframe);
//   panelIframe = iframe;
//   return iframe;
// }

// function removePanel() {
//   const el = document.getElementById('smartScraperPanel');
//   if (el) el.remove();
//   panelIframe = null;
//   stopPick();
// }

// // handle messages from background (toggle)
// chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
//   if (msg.action === 'togglePanel') {
//     const exists = !!document.getElementById('smartScraperPanel');
//     if (exists) removePanel();
//     else createPanel();
//   }
// });

// // receive messages from iframe via window.postMessage
// window.addEventListener('message', (event) => {
//   // Only accept messages from our iframe
//   // event.source will equal panelIframe.contentWindow if from iframe
//   if (!panelIframe) return;
//   if (event.source !== panelIframe.contentWindow) return;
//   const msg = event.data || {};
//   if (msg.type === 'startPick') {
//     startPick();
//   } else if (msg.type === 'stopPick') {
//     stopPick();
//   } else if (msg.type === 'scrapeSelector') {
//     const selector = msg.selector;
//     const results = runScrape(selector);
//     // send results back to iframe
//     panelIframe.contentWindow.postMessage({ type: 'scrapeResult', results }, '*');
//   } else if (msg.type === 'closePanel') {
//     removePanel();
//   }
// });

// // Picker logic
// function startPick() {
//   if (pickMode) return;
//   pickMode = true;
//   hoverBox = document.createElement('div');
//   Object.assign(hoverBox.style, {
//     position: 'fixed',
//     pointerEvents: 'none',
//     border: '3px solid #ff9800',
//     zIndex: 2147483646,
//     background: 'rgba(255,152,0,0.05)'
//   });
//   document.documentElement.appendChild(hoverBox);
//   document.addEventListener('mousemove', onMouseMove, true);
//   document.addEventListener('click', onClickPick, true);
//   document.addEventListener('keydown', onKeyDown, true);
// }

// function stopPick() {
//   pickMode = false;
//   if (hoverBox) hoverBox.remove();
//   hoverBox = null;
//   document.removeEventListener('mousemove', onMouseMove, true);
//   document.removeEventListener('click', onClickPick, true);
//   document.removeEventListener('keydown', onKeyDown, true);
// }

// function onMouseMove(e) {
//   if (!pickMode) return;
//   const el = document.elementFromPoint(e.clientX, e.clientY);
//   if (!el) return;
//   const rect = el.getBoundingClientRect();
//   Object.assign(hoverBox.style, {
//     top: rect.top + 'px',
//     left: rect.left + 'px',
//     width: rect.width + 'px',
//     height: rect.height + 'px'
//   });
// }

// function onClickPick(e) {
//   if (!pickMode) return;
//   e.preventDefault(); e.stopPropagation();
//   const el = document.elementFromPoint(e.clientX, e.clientY);
//   if (!el) { stopPick(); return; }
//   const selector = getCssPath(el);
//   stopPick();
//   // send selector back to iframe
//   if (panelIframe && panelIframe.contentWindow) {
//     panelIframe.contentWindow.postMessage({ type: 'selectorPicked', selector }, '*');
//   } else {
//     // fallback: store in chrome.storage
//     chrome.storage.local.set({ lastPicked: selector });
//   }
// }

// function onKeyDown(e) {
//   if (e.key === 'Escape') stopPick();
// }


// function getCssPath(el) {
//   if (!(el instanceof Element)) return '';
//   const path = [];
  
//   while (el && el.nodeType === Node.ELEMENT_NODE) {
//     let selector = el.nodeName.toLowerCase();
    
//     // Handle Shadow DOM elements
//     if (el.getRootNode() && el.getRootNode().host) {
//       const host = el.getRootNode().host;
//       const shadowPath = getCssPath(host);
//       const shadowSelector = generateShadowSelector(el, host);
//       return shadowPath ? `${shadowPath} >>> ${shadowSelector}` : shadowSelector;
//     }
    
//     // ID has highest priority
//     if (el.id) {
//       selector += `#${el.id}`;
//       path.unshift(selector);
//       break;
//     } 
//     // Handle custom web components (like <app-product-grid-item-akron>)
//     else if (el.tagName.includes('-')) {
//       // For custom elements, try to find unique attributes first
//       const uniqueAttr = getUniqueAttribute(el);
//       if (uniqueAttr) {
//         selector += uniqueAttr;
//         path.unshift(selector);
//         break;
//       }
      
//       // Try meaningful classes for custom elements
//       const meaningfulClass = getMeaningfulClass(el);
//       if (meaningfulClass) {
//         selector += meaningfulClass;
//         path.unshift(selector);
//         // Don't break - allow context building for better specificity
//       } else {
//         // Use the custom element tag name
//         path.unshift(selector);
//         // Don't break - continue to build parent context
//       }
//     }
//     // Regular HTML elements
//     else {
//       // Try meaningful classes first
//       const meaningfulClass = getMeaningfulClass(el);
//       if (meaningfulClass) {
//         selector += meaningfulClass;
//         // Check if this selector is unique enough
//         if (isSelectorUnique(selector)) {
//           path.unshift(selector);
//           break;
//         }
//       }
      
//       // Use position as fallback
//       const nth = getElementPosition(el);
//       selector += `:nth-child(${nth})`;
//       path.unshift(selector);
//     }
    
//     // Stop conditions
//     if (el.tagName === 'BODY' || path.length >= 8) {
//       break;
//     }
    
//     el = el.parentElement;
//   }
  
//   const fullSelector = path.join(' > ');
  
//   // Validate the selector works
//   return validateAndSimplifySelector(fullSelector, el);
// }

// // Helper function to generate selector for shadow DOM elements
// function generateShadowSelector(element, host) {
//   const path = [];
//   let current = element;
  
//   while (current && current !== host) {
//     let selector = current.nodeName.toLowerCase();
    
//     if (current.id) {
//       selector += `#${current.id}`;
//       path.unshift(selector);
//       break;
//     } else {
//       const meaningfulClass = getMeaningfulClass(current);
//       if (meaningfulClass) {
//         selector += meaningfulClass;
//         path.unshift(selector);
//         break;
//       } else {
//         const nth = getElementPosition(current);
//         selector += `:nth-child(${nth})`;
//         path.unshift(selector);
//       }
//     }
    
//     current = current.parentElement;
//   }
  
//   return path.join(' > ');
// }

// // Helper function to get element position (more reliable than nth-of-type)
// function getElementPosition(element) {
//   const parent = element.parentElement;
//   if (!parent) return 1;
  
//   const children = Array.from(parent.children)
//     .filter(child => child.nodeType === Node.ELEMENT_NODE);
  
//   return children.indexOf(element) + 1;
// }

// // Helper function to find meaningful class names
// function getMeaningfulClass(element) {
//   if (!element.className || typeof element.className !== 'string') {
//     return null;
//   }
  
//   const classes = element.className.split(' ')
//     .filter(className => {
//       // Filter out generic, short, or framework-specific classes
//       return className.length > 2 &&
//              !className.startsWith('ng-') &&
//              !className.startsWith('js-') &&
//              !className.startsWith('is-') &&
//              !/^[a-z]$/.test(className) &&
//              !className.includes('hover') &&
//              !className.includes('active') &&
//              !className.includes('focus') &&
//              !className.includes('loading');
//     });
  
//   if (classes.length === 0) return null;
  
//   // Prioritize semantic classes that indicate content type
//   const semanticClasses = classes.filter(c => 
//     c.includes('product') || c.includes('item') || c.includes('tile') ||
//     c.includes('card') || c.includes('grid') || c.includes('list') ||
//     c.includes('price') || c.includes('title') || c.includes('image') ||
//     c.includes('button') || c.includes('link') || c.includes('header') ||
//     c.includes('footer') || c.includes('nav') || c.includes('menu') ||
//     c.includes('content') || c.includes('main') || c.includes('side')
//   );
  
//   return semanticClasses.length > 0 ? `.${semanticClasses[0]}` : `.${classes[0]}`;
// }

// // Helper function to find unique attributes
// function getUniqueAttribute(element) {
//   const attrs = element.attributes;
  
//   // Check for unique identifiers
//   for (let i = 0; i < attrs.length; i++) {
//     const attr = attrs[i];
//     if (attr.name === 'data-product-id' || 
//         attr.name === 'data-id' || 
//         attr.name === 'data-sku' ||
//         attr.name === 'data-uid' ||
//         attr.name === 'data-testid' ||
//         attr.name === 'data-cy' ||
//         attr.name === 'data-test-id' ||
//         attr.name === 'data-element' ||
//         attr.name === 'data-selector') {
//       return `[${attr.name}="${attr.value}"]`;
//     }
//   }
  
//   // Check for role or aria attributes
//   for (let i = 0; i < attrs.length; i++) {
//     const attr = attrs[i];
//     if (attr.name === 'role' || attr.name.startsWith('aria-')) {
//       return `[${attr.name}="${attr.value}"]`;
//     }
//   }
  
//   return null;
// }

// // Helper function to check if selector is unique
// function isSelectorUnique(selector) {
//   try {
//     const elements = document.querySelectorAll(selector);
//     return elements.length === 1;
//   } catch (e) {
//     return false;
//   }
// }

// // Helper function to validate and simplify selector
// function validateAndSimplifySelector(selector, originalElement) {
//   try {
//     const elements = document.querySelectorAll(selector);
    
//     // If selector finds exactly the clicked element, it's good
//     if (elements.length === 1 && elements[0] === originalElement) {
//       return selector;
//     }
    
//     // If selector finds multiple elements but includes the original, try to simplify
//     if (elements.length > 1 && Array.from(elements).includes(originalElement)) {
//       // Try to find a shorter unique selector
//       return findShorterSelector(originalElement, selector);
//     }
    
//     // If selector doesn't work, generate a simpler one
//     return generateFallbackSelector(originalElement);
//   } catch (e) {
//     return generateFallbackSelector(originalElement);
//   }
// }

// // Helper function to find shorter selector
// function findShorterSelector(element, originalSelector) {
//   // Try different approaches to shorten the selector
  
//   // 1. Try just the custom element with class
//   if (element.tagName.includes('-')) {
//     const tagName = element.tagName.toLowerCase();
//     const meaningfulClass = getMeaningfulClass(element);
//     if (meaningfulClass) {
//       const shortSelector = tagName + meaningfulClass;
//       if (isSelectorUnique(shortSelector)) {
//         return shortSelector;
//       }
//     }
//   }
  
//   // 2. Try with just the last 2 parts of the path
//   const parts = originalSelector.split(' > ');
//   if (parts.length > 2) {
//     const shortSelector = parts.slice(-2).join(' > ');
//     try {
//       const elements = document.querySelectorAll(shortSelector);
//       if (elements.length === 1 && elements[0] === element) {
//         return shortSelector;
//       }
//     } catch (e) {}
//   }
  
//   return originalSelector;
// }

// // Fallback selector generator
// function generateFallbackSelector(element) {
//   // Simple fallback: use tag name with classes if available
//   let selector = element.tagName.toLowerCase();
  
//   const meaningfulClass = getMeaningfulClass(element);
//   if (meaningfulClass) {
//     selector += meaningfulClass;
//   }
  
//   // If still not unique, add parent context
//   if (!isSelectorUnique(selector) && element.parentElement) {
//     const parent = element.parentElement;
//     const parentClass = getMeaningfulClass(parent);
//     if (parentClass) {
//       const position = getElementPosition(element);
//       selector = `${parent.tagName.toLowerCase()}${parentClass} > ${element.tagName.toLowerCase()}:nth-child(${position})`;
//     }
//   }
  
//   return selector;
// }



// // basic scraping logic to extract title/price/image/link heuristics
// function runScrape(selector) {
//   try {
//     // alert('Scraping selector:', selector);
//     const nodes = Array.from(document.querySelectorAll(selector || 'body'));
//     // alert('Found nodes:', nodes);
//     const results = nodes.map(node => {
//       // alert('Scraping node:', node);
//       const attrs = {}; for (let a of Array.from(node.attributes || [])) attrs[a.name]=a.value;
//       const text = node.innerText ? node.innerText.trim() : '';
//       const html = node.innerHTML ? node.innerHTML.trim() : '';
//       const title = (node.querySelector && (node.querySelector('h1,h2,h3,.title,.product-title,[itemprop="name"]')?.innerText || node.querySelector('b,strong')?.innerText)) || (text.split('\n').map(s=>s.trim()).filter(Boolean)[0]||'');
//       const price = (node.querySelector && (node.querySelector('.price,[itemprop="price"],.amount')?.innerText)) || (text.match(/(₹|Rs\.?|USD|US\$|\$|EUR|€|GBP|£)\s?\d[\d,\.\s]*/i)?.[0]||'');
//       const image = (node.querySelector && (node.querySelector('img')?.src)) || '';
//       // const image = getProductImage(node);

//       const link = (node.querySelector && (node.querySelector('a[href]')?.href)) || '';
//       return { title, price, image, link, text, html, attributes: attrs };
//     });
//     // alert('Scrape results:', results);
//     return results;
//   } catch (err) {
//     return { error: String(err) };
//   }
// }


// chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
//     if (msg.action === "get_page_title") {
//         sendResponse({ page_title: document.title });
//     }
// });



// chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
//     if (msg.action === "get_page_url") {
//         sendResponse({ page_url: window.location.href });
//     }
// });





////////////////////////////////////////////////////////////////////////////////////////////////////////

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


function getCssPath(el) {
  if (!(el instanceof Element)) return '';
  const path = [];
  
  while (el && el.nodeType === Node.ELEMENT_NODE) {
    let selector = el.nodeName.toLowerCase();
    
    // Handle Shadow DOM elements
    if (el.getRootNode() && el.getRootNode().host) {
      const host = el.getRootNode().host;
      const shadowPath = getCssPath(host);
      const shadowSelector = generateShadowSelector(el, host);
      return shadowPath ? `${shadowPath} >>> ${shadowSelector}` : shadowSelector;
    }
    
    // ID has highest priority
    if (el.id) {
      selector += `#${el.id}`;
      path.unshift(selector);
      break;
    } 
    // Handle custom web components (like <app-product-grid-item-akron>)
    else if (el.tagName.includes('-')) {
      // For custom elements, try to find unique attributes first
      const uniqueAttr = getUniqueAttribute(el);
      if (uniqueAttr) {
        selector += uniqueAttr;
        path.unshift(selector);
        break;
      }
      
      // Try meaningful classes for custom elements
      const meaningfulClass = getMeaningfulClass(el);
      if (meaningfulClass) {
        selector += meaningfulClass;
        path.unshift(selector);
        // Don't break - allow context building for better specificity
      } else {
        // Use the custom element tag name
        path.unshift(selector);
        // Don't break - continue to build parent context
      }
    }
    // Regular HTML elements
    else {
      // Try meaningful classes first
      const meaningfulClass = getMeaningfulClass(el);
      if (meaningfulClass) {
        selector += meaningfulClass;
        // Check if this selector is unique enough
        if (isSelectorUnique(selector)) {
          path.unshift(selector);
          break;
        }
      }
      
      // Use position as fallback
      const nth = getElementPosition(el);
      selector += `:nth-child(${nth})`;
      path.unshift(selector);
    }
    
    // Stop conditions
    if (el.tagName === 'BODY' || path.length >= 8) {
      break;
    }
    
    el = el.parentElement;
  }
  
  const fullSelector = path.join(' > ');
  
  // Validate the selector works
  return validateAndSimplifySelector(fullSelector, el);
}

// Helper function to generate selector for shadow DOM elements
function generateShadowSelector(element, host) {
  const path = [];
  let current = element;
  
  while (current && current !== host) {
    let selector = current.nodeName.toLowerCase();
    
    if (current.id) {
      selector += `#${current.id}`;
      path.unshift(selector);
      break;
    } else {
      const meaningfulClass = getMeaningfulClass(current);
      if (meaningfulClass) {
        selector += meaningfulClass;
        path.unshift(selector);
        break;
      } else {
        const nth = getElementPosition(current);
        selector += `:nth-child(${nth})`;
        path.unshift(selector);
      }
    }
    
    current = current.parentElement;
  }
  
  return path.join(' > ');
}

// Helper function to get element position (more reliable than nth-of-type)
function getElementPosition(element) {
  const parent = element.parentElement;
  if (!parent) return 1;
  
  const children = Array.from(parent.children)
    .filter(child => child.nodeType === Node.ELEMENT_NODE);
  
  return children.indexOf(element) + 1;
}

// Helper function to find meaningful class names
function getMeaningfulClass(element) {
  if (!element.className || typeof element.className !== 'string') {
    return null;
  }
  
  const classes = element.className.split(' ')
    .filter(className => {
      // Filter out generic, short, or framework-specific classes
      return className.length > 2 &&
             !className.startsWith('ng-') &&
             !className.startsWith('js-') &&
             !className.startsWith('is-') &&
             !/^[a-z]$/.test(className) &&
             !className.includes('hover') &&
             !className.includes('active') &&
             !className.includes('focus') &&
             !className.includes('loading');
    });
  
  if (classes.length === 0) return null;
  
  // Prioritize semantic classes that indicate content type
  const semanticClasses = classes.filter(c => 
    c.includes('product') || c.includes('item') || c.includes('tile') ||
    c.includes('card') || c.includes('grid') || c.includes('list') ||
    c.includes('price') || c.includes('title') || c.includes('image') ||
    c.includes('button') || c.includes('link') || c.includes('header') ||
    c.includes('footer') || c.includes('nav') || c.includes('menu') ||
    c.includes('content') || c.includes('main') || c.includes('side')
  );
  
  return semanticClasses.length > 0 ? `.${semanticClasses[0]}` : `.${classes[0]}`;
}

// Helper function to find unique attributes
function getUniqueAttribute(element) {
  const attrs = element.attributes;
  
  // Check for unique identifiers
  for (let i = 0; i < attrs.length; i++) {
    const attr = attrs[i];
    if (attr.name === 'data-product-id' || 
        attr.name === 'data-id' || 
        attr.name === 'data-sku' ||
        attr.name === 'data-uid' ||
        attr.name === 'data-testid' ||
        attr.name === 'data-cy' ||
        attr.name === 'data-test-id' ||
        attr.name === 'data-element' ||
        attr.name === 'data-selector') {
      return `[${attr.name}="${attr.value}"]`;
    }
  }
  
  // Check for role or aria attributes
  for (let i = 0; i < attrs.length; i++) {
    const attr = attrs[i];
    if (attr.name === 'role' || attr.name.startsWith('aria-')) {
      return `[${attr.name}="${attr.value}"]`;
    }
  }
  
  return null;
}

// Helper function to check if selector is unique
function isSelectorUnique(selector) {
  try {
    const elements = document.querySelectorAll(selector);
    return elements.length === 1;
  } catch (e) {
    return false;
  }
}

// Helper function to validate and simplify selector
function validateAndSimplifySelector(selector, originalElement) {
  try {
    const elements = document.querySelectorAll(selector);
    
    // If selector finds exactly the clicked element, it's good
    if (elements.length === 1 && elements[0] === originalElement) {
      return selector;
    }
    
    // If selector finds multiple elements but includes the original, try to simplify
    if (elements.length > 1 && Array.from(elements).includes(originalElement)) {
      // Try to find a shorter unique selector
      return findShorterSelector(originalElement, selector);
    }
    
    // If selector doesn't work, generate a simpler one
    return generateFallbackSelector(originalElement);
  } catch (e) {
    return generateFallbackSelector(originalElement);
  }
}

// Helper function to find shorter selector
function findShorterSelector(element, originalSelector) {
  // Try different approaches to shorten the selector
  
  // 1. Try just the custom element with class
  if (element.tagName.includes('-')) {
    const tagName = element.tagName.toLowerCase();
    const meaningfulClass = getMeaningfulClass(element);
    if (meaningfulClass) {
      const shortSelector = tagName + meaningfulClass;
      if (isSelectorUnique(shortSelector)) {
        return shortSelector;
      }
    }
  }
  
  // 2. Try with just the last 2 parts of the path
  const parts = originalSelector.split(' > ');
  if (parts.length > 2) {
    const shortSelector = parts.slice(-2).join(' > ');
    try {
      const elements = document.querySelectorAll(shortSelector);
      if (elements.length === 1 && elements[0] === element) {
        return shortSelector;
      }
    } catch (e) {}
  }
  
  return originalSelector;
}

// Fallback selector generator
function generateFallbackSelector(element) {
  // Simple fallback: use tag name with classes if available
  let selector = element.tagName.toLowerCase();
  
  const meaningfulClass = getMeaningfulClass(element);
  if (meaningfulClass) {
    selector += meaningfulClass;
  }
  
  // If still not unique, add parent context
  if (!isSelectorUnique(selector) && element.parentElement) {
    const parent = element.parentElement;
    const parentClass = getMeaningfulClass(parent);
    if (parentClass) {
      const position = getElementPosition(element);
      selector = `${parent.tagName.toLowerCase()}${parentClass} > ${element.tagName.toLowerCase()}:nth-child(${position})`;
    }
  }
  
  return selector;
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
      // const image = getProductImage(node);

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



chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
    if (msg.action === "get_page_url") {
        sendResponse({ page_url: window.location.href });
    }
});



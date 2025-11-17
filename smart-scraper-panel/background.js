chrome.action.onClicked.addListener(async (tab) => {
  try {
    await chrome.tabs.sendMessage(tab.id, { action: 'togglePanel' });
  } catch (err) {
    // content script may not be injected yet - inject and retry
    await chrome.scripting.executeScript({ target: { tabId: tab.id }, files: ['content.js'] });
    chrome.tabs.sendMessage(tab.id, { action: 'togglePanel' });
  }
});

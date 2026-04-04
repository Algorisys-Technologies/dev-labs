# Technical Mastery: Evolute AI Purchase Order Automation

This document provides a start-to-end technical explanation of how the Evolute AI Engine processes complex, noisy PO data with zero-click automation.

---

## 🚀 The Life of a Signal: Start to End

### Phase 1: Ingestion (The Signal Capture)
The system continuously polls a secure inbox using the **IMAP Protocol**. 
- **Monitoring**: It looks for unread emails and treats them as "Incoming Packets".
- **Real-time Sync**: The moment a mail hits the inbox, the background loop (`sync_emails_logic`) captures the raw text, subject, and sender metadata.

### Phase 2: Extraction (Semantic Parsing)
Unlike traditional systems that rely on rigid layouts, our **Semantic Extractor** uses a multi-strategy approach:
1.  **Section Anchoring**: It scans for headers like "Line Items", "Purchase Order No", or "Delivery Location".
2.  **Contextual Regex**: It captures PO numbers while ignoring "Ref" noise or "Date" strings.
3.  **List Extraction**: It identifies numbered lists (e.g., `1) Item: ...`) and parses multi-line descriptions into structured JSON.
4.  **Noisy Data Handling**: If a location is not explicitly labeled, it uses **Suffix Heuristics** (searching for city names and industrial zones like "MIDC" or "Chakan") to ensure the "Dispatch" info is never lost.

### Phase 3: Classification (Intelligence Engine)
The **AI Classifier** identifies the business category (Manufacturing, Trading, Distribution):
- **Model**: Logistic Regression + TF-IDF Vectorization.
- **N-Grams (1-3)**: The model doesn't just look at words; it looks at "chains" of words. 
  - *Example*: "Crankshaft Assembly" triggers **Manufacturing**.
  - *Example*: "Fast Chargers" triggers **Distribution**.
- **Dataset**: Trained on **8,000+ proprietary enterprise samples** to handle the noise and jargon found in real-world engineering POs.

### Phase 4: Zero-Click Persistence (Auto-Schema)
Once the extraction and classification are complete:
1.  **Instant Record**: The order is saved to the local SQLite database with a status of `Extracted | Syncing...`.
2.  **Autonomous Handshake**: An asynchronous task (`auto_push_after_delay`) triggers automatically.  
3.  **Schema Locking**: After a professional 2-second validation delay, the status updates to **`Pushed to Schema`**, marking the order as "ERP-Ready".

---

## 🎨 Professional Dashboard (Executive Visibility)
- **Zero-Click Workflow**: All buttons have been removed. The automation is 100% hands-free.
- **Trace Model**: Click the "Trace" button to see the "Forensic Proof":
  - **Source Mail**: The raw evidence.
  - **AI Extraction**: The structured JSON intelligence.
  - **SQL Terminal**: The proof of database persistence.
- **Priority HUD**: High-priority orders are instantly flagged with a red glowing badge, while normal orders remain clean to focus your attention where it matters.

---

**Engineering Rationale**: This architecture ensures that even the most complex "Axis Auto" style PO is transformed from a messy email into a clean, searchable database record within seconds—all without human intervention.

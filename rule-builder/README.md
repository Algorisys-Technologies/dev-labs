# Rule Builder — Node + React Router + TypeScript + Tailwind

This repo is a minimal, ready-to-open rule-builder app:
- Frontend: Vite + React + TypeScript + Tailwind + React Router + react-beautiful-dnd
- Backend: Express + TypeScript (simple file-based storage in `/server/data/rules.json`)
- Features:
  - Visual rule builder with groups and conditions
  - Drag & drop UI (react-beautiful-dnd)
  - Live human-readable preview with syntax highlighting
  - Save / Load rules (saved as JSON on server) with versioning
  - Server-side rule evaluation endpoint
  - Copy as JSON / Text buttons

**Security note:** The server can evaluate small "expression" snippets (for advanced return values). These are executed using `Function(...)` and are therefore potentially unsafe if you run untrusted input. For production, replace evaluation with a sandboxed engine.

## How to use

1. Unzip and `cd` into the `rule-builder` directory.
2. Install dependencies for client and server separately:
   - `cd client && npm install`
   - `cd server && npm install`
3. Start dev servers:
   - `cd server && npm run dev` (starts at http://localhost:4000)
   - `cd client && npm run dev` (starts at http://localhost:5173)
4. Open the client app, build rules, save them, and evaluate sample datasets.

## Contents
- `/client` — React app (Vite)
- `/server` — Express TypeScript API
- `/data` — generated on server run (stores rules)


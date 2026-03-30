# Ignite — Build a Phoenix-like Web Framework from Scratch

A step-by-step tutorial that teaches Elixir by building **Ignite**, a real web framework inspired by [Phoenix](https://www.phoenixframework.org/). You'll go from a raw TCP socket to a full-stack framework with LiveView, WebSockets, PubSub, and DOM diffing — all in 20 incremental commits.

By the end, you'll understand every layer that powers production Elixir web applications: the conn pipeline, macro-based routing, OTP supervision, EEx templates, middleware plugs, real-time LiveView with efficient DOM patching, and PubSub for cross-process broadcasting.

## ✨ Features Built

### Core
- **Macro-based Router** — define routes with a clean, Phoenix-like DSL
- **Plug-style Middleware** — composable request/response pipelines
- **EEx Template Engine** — server-side rendering with embedded Elixir
- **Multipart File Uploads** — streaming multipart parser with `%Ignite.Upload{}` struct and temp file cleanup
- **Error Handling** — `try/rescue` boundary catches crashes and renders 500 pages

### Real-time (LiveView)
- **LiveView** — server-side stateful processes that push DOM diffs over WebSockets
- **Diffing Engine** — calculates the minimal change between two renders to save bandwidth
- **PubSub** — `Ignite.PubSub` for broadcasting messages between LiveView processes
- **LiveView Navigation** — SPA-like page transitions with `ignite-navigate` and `push_redirect/2`
- **LiveComponents** — reusable stateful components with `live_component/3`, auto-namespaced events        
- **JS Hooks** — client-side lifecycle callbacks (`mounted`, `updated`, `destroyed`) for third-party JS interop
- **File Uploads** — chunked binary WebSocket uploads with `allow_upload/3`, progress tracking, drag-and-drop
- **Security & Reliability** — CSRF verification, strict CSP, HSTS, rate-limiting, and resilient automatic socket reconnections.

### Frontend Events
- **`ignite-click`** — click events with optional `ignite-value`
- **`ignite-change`** — form change events
- **`ignite-submit`** — form submission events

## Features & Routes
| Route | Description | Technology |
| :--- | :--- | :--- |
| `/` | Welcome | Static HTML render |
| `/hello` | Hello World | Custom controller action |
| `/counter` | Live Counter | LiveView (State + Events) |
| `/dashboard` | Dashboard | Multi-component LiveView |
| `/shared-counter` | Shared Counter | PubSub (Multiple browsers sync) |
| `/components` | Components demo | LiveComponents with independent state |
| `/hooks` | JS Hooks demo | Clipboard copy, local time, pushEvent |
| `/streams` | Streams demo | LiveView Streams for efficient list updates |
| `/upload` | File upload form | Multipart HTTP POST upload |
| `/upload-demo` | LiveView uploads | Chunked WebSocket uploads + progress |
| `/crash` | Error page | Error handler + 500 page |
| `POST /users` | Create user | POST body parsing |
| `PUT /users/42` | Update user | PUT/PATCH methods + JSON response |
| `PATCH /users/42` | Update user | Method overriding |
| `DELETE /users/42` | Delete user | HTTP method handling |
| `/api/status` | JSON API | `Jason` integration |
| `/todo` | Full Application | Ecto, LiveView Streams, Auth, CRUD |

## The Journey (45 Steps)

Ignite is a real framework. Over 45 steps, we achieved:
| Objective | Feature | Step |
| :--- | :--- | :---: |
| The Socket | Raw TCP server | 01 |
| HTTP Protocol | Request/Response parsing | 02 |
| Routing | Path matching | 04 |
| Controllers | Action-based responses | 05 |
| Dynamic Content | EEx template engine | 07 |
| Real-time | WebSocket upgrade | 11 |
| LiveView | Stateful processes | 12 |
| The Frontend | `ignite.js` DOM patching | 13 |
| Smart Patching | Morphdom integration | 16 |
| Coordination | PubSub broadcasting | 17 |
| Navigation | SPA transitions | 18 |
| Reusability | LiveComponents | 19 |
| Interop | JS Hooks | 20 |
| JSON API | REST support | 21 |
| Organization | Scoped routes | 23 |
| Optimization | Fine-grained diffing | 24 |
| Collections | LiveView Streams | 25 |
| File Uploads | Multipart + LiveView uploads | 26 |
| Database | Ecto & SQLite integration | 27 |
| Forms | Parsing & Validation | 28 |
| Sessions | Flash messages & cookies | 30 |
| Presence | Distributed tracking | 37 |
| Security | CSRF, CSP, HSTS, Rate Limit | 42 |
| App Building | Full Todo Context | 43 |
| Resilience | JS Reconnection backoff | 44 |
| Recovery | Server-side state recovery | 45 |

## Comprehensive Summary
To see a detailed breakdown of all 45 modules/steps, please read the [IGNITE_JOURNEY.md](./IGNITE_JOURNEY.md) file included in this repository!

## Prerequisites

Elixir and Mix installed on your system.

## Usage

1. Clone the repo
2. Install dependencies: `mix deps.get`
3. Start the server:
```bash
iex -S mix
```

## Examples

Visit the following URLs in your browser:
```bash
# http://localhost:4000              → Welcome page
# http://localhost:4000/counter      → LiveView counter
# http://localhost:4000/shared-counter → Multi-browser sync
# http://localhost:4000/components    → LiveComponents demo
# http://localhost:4000/hooks         → JS Hooks demo (clipboard, time)
# http://localhost:4000/streams      → LiveView Streams (efficient lists)
# http://localhost:4000/upload       → File upload form (multipart POST)
# http://localhost:4000/upload-demo  → LiveView uploads (chunked WebSocket + progress)
# http://localhost:4000/todo         → Full-Stack Todo Application
# http://localhost:4000/crash      → Error handler (500 page)
# curl -X POST -d "username=Jose" http://localhost:4000/users  → POST parsing
# http://localhost:4000/api/status   → JSON API response
# curl -X POST -H "Content-Type: application/json" -d '{"name":"Jose"}' http://localhost:4000/api/echo     
# curl -X PUT -H "Content-Type: application/json" -d '{"username":"Updated"}' http://localhost:4000/users/42
# curl -F "file=@README.md" http://localhost:4000/upload  → Multipart file upload
# curl -X DELETE http://localhost:4000/users/42
```

## Architecture

Ignite is built as a series of nested gen-servers and protocol adapters.

### Project Structure
```text
ignite/
├── lib/
│   ├── ignite/
│   │   ├── application.ex     # OTP Application
│   │   ├── conn.ex            # %Ignite.Conn{}
│   │   ├── router.ex          # Macro-based router
│   │   ├── controller.ex      # Controller helpers
│   │   ├── live_view.ex       # LiveView behaviour
│   │   ├── live_view/
│   │   │   ├── handler.ex      # WebSocket handler
│   │   │   ├── engine.ex      # Diffing engine
│   │   │   ├── eex_engine.ex  # Custom EEx engine for ~L sigil
│   │   │   ├── rendered.ex    # %Rendered{} struct
│   │   │   ├── stream.ex      # LiveView Streams
│   │   │   └── upload.ex      # LiveView upload helpers
│   │   ├── upload.ex          # %Ignite.Upload{} struct + temp file utils
│   │   ├── reloader.ex        # Hot code reloader
│   │   └── adapters/
│   │       └── cowboy.ex      # Cowboy HTTP adapter
│   └── my_app/                # Your application code
│       ├── router.ex
│       ├── controllers/
│       └── live/
└── assets/
    └── ignite.js              # Frontend framework glue
```

## Roadmap

Features that would bring Ignite closer to Phoenix for production use:

### Core
- [x] ~~OTP Supervision Tree~~ (Step 11)
- [x] ~~Macro-based Router DSL~~ (Step 10)
- [x] ~~Plugin-style middleware (Plugs)~~ (Step 08)
- [x] ~~Hot Code Reloading~~ (Step 09)
- [x] ~~JSON support (`Jason` serialization)~~ (Step 21)

### LiveView
- [x] ~~Efficient DOM diffing (Morphdom)~~ (Step 16)
- [x] ~~PubSub for real-time broadcasts~~ (Step 17)
- [x] ~~LiveView navigation (`live_redirect`, `push_patch` without full page reload)~~ (Step 18)
- [x] ~~LiveComponents (reusable stateful components within a LiveView)~~ (Step 19)
- [x] ~~Streams for large collections (append/prepend without re-rendering lists)~~ (Step 25)
- [x] ~~File uploads via LiveView~~ (Step 26)
- [x] ~~JS hooks (`phx-hook` equivalent for interop with JS libraries)~~ (Step 20)

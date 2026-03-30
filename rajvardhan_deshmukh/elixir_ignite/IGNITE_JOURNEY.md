# 🔥 The Ignite Framework Journey

This project is a custom, Phoenix-like web framework built entirely from scratch in Elixir. Over the course of 45 steps (modules), we constructed every layer of a modern web framework to deeply understand how tools like Phoenix, LiveView, and Ecto work under the hood.

This document serves as a high-level map of the 45 modules/steps we implemented.

---

## Part 1: The Core Foundation (Steps 1-10)
We started with bare TCP sockets and built up a functional HTTP web server.
*   **1-3. The OTP App & Web Server:** Set up a Supervisor tree, integrated `:cowboy` and `:ranch`, and learned how to accept raw HTTP connections.
*   **4-6. The Plug Pipeline:** Built `Ignite.Conn` (our version of `Plug.Conn`) to represent the HTTP request/response lifecycle. Implemented a pipeline architecture where functions transform the connection.
*   **7-8. Routing:** Created a DSL (Domain Specific Language) for routing using macros (`get "/path", to: Controller, action: :index`).
*   **9-10. Static Assets:** Built a static file server capable of reading MIME types and serving CSS/JS from the `priv/static` folder securely.

## Part 2: Rendering & Frontend (Steps 11-16)
Moving beyond raw text to dynamic HTML generation.
*   **11-12. The EEx Engine:** Integrated Elixir's built-in Embedded Elixir (EEx) to compile HTML templates into fast Elixir functions.
*   **13-14. Controllers & Layouts:** Built `Ignite.Controller` with helper functions (`render/3`, `html/2`, `json/2`) and implemented nested layouts (injecting templates into a root layout wrapper).
*   **15-16. Hot Reloading:** Implemented an aggressive file-watcher using `fs` that automatically recompiles modules and patches functions in memory without restarting the server.

## Part 3: Real-Time Magic (Steps 17-25)
Building the foundation for "LiveView" without writing JS frameworks.
*   **17-18. WebSockets:** Extended our Cowboy server to support persistent WebSocket connections.
*   **19-21. Ignite.LiveView:** Created a process that holds server-side state, renders HTML, and pushes it to the client.
*   **22-23. Morphdom & ignite.js:** Wrote vanilla JS frontend glue (`ignite.js`) using `morphdom` to surgically patch the DOM without losing focus or scroll position.
*   **24-25. Fine-Grained Diffing:** Optimized payload sizes by splitting templates into "Statics" (HTML structure sent once) and "Dynamics" (variables sent on every change).

## Part 4: Data & Forms (Steps 26-30)
Connecting to a database and handling user input.
*   **26-27. Ecto & SQLite:** Integrated `Ecto` with `Exqlite` to handle database interactions securely (avoiding SQL injection).
*   **28-29. Forms & Changesets:** Supported HTTP POST requests, parsed `application/x-www-form-urlencoded` payloads, and validated data using Ecto Changesets.
*   **30. Flash Messages & Sessions:** Implemented secure, signed cookies to persist session states and flash messages across redirects.

## Part 5: Componentization & Interop (Steps 31-35)
Scaling the frontend architecture.
*   **31-32. LiveComponents:** Built stateful, isolated components (`Ignite.LiveComponent`) that manage their own events and rendering lifecycle inside a parent LiveView.
*   **33-34. JS Hooks:** Created a bridge (`ignite-hook`) to allow custom JavaScript code to initialize, update, and communicate with the Elixir server (crucial for things like map libraries or charting).
*   **35. PubSub:** Built an in-memory Publish/Subscribe engine (`Ignite.PubSub`) allowing LiveViews to broadcast messages to each other globally (e.g., a shared counter or chat room).

## Part 6: Advanced Real-Time Features (Steps 36-40)
Adding cutting-edge Phoenix features.
*   **36-37. Presence:** Implemented a system to track "who is online" across the cluster using heartbeat monitors and PubSub.
*   **38. Streams:** Solved the large-list problem. Built `Ignite.LiveView.Stream` to let the server command the client to append/prepend/delete DOM elements without holding the entire list in memory.
*   **39-40. File Uploads:** Supported traditional HTTP multipart uploads, and then built highly advanced chunked WebSocket uploads directly through LiveView (handling progress bars and binary frames).

## Part 7: Security & Production Readiness (Steps 41-45)
Hardening the framework for the real world.
*   **41-42. Security Plugs:** Implemented CSRF (Cross-Site Request Forgery) token verification, strict CSP (Content Security Policy) headers, and HSTS. Added brute-force Rate Limiting using ETS tables.
*   **43. The Capstone Todo App:** Built a complete, production-grade application on top of the framework, featuring authentication, LiveView Streams, LiveComponents, and Ecto relationships.
*   **44. Resilience:** Strengthened the JS client with automatic exponential backoff reconnection, connection UI status indicators, and container-scoped event delegation.
*   **45. Server-Side Recovery:** Implemented state recovery logic so that if the user's connection drops and reconnects, they pick up exactly where they left off without losing their session context.

---

### 💡 Why we built this
By building tools like `LiveView`, `Plug`, and `Router` from absolute scratch, we demystified the "magic" of the Elixir ecosystem. We mapped out exactly how macros generate routes, how WebSockets maintain state, how morphdom algorithms calculate DOM diffs, and how Ecto changesets validate complex data. 

*The result is an ultra-lean, highly educational web framework powered by the BEAM.*

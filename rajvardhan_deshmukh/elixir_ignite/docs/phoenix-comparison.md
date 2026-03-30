# Ignite vs. Phoenix

Ignite is a pedagogical framework designed to teach you how Phoenix works by building a simplified version of it from scratch. While Ignite follows the same core architectural patterns, there are significant differences in implementation complexity, performance, and feature set.

## Comparison Table

| Feature | Ignite Implementation | Phoenix Implementation |
| :--- | :--- | :--- |
| **HTTP Server** | Cowboy (via custom adapter) | Cowboy / Bandit (via Plug/Plug.Conn) |
| **Routing** | Macro-based pattern matching | Highly optimized prefix trees |
| **Templating** | Basic EEx with custom Engine | HEEx (HTML-aware, optimized diffing) |
| **LiveView** | GenServer per connection | GenServer with advanced change tracking |
| **DOM Patching** | Morphdom (standard) | Optimized Morphdom fork + surgical patches |
| **PubSub** | Local Registry-based | Distributed (Redis, PG2, Postgres) |
| **File Uploads** | Chunked binary WebSocket frames | Multi-protocol (WebSocket, S3 direct, etc.) |

## Deep Dive: File Uploads

### Ignite (Pedagogical)
In Ignite, we implemented file uploads using **chunked binary WebSocket frames**. 
1. The client selects a file.
2. The JS side sends metadata for validation.
3. The JS side slices the file into chunks (e.g., 64KB) and sends them as binary frames.
4. Each binary frame is prefixed with a 2-byte length and a reference string to identify the upload.
5. The server appends these chunks to a temporary file.

### Phoenix (Production)
Phoenix LiveView uses a more sophisticated multi-channel approach:
- **Direct-to-S3/Cloud**: Phoenix supports "external" uploads where the browser gets a pre-signed URL and uploads directly to storage, bypassing the Elixir server for better scalability.
- **Consumption Logic**: Phoenix's `consume_uploaded_entries` is integrated with a complex entry lifecycle (pending, uploading, done).
- **Security**: Phoenix includes signed tokens for upload validation to prevent unauthorized binary transfers.

## Summary

Ignite is perfect for **learning**. It strips away the optimizations that make Phoenix production-ready but difficult to read. By building Ignite, you've mastered the *mental model* of Phoenix, making you a much more effective Phoenix developer.

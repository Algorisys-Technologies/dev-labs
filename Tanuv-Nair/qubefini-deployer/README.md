# qubefini-deployer

A shell script that pulls the latest (or a specific) release of the **qubefini** project, builds both the frontend and backend, and assembles a ready-to-deploy directory.

## Prerequisites

The machine running the script needs:

| Tool | Purpose |
|------|---------|
| `git` | Cloning the repos |
| `node` / `npm` | Building the React Router v7 frontend |
| `go` | Cross-compiling the backend binaries |

The Go toolchain must support cross-compilation for the target platform (it does by default — no extra setup needed).

## Setup

1. Clone or copy this deployer into a directory on your build machine.
2. Create a `.env` file **next to `deploy.sh`** containing the frontend's `VITE_` environment variables. These are baked into the frontend build at compile time.

   ```bash
   # .env
   VITE_API_URL=https://your-api-host
   # ... other VITE_ variables
   ```

   If `.env` is missing, the script will print the required variable names (from the repo's `.env.example`) and exit.

> **Note:** `.env` is listed in `.gitignore` — never commit it.

## Usage

```bash
# Build latest release for Windows (default)
./deploy.sh

# Build a specific tag for Windows
./deploy.sh --tag v1.0.1

# Build latest release for Linux
./deploy.sh --platform linux

# Build latest release for both platforms
./deploy.sh --platform all

# Combine both flags
./deploy.sh --tag v1.0.1 --platform windows
```

### Flags

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--tag` | e.g. `v1.0.1` | latest `v*` tag | Git tag to check out on both repos |
| `--platform` | `windows`, `linux`, `all` | `windows` | Target platform for backend binaries |

## Output

The script produces a single versioned directory next to `deploy.sh`:

```
qubefini-v1.0.1/
├── frontend/
│   ├── build/
│   │   ├── client/
│   │   └── server/
│   ├── .env.example
│   ├── .nvmrc
│   ├── package.json
│   └── package-lock.json
└── backend/
    ├── bin/
    │   └── windows_amd64/
    │       ├── mini-etl-api.exe
    │       ├── mini-etl-scheduler.exe
    │       └── mini-etl-seeder.exe
    ├── prisma/
    │   ├── schema.prisma
    │   └── migrations/        ← only migrations new since the previous tag
    └── .env.example
```

When `--platform all` is used, `bin/` will contain both `linux_amd64/` and `windows_amd64/` subdirectories.

## How it works

1. **Resolves the tag** — queries `git ls-remote` on the frontend repo for the latest `v*` tag, unless `--tag` is provided.
2. **Checks for `.env`** — exits early with clear instructions if the frontend build environment file is missing.
3. **Clones both repos** at the resolved tag (shallow clone, no history).
4. **Builds the frontend** — copies `.env` into the source tree, then runs `npm install && npm run build`.
5. **Builds the backend** — runs `./scripts/build.sh -p <platform>` which cross-compiles to the target OS/arch.
6. **Assembles the package** — copies build artefacts and supporting files into `qubefini-<tag>/`.
7. **Filters Prisma migrations** — diffs against the previous tag and includes only migrations that are new in this release.
8. **Cleans up** — the temporary working directory is always removed on exit, including on Ctrl+C.

## Repositories

| Component | Repository |
|-----------|-----------|
| Frontend (React Router v7 / SSR) | https://github.com/Algorisys-Technologies/mini-etl-ui |
| Backend (API, Scheduler, Seeder) | https://github.com/Algorisys-Technologies/mini-etl |

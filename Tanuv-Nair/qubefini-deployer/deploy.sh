#!/bin/bash
# deploy.sh - Build and package a qubefini deployment
#
# Usage:
#   ./deploy.sh [--tag v1.0.1] [--platform windows|linux|all]
#
#   --tag        Git tag to check out (default: latest v* tag)
#   --platform   Target platform: windows, linux, or all (default: windows)
#
# Requirements:
#   git, node/npm, go (with cross-compilation support)
#
# Output (example for windows):
#   qubefini-<tag>/
#   ├── frontend/
#   │   └── build/
#   │       ├── client/
#   │       └── server/
#   └── backend/
#       └── bin/
#           └── windows_amd64/
#               ├── mini-etl-api.exe
#               ├── mini-etl-scheduler.exe
#               └── mini-etl-seeder.exe

set -euo pipefail

FRONTEND_REPO="https://github.com/Algorisys-Technologies/mini-etl-ui"
BACKEND_REPO="https://github.com/Algorisys-Technologies/mini-etl"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Parse flags ─────────────────────────────────────────────────────────────

LATEST_TAG=""
PLATFORM="windows"  # default

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag)
            LATEST_TAG="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        *)
            echo "ERROR: Unknown argument '$1'" >&2
            echo "Usage: $0 [--tag v1.0.1] [--platform windows|linux|all]" >&2
            exit 1
            ;;
    esac
done

# Map friendly names to the format build.sh expects (-p flag)
case "$PLATFORM" in
    windows)  BUILD_PLATFORM="windows/amd64" ;;
    linux)    BUILD_PLATFORM="linux/amd64" ;;
    all)      BUILD_PLATFORM="all" ;;
    *)
        echo "ERROR: Unknown platform '$PLATFORM'. Use: windows, linux, or all." >&2
        exit 1
        ;;
esac

# ─── Resolve tag ─────────────────────────────────────────────────────────────

if [ -n "$LATEST_TAG" ]; then
    echo "Using specified tag: $LATEST_TAG"
else
    echo "Fetching latest release tag from $FRONTEND_REPO ..."
    LATEST_TAG=$(
        git ls-remote --tags --sort="-version:refname" "$FRONTEND_REPO" \
        | grep -v '\^{}' \
        | grep 'refs/tags/v' \
        | head -1 \
        | awk '{print $2}' \
        | sed 's|refs/tags/||'
    )
    if [ -z "$LATEST_TAG" ]; then
        echo "ERROR: Could not determine latest tag from $FRONTEND_REPO" >&2
        exit 1
    fi
    echo "Latest release tag: $LATEST_TAG"
fi

OUTPUT_DIR="$SCRIPT_DIR/qubefini-$LATEST_TAG"

if [ -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory already exists: $OUTPUT_DIR" >&2
    echo "       Remove it manually or choose a different tag." >&2
    exit 1
fi

# ─── Working directory ────────────────────────────────────────────────────────

WORK_DIR=$(mktemp -d)
trap 'echo ""; echo "Cleaning up temporary files..."; rm -rf "$WORK_DIR"' EXIT

echo ""
echo "Working directory : $WORK_DIR"
echo "Output directory  : $OUTPUT_DIR"
echo "Platform          : $PLATFORM ($BUILD_PLATFORM)"
echo ""

# ─── Clone repos ─────────────────────────────────────────────────────────────

echo "==> Cloning frontend @ $LATEST_TAG ..."
if [ ! -d "$WORK_DIR/frontend_src/.git" ]; then
    git clone -q --depth 1 --branch "$LATEST_TAG" "$FRONTEND_REPO" "$WORK_DIR/frontend_src" 2>/dev/null
else
    echo "    (already cloned during .env check, skipping)"
fi

echo ""
echo "==> Cloning backend @ $LATEST_TAG ..."
git clone -q --depth 1 --branch "$LATEST_TAG" "$BACKEND_REPO" "$WORK_DIR/backend_src" 2>/dev/null

# ─── Frontend .env check ─────────────────────────────────────────────────────
# TODO: Add a check for .env file to ensure if all the VITE_ prefixed environment variables are set

FRONTEND_ENV="$SCRIPT_DIR/.env"
if [ ! -f "$FRONTEND_ENV" ]; then
    echo ""
    echo "ERROR: No .env file found at $FRONTEND_ENV" >&2
    echo ""
    echo "The frontend build bakes VITE_ environment variables in at compile time." >&2
    echo "Please create a .env file next to deploy.sh with the required variables." >&2
    echo ""
    echo "Required variables (from .env.example in the frontend repo):"  >&2
    # Clone just enough to read .env.example if not already cloned
    if [ ! -f "$WORK_DIR/frontend_src/.env.example" ]; then
        git clone -q --depth 1 --branch "$LATEST_TAG" "$FRONTEND_REPO" "$WORK_DIR/frontend_src" >/dev/null 2>&1 || true
    fi
    if [ -f "$WORK_DIR/frontend_src/.env.example" ]; then
        grep '^VITE_' "$WORK_DIR/frontend_src/.env.example" | sed 's/^/  /' >&2
    else
        echo "  (could not fetch .env.example — check the repo manually)" >&2
    fi
    echo ""
    exit 1
fi
echo "Using .env from: $FRONTEND_ENV"

# ─── Build frontend ───────────────────────────────────────────────────────────

echo ""
echo "==> Building frontend ..."
# Copy the .env into the source tree so Vite picks it up at build time
cp "$FRONTEND_ENV" "$WORK_DIR/frontend_src/.env"
cd "$WORK_DIR/frontend_src"
if ! npm install; then
    echo "ERROR: 'npm install' for frontend failed. See output above for details." >&2
    exit 1
fi
if ! npm run build; then
    echo "ERROR: 'npm run build' for frontend failed. See output above for details." >&2
    exit 1
fi

# Verify expected output exists
if [ ! -d "$WORK_DIR/frontend_src/build" ]; then
    echo "ERROR: Frontend build did not produce a 'build' directory." >&2
    exit 1
fi

# ─── Build backend ────────────────────────────────────────────────────────────

echo ""
echo "==> Building backend (platform: $PLATFORM) ..."
cd "$WORK_DIR/backend_src"
chmod +x ./scripts/build.sh
./scripts/build.sh -p "$BUILD_PLATFORM"

# Verify expected output exists
if [ "$PLATFORM" = "all" ]; then
    VERIFY_DIR="$WORK_DIR/backend_src/bin"
    VERIFY_LABEL="bin/"
else
    GOOS="${BUILD_PLATFORM%%/*}"
    GOARCH="${BUILD_PLATFORM##*/}"
    VERIFY_DIR="$WORK_DIR/backend_src/bin/${GOOS}_${GOARCH}"
    VERIFY_LABEL="bin/${GOOS}_${GOARCH}"
fi

if [ ! -d "$VERIFY_DIR" ]; then
    echo "ERROR: Backend build did not produce '$VERIFY_LABEL'." >&2
    exit 1
fi

# ─── Assemble deployment package ─────────────────────────────────────────────

echo ""
echo "==> Assembling deployment package ..."
mkdir -p "$OUTPUT_DIR/frontend"
mkdir -p "$OUTPUT_DIR/backend"

# Frontend: build output + supporting files
cp -r "$WORK_DIR/frontend_src/build"            "$OUTPUT_DIR/frontend/"
cp    "$WORK_DIR/frontend_src/.env.example"     "$OUTPUT_DIR/frontend/"
cp    "$WORK_DIR/frontend_src/.nvmrc"           "$OUTPUT_DIR/frontend/"
cp    "$WORK_DIR/frontend_src/package.json"     "$OUTPUT_DIR/frontend/"
cp    "$WORK_DIR/frontend_src/package-lock.json" "$OUTPUT_DIR/frontend/"

# Backend: compiled binaries + supporting files
cp -r "$WORK_DIR/backend_src/bin"               "$OUTPUT_DIR/backend/"
cp    "$WORK_DIR/backend_src/.env.example"      "$OUTPUT_DIR/backend/"

# ─── Prisma: only new migrations ─────────────────────────────────────────────

echo ""
echo "==> Determining new prisma migrations since previous release ..."
mkdir -p "$OUTPUT_DIR/backend/prisma"

# Copy top-level prisma files (schema.prisma, etc.) — always included
find "$WORK_DIR/backend_src/prisma" -maxdepth 1 -type f \
    -exec cp {} "$OUTPUT_DIR/backend/prisma/" \;

# Find the tag immediately before the current one in the backend repo
PREV_TAG=$(
    git ls-remote --tags --sort="-version:refname" "$BACKEND_REPO" \
    | grep -v '\^{}' \
    | grep 'refs/tags/v' \
    | awk '{print $2}' \
    | sed 's|refs/tags/||' \
    | awk -v tag="$LATEST_TAG" 'found{print; exit} $0==tag{found=1}'
)

if [ -z "$PREV_TAG" ]; then
    echo "    No previous tag found — including all migrations."
    [ -d "$WORK_DIR/backend_src/prisma/migrations" ] && \
        cp -r "$WORK_DIR/backend_src/prisma/migrations" "$OUTPUT_DIR/backend/prisma/"
else
    echo "    Previous tag: $PREV_TAG  →  current tag: $LATEST_TAG"
    git clone -q --depth 1 --branch "$PREV_TAG" "$BACKEND_REPO" "$WORK_DIR/backend_prev" 2>/dev/null || true

    # Collect migration dirs that existed in the previous release
    declare -A PREV_MIGRATION_SET
    if [ -d "$WORK_DIR/backend_prev/prisma/migrations" ]; then
        while IFS= read -r dir; do
            PREV_MIGRATION_SET["$(basename "$dir")"]=1
        done < <(find "$WORK_DIR/backend_prev/prisma/migrations" \
                      -mindepth 1 -maxdepth 1 -type d)
    fi

    # Copy only migrations that did not exist in the previous release
    mkdir -p "$OUTPUT_DIR/backend/prisma/migrations"
    NEW_COUNT=0
    if [ -d "$WORK_DIR/backend_src/prisma/migrations" ]; then
        while IFS= read -r dir; do
            name="$(basename "$dir")"
            if [ -z "${PREV_MIGRATION_SET[$name]+_}" ]; then
                cp -r "$dir" "$OUTPUT_DIR/backend/prisma/migrations/"
                echo "    + $name"
                (( NEW_COUNT++ )) || true
            fi
        done < <(find "$WORK_DIR/backend_src/prisma/migrations" \
                      -mindepth 1 -maxdepth 1 -type d | sort)
    fi

    if [ "$NEW_COUNT" -eq 0 ]; then
        echo "    No new migrations in this release."
    else
        echo "    $NEW_COUNT new migration(s) included."
    fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

# Count files in each section for a concise summary
FRONTEND_FILES=$(find "$OUTPUT_DIR/frontend/build" -type f 2>/dev/null | wc -l | tr -d ' ')

MIGRATIONS=$(find "$OUTPUT_DIR/backend/prisma/migrations" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Deployment package ready                                   │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "  Location : $OUTPUT_DIR"
echo "  Tag      : $LATEST_TAG"
echo "  Platform : $PLATFORM"
echo ""
echo "  frontend/"
echo "    build/            ($FRONTEND_FILES files)"
echo "    .env.example"
echo "    .nvmrc"
echo "    package.json"
echo "    package-lock.json"
echo ""
echo "  backend/"
if [ "$PLATFORM" = "all" ]; then
    echo "    bin/              (linux_amd64 + windows_amd64)"
else
    GOOS="${BUILD_PLATFORM%%/*}"; GOARCH="${BUILD_PLATFORM##*/}"
    BIN_COUNT=$(find "$OUTPUT_DIR/backend/bin" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "    bin/${GOOS}_${GOARCH}/  ($BIN_COUNT binaries)"
fi
echo "    prisma/           ($MIGRATIONS new migration(s))"
# When PREV_TAG is not set, $MIGRATIONS represents all migrations, not just new ones.
if [ -n "${PREV_TAG:-}" ]; then
    MIGRATION_LABEL="new"
else
    MIGRATION_LABEL="total"
fi
echo "    prisma/           ($MIGRATIONS $MIGRATION_LABEL migration(s))"
echo ""

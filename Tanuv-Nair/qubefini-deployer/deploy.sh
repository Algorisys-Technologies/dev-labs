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
    git clone --depth 1 --branch "$LATEST_TAG" "$FRONTEND_REPO" "$WORK_DIR/frontend_src"
else
    echo "    (already cloned during .env check, skipping)"
fi

echo ""
echo "==> Cloning backend @ $LATEST_TAG ..."
git clone --depth 1 --branch "$LATEST_TAG" "$BACKEND_REPO" "$WORK_DIR/backend_src"

# ─── Frontend .env check ─────────────────────────────────────────────────────

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
        git clone --depth 1 --branch "$LATEST_TAG" "$FRONTEND_REPO" "$WORK_DIR/frontend_src" >/dev/null 2>&1 || true
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
cp -r "$WORK_DIR/backend_src/prisma"            "$OUTPUT_DIR/backend/"
cp    "$WORK_DIR/backend_src/.env.example"      "$OUTPUT_DIR/backend/"

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "┌─────────────────────────────────────────────────────┐"
if command -v tree >/dev/null 2>&1; then
    # Use 'tree' for a clear hierarchical view if it is available.
    (cd "$OUTPUT_DIR" && tree)
else
    # Fallback: list files with indentation based on path depth.
    # We sort the paths and then indent each item according to the
    # number of '/' components in the path relative to $OUTPUT_DIR.
    find "$OUTPUT_DIR" -print | sort | \
        awk 'BEGIN { FS = "/" } {
            depth = NF - 1
            indent = ""
            for (i = 1; i <= depth; i++) {
                indent = indent "  "
            }
            item = $NF
            if (item != "") {
                print indent item
            }
        }'
fi
echo ""
echo "  $OUTPUT_DIR"
echo ""
echo "Package contents:"
find "$OUTPUT_DIR" | sed "s|$OUTPUT_DIR||" | sort | sed 's|/[^/]*$|&|' | \
    awk 'BEGIN{FS="/"} {indent=""; for(i=1;i<NF;i++) indent=indent"  "; print indent $NF}'
echo ""

#!/bin/bash
# deploy.sh - Build and package a qubefini deployment
#
# Usage:
#   ./deploy.sh [--tag v1.0.1] [--frontend-tag v1.2.0 --backend-tag v1.2.3] [--platform windows|linux|all] [--all-migrations]
#
#   --tag             Single Git tag to use for both frontend and backend
#   --frontend-tag    Frontend tag to use (must be paired with --backend-tag)
#   --backend-tag     Backend tag to use (must be paired with --frontend-tag)
#   --platform        Target platform: windows, linux, or all (default: windows)
#   --all-migrations  Include all Prisma migrations, not just those new since the previous tag
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

get_repo_tags() {
    local repo="$1"
    git ls-remote --tags --sort="-version:refname" "$repo" \
        | grep -v '\^{}' \
        | grep 'refs/tags/v' \
        | awk '{print $2}' \
        | sed 's|refs/tags/||'
}

tag_exists_in_repo() {
    local tag="$1"
    local repo="$2"
    if get_repo_tags "$repo" | grep -q "^${tag}$"; then
        return 0
    fi
    return 1
}

extract_major_minor() {
    local tag="$1"
    if [[ "$tag" =~ ^v?([0-9]+)\.([0-9]+)\.[0-9]+$ ]]; then
        echo "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        return 0
    fi
    return 1
}

latest_of_two_tags() {
    local tag_a="$1"
    local tag_b="$2"
    printf "%s\n%s\n" "$tag_a" "$tag_b" | sort -Vr | head -1
}

# ─── Parse flags ─────────────────────────────────────────────────────────────

LATEST_TAG=""
REQUESTED_FRONTEND_TAG=""
REQUESTED_BACKEND_TAG=""
PLATFORM="windows"  # default
ALL_MIGRATIONS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag)
            LATEST_TAG="$2"
            shift 2
            ;;
        --frontend-tag)
            REQUESTED_FRONTEND_TAG="$2"
            shift 2
            ;;
        --backend-tag)
            REQUESTED_BACKEND_TAG="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --all-migrations)
            ALL_MIGRATIONS=true
            shift
            ;;
        *)
            echo "ERROR: Unknown argument '$1'" >&2
            echo "Usage: $0 [--tag v1.0.1] [--frontend-tag v1.2.0 --backend-tag v1.2.3] [--platform windows|linux|all] [--all-migrations]" >&2
            exit 1
            ;;
    esac
done

if [ -n "$LATEST_TAG" ] && { [ -n "$REQUESTED_FRONTEND_TAG" ] || [ -n "$REQUESTED_BACKEND_TAG" ]; }; then
    echo "ERROR: Use either --tag OR (--frontend-tag and --backend-tag), not both." >&2
    exit 1
fi

if { [ -n "$REQUESTED_FRONTEND_TAG" ] && [ -z "$REQUESTED_BACKEND_TAG" ]; } || \
   { [ -z "$REQUESTED_FRONTEND_TAG" ] && [ -n "$REQUESTED_BACKEND_TAG" ]; }; then
    echo "ERROR: --frontend-tag and --backend-tag must be provided together." >&2
    exit 1
fi

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

FRONTEND_TAG=""
BACKEND_TAG=""
SKIP_COMPATIBILITY_CHECK=false

if [ -n "$LATEST_TAG" ]; then
    echo "Using specified tag: $LATEST_TAG"
    if ! tag_exists_in_repo "$LATEST_TAG" "$FRONTEND_REPO"; then
        echo "ERROR: Tag '$LATEST_TAG' does not exist in frontend repo." >&2
        exit 1
    fi
    if ! tag_exists_in_repo "$LATEST_TAG" "$BACKEND_REPO"; then
        echo "ERROR: Tag '$LATEST_TAG' does not exist in backend repo." >&2
        exit 1
    fi
    FRONTEND_TAG="$LATEST_TAG"
    BACKEND_TAG="$LATEST_TAG"
elif [ -n "$REQUESTED_FRONTEND_TAG" ] && [ -n "$REQUESTED_BACKEND_TAG" ]; then
    FRONTEND_TAG="$REQUESTED_FRONTEND_TAG"
    BACKEND_TAG="$REQUESTED_BACKEND_TAG"
    echo "Using requested tags: frontend=$FRONTEND_TAG backend=$BACKEND_TAG"

    if ! tag_exists_in_repo "$FRONTEND_TAG" "$FRONTEND_REPO"; then
        echo "ERROR: Tag '$FRONTEND_TAG' does not exist in frontend repo." >&2
        exit 1
    fi
    if ! tag_exists_in_repo "$BACKEND_TAG" "$BACKEND_REPO"; then
        echo "ERROR: Tag '$BACKEND_TAG' does not exist in backend repo." >&2
        exit 1
    fi
    SKIP_COMPATIBILITY_CHECK=true
else
    echo "Resolving latest frontend/backend tags and checking compatibility ..."
    FRONTEND_TAGS="$(get_repo_tags "$FRONTEND_REPO")"
    BACKEND_TAGS="$(get_repo_tags "$BACKEND_REPO")"

    FRONTEND_TAG="$(echo "$FRONTEND_TAGS" | head -1)"
    BACKEND_TAG="$(echo "$BACKEND_TAGS" | head -1)"

    if [ -z "$FRONTEND_TAG" ] || [ -z "$BACKEND_TAG" ]; then
        echo "ERROR: Could not determine latest tags for both repositories." >&2
        echo "       Frontend latest: ${FRONTEND_TAG:-none}" >&2
        echo "       Backend latest : ${BACKEND_TAG:-none}" >&2
        exit 1
    fi

    echo "Frontend tag: $FRONTEND_TAG"
    echo "Backend tag : $BACKEND_TAG"
fi

if ! $SKIP_COMPATIBILITY_CHECK; then
    FRONTEND_MM="$(extract_major_minor "$FRONTEND_TAG" || true)"
    BACKEND_MM="$(extract_major_minor "$BACKEND_TAG" || true)"

    if [ -z "$FRONTEND_MM" ] || [ -z "$BACKEND_MM" ]; then
        echo "ERROR: Could not parse semantic version from selected tags." >&2
        echo "       Frontend tag: $FRONTEND_TAG" >&2
        echo "       Backend tag : $BACKEND_TAG" >&2
        exit 1
    fi

    if [ "$FRONTEND_MM" != "$BACKEND_MM" ]; then
        echo "ERROR: Selected frontend/backend versions are incompatible." >&2
        echo "       Frontend tag: $FRONTEND_TAG (major.minor=$FRONTEND_MM)" >&2
        echo "       Backend tag : $BACKEND_TAG (major.minor=$BACKEND_MM)" >&2
        echo "       Compatibility rule: major.minor must match." >&2
        exit 1
    fi

    echo "Compatibility check passed (major.minor: $FRONTEND_MM)"
else
    echo "Skipping compatibility check because explicit frontend/backend tags were provided."
fi

OUTPUT_TAG="$(latest_of_two_tags "$FRONTEND_TAG" "$BACKEND_TAG")"
OUTPUT_DIR="$SCRIPT_DIR/qubefini-$OUTPUT_TAG"

if [ -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory already exists: $OUTPUT_DIR" >&2
    echo "       Remove it manually or choose a different tag." >&2
    exit 1
fi

# ─── Working directory ────────────────────────────────────────────────────────

WORK_DIR=$(mktemp -d)
trap 'echo ""; echo "Cleaning up temporary files..."; rm -rf "$WORK_DIR"' EXIT

echo ""
echo "Working directory  : $WORK_DIR"
echo "Output directory   : $OUTPUT_DIR"
echo "Platform           : $PLATFORM ($BUILD_PLATFORM)"
echo "All migrations     : $ALL_MIGRATIONS"
echo ""

# ─── Clone repos ─────────────────────────────────────────────────────────────

echo "==> Cloning frontend @ $FRONTEND_TAG ..."
if [ ! -d "$WORK_DIR/frontend_src/.git" ]; then
    git clone -q --depth 1 --branch "$FRONTEND_TAG" "$FRONTEND_REPO" "$WORK_DIR/frontend_src" 2>/dev/null
else
    echo "    (already cloned during .env check, skipping)"
fi

echo ""
echo "==> Cloning backend @ $BACKEND_TAG ..."
git clone -q --depth 1 --branch "$BACKEND_TAG" "$BACKEND_REPO" "$WORK_DIR/backend_src" 2>/dev/null

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
        git clone -q --depth 1 --branch "$FRONTEND_TAG" "$FRONTEND_REPO" "$WORK_DIR/frontend_src" >/dev/null 2>&1 || true
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

# ─── Prisma migrations ───────────────────────────────────────────────────────

echo ""
if $ALL_MIGRATIONS; then
    echo "==> Including all prisma migrations (--all-migrations) ..."
else
    echo "==> Determining new prisma migrations since previous release ..."
fi
mkdir -p "$OUTPUT_DIR/backend/prisma"

# Copy top-level prisma files (schema.prisma, etc.) — always included
find "$WORK_DIR/backend_src/prisma" -maxdepth 1 -type f \
    -exec cp {} "$OUTPUT_DIR/backend/prisma/" \;

if $ALL_MIGRATIONS; then
    # Include every migration regardless of previous releases
    echo "    Copying all migrations."
    [ -d "$WORK_DIR/backend_src/prisma/migrations" ] && \
        cp -r "$WORK_DIR/backend_src/prisma/migrations" "$OUTPUT_DIR/backend/prisma/"
    PREV_TAG=""
else
    # Find the tag immediately before the current one in the backend repo
    PREV_TAG=$(
        git ls-remote --tags --sort="-version:refname" "$BACKEND_REPO" \
        | grep -v '\^{}' \
        | grep 'refs/tags/v' \
        | awk '{print $2}' \
        | sed 's|refs/tags/||' \
        | awk -v tag="$BACKEND_TAG" 'found{print; exit} $0==tag{found=1}'
    )

    if [ -z "$PREV_TAG" ]; then
        echo "    No previous tag found — including all migrations."
        [ -d "$WORK_DIR/backend_src/prisma/migrations" ] && \
            cp -r "$WORK_DIR/backend_src/prisma/migrations" "$OUTPUT_DIR/backend/prisma/"
    else
        echo "    Previous tag: $PREV_TAG  →  current tag: $BACKEND_TAG"
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
echo "  Frontend : $FRONTEND_TAG"
echo "  Backend  : $BACKEND_TAG"
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
if $ALL_MIGRATIONS; then
    MIGRATION_LABEL="total"
elif [ -n "${PREV_TAG:-}" ]; then
    MIGRATION_LABEL="new"
else
    MIGRATION_LABEL="total"
fi
echo "    prisma/           ($MIGRATIONS $MIGRATION_LABEL migration(s))"
echo ""

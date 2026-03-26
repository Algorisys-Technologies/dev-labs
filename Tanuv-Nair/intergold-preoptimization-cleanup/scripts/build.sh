#!/bin/bash

# Build script for intergold-preoptimization-cleanup
# Generates binaries for a specified platform (linux or windows)

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the project root directory (parent of scripts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Binary output directory
BIN_DIR="$PROJECT_ROOT/bin"

# Applications to build
APPS=("app")

usage() {
    echo "Usage: $0 [-p platform]"
    echo "Options:"
    echo "  -p  Platform to build (linux/amd64, windows/amd64, or all)"
    echo "      If not provided, you will be prompted to choose."
    echo ""
    echo "Example: $0 -p windows/amd64"
    exit 1
}

# Parse flags
while getopts "p:h" opt; do
    case $opt in
        p) PLATFORM="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Prompt for platform if not provided via flag
if [ -z "$PLATFORM" ]; then
    echo -e "${BLUE}No platform specified. Please choose one:${NC}"
    echo "  1) linux/amd64"
    echo "  2) windows/amd64"
    echo "  3) all"
    echo "  q) Quit"
    read -p "Selection [1-3, q]: " choice

    case $choice in
        1) PLATFORM="linux/amd64" ;;
        2) PLATFORM="windows/amd64" ;;
        3) PLATFORM="all" ;;
        q|Q) echo "Build cancelled."; exit 0 ;;
        *) echo -e "${RED}Invalid selection.${NC}"; exit 1 ;;
    esac
fi

# Define platforms to build
if [ "$PLATFORM" = "all" ]; then
    PLATFORMS=("linux/amd64" "windows/amd64")
else
    PLATFORMS=("$PLATFORM")
fi

# Create bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

echo -e "${BLUE}Starting build process...${NC}"
echo "Project root: $PROJECT_ROOT"
echo "Output directory: $BIN_DIR"
echo ""

# Build for each platform
for platform in "${PLATFORMS[@]}"; do
    IFS='/' read -r GOOS GOARCH <<< "$platform"

    if [ -z "$GOOS" ] || [ -z "$GOARCH" ]; then
        echo -e "${RED}Error: Invalid platform format '$platform'. Use GOOS/GOARCH.${NC}"
        continue
    fi

    echo -e "${BLUE}Building for $GOOS/$GOARCH...${NC}"

    # Create platform-specific directory
    PLATFORM_BIN_DIR="$BIN_DIR/${GOOS}_${GOARCH}"
    mkdir -p "$PLATFORM_BIN_DIR"

    for app in "${APPS[@]}"; do
        APP_PATH="$PROJECT_ROOT/cmd/$app"

        if [ ! -d "$APP_PATH" ]; then
            echo -e "${RED}Warning: Application path $APP_PATH not found, skipping...${NC}"
            continue
        fi

        # Set output binary name
        OUTPUT_NAME="intergold-preoptimization-cleanup"
        if [ "$GOOS" = "windows" ]; then
            OUTPUT_NAME="${OUTPUT_NAME}.exe"
        fi

        OUTPUT_PATH="$PLATFORM_BIN_DIR/$OUTPUT_NAME"

        # Build the binary
        echo "  Building $app..."
        cd "$PROJECT_ROOT"
        GOOS=$GOOS GOARCH=$GOARCH go build -o "$OUTPUT_PATH" "./cmd/$app"

        echo -e "  ${GREEN}✓${NC} $OUTPUT_PATH"
    done

    echo ""
done

echo -e "${GREEN}Build completed successfully!${NC}"
echo ""
echo "Binaries location: $BIN_DIR"

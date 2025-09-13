#!/usr/bin/env bash
set -euo pipefail

# GuitarAccuracy Build Script
# This script builds the macOS app from the command line without opening Xcode

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CONFIGURATION="Debug"
SCHEME="GuitarAccuracy"
DESTINATION="platform=macOS"
CLEAN=false
ARCHIVE=false
TEST=false
VERBOSE=false
OUTPUT_DIR="build-output"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build the GuitarAccuracy macOS app from the command line.

OPTIONS:
    -c, --configuration CONFIG    Build configuration (Debug|Release) [default: Debug]
    -s, --scheme SCHEME          Build scheme [default: GuitarAccuracy]
    -d, --destination DEST       Build destination [default: platform=macOS]
    -o, --output-dir DIR         Output directory [default: build]
    --clean                       Clean build folder before building
    --archive                     Create archive (for distribution)
    --test                        Run tests after building
    -v, --verbose                 Verbose output
    -h, --help                    Show this help message

EXAMPLES:
    $0                           # Build Debug configuration
    $0 --configuration Release   # Build Release configuration
    $0 --clean --test            # Clean build and run tests
    $0 --archive                 # Create distribution archive
    $0 --verbose                 # Build with verbose output

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -s|--scheme)
            SCHEME="$2"
            shift 2
            ;;
        -d|--destination)
            DESTINATION="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --archive)
            ARCHIVE=true
            shift
            ;;
        --test)
            TEST=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate configuration
if [[ "$CONFIGURATION" != "Debug" && "$CONFIGURATION" != "Release" ]]; then
    print_error "Invalid configuration: $CONFIGURATION. Must be 'Debug' or 'Release'"
    exit 1
fi

# Change to project root
cd "$(git rev-parse --show-toplevel)"

print_status "Building GuitarAccuracy..."
print_status "Configuration: $CONFIGURATION"
print_status "Scheme: $SCHEME"
print_status "Destination: $DESTINATION"
print_status "Output Directory: $OUTPUT_DIR"

# Check if XcodeGen is available
if ! command -v xcodegen >/dev/null 2>&1; then
    print_warning "XcodeGen not found. Installing via Homebrew..."
    if ! command -v brew >/dev/null 2>&1; then
        print_error "Homebrew not found. Please install Homebrew first: https://brew.sh"
        exit 1
    fi
    brew install xcodegen
fi

# Generate Xcode project if needed
print_status "Generating Xcode project..."
pushd macos >/dev/null
xcodegen generate --use-cache
popd >/dev/null

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Set up xcodebuild command
XCODEBUILD_CMD="xcodebuild -project macos/GuitarAccuracy.xcodeproj -scheme $SCHEME -configuration $CONFIGURATION -destination '$DESTINATION'"

# Add output directory
XCODEBUILD_CMD="$XCODEBUILD_CMD -derivedDataPath $OUTPUT_DIR/DerivedData"

# Add verbose flag if requested
if [[ "$VERBOSE" == true ]]; then
    XCODEBUILD_CMD="$XCODEBUILD_CMD -verbose"
fi

# Clean if requested
if [[ "$CLEAN" == true ]]; then
    print_status "Cleaning build folder..."
    eval "$XCODEBUILD_CMD clean"
fi

# Build or archive
if [[ "$ARCHIVE" == true ]]; then
    print_status "Creating archive..."
    ARCHIVE_PATH="$OUTPUT_DIR/GuitarAccuracy.xcarchive"
    eval "$XCODEBUILD_CMD -archivePath '$ARCHIVE_PATH' archive"
    print_success "Archive created at: $ARCHIVE_PATH"
else
    print_status "Building app..."
    eval "$XCODEBUILD_CMD build"
    
    # Find the built app
    APP_PATH=$(find "$OUTPUT_DIR/DerivedData" -name "GuitarAccuracy.app" -type d | head -1)
    if [[ -n "$APP_PATH" ]]; then
        print_success "App built successfully at: $APP_PATH"
    else
        print_warning "Could not locate built app in DerivedData"
    fi
fi

# Run tests if requested
if [[ "$TEST" == true ]]; then
    print_status "Running tests..."
    eval "$XCODEBUILD_CMD test"
    print_success "Tests completed"
fi

print_success "Build completed successfully!"

# Show useful information
if [[ "$ARCHIVE" == false ]]; then
    echo ""
    print_status "Useful commands:"
    echo "  Open project in Xcode: open macos/GuitarAccuracy.xcodeproj"
    if [[ -n "$APP_PATH" ]]; then
        echo "  Run the app: open '$APP_PATH'"
    fi
    echo "  Clean build: $0 --clean"
    echo "  Build Release: $0 --configuration Release"
    echo "  Run tests: $0 --test"
fi

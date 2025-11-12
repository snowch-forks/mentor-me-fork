#!/bin/bash

# MentorMe - Optimized Android Build Script
# This script creates optimized APKs for different scenarios
#
# Usage:
#   ./build_android.sh [build_type]
#
# Arguments:
#   build_type  Optional. Build type number (1-4)
#               1: Development (debug)
#               2: Single optimized APK
#               3: Split APKs by architecture (recommended)
#               4: App Bundle for Play Store
#
# Examples:
#   ./build_android.sh       # Interactive mode
#   ./build_android.sh 3     # Build split APKs directly

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Show help if requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "🏗️  MentorMe - Android Build Script"
    echo "===================================="
    echo ""
    echo "Usage: ./build_android.sh [build_type]"
    echo ""
    echo "Build Types:"
    echo "  1  Development (debug, fastest build)"
    echo "  2  Single optimized APK (all architectures, ~40-50MB)"
    echo "  3  Split APKs by architecture (recommended, ~20-30MB each)"
    echo "  4  App Bundle for Play Store (smallest download)"
    echo ""
    echo "Examples:"
    echo "  ./build_android.sh       # Interactive mode"
    echo "  ./build_android.sh 3     # Build split APKs directly"
    echo ""
    exit 0
fi

echo "🏗️  MentorMe - Android Build"
echo "===================================="
echo ""

# Clean previous builds
echo -e "${BLUE}📦 Cleaning previous builds...${NC}"
flutter clean
flutter pub get
echo -e "${GREEN}✓ Clean complete${NC}"
echo -e "${BLUE}Note: Localization files will be generated automatically during build${NC}"
echo ""

# Generate build info with git commit hash
echo -e "${BLUE}📝 Generating build info...${NC}"
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT_SHORT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p lib/config
cat > lib/config/build_info.dart <<EOF
// lib/config/build_info.dart
// Auto-generated during build - DO NOT EDIT MANUALLY
// Generated at: $BUILD_TIMESTAMP

class BuildInfo {
  // Git commit hash from when the app was built
  static const String gitCommitHash = '$GIT_COMMIT';

  // Short version of commit hash (first 7 characters)
  static const String gitCommitShort = '$GIT_COMMIT_SHORT';

  // Build timestamp (UTC)
  static const String buildTimestamp = '$BUILD_TIMESTAMP';

  // Helper to get formatted build info
  static String get formattedInfo => 'Build: \$gitCommitShort';
  static String get fullInfo => '\$gitCommitShort (\$buildTimestamp)';
}
EOF

echo -e "${GREEN}✓ Build info generated (commit: $GIT_COMMIT_SHORT)${NC}"
echo ""

# Check if build type provided as CLI argument
if [ -n "$1" ]; then
    choice="$1"
    echo -e "${BLUE}Using build type from argument: $choice${NC}"
    echo ""
else
    # Prompt user for build type
    echo -e "${YELLOW}Choose build type:${NC}"
    echo "1) Development (debug, fastest build)"
    echo "2) Single optimized APK (all architectures, ~40-50MB)"
    echo "3) Split APKs by architecture (recommended, ~20-30MB each)"
    echo "4) App Bundle for Play Store (smallest download)"
    echo ""
    read -p "Enter choice [1-4]: " choice
fi

case $choice in
    1)
        echo -e "${BLUE}🔨 Building debug APK...${NC}"
        flutter build apk --debug
        echo -e "${GREEN}✓ Build complete!${NC}"
        echo -e "Location: ${YELLOW}build/app/outputs/flutter-apk/app-debug.apk${NC}"
        ;;
    2)
        echo -e "${BLUE}🔨 Building optimized universal APK...${NC}"
        flutter build apk --release --shrink
        echo -e "${GREEN}✓ Build complete!${NC}"
        echo -e "Location: ${YELLOW}build/app/outputs/flutter-apk/app-release.apk${NC}"
        ;;
    3)
        echo -e "${BLUE}🔨 Building split APKs by architecture...${NC}"
        flutter build apk --release --split-per-abi --shrink
        echo -e "${GREEN}✓ Build complete!${NC}"
        echo ""
        echo -e "${YELLOW}Generated APKs:${NC}"
        echo "  • app-armeabi-v7a-release.apk (32-bit ARM - older devices)"
        echo "  • app-arm64-v8a-release.apk (64-bit ARM - most modern devices)"
        echo "  • app-x86_64-release.apk (Intel/AMD - emulators/tablets)"
        echo ""
        echo -e "${GREEN}For most devices, use: app-arm64-v8a-release.apk${NC}"
        echo -e "Location: ${YELLOW}build/app/outputs/flutter-apk/${NC}"
        ;;
    4)
        echo -e "${BLUE}🔨 Building App Bundle for Play Store...${NC}"
        flutter build appbundle --release
        echo -e "${GREEN}✓ Build complete!${NC}"
        echo -e "Location: ${YELLOW}build/app/outputs/bundle/release/app-release.aab${NC}"
        echo ""
        echo -e "${GREEN}Upload this .aab file to Google Play Console${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice: $choice${NC}"
        echo -e "${YELLOW}Please choose 1-4. Run './build_android.sh --help' for usage.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}===================================="
echo "Build completed successfully! 🎉"
echo -e "====================================${NC}"

# Show size analysis option
if [ "$choice" != "1" ]; then
    echo ""
    read -p "Would you like to see size analysis? [y/N]: " analyze
    if [ "$analyze" = "y" ] || [ "$analyze" = "Y" ]; then
        echo -e "${BLUE}📊 Analyzing build size...${NC}"
        flutter build apk --release --analyze-size
    fi
fi
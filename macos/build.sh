#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Local output avoids Finder/iCloud metadata breaking app code signing in Documents.
MAC_BUILD_DIR="${FONADO_MAC_BUILD_DIR:-/private/tmp/FonadoMacNativeBuild}"
MAC_PROJECT="macos/FonadoMac.xcodeproj"
xcodebuild -project "$MAC_PROJECT" -scheme FonadoMac \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$MAC_BUILD_DIR" \
  -clonedSourcePackagesDirPath build/MacSourcePackages build
printf '\nApp (Liblinphone): %s/Build/Products/Debug/Fonado.app\n' "$MAC_BUILD_DIR"

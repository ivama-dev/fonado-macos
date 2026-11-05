#!/bin/bash
set -euo pipefail
MAC_BUILD_DIR="${FONADO_MAC_BUILD_DIR:-/private/tmp/FonadoMacNativeBuild}"
APP="$MAC_BUILD_DIR/Build/Products/Debug/Fonado.app"
codesign --verify --deep --strict "$APP"
"$APP/Contents/MacOS/Fonado" --check-telephony
"$APP/Contents/MacOS/Fonado" --check-sip-lifecycle
"$APP/Contents/MacOS/Fonado" --check-authentication

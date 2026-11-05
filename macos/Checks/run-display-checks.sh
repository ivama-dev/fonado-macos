#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
DISPLAY_CHECK_DIR="${FONADO_DISPLAY_CHECK_DIR:-/private/tmp/FonadoMacDisplayChecks}"
mkdir -p "$DISPLAY_CHECK_DIR/module-cache"
swiftc -parse-as-library -module-cache-path "$DISPLAY_CHECK_DIR/module-cache" \
  macos/FonadoMac/MacDisplayScale.swift macos/Checks/DisplayScaleChecks.swift \
  -o "$DISPLAY_CHECK_DIR/DisplayScaleChecks"
"$DISPLAY_CHECK_DIR/DisplayScaleChecks"

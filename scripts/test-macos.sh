#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS=(--disable-xctest --package-path "$ROOT_DIR/macos/CodexUsageStatus")
# The standalone CLT install needs explicit Testing framework and macro paths.
if [[ "${DEVELOPER_DIR:-}" == "/Library/Developer/CommandLineTools" ]]; then
  FRAMEWORKS="$DEVELOPER_DIR/Library/Developer/Frameworks"
  ARGS+=(--build-system native -Xswiftc "-F$FRAMEWORKS"
    -Xswiftc -plugin-path -Xswiftc "$DEVELOPER_DIR/usr/lib/swift/host/plugins/testing"
    -Xlinker "-F$FRAMEWORKS" -Xlinker -rpath -Xlinker "$FRAMEWORKS")
fi
swift test "${ARGS[@]}"

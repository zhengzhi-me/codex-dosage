#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/macos/CodexUsageStatus"
DIST_DIR="$ROOT_DIR/dist"
OUTPUT_APP="$DIST_DIR/Codex Dosage.app"
BUILD_WORK="$(mktemp -d "${TMPDIR:-/tmp}/codex-dosage-build.XXXXXX")"
trap 'rm -rf "$BUILD_WORK"' EXIT
APP_DIR="$BUILD_WORK/Codex Dosage.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
VERSION="${VERSION:-0.1.0}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-13.0}"

detect_hardware_arch() {
  local machine
  machine="$(uname -m)"

  if [[ "$machine" == "x86_64" ]]; then
    if [[ "$(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null || true)" == "1" ]]; then
      echo "arm64"
      return
    fi
  fi

  echo "$machine"
}

BUILD_ARCH="${BUILD_ARCH:-$(detect_hardware_arch)}"

case "$BUILD_ARCH" in
  arm64 | x86_64)
    ;;
  *)
    echo "Unsupported BUILD_ARCH '$BUILD_ARCH'. Use arm64 or x86_64." >&2
    exit 1
    ;;
esac

TRIPLE="${BUILD_ARCH}-apple-macosx${MACOSX_DEPLOYMENT_TARGET}"
BUILD_ARGS=(
  --package-path "$SWIFT_DIR"
  -c release
  --triple "$TRIPLE"
)

BUILD_ARGS+=(--build-system native)

swift build "${BUILD_ARGS[@]}"
BINARY_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
BINARY_PATH="$BINARY_DIR/CodexUsageStatus"

if [[ ! -x "$BINARY_PATH" ]]; then
  echo "Build succeeded, but expected binary was not found at $BINARY_PATH" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$CONTENTS_DIR/Resources"

cp -X "$BINARY_PATH" "$MACOS_DIR/CodexUsageStatus"
"$ROOT_DIR/scripts/build-icon.sh" "$CONTENTS_DIR/Resources/AppIcon.icns"
cp -X "$ROOT_DIR/LICENSE" "$CONTENTS_DIR/Resources/LICENSE"
cp -X "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$CONTENTS_DIR/Resources/THIRD_PARTY_NOTICES.md"
mkdir -p "$CONTENTS_DIR/Resources/licenses"
cp -X "$ROOT_DIR/licenses/Lucide-LICENSE" "$CONTENTS_DIR/Resources/licenses/Lucide-LICENSE"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CodexUsageStatus</string>
  <key>CFBundleIdentifier</key>
  <string>dev.local.CodexUsageStatus</string>
  <key>CFBundleName</key>
  <string>Codex Dosage</string>
  <key>CFBundleDisplayName</key>
  <string>Codex Dosage</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>__VERSION__</string>
  <key>CFBundleVersion</key>
  <string>__VERSION__</string>
  <key>LSMinimumSystemVersion</key>
  <string>__MIN_MACOS__</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>MIT</string>
</dict>
</plist>
PLIST

/usr/bin/sed -i '' "s/__VERSION__/$VERSION/g" "$CONTENTS_DIR/Info.plist"
/usr/bin/sed -i '' "s/__MIN_MACOS__/$MACOSX_DEPLOYMENT_TARGET/g" "$CONTENTS_DIR/Info.plist"

/usr/bin/xattr -cr "$APP_DIR"
codesign --force --sign "$CODESIGN_IDENTITY" "$APP_DIR" >/dev/null
codesign --verify --deep --strict "$APP_DIR"

# Sign outside synced storage so Finder metadata cannot race with codesign.
mkdir -p "$DIST_DIR"
rm -rf "$OUTPUT_APP"
ditto --norsrc --noextattr "$APP_DIR" "$OUTPUT_APP"

echo "$OUTPUT_APP"

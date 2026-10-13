#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/Codex Dosage.app"
VERSION="${VERSION:-0.1.0}"
ARCHES=("arm64" "x86_64")

rm -f "$DIST_DIR"/Codex-Dosage-"$VERSION"-macos-*.zip "$DIST_DIR/SHA256SUMS.txt"

for arch in "${ARCHES[@]}"; do
  BUILD_ARCH="$arch" "$ROOT_DIR/scripts/build-macos-app.sh" >/dev/null
  ZIP_NAME="Codex-Dosage-${VERSION}-macos-${arch}.zip"
  ditto -c -k --norsrc --noextattr --keepParent "$APP_DIR" "$DIST_DIR/$ZIP_NAME"
done

(
  cd "$DIST_DIR"
  openssl dgst -sha256 -r Codex-Dosage-"$VERSION"-macos-*.zip > SHA256SUMS.txt
)

"$ROOT_DIR/scripts/build-macos-app.sh" >/dev/null

echo "$DIST_DIR"

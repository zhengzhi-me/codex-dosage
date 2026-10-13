# Codex Dosage 0.2.2 — local release validation

Date: 2026-10-13. Local Apple Silicon package; not published or installed into /Applications.

- App name and display name: Codex Dosage. Bundle identifier remains `dev.local.CodexUsageStatus` to preserve preferences. Internal Swift target/executable name stays unchanged.
- User-approved image copied unchanged to `assets/app-icon.png`. SHA256: `bdf4b63fd0dc50c80851dd837b40c8060c1517f4f0df4bcd1c5dafda1eacf3c3`.
- `build-icon.sh` resizes this image with sips and creates AppIcon.icns with iconutil; no design edits. Final ICNS extracted successfully with all ten 16–1024 pixel variants. Info.plist references AppIcon.
- Swift release build succeeded, targeting macOS 13. arm64 executable confirmed with file.
- Node tests: 8 passed. Swift tests: 9 passed. Shell syntax checks passed.
- Signed in a temporary directory to avoid iCloud Finder metadata racing with codesign; package excludes extended attributes.
- Final ZIP extracted to `/private/tmp/codex-dosage-v022-verify`; `codesign --verify --deep --strict` passed.
- Extracted executable `--once` successfully read real usage using the official local app-server.
- Extracted app launched in explicit demo mode; accessibility inspection identified the app as Codex Dosage and showed the complete quota/card panel, taller footer buttons, and date/time display. Demo process stopped after inspection.
- Prior Chinese/light and English/dark visual layout checks are recorded in `validation-icon-panel-refinement.md`.

Artifact: `dist/Codex-Dosage-0.2.2-macos-arm64.zip`

SHA256: `d5f6250df3b52ad94f569cc25350924b0d53ac34759eb52b057cfbe133cea596`

Ad-hoc signed, not Developer ID notarized. Intel build and macOS 13 runtime were not tested in this release.

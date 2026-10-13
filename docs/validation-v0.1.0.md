# Codex Dosage V0.1.0 — local release

Date: 2026-10-13. First independent `codex-dosage` version. The previous 0.2.x versions describe local development before this version reset; see development-history.md.

- Renamed workspace directory to `codex-dosage`; npm package name and version updated, as are Swift and Node app-server client version metadata and build/package defaults.
- User-supplied SVG is `assets/logo.svg`; supplied 480 × 480 PNG is copied unchanged to `assets/app-icon.png`. README uses SVG; macOS ICNS uses resized PNG variants without any design edits.
- SVG SHA256: `d89bd14dfb90498e93326427e2bac5eb79e653c5482a51697a48a00505db99dd`.
- PNG SHA256: `5ee1ad54fd8adda4e67f0f7cc4209185e4fcdc8d2e861df710a67f72ca17fd63`.
- Older icon drafts moved to ignored `dist/design-history/`; build references only approved app-icon.png.
- Original LICENSE preserved and bundled into app Resources. READMEs identify upstream and clarify independent third-party status.
- Apple Silicon release build succeeded. ZIP extracted to `/private/tmp/codex-dosage-v010-verify`; strict/deep signature verification passed. Info.plist name is Codex Dosage; both version fields are 0.1.0. Bundle identifier preserved for preference compatibility.
- Bundled LICENSE matched source byte-for-byte. ICNS extracted successfully; extracted 512 px icon visually checked against approved PNG.
- Extracted executable `--once` read real account quotas successfully. Node tests: 8 passed; Swift tests: 9 passed. Shell syntax checks passed.

Artifact: `dist/Codex-Dosage-0.1.0-macos-arm64.zip`.

SHA256: `81f0f1161e25977b3890f1b7ddace22cc32b75e6d3400a229f3fe690c9554814`.

Local ad-hoc signature; not notarized. Public release packages additionally include the Lucide/Feather icon license and third-party notices. Intel and macOS 13 runtime untested. Existing local release ZIPs retained for history; this package contains the new approved icon.

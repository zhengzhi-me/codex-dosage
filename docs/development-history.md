# Changelog

## 0.2.2 — 2026-10-13

- Rename the application to Codex Dosage while preserving its bundle identifier and existing preferences.
- Include the approved black-and-white application icon at all macOS icon sizes.
- Add vertical space inside the usage panel Settings and Refresh buttons.
- Show the last update date and time as `MM/dd HH:mm:ss` in the system time zone.

## 0.2.1 — 2026-10-13

- Show the complete usage panel without scrolling, using compact system fonts and intrinsic content sizing.
- Rename the panel header to Codex and remove keyboard focus from the close button.
- Add Automatic / Manual application discovery settings with persisted selection and migration from 0.2.0.
- Show the detected application bundle path in automatic mode; show the chooser only in manual mode.
- Narrow Settings and shorten the display-style label.

## 0.2.0 — 2026-10-13

- Discover official applications by bundle identity and supported executable layouts; choose custom `.app` locations in Settings.
- Add a transient usage popover with quota bars, reset-card details, balances and refresh status.
- Add System / Simplified Chinese / English UI selection and Chinese documentation.
- Preserve unknown quota values and avoid labeling unrelated metered buckets as Codex.
- Add Swift and Node tests for application resolution, reset-card compatibility and split Unicode JSON-RPC responses.
- Keep reset cards read-only and existing menu-bar badge preferences compatible.

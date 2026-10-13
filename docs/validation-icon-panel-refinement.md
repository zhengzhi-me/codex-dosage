# Icon and panel refinement — 2026-10-13

Status: source and icon preview only; no new release package or icon integration.

- Footer buttons now use 6 pt vertical text padding and 10 pt horizontal padding with the bordered style.
- Last successful refresh uses `MM/dd HH:mm:ss` in the system time zone.
- Demo mode initializes its update time so the full footer can be checked.
- Swift compilation succeeded; all 9 Swift tests passed.
- Same panel view inspected in the isolated preview window: Chinese/light and English/dark. Both showed the full date/time and taller buttons without clipping. This does not constitute a new production popover interaction test.

Icon preview: `assets/app-icon-preview-v3.png`, generated with the built-in imagegen tool. The bottom gap and four dots are preserved, with an empty center in the woven mark. Read-only raster inspection fitted the outer arc to a circle with radius 434.9 px; mean radial deviation 1.0 px, maximum 4.5 px. The raster is visually circular, not a mathematically exact vector circle.

Final edit prompt:

> Precise geometric icon refinement only. Preserve this approved design exactly: white rounded square tile, central six-loop black woven mark without any small inner hexagonal ring, downward opening outer circular arc, four dots at bottom. Reconstruct outer arc with compass precision: true circle equal X and Y radius, not ellipse, centered with central knot. Uniform outer arc stroke must be SAME THICKNESS as black center knot ribbon, approx 58 pixels on this 1254px square reference (increase current outer stroke slightly). Round arc ends. Four identical perfect-circle black dots equally spaced ON THAT SAME circular centerline in bottom gap; each dot DIAMETER must equal arc stroke width (reduce dots from current size), same visual weight as central knot. Preserve all other geometry, central mark shape and empty center. Pure black and white, extremely crisp smooth edges, no texture, no shadow, no perspective. A single square front-facing icon preview. Tile edges clean without ragged pixels, transparency only outside rounded-square white tile.

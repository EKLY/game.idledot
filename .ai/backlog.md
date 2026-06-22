# Backlog

- Place buildings/tiles on the grid (data-driven placement, locked/empty/upgradeable states)
- Implement the map detail popup (lightweight peek on tap before the full bottom sheet) — see KB [[UI]]
- Wire real economy data into the top bar and bottom sheet (replace mockup placeholders)
- Close the bottom sheet when tapping outside the panel (per docs/UI_SPEC_MAP.md)
- Verify the ₿ / ✦ / ✕ glyphs render in Godot's font; swap to icons or plain text if missing
- Add safe-area padding for the top bar and bottom sheet (iOS/Android)
- Optional: tile-line culling if the initial 100x100 grid draw stutters

## Map objects & terrain (concept locked — drawn, not sprites; see KB [[Map Objects]])

- Occupancy grid: track which cells are free/used — the foundation everything below queries
- Multi-cell building footprints (e.g. road = 1 cell, farm = 4-6 cells): size + origin per building, validate the footprint is free, mark occupied
- Procedural terrain drawn (no sprites): rivers as thick pencil paths, mountains as contour-line regions, forests as clustered scatter
- (Optional / perf) Make scatter skip occupied cells once the occupancy grid exists — grass-over-terrain is already solved by layering (scatter drawn below terrain), so this is only for perf + cleaning up grass poking out at mountain-cell corners
- Render order (current): paper+grid -> scatter -> terrain -> buildings -> UI (default map monochrome, player buildings coloured); siblings ordered in map.tscn, node-above = drawn-below

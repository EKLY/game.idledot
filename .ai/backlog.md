# Backlog

- Implement the map detail popup (lightweight peek on tap before the full bottom sheet) — see KB [[UI]]
- Wire real economy data into the top bar and bottom sheet (replace mockup placeholders)
- Close the bottom sheet when tapping outside the panel (per docs/UI_SPEC_MAP.md)
- Verify the ₿ / ✦ / ✕ / ⚙ glyphs render in Godot's font; swap to icons or plain text if missing
- Add safe-area padding for the top bar and bottom sheet (iOS/Android)
- Optional: culling / LOD for grid lines + scatter if drawing the full 100x100 map stutters
- River terrain — deferred; the path-based curve looked off, retry later (maybe cell-based)
- Dialog open/close animation (fade/scale) — optional polish
- Serialise WorldData to JSON (user://) when save/load lands

(Buildings & roads are now tracked in `.ai/plan-buildings.md`, not here.)

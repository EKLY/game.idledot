# memory.md

## Current State

- Godot 4.6 / GDScript, mobile portrait. Entry scene: `scenes/map.tscn`. No autoloads yet.
- The map is now **data-driven**: `WorldData` (`scripts/world_data.gd`, RefCounted) is the source of truth, generated once from a seed in `map.gd._ready`.
  - `resources[]` = mountains / ponds (placed, reserve cells via `occupancy`).
  - `cell_kind[]` = per-cell scatter, one kind each: EMPTY / GRASS / PEBBLE / TREE / BOULDER.
  - Query: `kind_at`, `is_occupied`, `label_at`. Detail (sub-positions/sizes/counts) is still hashed per cell at draw time — we store the layout, not every blade.
- Renderers READ WorldData:
  - `map.gd` — pencil-sketch grid (Node2D + Camera2D, pan/zoom), generates the world, sets viewport clear-color = paper.
  - `tile_decorator.gd` (node `Decorations`) — grass tufts + pebbles, mono.
  - `terrain.gd` (node `Terrain`) — mountains, ponds, fan-tuft broadleaf trees, 3-tier boulders, mono with pencil wobble. (Conifer trees + a path-based river were tried then removed.)
  - `cell_selector.gd` (node `Selection`) — blue highlight on the selected cell.
- Camera: pan/zoom + `pan_overscroll` (pan half a screen past top/bottom so tiles aren't hidden behind the bars); `set_pan_enabled(false)` freezes map input (used by the dialog).
- UI (`scripts/ui.gd`):
  - `sketch_box.gd` (`SketchBox`) — reusable hand-drawn frame (paper fill, wobble border, rounded corners, soft shadow, paper-stain NoiseTexture2D). Used by top bar AND bottom sheet.
  - Bottom sheet shows the selected cell's content via `world.label_at` (Mountain/Pond/Forest/Boulder/Grassland/Pebbles/Empty) + coords. income/upgrade still mockup.
  - `dialog.gd` (`CenterDialog`) — reusable centred modal (backdrop + SketchBox), opened by the ⚙ Settings button; freezes the map while open.

## Current Focus / Next

- Next: **Buildings & Roads** — follow `.ai/plan-buildings.md` (start Step 1: WorldData buildings/roads + `can_place`). Placeholder render first, roads manual+validate first, sprites later.

## Knowledge Base

- File-based Obsidian vault at `D:\project\unno.knowledge\knowledge\Projects\UNNO\Game Idledot\`.
- Notes: `Game Idledot` (index), `Map Grid`, `Map Objects`, `UI`. Log meaningful work here.

## Constraints / Rules

- User handles git commits/pushes — do NOT auto-commit or push.
- `.ai/*.md` English-only. JSON-only configs in `config/`. Save = JSON in `user://` (not built yet).
- No Godot CLI locally — can't verify headless; the user runs the editor to test.
- Default map stays mono (pencil); only player buildings get colour.

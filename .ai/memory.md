# memory.md

## Current State

- Project root: `d:\project\game.idledot`
- Engine: Godot 4.6
- Language: GDScript
- The old system (autoloads, economy, bottom sheet, config, sprites) was fully wiped to rewrite from scratch.
- Main scene: `scenes/map.tscn` (welcome screen was removed; map is the entry point).
- Scenes: `scenes/map.tscn`
- Scripts: `scripts/map.gd`
- No autoloads registered (removed from `project.godot`).
- No `config/` and no `assets/` yet (deleted; to be rebuilt).
- Design docs kept under `docs/` (UI_SPEC_MAP, ECONOMY_SPEC, DATA_SCHEMA, PIXEL_ART_SPEC, UI_SPEC_BUILDING_PANEL, AI_PLAN) — primary reference for the rewrite.

## Current Focus

- Map is a large pannable/zoomable pencil-sketch grid in `scripts/map.gd` (no image assets). Scene root is `Node2D` + child `Camera2D`; grid drawn once in world space, camera handles pan/zoom.
- Size: 100x100 tiles, cell 32px (world 3200x3200). Interior lines only (no border).
- Pencil look via `_draw()` + `FastNoiseLite` using `draw_polyline_colors` (wobble, multi-pass graphite, overshoot, edge fade; pressure-width dropped for perf).
- Input: mouse drag pan + wheel zoom; touch one-finger pan + two-finger pinch zoom. Tap (< `tap_threshold`) selects a tile, prints `(x,y)`, and emits `tile_selected`.
- UI mockup added (`scripts/ui.gd`, UI nodes in `scenes/map.tscn`): a `CanvasLayer` with a fixed top bar (Money/Trend/Prestige placeholders) and a bottom sheet that slides up on `tile_selected`. Popup is planned, not built.
- See KB notes [[Map Grid]] and [[UI]] for full details.

## Known Issues / TODO

- Validate scenes/scripts open without error in Godot editor (no Godot CLI available locally to verify headless).
- Next steps for the grid (per `docs/UI_SPEC_MAP.md`): data-driven tile placement, locked/empty tile states, bottom-sheet host, visual state cues.

## Knowledge Base

- File-based KB (Obsidian vault) at `D:\project\unno.knowledge\knowledge\Projects\UNNO\Game Idledot\`.
- Index note `Game Idledot.md`; topic notes per system (e.g. `Map Grid.md`).
- After each meaningful piece of work, record details in the KB (see `.ai/spec.md` -> Knowledge Base).

## Constraints / Rules to Follow

- User handles git commits/pushes themselves — do NOT auto-commit or push.
- All `.ai/*.md` files must remain English-only.
- Follow `docs/PIXEL_ART_SPEC.md` for pixel art rules.
- JSON-only configs in `config/`.
- Save format is JSON in `user://` with versioning.


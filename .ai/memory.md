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

- Map grid drawn procedurally in `scripts/map.gd` (no image assets): pencil/hand-sketch look via `_draw()` + `FastNoiseLite` — wobbled strokes, multi-pass low-opacity graphite, overshoot, varied stroke weight. Default 12x12 to match `source/concept/grid.png`.
- Only interior grid lines are drawn (outer border removed). Tap on a tile prints its `(x,y)` coords.

## Known Issues / TODO

- Validate scenes/scripts open without error in Godot editor (no Godot CLI available locally to verify headless).
- Next steps for the grid (per `docs/UI_SPEC_MAP.md`): data-driven tile placement, locked/empty tile states, bottom-sheet host, visual state cues.

## Knowledge Base

- File-based KB (Obsidian vault) at `D:\project\unno.knowledge\knowledge\Projects\UNNO\Game Idledot\`.
- Index note `Game Idledot.md`; topic notes per system (e.g. `Map Grid.md`).
- After each meaningful piece of work, record details in the KB (see `.ai/spec.md` -> Knowledge Base).

## Constraints / Rules to Follow

- All `.ai/*.md` files must remain English-only.
- Follow `docs/PIXEL_ART_SPEC.md` for pixel art rules.
- JSON-only configs in `config/`.
- Save format is JSON in `user://` with versioning.


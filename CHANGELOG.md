# Changelog

## 2026-06-23

- spec: pivot the economy from idle-exponential (money only) to a Colonists-style **production chain** — add material resources (`ore`/`log`/`fish`/`crop` → `metal`/`plank`/`food` → `goods`), a stockpile + input-constrained production model, and the rule that extractors bind to adjacent terrain; drop the "no extra resources in MVP" rule; rework Buildings archetypes into chain tiers.
- world: extend `WorldData` with player structures — `buildings` / `building_cells` / `roads`, plus `can_place`, `place_building`, `place_road`, `remove_at`, and `is_adjacent_to_terrain` (extractor binding) — validated the same way terrain reserves cells (plan-buildings Step 1).
- config: add `config/buildings.json` — the first config file — a 12-building catalog (id, name, size, color, tier, requires, inputs, outputs) spanning the full chain with fictional system-satire names; load via new `scripts/building_catalog.gd` (`BuildingCatalog.load_all`, typed entries) (plan-buildings Step 2).
- map: add a temporary `_selftest_buildings()` that prints the catalog + exercises the buildings/roads data model in the Output panel (to be removed when the Step 3-4 build UI / render node land).
- kb: add `Economy` note (production chain + catalog + placement); update `Map Objects`, `Game Idledot` index.

## 2026-06-22

- ui: add reusable `SketchBox` hand-drawn frame (paper fill, wobble border, rounded corners, soft shadow, paper-stain noise via NoiseTexture2D); use it for the top bar and bottom sheet; add side/bottom margins so they float as cards.
- map: scatter grass tufts + pebbles per cell (deterministic hash), monochrome grid-line tone (`tile_decorator.gd`).
- terrain: add procedural mountains (1-3 peaks, random heights, snow, foot rocks), fan-tuft broadleaf trees, 3-tier boulders, and still ponds — all hand-drawn mono with pencil wobble (`terrain.gd`). Conifer trees and a path-based river were tried and removed.
- world: introduce `WorldData` (resources + per-cell `cell_kind` + occupancy), generated once from a seed in `map.gd`; terrain & decorator now read it instead of rolling their own noise — query via `kind_at` / `is_occupied` / `label_at`.
- map: add blue selection highlight (`cell_selector.gd`); pan overscroll (half a screen past top/bottom); viewport clear-color = paper; `set_pan_enabled` to freeze input.
- ui: bottom sheet shows the selected cell's content (Mountain/Pond/Forest/Boulder/Grassland/Pebbles/Empty) + coords.
- ui: add reusable `CenterDialog` (backdrop + SketchBox), opened by a new ⚙ Settings button; freezes the map while open.
- plan: draft `.ai/plan-buildings.md` (buildings + roads + manual routing; placeholder render, sprites later).

## 2026-06-19

- spec: migrate legacy `AI_*.md` to `.ai/` (`spec.md`, `memory.md`) and `AI_CHANGELOG.md` to `CHANGELOG.md`; reconcile internal references.
- spec: add `## Knowledge Base` section (file-based Obsidian vault) and the ongoing rule to log work to the KB.
- chore: wipe the old system (autoloads, economy, bottom sheet, config, sprites) to rewrite from scratch; map is now the entry scene (welcome screen removed).
- map: rebuild as a procedural pencil-sketch grid drawn with no image assets (`_draw` + `FastNoiseLite`) — wobble, multi-pass graphite, overshoot, edge fade, random pencil-skip gaps; interior lines only (no border).
- map: make it a large pannable / zoomable world (Node2D + Camera2D), 100x100 tiles at 32px; `draw_polyline_colors` for scale; fix camera `position` overflow at the map edges via manual clamp.
- ui: add mockup top bar (always visible) and bottom sheet (slides up on tile tap) via a `CanvasLayer`; `map.gd` emits `tile_selected`.
- kb: set up file-based KB with `Game Idledot`, `Map Grid`, and `UI` notes (popup recorded as planned).

## 2026-01-28

- Created `AI_MEMORY.md` and `AI_CHANGELOG.md` to match AI spec template requirements.

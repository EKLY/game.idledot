# Changelog

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

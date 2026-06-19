# AI_MEMORY.md

## Current State

- Project root: `d:\project\game.idledot`
- Engine: Godot 4.6
- Language: GDScript
- Main scenes: `scenes/welcome.tscn`, `scenes/main.tscn`
- Autoloads: ConfigService, Economy, SaveService, TimeService, Events, GameState
- Config files present: `config/economy.json`, `config/buildings.json`, `config/missions.json`, `config/events.json`, `config/upgrades_permanent.json`
- Assets: `assets/logo.png`, `assets/sprites/buildings/b001..b009` (+ `_tile` variants), `*_org.png` originals
- Script tooling: `scripts/building_conv.py` (requires Pillow)
- UI: Theme helper in `scripts/ui/theme_helper.gd`

## Current Focus

- Map interaction: panning with mouse/touch; currently debugging drag handling and logging in `scripts/main.gd`
- UI layout: bottom sheet dynamic show/hide with close button

## Known Issues / TODO

- Map drag/pan not working yet; logging added to `scripts/main.gd` to trace input events.
- Ensure `MapContainer` receives input and `MapRoot` stays clamped within view.

## Constraints / Rules to Follow

- All `AI_*.md` files must remain English-only.
- Follow `docs/PIXEL_ART_SPEC.md` for pixel art rules.
- JSON-only configs in `config/`.
- Save format is JSON in `user://` with versioning.


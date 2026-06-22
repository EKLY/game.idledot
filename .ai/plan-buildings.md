# Buildings & Roads
> Status: draft

## Goal

Let the player place coloured, multi-cell buildings and draw roads on the grid,
validated against terrain so nothing can be built over mountains, trees,
boulders, or ponds. Player structures stand out (colour) against the monochrome
sketch terrain. Rendering starts as placeholders and is swappable to sprites
later; roads are drawn manually first, with A* auto-routing as a later add-on.

## Decisions (locked)

- Building render: **placeholder first** (flat coloured rounded rect), designed
  so a sprite layer can replace it without touching data/placement.
- Roads: **manual + validate first** (click/drag cells; can't cross obstacles).
  A* auto-route is a later phase.
- Sprites: **none yet** — keep a clean seam so art drops in later.

## Approach

Extend `WorldData` as the single source of truth (it already owns `occupancy`
and `cell_kind`). Buildings & roads reserve cells the same way mountains/ponds
do, so placement validation is just an occupancy / cell_kind check. A "build
mode" in the UI drives a ghost preview + confirm. A new render node draws
structures above terrain (placeholder now, sprite later). Building types come
from a JSON catalog (config-driven, per spec).

## Steps

1. **Data model** — extend WorldData: `buildings: Array[Dictionary]`
   ({type, origin:Vector2i, size:Vector2i}) and `roads` (Dictionary/Set of
   Vector2i). Helpers: `can_place(origin, size) -> bool` (all footprint cells
   in-bounds, not occupied, cell_kind not TREE/BOULDER and not a resource),
   `place_building(...)`, `place_road(cell)`, `remove_at(cell)`.
   -> verify: a temp hard-coded building shows + reserves its cells (scatter
   avoids them).

2. **Building catalog (config)** — `config/buildings.json`: id, name, size (w x h),
   placeholder colour (later: sprite path, cost, income). Load directly for now;
   formalise into a ConfigService when economy lands.
   -> verify: catalog loads; build UI lists entries.

3. **Placement + build mode** — UI build button -> enter build mode -> ghost
   follows the tapped/hovered cell, tinted valid/invalid via `can_place` -> tap
   confirms (place_building) -> exit. Cancel via back/dialog. Reuse the
   `set_pan_enabled` pattern so taps mean "place", not "select".
   -> verify: place on free cells, blocked on obstacles, occupancy updates.

4. **Building render node** — draws each building footprint as a flat coloured
   rounded rect (placeholder) above terrain, below UI. Keep the per-building draw
   in one function so swapping to `draw_texture` (sprite) later is a one-spot
   change.
   -> verify: placed buildings render at the right cells / size.

5. **Roads — manual + validate** — road build mode: click/drag cells to lay road
   (each must pass road `can_place`). Render roads as connected segments,
   auto-picking straight / corner / T / cross from neighbours.
   -> verify: a road stops at obstacles; junctions render correctly.

6. **(Later) Sprite rendering** — add sprite paths to the catalog; swap the
   placeholder draw for `draw_texture` scaled to the footprint.

7. **(Later) A* auto-route** — pick start/end; A* over free cells (obstacles =
   walls) lays a road along the path.

## Risks / Notes

- **Render layer order** — roads & buildings sit above terrain but below the
  selection highlight / UI; roads likely below buildings. Current order:
  grid -> scatter -> terrain -> [roads -> buildings] -> selection -> UI.
- **Build-mode input** — must coexist with pan/zoom; reuse `set_pan_enabled` or
  a dedicated mode flag so a tap places instead of selecting a tile.
- **Occupancy granularity** — a building reserves a w x h block; `can_place`
  must check every footprint cell and removal must free them all.
- **Save** — WorldData isn't serialised yet; buildings/roads will need it when
  save/load lands (separate backlog item).
- **Performance** — buildings/roads are sparse + static; redraw their node only
  on change, never per frame.

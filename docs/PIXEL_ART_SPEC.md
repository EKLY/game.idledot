# PIXEL_ART_SPEC.md

> Subordinate to AI_SPEC.md. If any conflict exists, AI_SPEC.md overrides this document.

---

## 1) Scope & Purpose

**Controls**
- All 2D pixel art assets used in-game, including buildings, terrain, UI map icons, and effects sprites.
- Authoring rules, palette rules, lighting rules, and file naming rules for pixel art.

**Does NOT control**
- Non-pixel UI layout, typography, or UX behavior.
- Audio, VFX particles, or 3D assets.
- Economy rules, balancing, or gameplay logic.

---

## 2) Canvas & Scaling Rules

- Authoring resolution MUST be exactly 32x32 px per tile/sprite.
- In-game rendering MUST use integer scaling only.
- Allowed scales: 2x (64x64), 3x (96x96), 4x (128x128).
- The same asset MUST NOT be rendered at non-integer scale.
- Rotation and skewing MUST NOT be used on pixel art sprites.
- Sub-pixel positioning MUST NOT be used; positions must land on whole pixels after scaling.

---

## 3) Perspective & Composition

- Camera perspective MUST be top-down 3/4.
- Roof-to-wall ratio MUST be 60% roof / 40% wall height within the 32x32 box.
- Buildings MUST read clearly from the map at 2x scale.
- Silhouettes MUST be distinguishable by shape alone at 64x64.
- Avoid extreme foreshortening; top surfaces must be visible but not dominant.

---

## 4) Color & Palette Policy

- Maximum colors per sprite: 12 (including outline and highlights).
- Saturation must be moderate; no fully saturated neon colors.
- Accent colors MUST be limited to 1 per sprite and occupy <= 10% of pixels.
- Forbidden colors:
  - Pure white (#FFFFFF) and pure black (#000000) for large fills.
  - Fully transparent internal holes unless intentional cutouts.
- Use consistent hue families for a building set to prevent visual noise.

---

## 5) Lighting & Outline Rules

- Light direction MUST be from top-left.
- Shadows MUST fall to bottom-right.
- Outlines MUST be 1px and use a darker shade of the local color, not pure black.
- Highlighting MUST be done with one lighter shade per material.
- Avoid heavy dithering; use flat clusters with clean edges.

---

## 6) Detail Density Rules

- Details MUST be readable at 2x scale without zoom.
- Use 1-2 pixel highlights to imply materials; do not draw micro-text.
- Large surfaces MUST be broken with at most 2 simple features (e.g., door + sign).
- MUST NOT use:
  - Single-pixel noise patterns
  - Text smaller than 4x4 px
  - Subtle gradients or banded dithering
  - Thin lines less than 1px (anti-aliased lines)

---

## 7) Animation Rules (Optional Assets)

- Allowed frame counts: 2, 4, or 6 frames.
- Idle animations MAY include:
  - Light flicker
  - Small sign blink
  - Simple bob (1px vertical shift)
- Animation timing:
  - 2 frames: 400-600ms per frame
  - 4 frames: 150-250ms per frame
  - 6 frames: 100-180ms per frame
- Animation MUST loop seamlessly with no sudden jumps.

---

## 8) Terrain & Map Tile Rules

- Terrain tiles MUST be 32x32 and tile seamlessly on all edges.
- Terrain MUST be lower-contrast than buildings to keep buildings readable.
- Building base pixels MUST not blend into terrain; use a 1px separation outline or shadow.
- Avoid high-frequency patterns that cause shimmering at 2x scale.

---

## 9) File Naming & Folder Structure

Canonical layout (relative to project root):

```
assets/
  pixel/
    buildings/
    terrain/
    ui/
    effects/
```

File naming rules:
- Lowercase, snake_case, no spaces.
- Building sprites MUST map to building IDs:
  - `assets/pixel/buildings/b001.png`
  - `assets/pixel/buildings/b001_idle_4f.png` (optional animation)
- Terrain tiles MUST follow:
  - `assets/pixel/terrain/terrain_grass.png`
  - `assets/pixel/terrain/terrain_road.png`
- UI map icons MUST follow:
  - `assets/pixel/ui/icon_upgradeable.png`

---

## 10) Quality Acceptance Checklist

An asset is accepted only if ALL are true:

- 32x32 authoring size; integer scaling only.
- Top-down 3/4 perspective with 60/40 roof-to-wall ratio.
- <= 12 colors and <= 1 accent color (<= 10% coverage).
- Light direction top-left; 1px local-color outlines.
- Silhouette readable at 64x64.
- No forbidden detail types (noise, tiny text, anti-aliased lines).
- File name matches naming rules and building ID mapping.
- Terrain tiles seamlessly on all edges (if terrain).


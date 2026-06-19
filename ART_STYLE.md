# ART_STYLE.md

## Game Art Direction

This project is a mobile-first 2D top-down farming and crafting colony simulation game.

The visual direction is inspired by children’s storybook illustrations: simple, readable, hand-drawn, warm, and charming.

The world starts mostly monochrome. Player-built objects introduce color, making the world feel more alive as the colony grows.

---

## Core Style

```yaml
camera: topdown
projection: orthographic
grid: square
platform: mobile_first
style: children_storybook
line_style: hand_drawn
line_weight: medium
detail: low_medium
```

---

## Camera Rules

All game assets must use a true top-down orthographic view.

Avoid:

* Isometric view
* 3/4 view
* Perspective camera
* Side view
* Dramatic camera angles

---

## Grid Rules

The world uses a square grid.

Recommended scale:

```yaml
tile_size: 64
small_asset: 1x1
medium_building: 2x2
large_building: 3x3
farm_field: 4x4
road: 1x1
```

Assets must align clearly to grid cells.

---

## Visual Style

Assets should look like they were drawn for a children’s storybook.

Preferred qualities:

* Simple silhouette
* Soft organic shapes
* Clear black outline
* Slightly imperfect hand-drawn lines
* Minimal internal detail
* Friendly and readable design
* No harsh realism

The art should feel handmade, but not messy.

---

## Detail Level

Use low-medium detail.

This means:

* Enough detail to feel hand-drawn
* Not enough detail to become noisy
* Readable at small mobile sizes
* No dense hatching
* No excessive branches, cracks, grass blades, stones, or decoration

Every asset must still be recognizable at 48x48 px.

---

## Color Direction

### Base World

The natural world is mostly monochrome.

```yaml
terrain: black_white_grayscale
natural_resources: black_white_grayscale
```

This includes:

* Grass
* Dirt
* Water
* Trees
* Rocks
* Mountains
* Empty land

Use grayscale contrast to separate tile types.

### Player-Built Objects

Player-built and upgraded objects use color.

```yaml
constructed_buildings: colored
crafted_resources: colored
production_objects: colored
```

This includes:

* Houses
* Farms
* Workshops
* Warehouses
* Roads built by player
* Machines
* Crafted goods
* Production-chain outputs

The purpose of color is to show progress.

The more the player builds, the more alive the map becomes.

---

## Line Rules

Preferred:

```yaml
outline: clean_black
line_weight: medium
line_feel: hand_drawn
line_variation: slight
```

Avoid:

* Thin technical lines
* Overly clean vector lines
* Heavy comic outlines
* Scratchy sketch lines
* Engraving lines
* Dense pen hatching

---

## Shape Language

Use simple, readable shapes.

Examples:

* Trees: round or cloud-like canopies
* Mountains: simple triangular clusters
* Rocks: chunky rounded stones
* Houses: clear roof shape, simple walls
* Farms: readable rows or patches
* Roads: simple paths with soft edges

Shape should communicate the object before detail does.

---

## Asset Priority

Build assets in this order:

1. Style Guide Sheet
2. Terrain Tiles
3. Natural Resources
4. Basic Buildings
5. Production Buildings
6. Crafted Goods
7. UI Icons
8. Characters
9. Animations

Do not start with characters or animations.

---

## First Style Guide Sheet

Before creating final assets, create one reference sheet containing:

```text
Trees x 5
Rocks x 3
Mountains x 3
Houses x 5
Farm plots x 3
Road tiles x 3
Storage / warehouse x 2
Workshop x 2
```

Rules for the sheet:

* No full scene
* No map layout
* No perspective
* No background details
* Objects arranged in a clean grid
* White or transparent background
* Consistent scale
* Consistent line weight

---

## Layer.ai Prompt Base

Use this as the base prompt for most assets:

```text
2D top-down orthographic mobile game asset,
children's storybook hand-drawn style,
simple readable silhouette,
clean black outline,
slightly imperfect hand-drawn line,
low-medium detail,
friendly farming colony game,
square grid compatible,
white or transparent background
```

---

## Monochrome World Prompt Add-on

Use for terrain and natural world assets:

```text
black and white grayscale only,
monochrome terrain,
no color,
clear grayscale contrast,
simple hand-drawn storybook look
```

---

## Colored Building Prompt Add-on

Use for player-built objects:

```text
soft warm storybook colors,
colored player-built object,
clear black outline,
simple mobile game readability,
not realistic,
not highly detailed
```

---

## Negative Prompt

Use this often:

```text
realistic,
photorealistic,
cinematic,
isometric,
3/4 view,
side view,
high detail,
intricate,
dense hatching,
engraving,
technical drawing,
concept art,
painting,
anime,
pixel art,
overly complex,
messy sketch,
dramatic lighting,
heavy shadows,
text,
logo
```

---

## Design Test

Before approving any asset, test it with these questions:

1. Is it readable at 48x48 px?
2. Does it clearly look top-down?
3. Does it fit the square grid?
4. Does it look like a children’s storybook drawing?
5. Is it too detailed?
6. Does it match the monochrome/color rule?
7. Can this style scale to hundreds of assets?

If the answer fails, regenerate or simplify.

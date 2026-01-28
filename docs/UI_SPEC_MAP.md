# UI_SPEC_MAP.md

> Source of truth: AI_SPEC.md. This document specifies the Map-first UX for v0.1.

---

## 1) Map Screen Purpose

- The map is the primary context and selector.
- All building management occurs via a bottom-sheet panel anchored on the map screen.
- No scene switching on building tap.

---

## 2) Grid Rules

### 2.1 Grid Size and Coordinates

- Grid dimensions must be configurable and match `buildings.json` grid size.
- v0.1 target: 6x6 to 8x8 (AI_SPEC.md baseline). Default grid is the config value.
- Coordinate origin: (0,0) at top-left; x increases right, y increases down.
- Each building occupies one tile.

ASCII layout example (7x7):

```
(0,0) -----------------> x
 |
 |
 v y
```

### 2.2 Tile Placement Rules

- Each building definition contains a fixed `tile` coordinate.
- Empty tiles are allowed and render as inactive terrain.
- Locked buildings still occupy their tile but are non-interactive.
- Overlap is invalid; validation must reject duplicate coordinates.

### 2.3 Unlock Behavior on Map

- Locked tiles show a lock overlay and muted art.
- Unlock triggers are soft gates only (money/trend/level/mission).
- Once unlocked, the tile is interactive and updates to normal art state.

---

## 3) Interactions

### 3.1 Tap

- Tap on an unlocked building tile opens the bottom-sheet building panel.
- Tapping outside the bottom sheet closes it (if open).
- Tapping a locked tile shows a brief lock tooltip (non-blocking) and no panel.

### 3.2 Long-Press (Optional)

- Long-press on an unlocked building triggers quick actions (Upgrade x1/x10/Info).
- If long-press is not implemented, the system must still be fully usable via tap.

### 3.3 Disabled States

- Disabled state examples: locked building, cooldown active, insufficient money.
- Disabled buildings do not open the panel and must show a clear visual state.

---

## 4) Visual State Indicators (Map Level)

The map must convey state at a glance. Minimum indicators:

- **Upgradeable:** glow or pulse outline; indicates enough money for x1 upgrade.
- **Blocked:** warning badge; indicates upgrade blocked by lock/cooldown/gate.
- **Boosted:** effect badge or icon; indicates a temporary boost is active.

Rules:
- Indicators must not overlap in a way that hides lock or boost state.
- Priority order (highest to lowest): locked > boosted > blocked > upgradeable.

---

## 5) Bottom-Sheet Host Behavior (Map Screen)

- Implemented as a Control-based UI panel anchored to the bottom of the map screen.
- The map remains active beneath the panel (no scene change).
- The panel receives focus and input capture while open.

### 5.1 Open/Close

- Open on building tap.
- Close on:
  - Tap outside panel,
  - Swipe down gesture on panel,
  - Dedicated close button.

### 5.2 Heights

- Collapsed: hidden (off-screen) state.
- Default open: 60% of screen height.
- Maximum: 85% of screen height (for long content).

### 5.3 Transitions

- Use a single easing curve; duration target 180-240ms.
- Opening and closing must be symmetrical and not block input longer than the duration.

---

## 6) Mobile Touch Constraints (Godot Control-based UI)

- Minimum tap target: 52-64 dp equivalent.
- One-hand reachable: primary CTA within lower 60% of screen.
- Safe-area compliance required for all Controls (top and bottom).
- The bottom sheet must inset above system gesture areas on iOS/Android.
- Do not rely on multi-touch gestures to access core actions.

---

## 7) Map UI States (State Machine)

```
[MapIdle] --tap unlocked--> [PanelOpen]
[MapIdle] --tap locked-->   [MapIdle + LockTooltip]
[PanelOpen] --close-->      [MapIdle]
```

- PanelOpen state captures input for the bottom sheet.
- MapIdle state accepts taps/long-press on tiles.

---

## 8) Cross-Reference

- Building panel content and rules: UI_SPEC_BUILDING_PANEL.md
- Economy-driven state cues: ECONOMY_SPEC.md
- Data-driven tile placement: DATA_SCHEMA.md


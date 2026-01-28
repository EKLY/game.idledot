# UI_SPEC_BUILDING_PANEL.md

> Source of truth: AI_SPEC.md. This document specifies the v0.1 building bottom-sheet panel.

---

## 1) Panel Purpose

- Show building info and enable upgrades from the map screen.
- One dominant action: Upgrade.
- No scene changes; panel is a Control-based bottom sheet.

---

## 2) Mandatory Fields (Layout Order)

Top to bottom order (single-column, left-aligned):

1) Header
   - Building icon
   - Building name
   - Level display
2) Primary Metrics
   - Current income per second
   - Trend multiplier (if applicable to building)
3) Upgrade Impact (Before/After)
   - Current income and projected income after upgrade quantity
4) Quantity Toggle Row
   - x1 / x10 / xMAX
5) Primary CTA
   - Upgrade button (dominant)
6) Secondary Actions (optional)
   - Boost (if available)
   - Details (optional; not required in v0.1)

Notes:
- All numeric values are derived from config-driven formulas.
- The panel must fit within 60% screen height at default open; scroll if needed.

---

## 3) Upgrade Flow (x1 / x10 / xMAX)

### 3.1 Quantity Toggle Rules

- Default selection: x1 on first open.
- x10 is enabled only if at least 10 levels are purchasable for that building.
- xMAX computes the maximum affordable levels based on current money and cost formula.
- If xMAX = 0, disable the CTA and show a not-enough-money state.

### 3.2 CTA Behavior

- CTA text uses quantity label: "Upgrade x1", "Upgrade x10", "Upgrade xMAX".
- On tap:
  - Validate unlock state and cooldown.
  - Validate affordability for selected quantity.
  - If valid, apply upgrade, update income, and refresh panel values.

### 3.3 Cost Display

- Show the total cost for the selected quantity.
- Cost must update immediately when toggling quantity.

---

## 4) Before/After Income Presentation

- Show current income per second.
- Show projected income per second after applying selected quantity.
- If the building is a non-money producer (e.g., trend or modifiers), show the affected stat instead:
  - Trend gain per second
  - Upgrade cost multiplier
  - Offline efficiency bonus

Example (player-facing text):

- Current: "Income now 12.5 /sec"
- After:   "After upgrade 18.7 /sec"

---

## 5) Error States

### 5.1 Not Enough Money

- CTA disabled, with inline message:
  - Example: "Not enough money"
- Cost remains visible.

### 5.2 Locked Building

- Panel does not open for locked tiles.
- If opened via edge case, show locked banner:
  - Example: "Locked"

### 5.3 Cooldown Active (if any in config)

- CTA disabled with remaining time indicator.
  - Example: "Cooldown 00:20"

---

## 6) Accessibility & Mobile Ergonomics

- Minimum button height: 52 dp.
- Primary CTA anchored to lower 40% of the panel.
- Quantity toggles are segmented buttons with clear active state.
- Text must wrap and scale without truncating key numbers.
- Support safe-area padding at bottom for iOS home indicator.

---

## 7) Panel State Machine

```
[Closed] --tap building--> [Open]
[Open] --upgrade--> [Open + Refresh]
[Open] --close--> [Closed]
```

- Refresh updates cost, income, and status indicators instantly.
- Errors do not close the panel.

---

## 8) Cross-Reference

- Map interactions and bottom sheet host: UI_SPEC_MAP.md
- Economy formulas: ECONOMY_SPEC.md
- Data-driven building attributes: DATA_SCHEMA.md


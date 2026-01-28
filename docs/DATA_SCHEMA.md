# DATA_SCHEMA.md

> Source of truth: AI_SPEC.md. This document defines canonical data contracts for v0.1.

---

## 1) Versioning & Migration Rules

- Every config and save file includes a `version` integer.
- Version increments are additive; fields may be added but not removed without migration.
- Migration rules:
  - `version + 1` migrations are allowed only if data can be derived or defaulted.
  - Unknown fields must be preserved when reading and writing (forward compatibility).
  - Missing fields must be defaulted to safe values documented here.

---

## 2) Save Integrity Rules

- Save payload must include:
  - `saveVersion`
  - `checksum` over canonicalized JSON (sorted keys, no whitespace)
  - `createdAt` and `updatedAt` UTC timestamps
- On load:
  - If checksum fails, load last known good backup.
  - If no backup, reset to new-game state.

---

## 3) PlayerState Schema

### 3.1 Required Fields

| Field | Type | Description |
|---|---|---|
| saveVersion | int | Player save schema version |
| money | BigNumber | Current money |
| trend | float | Current trend multiplier |
| prestigeCurrency | int | Permanent currency |
| buildingLevels | map<string,int> | Building id -> level |
| permanentUpgrades | list<string> | Purchased permanent upgrade ids |
| boostsActive | list<BoostState> | Active temporary boosts |
| lastActiveAt | string | UTC timestamp ISO-8601 |
| seasonState | SeasonState | Current season summary |
| missions | MissionState | Daily mission progress |

### 3.2 BigNumber Representation

```
{
  "mantissa": 1.234567,
  "exponent": 6
}
```

### 3.3 PlayerState Example (JSON)

```json
{
  "saveVersion": 1,
  "money": { "mantissa": 3.42, "exponent": 4 },
  "trend": 1.15,
  "prestigeCurrency": 0,
  "buildingLevels": {
    "B001": 12,
    "B002": 8
  },
  "permanentUpgrades": [],
  "boostsActive": [],
  "lastActiveAt": "2026-01-28T12:00:00Z",
  "seasonState": {
    "seasonId": "S001",
    "seasonPoints": 0,
    "endsAt": "2026-02-04T00:00:00Z"
  },
  "missions": {
    "daily": {
      "D001": { "progress": 3, "claimed": false },
      "D002": { "progress": 0, "claimed": false },
      "D003": { "progress": 10, "claimed": true }
    },
    "lastDailyResetAt": "2026-01-28T00:00:00Z"
  },
  "createdAt": "2026-01-28T11:00:00Z",
  "updatedAt": "2026-01-28T12:00:00Z",
  "checksum": "sha256:..."
}
```

---

## 4) Building Definition Schema

### 4.1 Building Object

| Field | Type | Description |
|---|---|---|
| id | string | Unique building id (e.g., B001) |
| name | string | Display name (Thai allowed) |
| category | enum | stable, trend, infra, volatile |
| tile | object | `x`, `y` grid coordinates |
| cost | object | `base`, `rate` |
| output | object | money or modifier output |
| trendScaling | object | `enabled`, `weight` |
| unlock | object | unlock rule |

### 4.2 Output Variants

- Money output:
  - `{ "basePerSec": number, "rate": number }`
- Trend output:
  - `{ "type": "trend", "trendPerSec": number, "rate": number }`
- Modifier output:
  - `{ "type": "modifier", "effects": [ { kind, target, value, rate? } ] }`

### 4.3 Building Example (JSON)

```json
{
  "id": "B001",
  "name": "ExampleStreetCart",
  "category": "stable",
  "tile": { "x": 2, "y": 4 },
  "cost": { "base": 15, "rate": 1.12 },
  "output": { "basePerSec": 0.8, "rate": 1.10 },
  "trendScaling": { "enabled": true, "weight": 1.0 },
  "unlock": { "type": "start" }
}
```

---

## 5) Mission Schema

### 5.1 Mission Definition

| Field | Type | Description |
|---|---|---|
| id | string | Unique mission id |
| title | string | Player-facing text (Thai allowed) |
| type | enum | upgrade_count, upgrade_any, lifetime_earnings |
| target | object | Type-specific target data |
| rewards | list<object> | Rewards granted on completion |

### 5.2 Mission Progress State

```
{
  "progress": number,
  "claimed": boolean
}
```

---

## 6) Event Schema

### 6.1 Event Definition

| Field | Type | Description |
|---|---|---|
| id | string | Event id |
| name | string | Display name |
| type | enum | seasonal |
| durationDays | int | Event duration |
| effects | list<object> | Temporary global effects |
| rewards | list<object> | Rewards for participation |

---

## 7) SeasonState Schema

```
{
  "seasonId": "S001",
  "seasonPoints": 0,
  "endsAt": "2026-02-04T00:00:00Z"
}
```

---

## 8) BoostState Schema

```
{
  "boostId": "incomeX2Minutes",
  "expiresAt": "2026-01-28T12:03:00Z",
  "source": "mission"
}
```

---

## 9) Cross-Reference

- Economy math and BigNumber policy: ECONOMY_SPEC.md
- UX-driven requirements: UI_SPEC_MAP.md and UI_SPEC_BUILDING_PANEL.md
- Non-goals and constraints: AI_SPEC.md


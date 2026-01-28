# AI_SPEC.md

> Project: Thai Satire Idle Economic (Mobile Idle / Incremental)
>
> Purpose: This spec is written for AI agents and collaborators. It defines non-negotiable rules, scope, architecture boundaries, and deliverables.

---

## 0) Project Summary

Build a **mobile-only** idle/incremental economic game with a **Thai cultural satire tone** (system-level parody, not real-world political/person references). The primary experience is a **top-down grid city map** where players tap buildings to open a **bottom-sheet building panel** to upgrade and manage production.

Core systems:

* Idle economy (exponential growth)
* Offline progress
* Prestige loop
* Rewarded ads (optional, no forced ads)
* Seasonal leaderboard

---

## 1) Non-Goals

* No PC/web version.
* No city-builder simulation (no complex construction/roads/zoning).
* No deep story cutscenes.
* No forced interstitial ads.
* No real-person/real-party/real-institution references.

---

## 2) Tone & Content Rules (Thai Satire Safety)

### 2.1 Allowed satire

* Consumer trends, hype cycles, “image > efficiency”, queues/paperwork, stamp/permit bureaucracy (fictionalized).
* Generic cultural behaviors (e.g., promo culture, point collecting, festival economy).

### 2.2 Disallowed

* References to real politicians, parties, institutions, or identifiable public figures.
* Hate/harassment against protected groups.
* Defamation of real entities.

### 2.3 Naming convention

Use **fictional brands** and **parody-style neutral names** (e.g., “สำนักงานประทับใจ”, “ศูนย์เอกสารดีเด่น”, “ทีมกระแส”). Avoid names that map 1:1 to real organizations.

---

## 3) Target Platform & UX Constraints

* Engine: **Godot 4.6**.
* Language: **GDScript**.

* Platform: **iOS + Android** (mobile only).
* Input: touch, one-hand friendly.
* Performance: stable 60fps UI; economy ticks must not cause UI jank.
* Sessions: short, frequent (30–120 seconds typical).

### 3.1 Pixel Art Rules (Authoritative Sub-Spec)

* All 2D pixel art assets MUST comply with `PIXEL_ART_SPEC.md`.
* `PIXEL_ART_SPEC.md` is the single source of truth for pixel art rules and is subordinate to this document.
* If any conflict exists between `PIXEL_ART_SPEC.md` and AI_SPEC.md, AI_SPEC.md MUST prevail.

### 3.2 Project Structure (Godot standard)

Required root file:

* `project.godot`

Standard folders (initial layout):

* `addons/`
* `assets/` (subfolders: `assets/sprites/`, `assets/ui/`, `assets/audio/`)
* `config/` (JSON only)
* `scenes/`
* `scripts/`
* `ui/`
* `tests/`

### 3.3 Naming Conventions (recommended)

* Files/folders: **snake_case** (preferred)
* Scenes: snake_case `.tscn` (match file name)
* Scripts: snake_case `.gd` (match scene/script name)
* Class names: PascalCase (when `class_name` is used)
* Node names: PascalCase for readability in the scene tree

Asset naming (buildings):

* Building icons and tiles live in `assets/sprites/buildings/`
* UI icon: `b001.png`
* Map tile: `b001_tile.png`

### 3.4 Core Architecture (Godot Autoloads, v0.x)

Use Autoload singletons for core systems (names below are recommended and can be adjusted):

* `GameState` (session state, current screen, session stats)
* `Economy` (ticks, income calc, trend)
* `SaveService` (JSON save/load, versioning, migration)
* `ConfigService` (loads JSON configs, caches)
* `TimeService` (offline time, timers, time scale)
* `Events` (lightweight signal hub for cross-system events)

UI structure should follow the dedicated UI docs under `docs/` (if conflicts occur, AI_SPEC.md prevails).

---

## 4) Core Gameplay Pillars

1. **Numbers always moving**: money/income visibly updates.
2. **Map as selector**: the map is the primary screen for context; management happens via panels.
3. **Single dominant action**: for buildings, the main action is Upgrade.
4. **Casual-friendly**: minimal friction, soft gates, no heavy time gates.
5. **Config-driven economy**: avoid hard-coded numbers scattered in UI/logic.

---

## 5) Core Loop

### 5.1 Primary loop

Produce → Accumulate → Upgrade → Produce faster → repeat

### 5.2 Mid loop

Unlock systems (infrastructure, trend) → automation → faster exponential growth

### 5.3 Long loop (Prestige)

Reset partial progress → gain permanent currency → accelerate next run

---

## 6) Economy Model (Must-follow)

### 6.1 Resources (3-layer)

* **Money**: primary currency.
* **Trend** (กระแส): global multiplier with decay.
* **Prestige currency** (บารมี/ตราประทับ): permanent upgrades.

No additional resource types in MVP.

### 6.2 Formulas (single source of truth)

All production and costs must be computed from config.

* Building upgrade cost:

  * `cost(level) = baseCost × (costRate ^ level)`
* Building output:

  * `output(level) = baseOutput × (outputRate ^ level)`
* Global income per second:

  * `incomePerSec = Σ output(building_i) × trendMultiplier × globalBonus × boosts`

### 6.3 Pacing targets (initial defaults)

* First meaningful upgrade: **20–30s** from fresh start.
* First prestige: **90–180 min**.
* Offline cap: **12 hours**.
* Offline efficiency: **70%**.

---

## 7) Offline Progress (Required)

* Persist `lastActiveAt`.
* On launch/resume:

  * compute `elapsed = now - lastActiveAt`.
  * clamp to offline cap.
  * award offline earnings using offline efficiency.
* Show **offline summary modal** once (dismissible).

---

## 8) Buildings & Content Structure

### 8.1 Building archetypes

* Stable income buildings (steady)
* Trend-driven buildings (volatile; higher ceiling)
* Infrastructure buildings (reduce friction; increase efficiency)
* PR/Event buildings (increase trend)

### 8.2 MVP building count

* Early game: 6 buildings
* v1 content: 12–18 buildings

### 8.3 Unlock system

Soft gates only:

* money threshold
* trend threshold
* prior building level
* mission completion

Avoid hard time gates.

### 8.4 Starter Buildings (MVP: 6 buildings)

> Goal: cover the 4 archetypes while keeping early progression simple. Names are fictional/parody-style and not mapped 1:1 to real entities.

#### B001 — รถเข็นสารพัด (Street Cart)

* Archetype: Stable income
* Role: first building; teaches “tap → panel → upgrade”
* Unlock: start
* Notes: very low cost, low output, fast upgrades

#### B002 — ร้านน้ำหวานหน้าปากซอย (Sweet Drink Stall)

* Archetype: Stable income
* Role: second stable generator; introduces x10 upgrades
* Unlock: money threshold (very small)

#### B003 — ตลาดนัดติดแอร์ (Indoor Market)

* Archetype: Stable income (mid early)
* Role: first “bigger jump” in income; longer upgrade cadence
* Unlock: B002 level gate

#### B004 — ทีมกระแส (Trend Team)

* Archetype: PR / Trend
* Role: increases Trend (global multiplier) and/or reduces Trend decay
* Unlock: money + mission completion (first daily)
* Notes: produces little/no money directly; it boosts others

#### B005 — ศูนย์เอกสารดีเด่น (Paperwork Center)

* Archetype: Infrastructure
* Role: reduces upgrade cost (global or category) OR increases offline efficiency cap
* Unlock: B003 level gate
* Notes: the “Thai satire friction” in a harmless, system-level way

#### B006 — งานแฟร์ชุมชน (Community Fair)

* Archetype: Trend-driven / Event
* Role: high income spikes via short boosts; slightly volatile (depends on Trend)
* Unlock: Trend threshold

### 8.5 Balancing guidance for starter set

* Early game should feel fast: B001/B002 upgrade cadence 5–20 seconds.
* Introduce Trend by minute 2–5 via B004.
* Introduce Infrastructure by minute 8–15 via B005.
* Volatile/high-ceiling building (B006) unlocks after player understands Trend.

---

## 9) Map-First UX Spec (Non-negotiable)

### 9.1 Map screen

* Top-down grid map (6×6 to 8×8).
* Buildings are tappable tiles sized for touch (>= ~52–64dp).
* Locked tiles show a clear lock state.

### 9.2 Interaction rules

* **Tap building** → open **Bottom Sheet Building Panel** (no scene change).
* **Close panel** → return to map instantly.
* Optional **long-press** → quick actions (Upgrade x1/x10/Info).
* Zoom/pan may exist but must never be required.

### 9.3 Visual status cues

Map must communicate at a glance:

* Upgrade available: glow/pulse
* Bottleneck/blocked: warning icon
* Boost active: effect badge

---

## 10) Building Panel Spec (Bottom Sheet)

### 10.1 Always present

* Building name + icon
* Level
* Income now
* Income after upgrade (before/after)
* Primary CTA: **Upgrade**
* Quantity toggle: x1 / x10 / xMAX (single row)

### 10.2 Optional actions

* Boost (if owned)
* Details (advanced)

### 10.3 UX limits

* One dominant action.
* No more than 2–3 secondary buttons.
* No multi-step menus.

---

## 11) Navigation Structure

Bottom navigation:

* Map (Home)
* Upgrade (List management)
* Event/Missions
* Prestige
* Ranking

Upgrade tab must support sorting:

* Upgradeable
* ROI-ish
* Cheapest
* Highest income

---

## 12) Prestige System

* Resets: money, building levels.
* Persists: prestige currency, permanent upgrades, achievements.

Prestige currency formula guideline:

* `prestigeGain = floor(sqrt(lifetimeEarnings / K))` (K tunable)

Permanent upgrades examples:

* Global multiplier
* Auto-collect
* Auto-upgrade priority rules
* Reduce costs
* Increase offline cap
* Reduce trend decay

---

## 13) Rewarded Ads (Optional, No Forced Ads)

* Ads are **rewarded only**.
* Rewards:

  * x2 income for 2–4 minutes
  * Instant cash equal to 30–120 minutes of income
  * Freeze trend decay for short period

Constraints:

* Daily limit and/or cooldown.
* Game must be playable without watching ads.

---

## 14) Leaderboard (Seasonal)

* Seasonal leaderboard (weekly default).
* Score should not be raw money to reduce cheating.

Recommended score function:

* `score = f(prestigeTotal, lifetimeEarnings, achievements, seasonPoints)`

Anti-cheat baseline:

* authoritative server for score submission
* anomaly detection for impossible deltas

---

## 15) Data Model (Config-driven)

### 15.1 Config files (single source)

* `economy.json`
* `buildings.json`
* `upgrades_permanent.json`
* `missions.json`
* `events.json`

Config format is **JSON only** in v0.x.

### 15.2 Player save

Must include:

* money
* trend
* prestigeCurrency
* buildingLevels
* permanentUpgrades
* boostsActive
* lastActiveAt
* seasonState

Save format is **JSON** (store in `user://`), with versioning and migration starting in v0.x.

### 15.3 Example configs (MVP-ready)

> These examples define **structure**, not final numbers. Keep all tuning in configs (no scattered magic numbers).

#### `economy.json`

```json
{
  "version": 1,
  "pacing": {
    "offlineCapHours": 12,
    "offlineEfficiency": 0.70,
    "firstUpgradeTargetSeconds": 30,
    "firstPrestigeTargetMinutes": 120
  },
  "trend": {
    "baseMultiplier": 1.0,
    "maxMultiplier": 5.0,
    "decayPerMinute": 0.02,
    "minMultiplier": 0.8
  },
  "boosts": {
    "incomeX2Minutes": { "durationSeconds": 180, "multiplier": 2.0 },
    "freezeTrendDecay": { "durationSeconds": 180 }
  },
  "prestige": {
    "formula": "sqrt",
    "k": 1.0e6
  }
}
```

#### `buildings.json`

```json
{
  "version": 1,
  "grid": { "cols": 7, "rows": 7 },
  "buildings": [
    {
      "id": "B001",
      "name": "รถเข็นสารพัด",
      "category": "stable",
      "tile": { "x": 2, "y": 4 },
      "cost": { "base": 15, "rate": 1.12 },
      "output": { "basePerSec": 0.8, "rate": 1.10 },
      "trendScaling": { "enabled": true, "weight": 1.0 },
      "unlock": { "type": "start" }
    },
    {
      "id": "B002",
      "name": "ร้านน้ำหวานหน้าปากซอย",
      "category": "stable",
      "tile": { "x": 3, "y": 4 },
      "cost": { "base": 60, "rate": 1.13 },
      "output": { "basePerSec": 3.0, "rate": 1.11 },
      "trendScaling": { "enabled": true, "weight": 1.0 },
      "unlock": { "type": "money", "moneyRequired": 40 }
    },
    {
      "id": "B003",
      "name": "ตลาดนัดติดแอร์",
      "category": "stable",
      "tile": { "x": 4, "y": 4 },
      "cost": { "base": 300, "rate": 1.14 },
      "output": { "basePerSec": 14.0, "rate": 1.12 },
      "trendScaling": { "enabled": true, "weight": 1.1 },
      "unlock": { "type": "level", "buildingId": "B002", "levelRequired": 10 }
    },
    {
      "id": "B004",
      "name": "ทีมกระแส",
      "category": "trend",
      "tile": { "x": 4, "y": 3 },
      "cost": { "base": 450, "rate": 1.15 },
      "output": { "type": "trend", "trendPerSec": 0.003, "rate": 1.08 },
      "unlock": { "type": "mission", "missionId": "D001" }
    },
    {
      "id": "B005",
      "name": "ศูนย์เอกสารดีเด่น",
      "category": "infra",
      "tile": { "x": 5, "y": 3 },
      "cost": { "base": 900, "rate": 1.16 },
      "output": {
        "type": "modifier",
        "effects": [
          { "kind": "upgrade_cost_multiplier", "target": "all", "value": 0.995, "rate": 0.999 }
        ]
      },
      "unlock": { "type": "level", "buildingId": "B003", "levelRequired": 8 }
    },
    {
      "id": "B006",
      "name": "งานแฟร์ชุมชน",
      "category": "volatile",
      "tile": { "x": 5, "y": 4 },
      "cost": { "base": 1200, "rate": 1.17 },
      "output": { "basePerSec": 40.0, "rate": 1.13 },
      "trendScaling": { "enabled": true, "weight": 1.35 },
      "unlock": { "type": "trend", "trendRequired": 1.2 }
    }
  ]
}
```

#### `upgrades_permanent.json`

```json
{
  "version": 1,
  "upgrades": [
    {
      "id": "P001",
      "name": "เมืองทำงานไวขึ้น",
      "costPrestige": 5,
      "effects": [{ "kind": "global_income_multiplier", "value": 1.10 }]
    },
    {
      "id": "P002",
      "name": "เพิ่มเพดานออฟไลน์",
      "costPrestige": 8,
      "effects": [{ "kind": "offline_cap_hours_add", "value": 2 }]
    },
    {
      "id": "P003",
      "name": "กระแสอยู่ได้นานขึ้น",
      "costPrestige": 10,
      "effects": [{ "kind": "trend_decay_multiplier", "value": 0.90 }]
    }
  ]
}
```

#### `missions.json`

```json
{
  "version": 1,
  "daily": [
    {
      "id": "D001",
      "title": "อัปเกรดร้านแรก 5 ครั้ง",
      "type": "upgrade_count",
      "target": { "buildingId": "B001", "count": 5 },
      "rewards": [{ "kind": "money", "value": 100 }, { "kind": "trend", "value": 0.05 }]
    },
    {
      "id": "D002",
      "title": "ทำรายได้รวมให้ถึง 1,000",
      "type": "lifetime_earnings",
      "target": { "value": 1000 },
      "rewards": [{ "kind": "boost", "boostId": "incomeX2Minutes" }]
    },
    {
      "id": "D003",
      "title": "อัปเกรดอะไรก็ได้ 10 ครั้ง",
      "type": "upgrade_any",
      "target": { "count": 10 },
      "rewards": [{ "kind": "money", "value": 250 }]
    }
  ]
}
```

#### `events.json` (simple weekly stub)

```json
{
  "version": 1,
  "events": [
    {
      "id": "E001",
      "name": "สัปดาห์ของแถม",
      "type": "seasonal",
      "durationDays": 7,
      "effects": [{ "kind": "global_income_multiplier", "value": 1.05 }],
      "rewards": [{ "kind": "season_points", "value": 100 }]
    }
  ]
}
```

---

## 16) Telemetry (Minimum viable)

Track:

* session count/day
* time to first upgrade
* time to first prestige
* ad watch count
* churn indicators (days inactive)

---

## 17) MVP Deliverables

### v0.1 (Playable Prototype)

* Map grid home
* 6 buildings
* building panel with upgrade
* exponential economy formula
* offline progress
* basic missions (3 daily)

### v0.2

* prestige
* simple automation unlocks

### v1.0

* rewarded ads
* seasonal leaderboard
* 12–18 buildings
* events

---

## 18) Definition of Done (DoD)

A feature is done only when:

* Config-driven values (no magic numbers in UI)
* Works offline/online
* Mobile touch targets respected
* UI feedback is immediate
* Save/load verified
* Basic anti-cheat constraints considered for ranking

---

## 19) Collaboration Protocol

* Keep this file authoritative.
* When implementing a new system, update:

  * this spec if rules change
  * any plan/task doc used by the team
* Prefer small, testable increments.

---

## 20) Open Questions (Fill later)

* Final theme naming set (fictional brands)
* Art style target (cartoon/flat/pixel)
* Server stack for leaderboard
* Monetization tuning (limits, cooldowns)

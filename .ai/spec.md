# spec.md

## Purpose

This specification is designed for a **single-developer, multi-AI workflow**. Its purpose is **cross-AI continuity and consistency**, not team or organizational governance.

---

## Core Principles

- The system must have explicit boundaries between major areas (UI vs core logic, client vs data/config, app vs persistence).
- AI must not invent architecture, conventions, or behaviors not written here or discovered in the repository.
- If repository reality conflicts with this spec, AI must report the mismatch and propose a spec update.

---

## Language Policy

### Human vs AI Documentation Language

- **Human-facing interaction (chat, explanations, reports)** must be written in **Thai**.
- **All files under `.ai/` (`.ai/*.md`) must be written in English only**.
- Mixing languages inside the same `.ai/*.md` file is not allowed.
- File paths, code, identifiers, and library names must always remain unchanged.
- AI must not translate existing English specification content into Thai.

---

## Project Summary

Build a **mobile-only** idle/incremental economic game with a **Thai cultural satire tone** (system-level parody, not real-world political/person references). The primary experience is a **top-down grid city map** where players tap buildings to open a **bottom-sheet building panel** to upgrade and manage production.

Core systems:

- Idle production-chain economy (terrain → extract → process → sell)
- Offline progress
- Prestige loop
- Rewarded ads (optional, no forced ads)
- Seasonal leaderboard

---

## Non-Goals

- No PC/web version.
- No city-builder simulation (no complex construction/roads/zoning).
- No deep story cutscenes.
- No forced interstitial ads.
- No real-person/real-party/real-institution references.

---

## Tone & Content Rules (Thai Satire Safety)

### Allowed satire

- Consumer trends, hype cycles, “image > efficiency”, queues/paperwork, stamp/permit bureaucracy (fictionalized).
- Generic cultural behaviors (e.g., promo culture, point collecting, festival economy).

### Disallowed

- References to real politicians, parties, institutions, or identifiable public figures.
- Hate/harassment against protected groups.
- Defamation of real entities.

### Naming convention

Use **fictional brands** and **parody-style neutral names**. Avoid names that map 1:1 to real organizations.

---

## Target Platform & Stack

- Engine: **Godot 4.6**
- Language: **GDScript**
- Platform: **iOS + Android** (mobile only)
- Input: touch, one-hand friendly
- Performance: stable 60fps UI; economy ticks must not cause UI jank
- Sessions: short, frequent (30–120 seconds typical)

---

## Pixel Art Rules (Authoritative Sub-Spec)

- All 2D pixel art assets MUST comply with `docs/PIXEL_ART_SPEC.md`.
- `docs/PIXEL_ART_SPEC.md` is the single source of truth for pixel art rules and is subordinate to this document.
- If any conflict exists between `docs/PIXEL_ART_SPEC.md` and `.ai/spec.md`, **.ai/spec.md prevails**.

---

## Project Structure (Godot standard)

Required root file:

- `project.godot`

Standard folders (current layout):

- `addons/`
- `assets/` (subfolders: `assets/sprites/`, `assets/ui/`, `assets/audio/`)
- `config/` (JSON only)
- `scenes/`
- `scripts/`
- `ui/`
- `tests/`

---

## Naming Conventions

- Files/folders: **snake_case** (preferred)
- Scenes: snake_case `.tscn` (match file name)
- Scripts: snake_case `.gd` (match scene/script name)
- Class names: PascalCase (when `class_name` is used)
- Node names: PascalCase for readability in the scene tree

### Asset naming (buildings)

- Building icons and tiles live in `assets/sprites/buildings/`
- UI icon: `b001.png`
- Map tile: `b001_tile.png`

---

## Core Architecture (Godot Autoloads, v0.x)

Use Autoload singletons for core systems (names below are recommended and can be adjusted):

- `ConfigService` (loads JSON configs, caches)
- `Economy` (ticks, income calc, trend)
- `SaveService` (JSON save/load, versioning, migration)
- `TimeService` (offline time, timers, time scale)
- `Events` (lightweight signal hub for cross-system events)
- `GameState` (session state, current screen, session stats)

---

## Core Gameplay Pillars

1. Numbers always moving: money/income visibly updates.
2. Map as selector: the map is the primary screen for context; management happens via panels.
3. Single dominant action: for buildings, the main action is Upgrade.
4. Casual-friendly: minimal friction, soft gates, no heavy time gates.
5. Config-driven economy: avoid hard-coded numbers scattered in UI/logic.

---

## Core Loop

### Primary loop

Produce → Accumulate → Upgrade → Produce faster → repeat

### Mid loop

Unlock systems (infrastructure, trend) → automation → faster exponential growth

### Long loop (Prestige)

Reset partial progress → gain permanent currency → accelerate next run

---

## Economy Model (Must-follow)

### Currencies (3-layer)

- Money: primary currency, earned only at the tail of the production chain.
- Trend: global multiplier with decay.
- Prestige currency: permanent upgrades.

### Material resources (production chain)

Colonists-style chain: terrain yields raw materials, buildings transform them tier
by tier until the final tier sells for Money. Each material has a single global
stockpile (a running balance, not per-building).

- Raw (extracted from terrain): `ore` (mountain), `log` (tree), `fish` (pond), `crop` (open land)
- Processed: `metal` (ore), `plank` (log), `food` (fish + crop)
- Manufactured: `goods` (metal + plank)

New materials are added by extending `buildings.json` + the stockpile, never
hard-coded in UI/logic.

### Production model

- A building runs a tick only when its `inputs` are in the stockpile; it consumes
  inputs and adds outputs at its configured rate.
- Throughput is input-constrained: a downstream building idles (bottleneck) when
  its inputs run dry — the map must surface this (see Visual status cues).
- Extractors bind to terrain: they must be placed adjacent to their resource
  (mine ↔ mountain, logging ↔ tree, fishing ↔ pond); farms sit on open land.
- Retail buildings output `money`; PR buildings output `trend`.

### Formulas (single source of truth)

All production and costs must be computed from config.

- Building cost: `cost(level) = baseCost × (costRate ^ level)`
- Building rate: `rate(level) = baseRate × (rateRate ^ level)` (units/sec, per input and output)
- Effective output: full `rate` only while inputs last; otherwise scaled to what the stockpile can feed.
- Money per second: `Σ output(retail_i) × trendMultiplier × globalBonus × boosts`

### Pacing targets (initial defaults)

- First meaningful upgrade: 20–30s from fresh start.
- First prestige: 90–180 min.
- Offline cap: 12 hours.
- Offline efficiency: 70%.

---

## Offline Progress (Required)

- Persist `lastActiveAt`.
- On launch/resume:
  - compute `elapsed = now - lastActiveAt`
  - clamp to offline cap
  - award offline earnings using offline efficiency
- Show offline summary once (dismissible)

---

## Buildings & Content Structure

### Archetypes (production-chain tiers)

- Extractors — pull raw materials from adjacent terrain (mine / logging / fishing / farm)
- Processors — refine raw into intermediate goods (smelter / sawmill / food plant)
- Manufacturers — combine intermediates into higher goods (assembly)
- Retail — sell final goods for Money (stall / mall)
- Infrastructure — reduce friction / increase efficiency (permit office)
- PR/Event — increase Trend (promo booth)

### MVP building count

- Early game: 6 buildings
- v1 content: 12–18 buildings

### Unlock system

Soft gates only:

- money threshold
- trend threshold
- prior building level
- mission completion

Avoid hard time gates.

---

## Map-First UX Spec (Non-negotiable)

### Map screen

- Top-down grid map (current prototype: 12×12; configurable).
- Buildings are tappable tiles sized for touch (>= ~52–64dp).
- Locked tiles show a clear lock state.

### Interaction rules

- Tap building → open Bottom Sheet Building Panel (no scene change).
- Close panel → return to map instantly.
- Optional long-press → quick actions (Upgrade x1/x10/Info).
- Zoom/pan may exist but must never be required.

### Visual status cues

Map must communicate at a glance:

- Upgrade available: glow/pulse
- Bottleneck/blocked: warning icon
- Boost active: effect badge

---

## Building Panel Spec (Bottom Sheet)

Always present:

- Building name + icon
- Level
- Income now
- Income after upgrade (before/after)
- Primary CTA: Upgrade
- Quantity toggle: x1 / x10 / xMAX (single row)

Optional actions:

- Boost (if owned)
- Details (advanced)

UX limits:

- One dominant action.
- No more than 2–3 secondary buttons.
- No multi-step menus.

---

## Navigation Structure

Bottom navigation:

- Map (Home)
- Upgrade (List management)
- Event/Missions
- Prestige
- Ranking

Upgrade tab must support sorting:

- Upgradeable
- ROI-ish
- Cheapest
- Highest income

---

## Prestige System

- Resets: money, building levels.
- Persists: prestige currency, permanent upgrades, achievements.

Prestige currency formula guideline:

- `prestigeGain = floor(sqrt(lifetimeEarnings / K))` (K tunable)

Permanent upgrades examples:

- Global multiplier
- Auto-collect
- Auto-upgrade priority rules
- Reduce costs
- Increase offline cap
- Reduce trend decay

---

## Rewarded Ads (Optional, No Forced Ads)

- Ads are rewarded only.
- Rewards:
  - x2 income for 2–4 minutes
  - Instant cash equal to 30–120 minutes of income
  - Freeze trend decay for short period

Constraints:

- Daily limit and/or cooldown.
- Game must be playable without watching ads.

---

## Leaderboard (Seasonal)

- Seasonal leaderboard (weekly default).
- Score should not be raw money to reduce cheating.

Recommended score function:

- `score = f(prestigeTotal, lifetimeEarnings, achievements, seasonPoints)`

Anti-cheat baseline:

- authoritative server for score submission
- anomaly detection for impossible deltas

---

## Data Model (Config-driven)

### Config files (single source)

- `economy.json`
- `buildings.json`
- `upgrades_permanent.json`
- `missions.json`
- `events.json`

Config format is **JSON only** in v0.x.

### Player save

Must include:

- money
- trend
- prestigeCurrency
- buildingLevels
- permanentUpgrades
- boostsActive
- lastActiveAt
- seasonState

Save format is **JSON** (store in `user://`), with versioning and migration starting in v0.x.

---

## Telemetry (Minimum viable)

Track:

- session count/day
- time to first upgrade
- time to first prestige
- ad watch count
- churn indicators (days inactive)

---

## MVP Deliverables

### v0.1 (Playable Prototype)

- Map grid home
- 6 buildings
- building panel with upgrade
- exponential economy formula
- offline progress
- basic missions (3 daily)

### v0.2

- prestige
- simple automation unlocks

### v1.0

- rewarded ads
- seasonal leaderboard
- 12–18 buildings
- events

---

## Definition of Done (DoD)

A feature is done only when:

- Config-driven values (no magic numbers in UI)
- Works offline/online
- Mobile touch targets respected
- UI feedback is immediate
- Save/load verified
- Basic anti-cheat constraints considered for ranking

---

## Task Invocation Contract

To reduce prompt verbosity, AI must treat the following minimal instruction as sufficient to begin work:

> "Before starting, read .ai/spec.md and then execute the task below."

The absence of repeated instructions in the prompt does not relax or override any rule in this specification.

---

## AI Cross-Agent Rules

### Optional Cross-Project Document: `.ai/document.md`

A project may optionally provide an `.ai/document.md` file.

This file is not required for internal development tasks. It exists to support cross-project AI interaction.

Its purpose is to explain, at a system and interface level:

- What this project is
- What services, APIs, or capabilities it exposes
- How external systems or other projects should integrate with it
- What assumptions or constraints external AI agents must respect

When present:

- `.ai/document.md` is written in **English only**.
- It is a **project-facing integration document**, not a working document.
- It may be updated after tasks are completed to reflect new or changed integration capabilities.
- It must not be used as working memory or internal history.
- AI must not place project state, internal decisions, or changelog-style entries in this file.

---

## Knowledge Base

This project uses a **file-based Knowledge Base** (Obsidian vault) — not an MCP server or CLI.

- **Location:** `D:\project\unno.knowledge\knowledge\Projects\UNNO\Game Idledot\`
- **Access:** read/write Markdown files directly at that path.
- **Structure:** one folder for the project. `Game Idledot.md` is the index note; one topic note per system (e.g. `Map Grid.md`). Notes use Obsidian frontmatter (`tags`, `aliases`) and `[[wikilinks]]`. Prose may be Thai; technical content English.
- **Ongoing rule:** after each meaningful piece of work, record the details in the KB (what was built, key decisions, parameters, file paths). The KB is the durable design/work log. `.ai/memory.md` holds only the current state; chronological history goes to `CHANGELOG.md`.

---

## Mandatory AI Execution Order

1. Read `.ai/spec.md` first
2. Read `.ai/memory.md` second
3. Execute the assigned task
4. Update `.ai/memory.md`
5. Record meaningful work details in the Knowledge Base (see "Knowledge Base")

---

## AI Memory Discipline

- `.ai/memory.md` is the only persistent working memory for AI across tasks.
- AI must not rely on chat history as long-term memory.
- Any decision, assumption, or state required for future work must be written to `.ai/memory.md`.

### Task-Scoped Memory File Selection

AI may be instructed to use a task-specific memory file instead of the root `.ai/memory.md`.

If the user explicitly specifies a memory file path in the task instruction (e.g., "Start work by reading .ai/spec.md using `frontend/src/pages/crm/.ai/memory.md`"), then:

- Treat the specified file as the active `.ai/memory.md` for that task.
- Read from it as step 2 in the Mandatory AI Execution Order.
- Write updates to that file instead of the root `.ai/memory.md`.

If no memory file path is explicitly specified, use the root `.ai/memory.md`.

---

## Change Log Policy

- All historical and chronological records must be written to `CHANGELOG.md`.
- `.ai/memory.md` must reflect only the current state, not history.
- AI must not append change history to `.ai/memory.md`.
- Every completed task or meaningful change must result in an entry in `CHANGELOG.md`.

---

## Collaboration Protocol

- Keep this file authoritative.
- When implementing a new system, update this spec if rules change.
- Prefer small, testable increments.

---

## Open Questions

- Final theme naming set (fictional brands)
- Art style target (cartoon/flat/pixel)
- Server stack for leaderboard
- Monetization tuning (limits, cooldowns)
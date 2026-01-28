# AI_PLAN.md

> Source of truth: AI_SPEC.md. This plan decomposes the v0.1 MVP only.

---

## 1) Milestones (v0.1 only)

| Milestone | Goal | Primary Output |
|---|---|---|
| M1 | Foundations + Data Contracts | Core data schemas, save/load skeleton, config parsing contracts |
| M2 | Economy Core + Offline Progress | Deterministic economy math, trend decay, offline earnings |
| M3 | Map-First UX | Map grid, tile states, tap/long-press, bottom-sheet host |
| M4 | Building Panel + Upgrades | Building panel UI, upgrade quantities, validation/errors |
| M5 | Missions (3 Daily) + Telemetry (Minimum) | Basic mission tracking/rewards, minimal telemetry events |

---

## 2) Milestone Scopes

### M1: Foundations + Data Contracts

**IN**
- Canonical schemas and versioning rules (see DATA_SCHEMA.md)
- Config loading contracts for economy/buildings/missions/events
- Save container structure and integrity checks (no runtime loader code in this plan)
- Deterministic time source contract (real-time seconds)

**OUT**
- Any UI implementation
- Any live economy tick logic
- Prestige, leaderboard, ads, events runtime

### M2: Economy Core + Offline Progress

**IN**
- Formal formulas and trend decay model (see ECONOMY_SPEC.md)
- Offline progress algorithm (time-based, clamped)
- Large-number policy, rounding, and determinism rules
- Unit test plan (spec-level) for formula correctness

**OUT**
- Automation systems
- Prestige loop (v0.2)
- Ad-based boosts (v1.0)

### M3: Map-First UX

**IN**
- Top-down grid sizing and placement rules
- Tile states: locked/available/upgradeable/blocked/boosted
- Tap and optional long-press semantics (no scene switches)
- Bottom-sheet host container (anchored Control)
- Safe-area handling and touch target minimums

**OUT**
- Upgrade list tab
- Ranking, prestige, events screens

### M4: Building Panel + Upgrades

**IN**
- Building panel fields, layout order, CTA rules
- Upgrade quantity toggles: x1 / x10 / xMAX
- Before/after income presentation rules
- Error states: not enough money, locked, cooldown
- Basic boost slot if defined in config

**OUT**
- Advanced detail screens
- Multi-step menus

### M5: Missions (3 Daily) + Telemetry (Minimum)

**IN**
- Daily missions tracking (3) and reward claims
- Mission gating for building unlocks
- Telemetry events defined in AI_SPEC.md (session count, time-to-first-upgrade/prestige, etc.)

**OUT**
- Seasonal leaderboard submission
- Ad watch events and rewards

---

## 3) System Dependencies

- **Data Contracts (M1)** -> required by **Economy (M2)** and **Map/Panel (M3/M4)**
- **Economy (M2)** -> required by **Panel Upgrade UI (M4)** and **Mission targets (M5)**
- **Map UX (M3)** -> required by **Panel (M4)** for navigation and state cues
- **Missions (M5)** -> required by **Building unlock rules** (see AI_SPEC.md and DATA_SCHEMA.md)

ASCII dependency view:

```
M1 -> M2 -> M4
  \\-> M3 --/
      \\-> M5
```

---

## 4) Validation Criteria (Definition of Done per Milestone)

### M1 Completion
- Schemas defined for PlayerState, Building, Mission, Event
- Versioning and migration rules documented
- Save integrity rules defined (checksums/validation)
- No contradictions with AI_SPEC.md

### M2 Completion
- Economy formulas are fully specified and deterministic
- Trend decay model is time-based (not frame-based)
- Offline progress algorithm is step-by-step and clamped to cap
- Large-number precision policy is specified

### M3 Completion
- Map grid rules and placement constraints specified
- Interaction rules (tap/long-press/disabled) are explicit
- Visual indicators defined for upgradeable/blocked/boosted
- Bottom-sheet host behavior defined (no scene switch)
- Safe-area and touch-target constraints documented

### M4 Completion
- Building panel fields and layout order specified
- Upgrade flow defined for x1/x10/xMAX
- Before/after income rules stated and unambiguous
- Error states and messaging behavior documented

### M5 Completion
- Mission schema and examples match AI_SPEC.md constraints
- Reward claims and gating rules documented
- Telemetry event list and definitions provided

---

## 5) Risks & Mitigations (v0.1)

- **Risk:** Economy math ambiguity leads to tuning drift.
  - **Mitigation:** Central formula definitions in ECONOMY_SPEC.md; no ad-hoc math in UI.
- **Risk:** Offline progress inconsistent across devices.
  - **Mitigation:** Deterministic inputs only; elapsed time computed once per resume.
- **Risk:** UI complexity increases scene switching.
  - **Mitigation:** Bottom-sheet panel as anchored Control, map remains active.


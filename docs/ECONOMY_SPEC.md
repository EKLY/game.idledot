# ECONOMY_SPEC.md

> Source of truth: AI_SPEC.md. This document defines formal economy math for v0.1.

---

## 1) Core Definitions

Let:

- `level` = integer building level (>= 0)
- `baseCost`, `costRate` from config
- `baseOutput`, `outputRate` from config
- `trendMultiplier` = global multiplier (>= minMultiplier)
- `globalBonus` = product of global multipliers (prestige, infra, etc.)
- `boosts` = product of temporary multipliers (if active)

### 1.1 Building Upgrade Cost

```
cost(level) = baseCost * (costRate ^ level)
```

### 1.2 Building Output

```
output(level) = baseOutput * (outputRate ^ level)
```

### 1.3 Global Income Per Second

```
incomePerSec = sum(output(building_i)) * trendMultiplier * globalBonus * boosts
```

Notes:
- `output` for non-money buildings may be trend gain or modifiers; those apply via `globalBonus` or trend rules.

---

## 2) Trend Decay Model (Time-Based)

Trend is a global multiplier with decay defined in config:

- `decayPerMinute` (e.g., 0.02)
- `minMultiplier`
- `maxMultiplier`

### 2.1 Decay Formula (Exponential)

Given current trend at time `t0`, after elapsed minutes `m`:

```
trend(t0 + m) = max(minMultiplier, trend(t0) * (1 - decayPerMinute) ^ m)
```

Rules:
- Trend is clamped to `[minMultiplier, maxMultiplier]` after any update.
- Decay is calculated from elapsed real time, not per frame.

---

## 3) Trend Gain (from Trend Buildings)

If a building has `output.type = "trend"`:

```
trendGainPerSec(level) = baseTrendPerSec * (rate ^ level)
```

Trend update step (per economy evaluation interval):

```
trend = clamp(trend + trendGainPerSec * deltaSeconds, minMultiplier, maxMultiplier)
```

Notes:
- Trend gain must be applied using time deltas, not per-frame ticks.

---

## 4) Offline Progress Algorithm (v0.1)

### 4.1 Inputs

- `lastActiveAt` (UTC timestamp)
- `now` (UTC timestamp at resume)
- `offlineCapSeconds` (from config)
- `offlineEfficiency` (from config)
- Current `PlayerState` (money, trend, building levels, boosts)

### 4.2 Step-by-Step Algorithm

1) Compute elapsed time:
   - `elapsed = clamp(now - lastActiveAt, 0, offlineCapSeconds)`
2) If `elapsed == 0`, exit.
3) Determine segment boundaries:
   - `t=0`
   - boost expiry times (if active at logout)
   - time when trend reaches `minMultiplier` (if it will)
4) For each segment `[t_i, t_{i+1}]`:
   - Compute trend multiplier at segment start using decay formula.
   - Compute effective income per second for the segment.
   - Accumulate earnings:
     - `segmentEarnings = incomePerSec * (t_{i+1} - t_i)`
5) Total offline earnings = sum of segment earnings.
6) Apply efficiency:
   - `offlineEarnings = totalEarnings * offlineEfficiency`
7) Add to money; update trend to its value at `elapsed`.
8) Record `lastActiveAt = now`.
9) Show a one-time offline summary modal.

### 4.3 Deterministic Segmenting

- Use only deterministic events (boost expiration, trend floor).
- If no events occur, use a single segment for the full elapsed time.
- Do not use frame-based or variable step sizes.

---

## 5) Precision & Large-Number Handling

### 5.1 Internal Representation

- Use a scientific notation pair `(mantissa, exponent)` in base-10:
  - `value = mantissa * 10^exponent`
  - `mantissa` is in `[1, 10)` or `0`.
- This representation is used for money and income values.

### 5.2 Operations

- Addition: align exponents, add mantissas, normalize to `[1,10)`.
- Multiplication: multiply mantissas, add exponents, normalize.
- Division: divide mantissas, subtract exponents, normalize.

### 5.3 Rounding Policy

- Normalize after every operation.
- Round mantissa to 6 decimal places after normalization.
- Display rounding is separate from internal rounding.

### 5.4 Display Formatting

- Display uses SI-like suffixes (K, M, B, T, Qa, Qi) or scientific notation beyond Qi.
- Formatting must not alter internal stored values.

---

## 6) Determinism Rules

- Same inputs produce the same outputs across devices.
- Use UTC timestamps only; no locale-dependent formats.
- All formulas are pure functions of config + state + elapsed time.
- Clamp all values explicitly (trend min/max, offline cap).
- Do not use random values in core economy calculations.

---

## 7) Validation Checklist (v0.1)

- Formula outputs match AI_SPEC.md definitions.
- Trend decay uses real time, not frame counts.
- Offline progress equals online earnings at 70% efficiency for same elapsed time.
- Large-number formatting is consistent and stable.


# Dynamic FMI: Environmental Pressure Extension

**Status:** Conceptual — Future Work (Paper 2 candidate)  
**Author:** Kafkas M. Caprazli (ORCID: 0000-0002-5744-8944)  
**Date:** 2025-12-07  
**Origin:** Analysis of fast-turnover species validation results

---

## Executive Summary

Static FMI assumes natural mortality (M) is constant. However, environmental stressors (thermal anomalies, hypoxia, upwelling failure) can elevate effective mortality, particularly for small pelagic species. This document proposes a Dynamic FMI extension that incorporates environmental pressure, enabling the safe exploitation zone to contract during stress events. This would transform FMI from a static diagnostic into a climate-responsive early warning system.

---

## Scientific Rationale

### The Problem

Stratified ROC analysis revealed that FMI performs poorly for fast-turnover species:

| Life History | Optimal Threshold | AUC | Interpretation |
|--------------|-------------------|-----|----------------|
| Long-lived (M<0.2) | 4.91 | 0.79 | Fishing-driven collapses |
| Fast turnover (M≥0.8) | 0.45 | 0.71 | Non-fishing drivers dominate |

The low optimal threshold (0.45) for fast-turnover species indicates that collapse occurs even at low fishing pressure. This is consistent with extensive literature demonstrating environmental control of small pelagic populations:

- Peruvian anchoveta and El Niño (Chavez et al. 2003)
- California sardine and Pacific Decadal Oscillation (Jacobson & MacCall 1995)
- Japanese anchovy and Kuroshio Current dynamics (Watanabe et al. 1995)
- NW African anchovy and Canary Current upwelling (Belvèze & Erzini 1983)

### The Insight

Total mortality pressure on a stock has two components:

1. **Fishing pressure (F):** Anthropogenic removal — what FMI currently measures
2. **Environmental pressure (M_env):** Climate-driven mortality elevation — currently ignored

When environmental stress increases, the same fishing pressure becomes proportionally more dangerous. The safe exploitation zone should contract accordingly.

### The Mechanism

Environmental stressors elevate effective natural mortality through multiple pathways:

| Stressor | Mechanism | Effect on M |
|----------|-----------|-------------|
| Elevated SST | Higher metabolic costs, reduced growth efficiency | M increases |
| Hypoxia | Direct mortality, habitat compression | M increases |
| Upwelling failure | Reduced primary productivity, starvation | M increases |
| Marine heatwaves | Physiological stress, disease susceptibility | M increases |
| Acidification | Calcification stress, altered behavior | M increases |

---

## Proposed Extension

### Static FMI (Current Implementation)

```
FMI = F / M_base

Threshold = constant (e.g., 1.25)
Safe zone = FMI < Threshold
```

Assumes M is a fixed biological parameter.

### Dynamic FMI (Proposed)

```
M_effective = M_base + M_env(t)

Where:
  M_env(t) = f(SST_anomaly, ONI, O2, upwelling_index, ...)

FMI_dynamic = F / M_effective
```

**Or equivalently**, keep FMI formula unchanged but adjust threshold dynamically:

```
Threshold(t) = Threshold_base × g(environmental_stress)

Where g() is a contraction function:
  Normal conditions:  g = 1.0  → Threshold = 1.25
  El Niño conditions: g = 0.6  → Threshold = 0.75
  Marine heatwave:    g = 0.5  → Threshold = 0.625
```

### Visual Representation

```
        log(F)
          ↑
          │
     3.0  ┤        ██████████████████████████████████
          │        ██  DANGER ZONE (always unsafe)  ██
     2.0  ┤        ██████████████████████████████████
          │        ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ Static threshold (1.25)
     1.25 ┤═══════════════════════════════════════════
          │        - - - - - - - - - - - - - - - - -  Dynamic threshold (El Niño)
     0.75 ┤        ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
          │        
          │        ░░░░░░ SAFE ZONE ░░░░░░░░░░░░░░░░░
          │        ░░ (contracts under stress) ░░░░░░
     0.0  ┼────────────────────────────────────────────→ log(M)
```

During environmental stress events:
- The danger threshold drops
- The safe zone contracts
- The same F value that was safe yesterday becomes dangerous today
- Management response: reduce F to stay in safe zone

---

## Implementation Approach

### Phase 1: Proof of Concept (Single System)

Select well-documented system with:
- Long time series of stock assessments (F, B/BMSY)
- Strong environmental signal
- Documented collapses

**Candidate:** Peruvian anchoveta (PANCHCSCH)
- Oceanic Niño Index (ONI) readily available from NOAA
- Multiple documented El Niño collapses (1972, 1983, 1998)
- Extensive literature baseline

### Phase 2: Calibration

1. Define environmental stress index for region:
   ```
   E_stress = weighted_average(SST_anomaly, ONI, upwelling_index)
   ```

2. Estimate M_env empirically:
   ```
   M_env = α × E_stress
   
   Where α calibrated from historical stock-recruitment relationships
   ```

3. Or estimate threshold adjustment function:
   ```
   Threshold(t) = Threshold_base × exp(-β × E_stress)
   ```

### Phase 3: Validation

Compare predictive skill:

| Model | Sensitivity | Specificity | AUC |
|-------|-------------|-------------|-----|
| Static FMI | baseline | baseline | baseline |
| Dynamic FMI | ? | ? | ? |

**Success criterion:** Dynamic FMI shows improved AUC for small pelagics without degrading performance for other life histories.

### Phase 4: Generalization

If validated:
- Extend to other upwelling systems (California Current, Canary Current, Benguela)
- Develop region-specific M_env calibrations
- Create operational dashboard with real-time environmental inputs

---

## Data Requirements

| Data Type | Source | Temporal Coverage |
|-----------|--------|-------------------|
| F time series | RAM Legacy | 1950–present |
| B/BMSY time series | RAM Legacy | 1950–present |
| Sea Surface Temperature | NOAA OISST, Copernicus | 1982–present |
| Oceanic Niño Index | NOAA CPC | 1950–present |
| Upwelling indices | NOAA, regional sources | Variable |
| Dissolved oxygen | World Ocean Atlas, Argo | Limited |
| Chlorophyll-a | SeaWiFS, MODIS | 1997–present |

---

## Potential Challenges

| Challenge | Severity | Mitigation |
|-----------|----------|------------|
| Circular reasoning | High | Use independent training/test periods; out-of-sample validation |
| Time lags | Medium | Cross-correlation analysis to determine optimal lag structure |
| Regional specificity | Medium | Develop region-specific calibrations; avoid one-size-fits-all |
| Overfitting | High | Regularization; parsimony in predictor selection; cross-validation |
| Data availability | Medium | Focus on data-rich systems first |
| Causality vs correlation | High | Ground-truth with mechanistic literature |

---

## Novelty Assessment

| Component | Prior Art | Novel Contribution |
|-----------|-----------|-------------------|
| Climate effects on M | Extensive literature | No |
| Climate-adjusted reference points | Punt et al., others | No |
| F/M phase space visualization | FMI (this work) | Yes |
| **Dynamic thresholds in F/M space** | **Not implemented** | **Yes** |
| **Visual contraction of safe zone** | **Not implemented** | **Yes** |

The combination of FMI visualization with dynamic, climate-responsive thresholds would be novel.

---

## Estimated Effort

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Literature review | 2 weeks | None |
| Data acquisition | 2 weeks | NOAA, Copernicus access |
| Calibration | 4 weeks | R/Python implementation |
| Validation | 4 weeks | Statistical analysis |
| Manuscript | 4 weeks | Results complete |
| **Total** | **4–6 months** | After Paper 1 submission |

---

## Decision

**For Paper 1 (Current):** Do not implement. Add discussion paragraph acknowledging the limitation and proposing the extension as future work.

**For Paper 2 (Future):** Strong candidate. Would address the key limitation of static FMI for environmentally-sensitive stocks.

---

## Discussion Text for Paper 1

> The FMI framework as presented assumes constant natural mortality. However, environmental stressors—including thermal anomalies, hypoxia, and upwelling variability—can elevate effective mortality beyond baseline M values, particularly for small pelagic species tightly coupled to oceanographic conditions. The low optimal FMI threshold observed for fast-turnover species (0.45 vs. 2.15–4.91 for slower life histories) likely reflects this environmental sensitivity: these stocks collapse under conditions where fishing pressure alone would be sustainable, suggesting that non-fishing mortality dominates their population dynamics.
>
> A logical extension would incorporate environmental indices to dynamically adjust FMI thresholds. During El Niño events or marine heatwaves, the safe exploitation zone would contract, signaling managers to reduce fishing pressure even if static FMI values appear acceptable. This "environmental pressure" component would transform FMI from a static diagnostic into a climate-responsive early warning system. Development and validation of such a Dynamic FMI approach, initially focusing on well-documented upwelling systems such as the Humboldt Current, represents a priority for future research.
>
> Importantly, the current limitation does not invalidate FMI for its intended purpose. FMI is designed to detect fishing-driven overfishing and performs well for that objective (AUC = 0.79–0.85 for medium and long-lived species). For small pelagic management, FMI should be interpreted in conjunction with environmental monitoring rather than as a standalone indicator.

---

## References

Belvèze, H., & Erzini, K. (1983). The influence of hydroclimatic factors on the availability of the sardine (*Sardina pilchardus* Walbaum) in the Moroccan Atlantic fishery. *FAO Fisheries Report*, 291, 285–327.

Chavez, F. P., Ryan, J., Lluch-Cota, S. E., & Ñiquen, M. (2003). From anchovies to sardines and back: Multidecadal change in the Pacific Ocean. *Science*, 299(5604), 217–221.

Jacobson, L. D., & MacCall, A. D. (1995). Stock-recruitment models for Pacific sardine (*Sardinops sagax*). *Canadian Journal of Fisheries and Aquatic Sciences*, 52(3), 566–577.

Punt, A. E., A'mar, T., Bond, N. A., Butterworth, D. S., de Moor, C. L., De Oliveira, J. A., ... & Szuwalski, C. S. (2014). Fisheries management under climate and environmental uncertainty: control rules and performance simulation. *ICES Journal of Marine Science*, 71(8), 2208–2220.

Watanabe, Y., Zenitani, H., & Kimura, R. (1995). Population decline of the Japanese sardine *Sardinops melanostictus* owing to recruitment failures. *Canadian Journal of Fisheries and Aquatic Sciences*, 52(8), 1609–1616.

---

---

# PLAIN TEXT: The Car Dashboard Explanation

*For readers who want the concept without the jargon.*

---

## The Basic Idea

Imagine you're driving a car with two important gauges:

**Speedometer (F):** How fast you're going — this is fishing pressure  
**Tachometer/RPM (M):** How hard your engine is working — this is natural mortality

### The Current FMI: A Simple Speed Limit

Right now, FMI works like this:

> "If your speed divided by your RPM is above 1.25, you're in the danger zone."

This is like having a fixed speed limit: "Don't exceed 120 km/h."

Works fine on a sunny day on dry pavement.

---

### The Problem: Road Conditions Change

But what happens when:
- It starts raining? (El Niño)
- There's ice on the road? (marine heatwave)
- Fog rolls in? (hypoxia)

**The safe speed changes.** 

120 km/h on dry pavement = fine  
120 km/h on black ice = death

Same speed. Different conditions. Different outcome.

---

### What We Found

When we tested FMI on different types of fish:

**Long-lived fish (sharks, rockfish)** = Driving a tank
- Stable, heavy, not sensitive to road conditions
- Can handle higher "speeds" before crashing
- FMI works great for these

**Fast-turnover fish (anchovies, sardines)** = Driving a motorcycle
- Light, nimble, extremely sensitive to road conditions
- Crash even at low "speeds" when conditions are bad
- FMI alone doesn't predict their crashes well

---

### The Solution: A Smart Dashboard

What if your car had a dashboard that said:

> ☀️ **DRY CONDITIONS:** Safe speed limit = 120 km/h  
> 🌧️ **WET CONDITIONS:** Safe speed limit = 90 km/h  
> ❄️ **ICY CONDITIONS:** Safe speed limit = 50 km/h

**The speed limit adjusts to road conditions.**

That's Dynamic FMI:

> ☀️ **NORMAL OCEAN:** Safe FMI threshold = 1.25  
> 🌊 **EL NIÑO YEAR:** Safe FMI threshold = 0.75  
> 🔥 **MARINE HEATWAVE:** Safe FMI threshold = 0.50

---

### Why This Matters for Fishing

When ocean conditions get tough:

1. Fish are already stressed (equivalent to icy road)
2. Even "normal" fishing pressure becomes dangerous
3. The safe zone shrinks
4. Managers need to reduce catch limits

**Current FMI says:** "You're going 100 in a 120 zone — you're fine!"  
**Dynamic FMI says:** "You're going 100 in a 50 zone — SLOW DOWN!"

---

### The Two Pressure Gauges

Think of the fish population like a bank account:

**Withdrawals:**
1. 💰 Fishing (F) — what humans take out
2. 🌡️ Environment (M_env) — what nature takes out (heat stress, no food, bad water)

**Current FMI:** Only watches the fishing withdrawal  
**Dynamic FMI:** Watches BOTH withdrawals

When nature starts taking more (El Niño, heatwave), humans need to take less. Otherwise the account goes bankrupt (stock collapse).

---

### The Gas Tank Analogy

Your fish stock is like a gas tank:

- **M (natural mortality):** The baseline fuel consumption — engine always burns some fuel
- **F (fishing):** Additional fuel you burn by driving — controllable
- **M_env (environmental stress):** A fuel leak that opens up during bad weather

**Normal conditions:**
```
Tank drains at: M + F = sustainable if you refuel (reproduction)
```

**El Niño:**
```
Tank drains at: M + F + M_env = TOO FAST
Even if you don't change F, you're losing fuel faster
Solution: Reduce F to compensate for the leak
```

Dynamic FMI tells you: "There's a leak. Drive slower or you'll run out of gas."

---

### What We're NOT Doing (Yet)

This document describes the **concept**. We haven't built it yet.

**Paper 1 (now):** Static FMI — works great for most fish, acknowledge limitation for anchovies  
**Paper 2 (future):** Dynamic FMI — add the "road conditions" adjustment

---

### One-Sentence Summary

> **Static FMI is a speed limit sign. Dynamic FMI is a smart sign that changes based on road conditions — because 120 km/h on ice is not the same as 120 km/h on dry pavement.**

---

### For the Fisheries Manager

If you manage anchovies or sardines:

1. FMI alone won't predict your crashes — it's measuring the wrong thing
2. Watch El Niño indices, sea surface temperature, upwelling strength
3. When those go bad, reduce fishing BEFORE FMI tells you to
4. FMI + environmental monitoring = better than FMI alone

If you manage cod, rockfish, or other long-lived species:

1. FMI works well for you — trust it
2. Environmental variation matters less (you're driving the tank, not the motorcycle)
3. Focus on keeping FMI below threshold

---

*End of document.*

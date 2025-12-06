# FUTURE WORK: Life-History-Specific Exploitation Thresholds

> **Status:** Documented hypothesis for Paper 2  
> **Date:** 2025-12-06  
> **Author:** Kafkas M. Caprazli (ORCID: 0000-0002-5744-8944)

---

## The Limitation of Universal Thresholds

### Current Approach (Paper 1)

The Caprazli FMI uses **universal thresholds** based on Gulland (1971):

| Zone | F/M Ratio | Exploitation Rate (E) |
|------|-----------|----------------------|
| Safe | < 0.75 | < 0.43 |
| Gulland Limit | 1.0 | 0.50 |
| Danger | > 1.25 | > 0.56 |

These thresholds apply identically to all species regardless of life history.

### The Problem

Biological reality: **Species with different life histories have different sustainable exploitation rates.**

| Life History | Typical M | Intrinsic Growth (r) | Recovery Capacity |
|--------------|-----------|---------------------|-------------------|
| Long-lived (sharks, rockfish) | 0.02–0.2 | Very low | Decades |
| Medium (cod, tuna) | 0.2–0.4 | Moderate | Years |
| Moderate turnover (hake) | 0.4–0.8 | Moderate-high | 1-3 years |
| Fast turnover (anchovy, shrimp) | 0.8–2.0+ | Very high | Months |

**A single threshold cannot be optimal for all.**

---

## Evidence from Validation Results

### FMI Danger Breach Rates (from forensic_hindcast_validation.R)

| Life History | % Breached Danger (>1.25) | Mean Max FMI |
|--------------|---------------------------|--------------|
| Long-lived (M < 0.2) | **85%** | 6.54 |
| Medium (0.2 ≤ M < 0.4) | 67% | 3.96 |
| Moderate (0.4 ≤ M < 0.8) | 65% | 2.08 |
| Fast turnover (M ≥ 0.8) | **22%** | 1.15 |

### Interpretation

The 85% vs 22% gap is not random noise. It reflects:

1. **Systematic overfishing of long-lived species** — OR —
2. **Thresholds too lenient for long-lived, too strict for fast-turnover**

Both interpretations have the same implication: **Universal thresholds are suboptimal.**

---

## The Hypothesis

### Divergent Safety Lanes

Instead of parallel safety lanes (constant F/M ratios), optimal thresholds should **diverge by life history**:

```
        ↑ F (Fishing Mortality)
        │
        │              ___--- Fast turnover: F_safe = 1.5M
        │         __---
        │     __--      Medium: F_safe = 1.0M (Gulland)
        │   _-
        │  /            Long-lived: F_safe = 0.5M
        │ /
        │/
        └──────────────────────→ M (Natural Mortality)
              Low M           High M
              (Sharks)        (Anchovies)
```

### Proposed Life-History-Specific Thresholds

| Life History | M Range | Proposed F_safe/M | Proposed E_safe |
|--------------|---------|-------------------|-----------------|
| Long-lived | < 0.2 | 0.5 | 0.33 |
| Medium | 0.2–0.4 | 0.75 | 0.43 |
| Moderate | 0.4–0.8 | 1.0 | 0.50 |
| Fast turnover | ≥ 0.8 | 1.25–1.5 | 0.56–0.60 |

**Note:** These are hypothesized values requiring empirical validation.

---

## Testable Predictions

### Prediction 1: Collapse Rate Correlation
If universal thresholds are wrong, collapse rates should correlate with life history even after controlling for FMI.

**Test:** Compare collapse probability at FMI = 1.25 across life histories.

### Prediction 2: Optimal Threshold Varies
ROC analysis should yield different optimal F/M thresholds for each life history category.

**Test:** For each category, find F/M threshold that maximizes (sensitivity + specificity) for predicting collapse.

### Prediction 3: Improved Prediction with Adjusted Thresholds
Life-history-adjusted FMI should outperform universal-threshold FMI in predicting collapses.

**Test:** Compare AUC (area under ROC curve) between universal and adjusted models.

---

## Required Data for Paper 2

### From RAM Legacy

| Table | Variable | Purpose |
|-------|----------|---------|
| timeseries | SSB, TB (biomass) | Define collapse outcome |
| timeseries | F, U, ER | Calculate FMI |
| bioparams | M | Calculate FMI |
| stock | Taxonomy | Assign life history |

### Collapse Definition

```r
# Proposed collapse criteria
collapse <- B_BMSY < 0.2  # Below 20% of BMSY at any point in time series
# OR
collapse <- B < Blim      # Below limit reference point
```

### Analysis Method

```r
# Pseudocode for ROC optimization
for (life_history in c("long-lived", "medium", "moderate", "fast")) {
  
  stocks_lh <- filter(stocks, life_history == lh)
  
  # For each possible threshold
  for (threshold in seq(0.5, 2.0, by = 0.1)) {
    
    predicted_collapse <- FMI > threshold
    actual_collapse <- B_BMSY < 0.2
    
    sensitivity <- sum(predicted & actual) / sum(actual)
    specificity <- sum(!predicted & !actual) / sum(!actual)
    
    store(threshold, sensitivity, specificity)
  }
  
  optimal_threshold[lh] <- threshold_maximizing(sensitivity + specificity)
}
```

---

## Literature Support

### Existing Work on Life-History-Specific Thresholds

1. **Zhou et al. (2012)** — Proposed F/M as proxy, noted life history effects
2. **Froese (2004)** — Length-based indicators vary by life history
3. **Prince et al. (2015)** — SPR targets differ by productivity
4. **Then et al. (2015)** — M estimation varies by life history
5. **Hordyk et al. (2015)** — LBSPR accounts for life history in SPR

### Gap in Literature

No study has:
- Empirically derived optimal F/M thresholds per life history category
- Tested divergent thresholds on phase-space visualization
- Compared predictive accuracy of universal vs. adjusted thresholds

**This is the Paper 2 contribution.**

---

## Acknowledgment for Paper 1

### Suggested Text (Limitations Section)

> "The FMI thresholds used in this study (F/M = 0.75, 1.0, 1.25) are universal, applying the Gulland (1971) heuristic uniformly across all life histories. However, life history theory predicts that long-lived, low-productivity species (e.g., elasmobranchs, rockfish) require more conservative thresholds than fast-turnover species (e.g., small pelagics). Our validation results are consistent with this prediction: 85% of long-lived stocks breached the danger threshold compared to only 22% of fast-turnover stocks. Future work should derive empirically optimized, life-history-specific thresholds using ROC analysis to maximize predictive accuracy across the full spectrum of exploited taxa."

---

## Timeline

| Phase | Task | Target |
|-------|------|--------|
| Paper 1 | Universal thresholds + limitation acknowledgment | 2025 Q1 |
| Paper 2 | ROC analysis + life-history-specific thresholds | 2025 Q2-Q3 |
| Paper 3 | Ecosystem analysis (trophic level stratification) | 2025 Q4 |

---

## Files Related to This Hypothesis

```
caprazliFMI/
├── docs/
│   └── FUTURE_life_history_thresholds.md   ← THIS FILE
├── output/
│   └── forensic_hindcast/
│       └── breach_analysis_full.csv        ← Contains life history breach rates
└── R/
    └── [future] life_history_ROC_analysis.R
```

---

## Summary

**The insight is scientifically valid but requires dedicated analysis.**

For Paper 1: Acknowledge as limitation, cite supporting literature.

For Paper 2: Conduct ROC analysis, derive optimal thresholds, demonstrate improved prediction.

This positions the Caprazli FMI as an evolving framework that can incorporate life-history-specific refinements — a feature, not a bug.

---

*K. M. Caprazli, 2025-12-06*

# CLAUDE.md — Caprazli Fisheries Mortality Index (FMI)

> **Project Intelligence File for Claude Code CLI**  
> Last Updated: 2025-12-06  
> Status: Publication-Track Development

---

## 🎯 PROJECT IDENTITY

| Field | Value |
|-------|-------|
| **Name** | Caprazli FMI (Fisheries Mortality Index) |
| **Author** | Kafkas M. Caprazli (caprazli@gmail.com) |
| **ORCID** | [0000-0002-5744-8944](https://orcid.org/0000-0002-5744-8944) |
| **License** | MIT |
| **Language** | R (ggplot2-based visualization) |
| **Git Remote** | `github.com/capraCoder/caprazliFMI` |
| **Status** | Active Development — Targeting peer-reviewed publication |

---

## 📖 SCIENTIFIC ABSTRACT (Draft for Publication)

> "We propose the **Caprazli Fisheries Mortality Index (FMI)**, a dual-axis diagnostic tool for data-limited stocks. Unlike traditional single-point metrics (e.g., Exploitation Rate E), the FMI utilizes a log-log mortality phase plot to simultaneously visualize **exploitation status** (via ratio-based lane position relative to the F=M isocline) and **life-history magnitude** (via distance from the origin). This approach creates a unified 'Mortality Highway' that allows managers to compare risks across diverse taxa—from long-lived elasmobranchs to short-lived pelagics—within a single standardized framework."

---

## 🔬 THEORETICAL FOUNDATION

### The Problem with Exploitation Rate (E)

The traditional **Exploitation Rate** (E = F/Z = F/(F+M)) has critical limitations:

| Issue | Description |
|-------|-------------|
| **Compression** | As F increases, E asymptotically approaches 1.0. A change from F=2 to F=4 only moves E from 0.8 to 0.9 |
| **Loss of Magnitude** | E collapses two dimensions into one, hiding the difference between sharks (M=0.1) and sardines (M=1.2) |
| **Insensitivity** | At high fishing levels, E loses discriminatory power |

### The FMI Solution: Two Dimensions of Meaning

The FMI restores the lost dimension by plotting F vs. M on log-log axes:

**Dimension 1: STATUS (Lane Position on the Mortality Highway)**
- Measured by the F/M **ratio**, not geometric distance
- Center Lane: F = M (Gulland limit, E=0.5)
- Safe Lane: F < 0.75M (ratio F/M < 0.75)
- Danger Lane: F > 1.25M (ratio F/M > 1.25)

**Dimension 2: MAGNITUDE (Distance from Origin)**
- Measures biological turnover speed / "system energy"
- Near Origin: Slow dynamics, high fragility (sharks, rockfish)
- Far from Origin: Fast dynamics, high volatility (sardines, squid)

### Why Ratios, Not Geometric Distance

**Critical insight from development:** Using fixed geometric distance (e.g., "0.2 units from the line") creates dangerous bias:
- For Sardines (M=1.0): A buffer of 0.2 is small (F ranges 0.8–1.2)
- For Sharks (M=0.1): A buffer of 0.2 is enormous (would allow F up to 0.3, or 3× natural mortality!)

**The solution:** Define safety zones as **ratios** (F/M = 0.75, F/M = 1.25). On log-log axes, these ratios appear as **parallel lines** to the F=M isocline, creating a geometrically consistent "highway" regardless of species life history.

### Mathematical Proof: The 45° Line = E = 0.5

On the 45-degree line: F = M

Substituting into E = F/(F+M):
```
E = F/(F+F) = F/2F = 0.5
```

**Therefore, the 45° line is mathematically identical to the Gulland (1971) threshold.**

| Angle on Plot | Ratio (F/M) | Exploitation Rate (E) | Status |
|---------------|-------------|----------------------|--------|
| Low (< 45°) | F/M < 1 | E < 0.5 | Safe Zone |
| 45° Line | F/M = 1 | E = 0.5 | Threshold |
| Steep (> 45°) | F/M > 1 | E > 0.5 | Overfishing |
| Vertical (90°) | F/M >> 1 | E → 1.0 | Collapse |

---

## 🛣️ THE "MORTALITY HIGHWAY" METAPHOR

On log-log axes, the safety zones form a visual highway with parallel lanes:

```
        ↑ F (Fishing Mortality)
        │
        │    ══════════════  F = 1.25M (DANGER ZONE - Off Road)
        │    
        │    ──────────────  F = M (CENTER LINE - Gulland Limit)
        │    
        │    ══════════════  F = 0.75M (SAFE ZONE - Right Lane)
        │
        └──────────────────→ M (Natural Mortality)
```

**Lane Position** = Which ratio band (F/M) the stock occupies
**Speed** = Distance from origin (how fast the biological "engine" runs)

---

## 🌋 THE SEISMIC ANALOGY

The FMI is to fisheries what the **Richter Scale** is to geophysics. Both systems deal with power laws and energy flux.

### The Gutenberg-Richter Connection

| Seismology | Fisheries (FMI) |
|------------|-----------------|
| Gutenberg-Richter Law | Metabolic Theory of Ecology (Kleiber's Law) |
| Magnitude 2 tremors (frequent) | High-M species: sardines, squid (fast turnover) |
| Magnitude 9 quakes (rare) | Low-M species: sharks, whales (slow accumulation) |
| Cannot use same instruments for M2 vs M9 | Cannot use same quota tools for sardines vs sharks |

### Two Dimensions = Two Measurements

| FMI Dimension | Seismic Equivalent | Meaning |
|---------------|-------------------|---------|
| **Distance from Origin** | Magnitude (Energy Released) | Total Biological Flux — √(log²F + log²M) |
| **Lane Position (F/M ratio)** | Intensity (Damage Level) | Exploitation Stress — structural health |

### The Dashboard Metaphor

> *"The F/M ratio (FMI) is the **Tachometer**, protecting the engine from over-revving. Biomass-based limits are the **Fuel Gauge**, ensuring you don't run dry.*
>
> *In normal conditions, the Tachometer is the better guide for performance (Sustainability). But if the car drives off a cliff (Krakatoa), neither gauge matters—but the Fuel Gauge (Biomass) will hit zero first."*

**Key insight:** The FMI is a **dashboard for a running car**. It is not a detector for bridge collapse. It measures **Pressure**, not **State**.

---

## 📊 VISUALIZATION PROTOCOL: BIO-WEIGHTED VECTORS

The visual encoding is **scientifically weighted**, not decorative.

### Encoding Table

| Visual Element | Data Variable | Encoding | Scientific Interpretation |
|----------------|---------------|----------|---------------------------|
| **X-Position** | Natural Mortality (M) | Log scale | Biological Resilience — static species characteristic |
| **Wedge Thickness** | M (Natural Mortality) | Log-scaled (k=9), M∈[0.05,3.0] → width∈[0.8pt,6.0pt] | **Bio-Weighting / Ecological Flux** — Thick lines = high-turnover stocks (sardines) |
| **Wedge Direction** | ΔF (F_end − F_start) | Up/Down | **Management Trajectory** — Up = worsening, Down = improving |
| **Color Saturation** | \|ΔF\| (magnitude of change) | Log-scaled (k=15), diverging | **Change Intensity** — Darker = more drastic policy shift |
| **Color Hue** | Sign of ΔF | Diverging scale | **Direction** — Red = increasing F (bad), Blue = decreasing F (good) |
| **Golden Halo** | Outliers (>90th percentile ΔF) | Binary flag | **Early Warning Signal** — Flags extreme shifts |

### Key Parameters (in `batch_regions_dual_mode_v6.R`)

```r
# Thickness (Bio-Weighting)
T_MIN  <- 0.8    # Minimum line thickness (pt)
T_MAX  <- 6.0    # Maximum line thickness (pt)
K_THICKness <- 9 # Log scaling factor

# Color (Change Intensity)
K_COLOR <- 15    # Log scaling factor for color

# Geometry
WEDGE_SCALER <- 0.015  # Fatness: 0.008=Needle, 0.015=Wedge, 0.025=Cone

# M Range
M_MIN  <- 0.05
M_MAX  <- 3.0
```

### The Thickness Formula

```r
M_Norm = pmin(pmax((M - M_MIN) / (M_MAX - M_MIN), 0), 1)
Vis_Thickness = T_MIN + (T_MAX - T_MIN) * (log1p(K_THICKness * M_Norm) / log1p(K_THICKness))
```

### Why Log-Log Scales Are Essential

On log-log axes, **percentage changes become linear distances**. This means:
- A shark going from F=0.1 to F=0.2 (100% increase) has the **same visual length** as a sardine going from F=1.0 to F=2.0 (100% increase)
- This is scientifically correct: both represent the same **relative policy failure**
- Safety zone boundaries (F=0.75M, F=1.25M) appear as **parallel lines** to the F=M isocline — creating consistent lane widths across all life histories

---

## 🔬 FORENSIC VALIDATION — HISTORICAL CASE STUDIES

The FMI was tested against known stock collapses using **5-year Hindcast Analysis**.

### Case 1: Northern Cod (Atlantic Canada)

| Metric | Value |
|--------|-------|
| **Collapse Year** | 1992 (moratorium declared) |
| **FMI Warning Signal** | Breached F = 1.25M in **1987** |
| **Lead Time** | **5 years advance warning** |
| **Conclusion** | ✅ **SUCCESS** — FMI correctly flagged the most famous fishery collapse in history |

### Case 2: Georges Bank Haddock (US East Coast)

| Metric | Value |
|--------|-------|
| **Collapse Year** | 1994 |
| **FMI Signal** | **No breach** (Max F ≈ 0.19, Limit ≈ 0.25) |
| **Conclusion** | ⚠️ **INSTRUCTIVE FAILURE** — Collapse was due to recruitment/biomass factors, NOT high F |

### Scientific Insight

> Georges Bank proves the FMI is **not a silver bullet**. It measures **Pressure** (the tachometer), not **State** (the fuel gauge). The FMI must be connected to biomass analysis for complete diagnosis.

---

## 📈 PEER REVIEW ASSESSMENT

### Initial Score: 7.5 / 10

**Critiques Received:**

1. **"False Precision"** — FMI implies precision that doesn't exist in M estimates
2. **"Empty Tank Blindspot"** — FMI measures pressure, not state (can show "safe" while biomass is 5%)
3. **"Gulland Controversy"** — F=M may be too aggressive for low-productivity stocks

### Rebuttals & Upgrades

| Critique | Rebuttal | Upgrade |
|----------|----------|---------|
| **False Precision** | E uses identical inputs. Log scales actually **reduce** noise sensitivity (decimal changes → negligible movement) | Log-log visualization emphasizes orders of magnitude, not decimal noise |
| **Empty Tank Blindspot** | Valid limitation | **Time trajectories (vectors)** solve "Are we fixing it?" question — if vector points away from danger, we know we stopped draining the tank |
| **Gulland Controversy** | Same critique applies to E=0.5 | FMI makes adjustments **visually explicit** — shift safety lane from F=M to F=0.5M for sensitive species. The ratio-based approach makes precautionary adjustments intuitive. |

### Revised Score: 8.5 / 10

> *"Accept with Major Revisions"* — a very strong starting position for peer review.

---

## 🚀 LOGICAL EXTENSIONS — FUTURE RESEARCH

### A. Consequence Analysis (FMI vs. Biomass)

**Logic:** Validate if high FMI pressure (F/M > 1) actually leads to stock collapse (B/B_MSY < 0.5).

**Visualization:** Scatter plot with quadrants:
- X-axis: Caprazli Ratio (F/M)
- Y-axis: Biomass Status (B/B_MSY)
- **Quadrant of Death** (Bottom-Right): High FMI + Low Biomass → proves FMI works
- **Quadrant of Resilience** (Top-Right): High FMI + High Biomass → "Zombie Stocks" (why do they survive?)

### B. Ecosystem Analysis (Trophic Levels)

**Logic:** Are we protecting Apex Predators (TL > 4.0) more strictly than Forage Fish (TL < 3.0)?

**Visualization:** FMI Comet Plots faceted by Trophic Level:
- Panel A: Apex Predators (should be thin lines, mostly in Safe Zone)
- Panel B: Forage Fish
- **Crisis Signal:** Red arrows in Apex Predator panel = "Fishing Down the Food Web"

### C. Economic Analysis (Yield Bubble)

**Logic:** Not all dots are equal economically. Overfishing Alaskan Pollock = global food crisis.

**Visualization:** Bubble size scaled by Total Catch (tonnes) or Ex-Vessel Value ($).
- Huge bubbles in Safe Zone → food supply secure
- Huge bubbles in Danger Zone → food security crisis

### D. Global Pulse (Ratio Distribution)

**Logic:** Single macro-level scorecard — how is the planet doing?

**Visualization:** Stacked Density Plot of F/M ratio by decade (1980s, 1990s, 2000s, 2010s).
- Has the peak shifted left (toward safety) or remained right (danger)?
- Visualizes the "global shift in consciousness" about fisheries management.

---

## 📁 PROJECT STRUCTURE

```
C:\Users\capra\caprazliFMI\
│
├── CLAUDE.md                    ← THIS FILE
├── README.md                    ← Public documentation
├── CaprazliFMI.Rproj           ← RStudio project
├── Dockerfile                   ← Container reproducibility
├── .gitignore
│
├── R/                           ← ALL R SCRIPTS
│   ├── Caprazli_FMI_Engine.R           ← Core engine
│   ├── Caprazli_Static_Master.R        ← ⭐ Final static plots
│   ├── batch_regions_dual_mode_v6.R    ← ⭐ Wedge generator
│   ├── validation_forensic_final.R     ← ⭐ Historical validation
│   ├── trajectory_analysis.R           ← Full temporal paths
│   ├── global_analysis.R               ← All-region sweep
│   └── schema_scout.R                  ← DB explorer
│
├── data/
│   └── RAM_DBdata.RData                ← RAM Legacy v4.64 (~600 MB)
│
├── output/                              ← Generated visualizations
│   ├── regions_v1/ ... v6/             ← Static plot iterations
│   └── dual_motion_broad_v1/ ... v3/   ← Wedge trajectory versions
│
├── docs/                                ← Methodology notes
│
└── run_*.ps1                            ← PowerShell launchers
```

---

## 📊 DATA SOURCE

**RAM Legacy Stock Assessment Database v4.64**

| Property | Value |
|----------|-------|
| Source | Zenodo (DOI available) |
| Format | `.RData` containing relational tibbles |
| Size | ~600 MB |
| Coverage | 400+ stocks globally |

### Key Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `bioparams` | Biological parameters | `stockid`, `bioid` (filter: "M-*"), `biovalue` |
| `timeseries` | Time series data | `stockid`, `tsyear`, `tsid` (filter: "F-*", "U-*", "ER-*"), `tsvalue` |
| `stock` | Metadata | `stockid`, `commonname`, `region`, `scientificname` |

### Standard Extraction Pattern

```r
# Natural Mortality (M)
m_data <- bioparams %>%
  filter(grepl("^M-", bioid)) %>%
  mutate(M = as.numeric(biovalue)) %>%
  group_by(stockid) %>%
  summarise(M = mean(M, na.rm = TRUE))

# Fishing Mortality (F) — priority: F > U > ER
f_data <- timeseries %>%
  filter(grepl("^(F|U|ER)-", tsid)) %>%
  mutate(metric_type = substr(tsid, 1, 1)) %>%
  group_by(stockid, tsyear) %>%
  arrange(metric_type) %>%
  slice(1)
```

---

## 🎨 VISUAL CONVENTIONS

### Color Palette

| Element | Color | Hex | Meaning |
|---------|-------|-----|---------|
| Increasing F | Red | `#c0392b` | Bad — pressure intensifying |
| Decreasing F | Blue | `#2980b9` | Good — recovery |
| Neutral | Grey | `grey80` | Stable/stagnant |
| F=M isocline | Dark grey | `#34495e` | Gulland limit |
| Safe boundary | Green dashed | `#27ae60` | F = 0.75M |
| Danger boundary | Red dashed | `#e74c3c` | F = 1.25M |
| Outlier halo | Yellow | `#f1c40f` | Early warning |

### Scale Conventions

- **ALWAYS log-log axes** (never linear without explicit request)
- X-axis (M): 0.05 to 3.0
- Y-axis (F): 0.01 to 4.0

---

## 📚 KEY REFERENCES

| Citation | Relevance |
|----------|-----------|
| Gulland (1971) | F=M heuristic, E=0.5 threshold |
| Pauly (1980) | ELEFAN methodology, M estimation |
| Pauly (1984) | E interpretation for tropical stocks |
| Froese (2004) | Length-based indicators |
| Zhou et al. (2012) | Data-limited methods, F/M as proxy |
| Prince et al. (2015) | Length-based SPR |
| Hordyk et al. (2015) | LBSPR methodology |
| Then et al. (2015) | Natural mortality estimation |
| Kleiber's Law | Metabolic scaling (seismic analogy foundation) |

---

## 📝 PUBLICATION STRATEGY

### Target Journals

| Journal | Type | Notes |
|---------|------|-------|
| **Fisheries Research** | Technical methods | Good for novel diagnostics |
| **ICES Journal of Marine Science** | High-impact | Requires strong empirical validation |
| **Fish & Fisheries** | Review/methods | If framed as paradigm shift |
| **PLOS ONE** | Open access | Judges technical soundness, not "importance" — good for independents |
| **Marine Policy** | Policy focus | If emphasizing dashboard/management aspects |

### Publication Roadmap

1. [ ] **Complete forensic validation** on 10+ stocks across life histories
2. [ ] **Preprint upload** to EcoEvoRxiv or bioRxiv (establishes priority, gets DOI)
3. [ ] **Zenodo DOI** for R code repository
4. [ ] **Cold-contact experts** for feedback:
   - Jason Cope (data-limited methods)
   - Rainer Froese (length-based indicators)
   - Natalie Dowling (CSIRO)
   - Thomas Carruthers (DLMtool)
5. [ ] **Submit Short Communication** (~3,000 words)

### Manuscript Structure

```
1. Abstract (use draft above)
2. Introduction: E's limitations, the FMI solution
3. Methods: Geometry, log-log derivation, ratio-based safety zones, bio-weighting protocol
4. Case Studies: Northern Cod (success), Georges Bank (instructive failure)
5. Discussion: Seismic analogy, limitations, connection to biomass
6. Conclusion: FMI as triage tool for data-limited stocks
```

---

## ⚙️ DEPENDENCIES

```r
# Core
library(ggplot2)
library(dplyr)
library(tidyr)

# Visualization
library(ggrepel)
library(viridis)
library(scales)
library(grid)

# Animation (optional)
library(gganimate)
library(gifski)
```

---

## 📋 CONVENTIONS FOR CLAUDE CODE

When working on this project:

1. **Preserve author attribution** — All outputs credit "Kafkas M. Caprazli" / caprazli@gmail.com / ORCID 0000-0002-5744-8944
2. **File naming** — `snake_case.R`, version suffixes like `_v2.R`, `_v3.R`
3. **Output versioning** — Auto-increment: `output/regions_vN/`, `output/dual_motion_broad_vN/`
4. **Log-log is sacred** — Never switch to linear axes without explicit request
5. **Color semantics are fixed** — Red = bad (↑F), Blue = good (↓F). **Never reverse.**
6. **Visualization is science** — Encoding is meaningful, not decorative
7. **Use ratio-based language** — "Lane position" and "F/M ratio", NOT "perpendicular distance"
8. **Cite Gulland (1971)** when discussing F=M threshold
9. **Frame as triage tool** — Not a replacement for full stock assessment

---

## 🔗 RELATED PROJECTS

**FISHSTOCK-ANALYST** (`C:\Users\capra\fishstock-analyst\`)
- Author's automated length-based stock assessment system
- Uses TropFishR, LBSPR for data-limited assessments
- Docker-based, Python + R integration
- Potential future integration with FMI for unified PERSGA toolkit

---

## 💬 AUTHOR NOTES

The FMI was developed to provide managers with an intuitive "seismic" view of fisheries status. The metaphor of earthquakes (magnitude + location) maps well to fisheries (turnover + compliance). The wedge visualization emerged from frustration with static point plots that hide temporal dynamics.

The forensic validation against Northern Cod (success) and Georges Bank Haddock (instructive failure) demonstrates both the power and limitations of the approach. 

**Core insight:** The FMI is a **pressure gauge**, not a **state indicator**. It answers "Are we fishing recklessly relative to biology?" but not "How much fish is left?" Both questions matter. The FMI excels at the first.

**Technical note on geometry:** Safety zones are defined by F/M **ratios** (0.75, 1.0, 1.25), which appear as parallel lines on log-log axes. This ratio-based approach ensures consistent lane widths regardless of species life history — a shark (M=0.1) and a sardine (M=1.0) both have the same proportional safety margin.

Future work priorities:
1. M-dependent safety thresholds (stricter for low-M species)
2. Uncertainty visualization (confidence ellipses)
3. Connection to B/B_MSY (Consequence Analysis)
4. Trophic-level stratification (Ecosystem Analysis)

— K. M. Caprazli, 2025

# Caprazli Fisheries Mortality Index (FMI)

[![DOI](https://zenodo.org/badge/1111089433.svg)](https://doi.org/10.5281/zenodo.17844169)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-≥4.0-blue.svg)](https://www.r-project.org/)

**A visualization framework for fisheries exploitation status with life-history-specific threshold calibration**

---

## Author

**Kafkas M. Caprazli**  
📧 caprazli@gmail.com  
🆔 ORCID: [0000-0002-5744-8944](https://orcid.org/0000-0002-5744-8944)

---

## Overview

The Caprazli Fisheries Mortality Index (FMI) plots fishing mortality (F) against natural mortality (M) on log-log axes. Unlike the traditional Exploitation Rate (E = F/Z), which compresses information into a single dimension, FMI preserves two independent dimensions:

1. **Status** — Position relative to the F=M isocline (Gulland threshold)
2. **Magnitude** — Distance from origin representing biological turnover

The F=M line is mathematically equivalent to E=0.5:

```
F = M  →  E = F/(F+M) = 0.5
```

This anchors FMI to the Gulland (1971) heuristic while providing superior visual discrimination across life histories.

---

## Validation Results

Validated on **209 stocks** (10,565 stock-years) from the RAM Legacy Database.

### Performance

| Approach | Sensitivity | Specificity | PPV | AUC |
|----------|-------------|-------------|-----|-----|
| Universal (threshold 1.25) | 89% | 39% | 54% | 0.72 |
| **Stratified** | 76% | **69%** | **66%** | 0.71–0.85 |

### Life-History-Specific Thresholds

| Life History | M Range | Optimal Threshold | AUC |
|--------------|---------|-------------------|-----|
| Long-lived | < 0.2 | 4.91 | 0.79 |
| Medium | 0.2–0.4 | 2.15 | 0.79 |
| Moderate turnover | 0.4–0.8 | 2.45 | 0.85 |
| Fast turnover | ≥ 0.8 | 0.45 | 0.71 |

**Key finding:** Stratification improves specificity from 39% to 69% (+30 percentage points).

---

## Quick Start

### Prerequisites

```r
install.packages(c("dplyr", "tidyr", "ggplot2", "purrr", "pROC", "cli"))
```

### Run Validation

```powershell
& "C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe" R\sliding_window_validation.R
& "C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe" R\stratified_roc_analysis.R
```

---

## Repository Structure

```
caprazliFMI/
├── R/
│   ├── RAM_validation_candidates.R      # Extract F+M stocks
│   ├── sliding_window_validation.R      # Main validation
│   ├── stratified_roc_analysis.R        # Life-history ROC
│   └── investigate_false_negatives.R    # Diagnostic analysis
├── output/
│   ├── sliding_window/                  # Validation results
│   └── stratified_roc/                  # Stratified analysis
├── docs/
│   ├── VALIDATION_sliding_window.md     # Results documentation
│   ├── FUTURE_dynamic_FMI.md            # Paper 2 roadmap
│   └── FUTURE_life_history_thresholds.md
├── data/                                # RAM Legacy (not in git)
├── CLAUDE.md                            # Project intelligence
└── README.md
```

---

## Data Source

**RAM Legacy Stock Assessment Database v4.65**  
DOI: [10.5281/zenodo.7708834](https://doi.org/10.5281/zenodo.7708834)

> Ricard, D., Minto, C., Jensen, O.P., and Baum, J.K. (2012). Examining the knowledge base and status of commercially exploited marine species with the RAM Legacy Stock Assessment Database. *Fish and Fisheries* 13(4): 380-398.

---

## Citation

```bibtex
@software{caprazli_fmi_2025,
  author    = {Caprazli, Kafkas M.},
  title     = {Caprazli Fisheries Mortality Index (FMI)},
  year      = {2025},
  publisher = {Zenodo},
  doi       = {10.5281/zenodo.17844169},
  url       = {https://github.com/capraCoder/caprazliFMI}
}
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Contact

**Kafkas M. Caprazli**  
📧 caprazli@gmail.com  
🆔 ORCID: [0000-0002-5744-8944](https://orcid.org/0000-0002-5744-8944)

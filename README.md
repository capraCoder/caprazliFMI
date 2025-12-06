# Caprazli Fisheries Mortality Index (FMI)

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-≥4.0-blue.svg)](https://www.r-project.org/)

**A dual-axis diagnostic tool for data-limited fisheries stock assessment**

---

## Author

**Kafkas M. Caprazli**  
📧 caprazli@gmail.com  
🆔 ORCID: [0000-0002-5744-8944](https://orcid.org/0000-0002-5744-8944)

---

## Overview

The Caprazli Fisheries Mortality Index (FMI) is a visualization and diagnostic framework that plots fishing mortality (F) against natural mortality (M) on log-log axes. Unlike the traditional Exploitation Rate (E = F/Z), which compresses information into a single dimension, the FMI preserves two independent dimensions of meaning:

1. **STATUS** — Lane position relative to the F=M isocline (Gulland threshold)
2. **MAGNITUDE** — Distance from origin representing biological turnover speed

This creates a "Mortality Highway" where species from sharks (low M) to sardines (high M) can be compared on a unified scale, with safety zones defined by F/M ratios (0.75, 1.0, 1.25) appearing as parallel lanes.

### Key Innovation

The F=M line (45° on log-log axes) is mathematically equivalent to E=0.5:

```
On the line: F = M
Therefore:   E = F/(F+M) = F/2F = 0.5
```

This anchors the FMI to the classic Gulland (1971) heuristic while providing superior visual discrimination across life histories.

---

## Scientific Background

### The Problem with Exploitation Rate

| Issue | Description |
|-------|-------------|
| **Compression** | E asymptotically approaches 1.0 at high F |
| **Loss of Magnitude** | Collapses two dimensions into one |
| **Insensitivity** | Cannot distinguish sharks (M=0.1) from sardines (M=1.2) |

### The FMI Solution

- **Ratio-based safety zones** (F/M = 0.75, 1.0, 1.25) create consistent lane widths across all life histories
- **Log-log scales** make percentage changes linear distances
- **Bio-weighted visualization** encodes ecological flux in line thickness

### Key References

- Gulland, J.A. (1971). *The Fish Resources of the Ocean*. Fishing News Books.
- Pauly, D. (1980). On the interrelationships between natural mortality, growth parameters, and mean environmental temperature in 175 fish stocks. *ICES Journal of Marine Science* 39(2):175-192.
- Zhou, S. et al. (2012). Ecosystem-based fisheries management requires a change to the selective fishing philosophy. *PNAS* 109(26):9485-9489.

---

## Data Sources

### Primary: RAM Legacy Stock Assessment Database

| Field | Value |
|-------|-------|
| **Name** | RAM Legacy Stock Assessment Database |
| **Version** | 4.64 |
| **DOI** | [10.5281/zenodo.7708834](https://doi.org/10.5281/zenodo.7708834) |
| **URL** | https://www.ramlegacy.org |
| **Format** | `.RData` containing relational tibbles |
| **Local Path** | `data/RAM_DBdata.RData` |
| **Size** | ~600 MB |

**Coverage Statistics (as extracted 2025-12-06):**

| Metric | Count |
|--------|-------|
| Total stocks in database | 1,512 |
| Stocks with M estimates | 366 |
| Stocks with F time series | 961 |
| **Stocks with BOTH F and M** | **344** |

**Primary Citation:**

> Ricard, D., Minto, C., Jensen, O.P., and Baum, J.K. (2012). Examining the knowledge base and status of commercially exploited marine species with the RAM Legacy Stock Assessment Database. *Fish and Fisheries* 13(4): 380-398. DOI: [10.1111/j.1467-2979.2011.00435.x](https://doi.org/10.1111/j.1467-2979.2011.00435.x)

**Data Extraction Methodology:**

- **Natural Mortality (M):** Extracted from `bioparams` table, filtering `bioid` starting with "M-"
- **Fishing Mortality (F):** Extracted from `timeseries` table, priority order: F > U (exploitation rate) > ER
- **Quality filtering:** M values constrained to 0 < M < 5; F values ≥ 0

### Supplementary: Life History Parameters

For stocks lacking M estimates, supplementary values can be derived from:

- **FishBase** (www.fishbase.org) — Pauly equation estimates
- **FishLife** R package (Thorson et al. 2017) — Phylogenetic predictions

---

## Repository Structure

```
caprazliFMI/
│
├── CLAUDE.md                         # Project intelligence file
├── README.md                         # This file
├── CaprazliFMI.Rproj                # RStudio project
├── Dockerfile                        # Container reproducibility
├── LICENSE                           # MIT License
│
├── R/                                # Analysis scripts
│   ├── RAM_validation_candidates.R   # Extract F+M stocks from RAM Legacy
│   ├── Caprazli_Static_Master.R      # Static FMI plots
│   ├── batch_regions_dual_mode_v6.R  # Wedge trajectory generator
│   ├── validation_forensic_final.R   # Historical collapse validation
│   └── ...
│
├── data/                             # Source data (not in git)
│   └── RAM_DBdata.RData              # RAM Legacy v4.64
│
├── output/                           # Generated outputs
│   ├── validation/                   # FMI validation datasets
│   │   ├── RAM_all_FMI_candidates.csv
│   │   ├── RAM_top15_validation.csv
│   │   ├── RAM_life_history_summary.csv
│   │   └── RAM_famous_stocks.csv
│   ├── regions_v1/ ... v6/          # Static plot iterations
│   └── dual_motion_broad_v1/ ... v3/ # Wedge trajectory versions
│
├── docs/                             # Methodology documentation
│
└── run_*.ps1                         # PowerShell launchers
```

---

## Validation Corpus

The FMI validation pool consists of 344 stocks stratified by life history:

| Life History Category | M Range | Stocks | Example Species |
|-----------------------|---------|--------|-----------------|
| Long-lived | < 0.2 | 148 | Acadian redfish, Cowcod |
| Medium-lived | 0.2–0.4 | 123 | Albacore tuna, California scorpionfish |
| Moderate turnover | 0.4–0.8 | 37 | Cape hake, Pacific chub mackerel |
| Fast turnover | ≥ 0.8 | 36 | Atlantic menhaden, Anchovy |

### Forensic Validation Cases

| Stock | Common Name | M | Mean FMI | Status |
|-------|-------------|---|----------|--------|
| CODIS | Icelandic Cod | 0.20 | 5.15 | Known issues |
| COWCODSCAL | Cowcod | 0.06 | 5.71 | Collapsed |
| HERR4VWX | Herring (4VWX) | 0.20 | 3.14 | Overfished |
| ALBANATL | Albacore Tuna | 0.30 | 0.27 | Healthy benchmark |

---

## Installation & Usage

### Prerequisites

```r
install.packages(c("dplyr", "tidyr", "ggplot2", "stringr"))
```

### Download RAM Legacy Database

```r
# Option 1: Via ramlegacy package
install.packages("ramlegacy")
library(ramlegacy)
download_ramlegacy(version = "4.65")

# Option 2: Direct from Zenodo
# https://doi.org/10.5281/zenodo.7708834
# Download and place in data/RAM_DBdata.RData
```

### Run Validation Candidate Extraction

```powershell
# From project root
& "C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe" R\RAM_validation_candidates.R
```

Or use the PowerShell launcher:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_validation_candidates.ps1
```

### Output Files

After running, check `output/validation/` for:

- `RAM_all_FMI_candidates.csv` — All 344 stocks with F+M data
- `RAM_top15_validation.csv` — Top candidates per life history category
- `RAM_life_history_summary.csv` — Category breakdown
- `RAM_famous_stocks.csv` — Iconic stocks (cod, herring, anchovy, etc.)

---

## Reproducibility

### Software Environment

| Component | Version |
|-----------|---------|
| R | 4.5.1+ |
| dplyr | 1.1.0+ |
| tidyr | 1.3.0+ |
| ggplot2 | 3.4.0+ |
| Operating System | Windows 11 / Linux (Docker) |

### Docker (optional)

```bash
docker build -t caprazli-fmi .
docker run -v $(pwd)/output:/app/output caprazli-fmi
```

---

## Citation

If you use this work, please cite:

```bibtex
@software{caprazli_fmi_2025,
  author       = {Caprazli, Kafkas M.},
  title        = {Caprazli Fisheries Mortality Index (FMI)},
  year         = {2025},
  publisher    = {GitHub},
  url          = {https://github.com/capraCoder/caprazliFMI}
}
```

And the underlying data source:

```bibtex
@article{ricard2012ram,
  author  = {Ricard, Daniel and Minto, C{\'o}il{\'i}n and Jensen, Olaf P. and Baum, Julia K.},
  title   = {Examining the knowledge base and status of commercially exploited marine species with the {RAM} {Legacy} {Stock} {Assessment} {Database}},
  journal = {Fish and Fisheries},
  year    = {2012},
  volume  = {13},
  number  = {4},
  pages   = {380--398},
  doi     = {10.1111/j.1467-2979.2011.00435.x}
}
```

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

The RAM Legacy Stock Assessment Database is subject to its own terms of use. See https://www.ramlegacy.org for details.

---

## Acknowledgments

- RAM Legacy Database team for maintaining the global stock assessment repository
- Dr. Daniel Pauly and colleagues for foundational work on natural mortality estimation
- The R community for open-source statistical tools

---

## Contact

For questions, collaborations, or feedback:

**Kafkas M. Caprazli**  
📧 caprazli@gmail.com  
🆔 ORCID: [0000-0002-5744-8944](https://orcid.org/0000-0002-5744-8944)

# The Caprazli Fisheries Mortality Index (FMI)

[![Status](https://img.shields.io/badge/Status-Active_Development-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)]()
[![R](https://img.shields.io/badge/Built_With-R_4.5+-blue.svg)]()

> **A dual-axis diagnostic tool for visualizing fisheries status and turnover magnitude in data-limited stocks.**

## 📖 Overview

The **Caprazli FMI** is a quantitative framework that addresses the limitations of the traditional Exploitation Rate ($E = F/Z$) metric. By mapping stocks onto a log-log phase plot of Fishing Mortality ($F$) vs. Natural Mortality ($M$), the FMI reveals two critical dimensions of fisheries management simultaneously:

1.  **Status (Compliance):** The perpendicular distance from the $F=M$ isocline (Gulland limit) indicates overfishing severity.
2.  **Magnitude (Turnover):** The distance from the origin indicates the biological speed of the system (Vector Magnitude), differentiating "High Volatility" stocks (e.g., Sardines) from "High Fragility" stocks (e.g., Sharks).

## 📊 The "Seismic" Dashboard

The pipeline generates a standardized phase plot with parallel safety isoclines.

* **X-Axis:** Natural Mortality ($M$) - Proxy for Biological Turnover.
* **Y-Axis:** Fishing Mortality ($F$) - Proxy for Anthropogenic Pressure.
* **Zones:**
    * 🔴 **Danger Zone:** $F > 1.25M$
    * 🟢 **Safe Zone:** $F < 0.75M$
    * 🛣️ **The Corridor:** $F \approx M$ (Target)

## 🚀 Quick Start (Reproducibility)

This repository is containerized for instant reproducibility. You do not need to install R libraries manually.

### Option A: The "One-Click" Launcher (Windows)
Double-click `run_fmi.ps1`. This script will:
1.  Locate your local R installation.
2.  Install missing dependencies (`TropFishR`, `ggplot2`, etc.).
3.  Execute the stress tests and the `synLFQ7` case study.
4.  Generate the plot in `output/elite_fmi_result.png`.

### Option B: Docker (The Gold Standard)
If you have Docker installed, you can run the exact environment used by the author:

```bash
# Build the container
docker build -t caprazli-fmi .

# Run the pipeline
docker run --rm -v ${PWD}:/home/rstudio/caprazliFMI caprazli-fmi
#!/usr/bin/env Rscript
# ==============================================================================
# FALSE NEGATIVE INVESTIGATION — CAPRAZLI FMI
# ==============================================================================
# Why did FMI fail to predict these collapses?
# 1. Scotian Shelf Cod (COD4X5Yb) - 1993 collapse
# 2. NW African Anchovy (ANCHONWA) - 1997 collapse
#
# Author:  Kafkas M. Caprazli (caprazli@gmail.com)
# ORCID:   0000-0002-5744-8944
# ==============================================================================

cat("
================================================================================
  FALSE NEGATIVE INVESTIGATION — CAPRAZLI FMI
  Why did FMI fail to predict these collapses?
================================================================================
\n")

# Load packages
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# Thresholds
DANGER_THRESHOLD <- 1.25
GULLAND_THRESHOLD <- 1.00

# Load data
load("data/RAM_DBdata.RData")
candidates <- read.csv("output/validation/RAM_all_FMI_candidates.csv")

# ==============================================================================
# CASE 1: SCOTIAN SHELF COD (COD4X5Yb)
# ==============================================================================
cat("\n")
cat("================================================================================\n")
cat("  CASE 1: SCOTIAN SHELF COD (COD4X5Yb)\n")
cat("  Known collapse: 1993\n")
cat("================================================================================\n\n")

# Get stock info
cod_info <- candidates %>% filter(stockid == "COD4X5Yb")

if (nrow(cod_info) > 0) {
  cat(sprintf("Stock: %s\n", cod_info$commonname))
  cat(sprintf("Region: %s\n", cod_info$region))
  cat(sprintf("M (Natural Mortality): %.3f\n", cod_info$M))
  cat(sprintf("Life History: %s\n", cod_info$life_history))
  cat(sprintf("F data range: %d - %d (%d years)\n", 
              cod_info$F_year_start, cod_info$F_year_end, cod_info$F_years))
  cat(sprintf("Mean F: %.3f\n", cod_info$F_mean))
  cat(sprintf("Mean FMI (F/M): %.2f\n", cod_info$FMI_mean))
  
  # Get full time series
  cod_ts <- timeseries %>%
    filter(stockid == "COD4X5Yb") %>%
    filter(grepl("^(F-|U-|ER-)", tsid)) %>%
    mutate(F = as.numeric(tsvalue)) %>%
    filter(!is.na(F)) %>%
    group_by(tsyear) %>%
    slice(1) %>%
    ungroup() %>%
    mutate(
      M = cod_info$M,
      FMI = F / M
    ) %>%
    arrange(tsyear)
  
  cat(sprintf("\nTime series: %d years (%d - %d)\n", 
              nrow(cod_ts), min(cod_ts$tsyear), max(cod_ts$tsyear)))
  
  # Key period analysis (1980-1995)
  cat("\n--- KEY PERIOD (1985-1995) ---\n")
  key_period <- cod_ts %>% 
    filter(tsyear >= 1985 & tsyear <= 1995) %>%
    select(tsyear, F, FMI)
  
  print(key_period)
  
  cat(sprintf("\nMax FMI in entire series: %.2f (year %d)\n",
              max(cod_ts$FMI), cod_ts$tsyear[which.max(cod_ts$FMI)]))
  cat(sprintf("Max FMI pre-collapse (before 1993): %.2f\n",
              max(cod_ts$FMI[cod_ts$tsyear < 1993])))
  
  # THE QUESTION: Why didn't FMI breach 1.25?
  cat("\n--- DIAGNOSIS ---\n")
  if (max(cod_ts$FMI) < DANGER_THRESHOLD) {
    cat(sprintf("FMI never exceeded DANGER threshold (1.25)\n"))
    cat(sprintf("Max FMI was %.2f\n", max(cod_ts$FMI)))
    
    # What M would have triggered danger?
    max_F_pre <- max(cod_ts$F[cod_ts$tsyear < 1993])
    M_needed <- max_F_pre / DANGER_THRESHOLD
    cat(sprintf("\nFor DANGER breach with max F=%.3f:\n", max_F_pre))
    cat(sprintf("  M would need to be < %.3f (actual M = %.3f)\n", M_needed, cod_info$M))
    
    if (cod_info$M > M_needed) {
      cat("\n⚠️  FINDING: M estimate may be TOO HIGH for this stock\n")
      cat("   This could be a case of:\n")
      cat("   1. Overestimated M (making FMI look safer than reality)\n")
      cat("   2. Collapse driven by recruitment failure, not fishing pressure\n")
      cat("   3. FMI limitation for high-M stocks\n")
    }
  }
  
  # Compare M with similar cod stocks
  cat("\n--- M COMPARISON WITH OTHER COD STOCKS ---\n")
  cod_stocks <- candidates %>%
    filter(grepl("cod|COD", commonname, ignore.case = TRUE)) %>%
    select(stockid, commonname, region, M, FMI_mean) %>%
    arrange(M)
  print(cod_stocks)
  
} else {
  cat("Stock COD4X5Yb not found in candidates\n")
}

# ==============================================================================
# CASE 2: NW AFRICAN ANCHOVY (ANCHONWA)
# ==============================================================================
cat("\n\n")
cat("================================================================================\n")
cat("  CASE 2: NW AFRICAN ANCHOVY (ANCHONWA)\n")
cat("  Known collapse: 1997\n")
cat("================================================================================\n\n")

# Get stock info
anch_info <- candidates %>% filter(stockid == "ANCHONWA")

if (nrow(anch_info) > 0) {
  cat(sprintf("Stock: %s\n", anch_info$commonname))
  cat(sprintf("Region: %s\n", anch_info$region))
  cat(sprintf("M (Natural Mortality): %.3f\n", anch_info$M))
  cat(sprintf("Life History: %s\n", anch_info$life_history))
  cat(sprintf("F data range: %d - %d (%d years)\n", 
              anch_info$F_year_start, anch_info$F_year_end, anch_info$F_years))
  cat(sprintf("Mean F: %.3f\n", anch_info$F_mean))
  cat(sprintf("Mean FMI (F/M): %.2f\n", anch_info$FMI_mean))
  
  # Get full time series
  anch_ts <- timeseries %>%
    filter(stockid == "ANCHONWA") %>%
    filter(grepl("^(F-|U-|ER-)", tsid)) %>%
    mutate(F = as.numeric(tsvalue)) %>%
    filter(!is.na(F)) %>%
    group_by(tsyear) %>%
    slice(1) %>%
    ungroup() %>%
    mutate(
      M = anch_info$M,
      FMI = F / M
    ) %>%
    arrange(tsyear)
  
  cat(sprintf("\nTime series: %d years (%d - %d)\n", 
              nrow(anch_ts), min(anch_ts$tsyear), max(anch_ts$tsyear)))
  
  # Key period analysis
  cat("\n--- FULL TIME SERIES ---\n")
  print(anch_ts %>% select(tsyear, F, FMI))
  
  cat(sprintf("\nMax FMI: %.2f (year %d)\n",
              max(anch_ts$FMI), anch_ts$tsyear[which.max(anch_ts$FMI)]))
  
  # THE QUESTION: Breach was AFTER collapse
  cat("\n--- DIAGNOSIS ---\n")
  first_breach <- min(anch_ts$tsyear[anch_ts$FMI >= DANGER_THRESHOLD], na.rm = TRUE)
  if (!is.infinite(first_breach)) {
    cat(sprintf("First DANGER breach: %d\n", first_breach))
    cat(sprintf("Collapse year: 1997\n"))
    cat(sprintf("Breach came %d years AFTER collapse\n", first_breach - 1997))
    
    cat("\n⚠️  FINDING: FMI breach came AFTER collapse\n")
    cat("   This could be a case of:\n")
    cat("   1. Environmental collapse (upwelling failure, climate)\n")
    cat("   2. Recruitment failure independent of fishing\n")
    cat("   3. Regime shift in ecosystem\n")
    cat("   4. Data quality issues (F estimates lagging reality)\n")
    cat("\n   For small pelagics, environmental variability often\n")
    cat("   dominates over fishing mortality as collapse driver.\n")
  }
  
  # Compare with other anchovy stocks
  cat("\n--- M COMPARISON WITH OTHER ANCHOVY STOCKS ---\n")
  anch_stocks <- candidates %>%
    filter(grepl("anchov", commonname, ignore.case = TRUE)) %>%
    select(stockid, commonname, region, M, FMI_mean) %>%
    arrange(M)
  print(anch_stocks)
  
} else {
  cat("Stock ANCHONWA not found in candidates\n")
}

# ==============================================================================
# SUMMARY: WHY FMI MISSED THESE COLLAPSES
# ==============================================================================
cat("\n\n")
cat("================================================================================\n")
cat("  SUMMARY: WHY FMI MISSED THESE COLLAPSES\n")
cat("================================================================================\n\n")

cat("SCOTIAN SHELF COD (COD4X5Yb):\n")
cat("  - High M estimate (1.28) relative to other cod stocks\n")
cat("  - FMI never reached danger threshold despite high F\n")
cat("  - Possible M overestimation OR recruitment-driven collapse\n")
cat("  - RECOMMENDATION: Flag as FMI limitation for high-M cod variants\n")
cat("\n")

cat("NW AFRICAN ANCHOVY (ANCHONWA):\n")
cat("  - FMI breach occurred AFTER collapse (2001 vs 1997)\n")
cat("  - Classic small pelagic pattern: environment > fishing\n")
cat("  - Canary Current upwelling system highly variable\n")
cat("  - RECOMMENDATION: Acknowledge FMI limitation for environment-driven\n")
cat("                    small pelagic collapses\n")
cat("\n")

cat("PUBLICATION FRAMING:\n")
cat("  'The FMI showed reduced sensitivity for (1) stocks with potentially\n")
cat("   overestimated M values (Scotian Shelf Cod, M=1.28 vs typical cod M≈0.2),\n")
cat("   and (2) small pelagic stocks where environmental variability dominates\n")
cat("   over fishing pressure as the primary collapse driver (NW African Anchovy).'\n")
cat("\n")

# ==============================================================================
# GENERATE DIAGNOSTIC PLOTS
# ==============================================================================
cat("Generating diagnostic plots...\n")

output_dir <- "output/forensic_hindcast"

# Plot 1: Scotian Shelf Cod
if (exists("cod_ts") && nrow(cod_ts) > 0) {
  p1 <- ggplot(cod_ts, aes(x = tsyear, y = FMI)) +
    # Zone backgrounds
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0, ymax = 0.75,
             fill = "#27ae60", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.75, ymax = 1.0,
             fill = "#f39c12", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1.0, ymax = 1.25,
             fill = "#e67e22", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1.25, ymax = Inf,
             fill = "#c0392b", alpha = 0.15) +
    # Thresholds
    geom_hline(yintercept = 1.0, linetype = "solid", color = "#34495e", linewidth = 1) +
    geom_hline(yintercept = 1.25, linetype = "dashed", color = "#c0392b", linewidth = 0.8) +
    # Collapse line
    geom_vline(xintercept = 1993, linetype = "dotted", color = "#8e44ad", linewidth = 1.2) +
    annotate("text", x = 1993, y = max(cod_ts$FMI) * 0.9,
             label = "COLLAPSE\n1993", color = "#8e44ad", fontface = "bold", hjust = -0.1) +
    # Data
    geom_line(linewidth = 1.2, color = "#2c3e50") +
    geom_point(size = 2) +
    # Labels
    labs(
      title = "FALSE NEGATIVE: Scotian Shelf Cod (COD4X5Yb)",
      subtitle = sprintf("M = %.2f (HIGH for cod) | FMI never breached 1.25 | Collapse 1993", cod_info$M),
      x = "Year", y = "FMI (F/M)",
      caption = "FMI failed: High M estimate kept ratio below danger threshold"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", color = "#c0392b"))
  
  ggsave(file.path(output_dir, "FALSE_NEGATIVE_COD4X5Yb.png"), p1, 
         width = 12, height = 7, dpi = 150, bg = "white")
  cat("  ✓ Saved: FALSE_NEGATIVE_COD4X5Yb.png\n")
}

# Plot 2: NW African Anchovy
if (exists("anch_ts") && nrow(anch_ts) > 0) {
  p2 <- ggplot(anch_ts, aes(x = tsyear, y = FMI)) +
    # Zone backgrounds
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0, ymax = 0.75,
             fill = "#27ae60", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.75, ymax = 1.0,
             fill = "#f39c12", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1.0, ymax = 1.25,
             fill = "#e67e22", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1.25, ymax = Inf,
             fill = "#c0392b", alpha = 0.15) +
    # Thresholds
    geom_hline(yintercept = 1.0, linetype = "solid", color = "#34495e", linewidth = 1) +
    geom_hline(yintercept = 1.25, linetype = "dashed", color = "#c0392b", linewidth = 0.8) +
    # Collapse line
    geom_vline(xintercept = 1997, linetype = "dotted", color = "#8e44ad", linewidth = 1.2) +
    annotate("text", x = 1997, y = max(anch_ts$FMI) * 0.9,
             label = "COLLAPSE\n1997", color = "#8e44ad", fontface = "bold", hjust = 1.1) +
    # First breach line
    first_breach <- min(anch_ts$tsyear[anch_ts$FMI >= 1.25], na.rm = TRUE)
    if (!is.infinite(first_breach)) {
      geom_vline(xintercept = first_breach, linetype = "dashed", color = "#c0392b", linewidth = 1)
      annotate("text", x = first_breach, y = 1.3,
               label = sprintf("BREACH\n%d", first_breach), color = "#c0392b", 
               fontface = "bold", hjust = -0.1)
    }
    # Data
    geom_line(linewidth = 1.2, color = "#2c3e50") +
    geom_point(size = 2) +
    # Labels
    labs(
      title = "FALSE NEGATIVE: NW African Anchovy (ANCHONWA)",
      subtitle = sprintf("M = %.2f | FMI breach came AFTER collapse | Environment-driven?", anch_info$M),
      x = "Year", y = "FMI (F/M)",
      caption = "FMI failed: Breach in 2001, collapse in 1997 — likely environmental driver"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", color = "#c0392b"))
  
  ggsave(file.path(output_dir, "FALSE_NEGATIVE_ANCHONWA.png"), p2, 
         width = 12, height = 7, dpi = 150, bg = "white")
  cat("  ✓ Saved: FALSE_NEGATIVE_ANCHONWA.png\n")
}

# Plot 3: M comparison across cod stocks
cat("\n--- GENERATING M COMPARISON PLOT ---\n")

cod_comparison <- candidates %>%
  filter(grepl("cod|COD", commonname, ignore.case = TRUE)) %>%
  mutate(
    is_false_negative = stockid == "COD4X5Yb",
    label = ifelse(is_false_negative, "FALSE NEGATIVE", "")
  )

if (nrow(cod_comparison) > 0) {
  p3 <- ggplot(cod_comparison, aes(x = reorder(stockid, M), y = M)) +
    geom_col(aes(fill = is_false_negative), width = 0.7) +
    geom_hline(yintercept = 0.2, linetype = "dashed", color = "#27ae60", linewidth = 1) +
    annotate("text", x = 1, y = 0.22, label = "Typical cod M ≈ 0.2", 
             hjust = 0, color = "#27ae60", fontface = "italic") +
    scale_fill_manual(values = c("TRUE" = "#c0392b", "FALSE" = "#3498db"), guide = "none") +
    coord_flip() +
    labs(
      title = "Natural Mortality (M) Across Cod Stocks",
      subtitle = "COD4X5Yb has anomalously high M = 1.28 (typical cod M ≈ 0.2)",
      x = "", y = "Natural Mortality (M)",
      caption = "High M makes FMI less sensitive — possible data quality issue"
    ) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"))
  
  ggsave(file.path(output_dir, "M_comparison_cod_stocks.png"), p3, 
         width = 10, height = 6, dpi = 150, bg = "white")
  cat("  ✓ Saved: M_comparison_cod_stocks.png\n")
}

cat("\n✓ FALSE NEGATIVE INVESTIGATION COMPLETE\n")
cat("  Review plots in output/forensic_hindcast/\n\n")

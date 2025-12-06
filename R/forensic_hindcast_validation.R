#!/usr/bin/env Rscript
# ==============================================================================
# FORENSIC HINDCAST VALIDATION FOR CAPRAZLI FMI
# ==============================================================================
# Purpose: Test whether FMI (F/M ratio) predicts stock collapses
#          by checking if danger threshold was breached BEFORE collapse
#
# Author:  Kafkas M. Caprazli (caprazli@gmail.com)
# ORCID:   0000-0002-5744-8944
# Date:    2025-12-06
# ==============================================================================

cat("
================================================================================
  FORENSIC HINDCAST VALIDATION — CAPRAZLI FMI
  Testing: Does FMI predict stock collapses?
================================================================================
\n")

# ------------------------------------------------------------------------------
# 1. LOAD PACKAGES
# ------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(stringr)
})

# ------------------------------------------------------------------------------
# 2. CONFIGURATION
# ------------------------------------------------------------------------------

# FMI Thresholds (from CLAUDE.md)
SAFE_THRESHOLD    <- 0.75   # F/M < 0.75 = Safe Zone
GULLAND_THRESHOLD <- 1.00   # F/M = 1.0 = Gulland limit (E = 0.5)
DANGER_THRESHOLD  <- 1.25   # F/M > 1.25 = Danger Zone

# Minimum years of data for validation
MIN_YEARS <- 15

# Output directory
OUTPUT_DIR <- "output/forensic_hindcast"
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# ------------------------------------------------------------------------------
# 3. LOAD RAM LEGACY DATABASE
# ------------------------------------------------------------------------------
cat("Loading RAM Legacy v4.64...\n")

ram_path <- "data/RAM_DBdata.RData"
if (!file.exists(ram_path)) {
  alt_paths <- c("RAM_DBdata.RData", "../data/RAM_DBdata.RData")
  for (p in alt_paths) {
    if (file.exists(p)) { ram_path <- p; break }
  }
}
load(ram_path)
cat("  ✓ Database loaded\n\n")

# ------------------------------------------------------------------------------
# 4. LOAD VALIDATION CANDIDATES
# ------------------------------------------------------------------------------
cat("Loading validation candidates...\n")

candidates_path <- "output/validation/RAM_all_FMI_candidates.csv"
if (!file.exists(candidates_path)) {
  stop("Run RAM_validation_candidates.R first to generate candidates.")
}

candidates <- read.csv(candidates_path, stringsAsFactors = FALSE)
cat(sprintf("  ✓ Loaded %d candidates with F+M data\n\n", nrow(candidates)))

# ------------------------------------------------------------------------------
# 5. EXTRACT FULL F TIME SERIES FOR ALL CANDIDATES
# ------------------------------------------------------------------------------
cat("Extracting full F time series for all candidates...\n")

# Get F time series
f_timeseries <- timeseries %>%
  filter(stockid %in% candidates$stockid) %>%
  filter(grepl("^(F-|U-|ER-)", tsid, ignore.case = TRUE)) %>%
  mutate(
    F_value = as.numeric(tsvalue),
    metric_type = case_when(
      grepl("^F-", tsid) ~ "F",
      grepl("^U-", tsid) ~ "U",
      grepl("^ER-", tsid) ~ "ER",
      TRUE ~ "Other"
    )
  ) %>%
  filter(!is.na(F_value) & F_value >= 0) %>%
  # Priority: F > U > ER per stock-year

  group_by(stockid, tsyear) %>%
  arrange(match(metric_type, c("F", "U", "ER"))) %>%
  slice(1) %>%
  ungroup() %>%
  select(stockid, year = tsyear, F = F_value, metric_type)

# Join with M values
fmi_timeseries <- f_timeseries %>%
  left_join(
    candidates %>% select(stockid, M, commonname, region, life_history),
    by = "stockid"
  ) %>%
  mutate(
    FMI = F / M,
    # Zone classification
    zone = case_when(
      FMI < SAFE_THRESHOLD ~ "Safe",
      FMI < GULLAND_THRESHOLD ~ "Caution",
      FMI < DANGER_THRESHOLD ~ "Warning",
      TRUE ~ "Danger"
    )
  )

cat(sprintf("  ✓ Built FMI time series: %d stock-years across %d stocks\n\n",
            nrow(fmi_timeseries), n_distinct(fmi_timeseries$stockid)))

# ------------------------------------------------------------------------------
# 6. IDENTIFY THRESHOLD BREACH EVENTS
# ------------------------------------------------------------------------------
cat("Identifying threshold breach events...\n")

breach_analysis <- fmi_timeseries %>%
  group_by(stockid, commonname, region, M, life_history) %>%
  arrange(year) %>%
  summarise(
    # Time series coverage
    year_start = min(year),
    year_end = max(year),
    n_years = n(),
    
    # FMI statistics
    FMI_mean = mean(FMI, na.rm = TRUE),
    FMI_max = max(FMI, na.rm = TRUE),
    FMI_min = min(FMI, na.rm = TRUE),
    
    # First breach of each threshold
    first_breach_caution = suppressWarnings(min(year[FMI >= SAFE_THRESHOLD], na.rm = TRUE)),
    first_breach_warning = suppressWarnings(min(year[FMI >= GULLAND_THRESHOLD], na.rm = TRUE)),
    first_breach_danger = suppressWarnings(min(year[FMI >= DANGER_THRESHOLD], na.rm = TRUE)),
    
    # Years in each zone
    years_safe = sum(FMI < SAFE_THRESHOLD, na.rm = TRUE),
    years_caution = sum(FMI >= SAFE_THRESHOLD & FMI < GULLAND_THRESHOLD, na.rm = TRUE),
    years_warning = sum(FMI >= GULLAND_THRESHOLD & FMI < DANGER_THRESHOLD, na.rm = TRUE),
    years_danger = sum(FMI >= DANGER_THRESHOLD, na.rm = TRUE),
    
    # Peak danger period
    peak_FMI_year = year[which.max(FMI)],
    
    .groups = "drop"
  ) %>%
  mutate(
    # Clean up Inf values
    first_breach_caution = ifelse(is.infinite(first_breach_caution), NA, first_breach_caution),
    first_breach_warning = ifelse(is.infinite(first_breach_warning), NA, first_breach_warning),
    first_breach_danger = ifelse(is.infinite(first_breach_danger), NA, first_breach_danger),
    
    # Ever breached danger?
    ever_breached_danger = !is.na(first_breach_danger),
    
    # Percent time in danger
    pct_danger = round(years_danger / n_years * 100, 1)
  )

cat(sprintf("  ✓ Analyzed %d stocks\n", nrow(breach_analysis)))
cat(sprintf("  ✓ %d stocks breached DANGER threshold (FMI > 1.25) at least once\n\n",
            sum(breach_analysis$ever_breached_danger)))

# ------------------------------------------------------------------------------
# 7. KNOWN COLLAPSE EVENTS (Manual Reference Data)
# ------------------------------------------------------------------------------
cat("Loading known collapse events for validation...\n")

# Known historical collapses with approximate dates
# Sources: FAO, ICES, scientific literature
known_collapses <- tribble(
  ~stockid_pattern, ~collapse_year, ~collapse_name, ~notes,
  "COD2J3KL",       1992,          "Northern Cod",              "Canadian moratorium",
  "COD3Pn4RS",      1993,          "Gulf of St Lawrence Cod",   "Canadian collapse",
  "COD4X5Yb",       1993,          "Scotian Shelf Cod",         "Canadian collapse",
  "CODIS",          2008,          "Icelandic Cod",             "Severe depletion",
  "COWCOD",         2000,          "Cowcod",                    "US West Coast collapse",
  "HERR4VWX",       1977,          "SW Nova Scotia Herring",    "Collapse and recovery",
  "SARDPAC",        1952,          "Pacific Sardine",           "California collapse",
  "ANCHONWA",       1997,          "NW African Anchovy",        "Overfishing event",
  "BLUEFINATL",     2007,          "Atlantic Bluefin Tuna",     "Near collapse",
  "HACCP",          1990,          "Haddock Georges Bank",      "Groundfish crisis"
)

# Match known collapses to our dataset
collapse_matches <- breach_analysis %>%
  mutate(
    known_collapse = case_when(
      grepl("COD2J3KL", stockid) ~ 1992,
      grepl("COD3Pn4RS", stockid) ~ 1993,
      grepl("COD4X5Yb", stockid) ~ 1993,
      grepl("CODIS", stockid) ~ 2008,
      grepl("COWCOD", stockid) ~ 2000,
      grepl("HERR4VWX", stockid) ~ 1977,
      grepl("SARDPAC", stockid) ~ 1952,
      grepl("ANCHONWA", stockid) ~ 1997,
      TRUE ~ NA_real_
    ),
    collapse_name = case_when(
      grepl("COD2J3KL", stockid) ~ "Northern Cod (1992)",
      grepl("COD3Pn4RS", stockid) ~ "Gulf St Lawrence Cod (1993)",
      grepl("COD4X5Yb", stockid) ~ "Scotian Shelf Cod (1993)",
      grepl("CODIS", stockid) ~ "Icelandic Cod (2008)",
      grepl("COWCOD", stockid) ~ "Cowcod (2000)",
      grepl("HERR4VWX", stockid) ~ "SW Nova Scotia Herring (1977)",
      grepl("SARDPAC", stockid) ~ "Pacific Sardine (1952)",
      grepl("ANCHONWA", stockid) ~ "NW African Anchovy (1997)",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(known_collapse)) %>%
  mutate(
    # Calculate lead time: years between first danger breach and collapse
    lead_time_danger = known_collapse - first_breach_danger,
    lead_time_warning = known_collapse - first_breach_warning,
    
    # Did FMI predict collapse?
    predicted_by_danger = !is.na(first_breach_danger) & first_breach_danger < known_collapse,
    predicted_by_warning = !is.na(first_breach_warning) & first_breach_warning < known_collapse
  )

if (nrow(collapse_matches) > 0) {
  cat(sprintf("  ✓ Found %d stocks with known collapse events\n", nrow(collapse_matches)))
  cat("\n  PRELIMINARY RESULTS:\n")
  
  for (i in 1:nrow(collapse_matches)) {
    row <- collapse_matches[i, ]
    if (row$predicted_by_danger) {
      cat(sprintf("    ✓ %s: FMI breached DANGER in %d, collapse in %d → %d YEARS WARNING\n",
                  row$collapse_name, row$first_breach_danger, row$known_collapse, row$lead_time_danger))
    } else if (row$predicted_by_warning) {
      cat(sprintf("    ~ %s: FMI breached WARNING in %d, collapse in %d → %d YEARS WARNING\n",
                  row$collapse_name, row$first_breach_warning, row$known_collapse, row$lead_time_warning))
    } else {
      cat(sprintf("    ✗ %s: FMI did NOT predict collapse (first breach: %s)\n",
                  row$collapse_name, 
                  ifelse(is.na(row$first_breach_danger), "never", as.character(row$first_breach_danger))))
    }
  }
} else {
  cat("  ⚠ No known collapse events matched in current dataset\n")
}

# ------------------------------------------------------------------------------
# 8. SELECT TOP STOCKS FOR DETAILED VISUALIZATION
# ------------------------------------------------------------------------------
cat("\n\nSelecting stocks for detailed forensic plots...\n")

# Priority 1: Stocks with known collapses
# Priority 2: Stocks that breached danger threshold with long time series
# Priority 3: Balanced life history representation

visualization_targets <- breach_analysis %>%
  filter(n_years >= MIN_YEARS) %>%
  mutate(
    priority = case_when(
      stockid %in% collapse_matches$stockid ~ 1,  # Known collapse
      ever_breached_danger & n_years >= 40 ~ 2,   # Long series + danger
      ever_breached_danger ~ 3,                   # Any danger breach
      TRUE ~ 4                                    # Other
    )
  ) %>%
  arrange(priority, desc(n_years)) %>%
  group_by(life_history) %>%
  slice_head(n = 4) %>%
  ungroup()

cat(sprintf("  ✓ Selected %d stocks for visualization\n\n", nrow(visualization_targets)))

# ------------------------------------------------------------------------------
# 9. GENERATE FORENSIC PLOTS
# ------------------------------------------------------------------------------
cat("Generating forensic hindcast plots...\n\n")

# Color palette
zone_colors <- c(
  "Safe" = "#27ae60",
  "Caution" = "#f39c12", 
  "Warning" = "#e67e22",
  "Danger" = "#c0392b"
)

# Function to create forensic plot for one stock
create_forensic_plot <- function(stock_id, fmi_data, breach_data, collapse_info = NULL) {
  
  stock_fmi <- fmi_data %>% filter(stockid == stock_id)
  stock_breach <- breach_data %>% filter(stockid == stock_id)
  
  if (nrow(stock_fmi) == 0) return(NULL)
  
  # Get collapse info if available
  known_collapse <- NULL
  if (!is.null(collapse_info) && stock_id %in% collapse_info$stockid) {
    known_collapse <- collapse_info %>% filter(stockid == stock_id)
  }
  
  # Title
  plot_title <- sprintf("%s (%s)", stock_breach$commonname, stock_breach$region)
  plot_subtitle <- sprintf("M = %.3f | Life History: %s | %d years of data",
                           stock_breach$M, stock_breach$life_history, stock_breach$n_years)
  
  # Create plot
  p <- ggplot(stock_fmi, aes(x = year, y = FMI)) +
    
    # Zone backgrounds
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0, ymax = SAFE_THRESHOLD,
             fill = "#27ae60", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = SAFE_THRESHOLD, ymax = GULLAND_THRESHOLD,
             fill = "#f39c12", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = GULLAND_THRESHOLD, ymax = DANGER_THRESHOLD,
             fill = "#e67e22", alpha = 0.15) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = DANGER_THRESHOLD, ymax = Inf,
             fill = "#c0392b", alpha = 0.15) +
    
    # Threshold lines
    geom_hline(yintercept = SAFE_THRESHOLD, linetype = "dashed", color = "#27ae60", linewidth = 0.8) +
    geom_hline(yintercept = GULLAND_THRESHOLD, linetype = "solid", color = "#34495e", linewidth = 1) +
    geom_hline(yintercept = DANGER_THRESHOLD, linetype = "dashed", color = "#c0392b", linewidth = 0.8) +
    
    # FMI time series
    geom_line(linewidth = 1.2, color = "#2c3e50") +
    geom_point(aes(color = zone), size = 2.5) +
    
    # Color scale
    scale_color_manual(values = zone_colors, name = "Zone") +
    
    # Labels
    labs(
      title = plot_title,
      subtitle = plot_subtitle,
      x = "Year",
      y = "FMI (F/M Ratio)",
      caption = "Caprazli FMI | Thresholds: Safe < 0.75 | Gulland = 1.0 | Danger > 1.25"
    ) +
    
    # Theme
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey40"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
  
  # Add collapse marker if known
  if (!is.null(known_collapse) && nrow(known_collapse) > 0) {
    p <- p +
      geom_vline(xintercept = known_collapse$known_collapse, 
                 linetype = "dotted", color = "#8e44ad", linewidth = 1.2) +
      annotate("text", x = known_collapse$known_collapse, y = max(stock_fmi$FMI) * 0.9,
               label = paste("COLLAPSE\n", known_collapse$known_collapse),
               color = "#8e44ad", fontface = "bold", size = 3, hjust = -0.1)
    
    # Add first danger breach marker
    if (!is.na(stock_breach$first_breach_danger) && 
        stock_breach$first_breach_danger < known_collapse$known_collapse) {
      lead_time <- known_collapse$known_collapse - stock_breach$first_breach_danger
      p <- p +
        geom_vline(xintercept = stock_breach$first_breach_danger,
                   linetype = "dashed", color = "#c0392b", linewidth = 1) +
        annotate("text", x = stock_breach$first_breach_danger, y = DANGER_THRESHOLD * 1.1,
                 label = sprintf("DANGER BREACH\n%d yrs warning", lead_time),
                 color = "#c0392b", fontface = "bold", size = 3, hjust = 1.1)
    }
  }
  
  return(p)
}

# Generate plots for all visualization targets
plot_list <- list()
for (i in 1:nrow(visualization_targets)) {
  stock_id <- visualization_targets$stockid[i]
  
  cat(sprintf("  Plotting %d/%d: %s (%s)...\n", 
              i, nrow(visualization_targets),
              visualization_targets$commonname[i],
              stock_id))
  
  p <- create_forensic_plot(
    stock_id = stock_id,
    fmi_data = fmi_timeseries,
    breach_data = breach_analysis,
    collapse_info = if(exists("collapse_matches")) collapse_matches else NULL
  )
  
  if (!is.null(p)) {
    plot_list[[stock_id]] <- p
    
    # Save individual plot
    filename <- file.path(OUTPUT_DIR, sprintf("forensic_%s.png", stock_id))
    ggsave(filename, p, width = 12, height = 7, dpi = 150, bg = "white")
  }
}

# ------------------------------------------------------------------------------
# 10. SUMMARY STATISTICS
# ------------------------------------------------------------------------------
cat("\n\n================================================================================\n")
cat("  FORENSIC VALIDATION SUMMARY\n")
cat("================================================================================\n\n")

# Overall statistics
total_stocks <- nrow(breach_analysis)
danger_stocks <- sum(breach_analysis$ever_breached_danger)
warning_stocks <- sum(!is.na(breach_analysis$first_breach_warning))

cat(sprintf("DATASET OVERVIEW:\n"))
cat(sprintf("  Total stocks analyzed:              %d\n", total_stocks))
cat(sprintf("  Stocks breaching DANGER (>1.25):    %d (%.1f%%)\n", 
            danger_stocks, danger_stocks/total_stocks*100))
cat(sprintf("  Stocks breaching WARNING (>1.0):    %d (%.1f%%)\n",
            warning_stocks, warning_stocks/total_stocks*100))

# Life history breakdown
cat(sprintf("\nBY LIFE HISTORY:\n"))
lh_summary <- breach_analysis %>%
  group_by(life_history) %>%
  summarise(
    n = n(),
    pct_danger = round(mean(ever_breached_danger) * 100, 1),
    mean_max_FMI = round(mean(FMI_max), 2),
    .groups = "drop"
  )
print(lh_summary)

# Known collapse prediction results
if (nrow(collapse_matches) > 0) {
  cat(sprintf("\nKNOWN COLLAPSE PREDICTION:\n"))
  cat(sprintf("  Stocks with known collapses:        %d\n", nrow(collapse_matches)))
  cat(sprintf("  Correctly predicted by DANGER:      %d (%.1f%%)\n",
              sum(collapse_matches$predicted_by_danger),
              mean(collapse_matches$predicted_by_danger) * 100))
  cat(sprintf("  Correctly predicted by WARNING:     %d (%.1f%%)\n",
              sum(collapse_matches$predicted_by_warning),
              mean(collapse_matches$predicted_by_warning) * 100))
  
  valid_lead_times <- collapse_matches$lead_time_danger[collapse_matches$predicted_by_danger]
  if (length(valid_lead_times) > 0) {
    cat(sprintf("  Average lead time (DANGER):         %.1f years\n", mean(valid_lead_times)))
    cat(sprintf("  Lead time range:                    %d to %d years\n", 
                min(valid_lead_times), max(valid_lead_times)))
  }
}

# ------------------------------------------------------------------------------
# 11. SAVE OUTPUTS
# ------------------------------------------------------------------------------
cat("\n\n================================================================================\n")
cat("  SAVING OUTPUTS\n")
cat("================================================================================\n\n")

# Save breach analysis
breach_file <- file.path(OUTPUT_DIR, "breach_analysis_full.csv")
write.csv(breach_analysis, breach_file, row.names = FALSE)
cat(sprintf("  ✓ Breach analysis: %s\n", breach_file))

# Save FMI time series
fmi_file <- file.path(OUTPUT_DIR, "fmi_timeseries_full.csv")
write.csv(fmi_timeseries, fmi_file, row.names = FALSE)
cat(sprintf("  ✓ FMI time series: %s\n", fmi_file))

# Save collapse matches
if (nrow(collapse_matches) > 0) {
  collapse_file <- file.path(OUTPUT_DIR, "collapse_validation.csv")
  write.csv(collapse_matches, collapse_file, row.names = FALSE)
  cat(sprintf("  ✓ Collapse validation: %s\n", collapse_file))
}

# Save visualization targets
viz_file <- file.path(OUTPUT_DIR, "visualization_targets.csv")
write.csv(visualization_targets, viz_file, row.names = FALSE)
cat(sprintf("  ✓ Visualization targets: %s\n", viz_file))

cat(sprintf("\n  ✓ Forensic plots saved to: %s/\n", OUTPUT_DIR))

# ------------------------------------------------------------------------------
# 12. FINAL SUMMARY TABLE
# ------------------------------------------------------------------------------
cat("\n\n================================================================================\n")
cat("  TOP DANGER STOCKS (Highest Max FMI)\n")
cat("================================================================================\n\n")

top_danger <- breach_analysis %>%
  filter(ever_breached_danger) %>%
  arrange(desc(FMI_max)) %>%
  select(stockid, commonname, region, M, FMI_max, first_breach_danger, 
         years_danger, pct_danger, life_history) %>%
  head(15)

print(top_danger, n = 15)

cat("\n\n✓ FORENSIC HINDCAST VALIDATION COMPLETE\n")
cat("  Review plots in output/forensic_hindcast/\n")
cat("  Key finding: Check collapse_validation.csv for predictive accuracy\n\n")

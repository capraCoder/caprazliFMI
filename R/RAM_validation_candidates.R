#!/usr/bin/env Rscript
# ==============================================================================
# RAM Legacy Validation Candidates for Caprazli FMI
# ==============================================================================
# Purpose: Extract stocks with complete F + M data, rank by quality,
#          stratify by life history, output Top 15 validation candidates
#
# Author:  Kafkas M. Caprazli (caprazli@gmail.com)
# ORCID:   0000-0002-5744-8944
# Date:    2025-12-06
# ==============================================================================

cat("
================================================================================
  RAM LEGACY VALIDATION CANDIDATES FOR CAPRAZLI FMI
  Extracting stocks with F + M data for forensic validation
================================================================================
\n")

# ------------------------------------------------------------------------------
# 1. LOAD PACKAGES
# ------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# ------------------------------------------------------------------------------
# 2. LOAD RAM LEGACY DATABASE
# ------------------------------------------------------------------------------
cat("Loading RAM Legacy v4.64...\n")

# Adjust path as needed
ram_path <- "data/RAM_DBdata.RData"

if (!file.exists(ram_path)) {
  # Try alternative paths
  alt_paths <- c(
    "RAM_DBdata.RData",
    "../data/RAM_DBdata.RData",
    "C:/Users/capra/caprazliFMI/data/RAM_DBdata.RData"
  )
  for (p in alt_paths) {
    if (file.exists(p)) {
      ram_path <- p
      break
    }
  }
}

if (!file.exists(ram_path)) {
  stop("RAM Legacy database not found. Please set correct path.")
}

load(ram_path)
cat("  ✓ Database loaded\n\n")

# ------------------------------------------------------------------------------
# 3. EXTRACT NATURAL MORTALITY (M) FROM BIOPARAMS
# ------------------------------------------------------------------------------
cat("Extracting Natural Mortality (M) from bioparams...\n")

m_data <- bioparams %>%
  filter(grepl("^M-", bioid, ignore.case = TRUE)) %>%
  mutate(M = as.numeric(biovalue)) %>%
  filter(!is.na(M) & M > 0 & M < 5) %>%  # Sanity check: M should be 0 < M < 5

  group_by(stockid) %>%
  summarise(
    M = mean(M, na.rm = TRUE),
    M_min = min(M, na.rm = TRUE),
    M_max = max(M, na.rm = TRUE),
    M_n_estimates = n(),
    .groups = "drop"
  )

cat(sprintf("  ✓ Found M estimates for %d stocks\n\n", nrow(m_data)))

# ------------------------------------------------------------------------------
# 4. EXTRACT FISHING MORTALITY (F) TIME SERIES
# ------------------------------------------------------------------------------
cat("Extracting Fishing Mortality (F) time series...\n")

# Priority: F > U (exploitation rate) > ER
f_data <- timeseries %>%
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
  # Prioritize F over U over ER
  group_by(stockid, tsyear) %>%
  arrange(match(metric_type, c("F", "U", "ER"))) %>%
  slice(1) %>%
  ungroup()

# Calculate F summary statistics per stock
f_summary <- f_data %>%
  group_by(stockid) %>%
  summarise(
    F_years = n(),
    F_year_start = min(tsyear),
    F_year_end = max(tsyear),
    F_span = max(tsyear) - min(tsyear) + 1,
    F_mean = mean(F_value, na.rm = TRUE),
    F_max = max(F_value, na.rm = TRUE),
    F_min = min(F_value, na.rm = TRUE),
    F_metric = first(metric_type),
    .groups = "drop"
  )

cat(sprintf("  ✓ Found F time series for %d stocks\n\n", nrow(f_summary)))

# ------------------------------------------------------------------------------
# 5. JOIN F + M + STOCK METADATA
# ------------------------------------------------------------------------------
cat("Joining F, M, and stock metadata...\n")

# Get stock metadata
stock_meta <- stock %>%
  select(stockid, stocklong, commonname, scientificname, region, primary_FAOarea)

# Join everything
fmi_candidates <- f_summary %>%
  inner_join(m_data, by = "stockid") %>%
  inner_join(stock_meta, by = "stockid") %>%
  # Calculate FMI metrics

  mutate(
    FMI_mean = F_mean / M,
    FMI_max = F_max / M,
    # Life history category based on M
    life_history = case_when(
      M < 0.2 ~ "Long-lived (M < 0.2)",
      M < 0.4 ~ "Medium-lived (0.2 ≤ M < 0.4)",
      M < 0.8 ~ "Moderate turnover (0.4 ≤ M < 0.8)",
      TRUE ~ "Fast turnover (M ≥ 0.8)"
    ),
    # Data quality score (0-100)
    quality_score = pmin(100, 
      (F_years / 50 * 30) +           # Up to 30 pts for length of time series
      (F_span / 70 * 20) +            # Up to 20 pts for span coverage
      (M_n_estimates / 5 * 20) +      # Up to 20 pts for M estimate confidence
      ifelse(F_metric == "F", 30, 
             ifelse(F_metric == "U", 20, 10))  # 30 pts for direct F, less for proxies
    )
  ) %>%
  arrange(desc(quality_score))

cat(sprintf("  ✓ Found %d stocks with BOTH F and M data\n\n", nrow(fmi_candidates)))

# ------------------------------------------------------------------------------
# 6. STRATIFY BY LIFE HISTORY
# ------------------------------------------------------------------------------
cat("Stratifying by life history category...\n\n")

life_history_summary <- fmi_candidates %>%
  group_by(life_history) %>%
  summarise(
    n_stocks = n(),
    M_range = paste0(round(min(M), 2), " - ", round(max(M), 2)),
    example_species = first(commonname),
    .groups = "drop"
  ) %>%
  arrange(match(life_history, c(
    "Long-lived (M < 0.2)",
    "Medium-lived (0.2 ≤ M < 0.4)",
    "Moderate turnover (0.4 ≤ M < 0.8)",
    "Fast turnover (M ≥ 0.8)"
  )))

print(life_history_summary)
cat("\n")

# ------------------------------------------------------------------------------
# 7. SELECT TOP CANDIDATES PER LIFE HISTORY
# ------------------------------------------------------------------------------
cat("Selecting top validation candidates per life history category...\n\n")

# Select top 4-5 from each category to get ~15 total
top_candidates <- fmi_candidates %>%
  group_by(life_history) %>%
  slice_max(order_by = quality_score, n = 4, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(M)  # Sort by M for the "highway" view

# ------------------------------------------------------------------------------
# 8. DISPLAY TOP 15 CANDIDATES
# ------------------------------------------------------------------------------
cat("================================================================================\n")
cat("  TOP VALIDATION CANDIDATES FOR CAPRAZLI FMI\n")
cat("================================================================================\n\n")

display_table <- top_candidates %>%
  select(
    stockid,
    commonname,
    region,
    M,
    F_mean,
    FMI_mean,
    F_years,
    F_year_start,
    F_year_end,
    quality_score,
    life_history
  ) %>%
  mutate(
    M = round(M, 3),
    F_mean = round(F_mean, 3),
    FMI_mean = round(FMI_mean, 2),
    quality_score = round(quality_score, 1)
  )

print(display_table, n = 20)

# ------------------------------------------------------------------------------
# 9. FAMOUS COLLAPSES CHECK
# ------------------------------------------------------------------------------
cat("\n\n================================================================================\n")
cat("  CHECKING FOR FAMOUS STOCK COLLAPSES IN DATASET\n")
cat("================================================================================\n\n")

famous_stocks <- c(
  "COD" = "Atlantic cod",
  "CODGB" = "Georges Bank",
  "COD2J3KL" = "Northern cod",
  "COD3Ps" = "Southern Grand Bank cod",
  "HERRING" = "Atlantic herring",
  "SARDINE" = "Sardine",
  "ANCHOVY" = "Anchovy",
  "BLUEFIN" = "Bluefin tuna"
)

famous_check <- fmi_candidates %>%
  filter(
    grepl("cod|herring|sardine|anchovy|bluefin|haddock|pollock", 
          commonname, ignore.case = TRUE) |
    grepl("COD|HERR|SARD|ANCH|BFT|HAD|POL", 
          stockid, ignore.case = TRUE)
  ) %>%
  select(stockid, commonname, region, M, F_mean, FMI_mean, F_years, quality_score) %>%
  arrange(commonname) %>%
  head(20)

if (nrow(famous_check) > 0) {
  cat("Found iconic/well-studied stocks:\n\n")
  print(famous_check)
} else {
  cat("No famous collapse stocks found in filtered dataset.\n")
}

# ------------------------------------------------------------------------------
# 10. SAVE OUTPUTS
# ------------------------------------------------------------------------------
cat("\n\n================================================================================\n")
cat("  SAVING OUTPUTS\n")
cat("================================================================================\n\n")

# Create output directory if needed
output_dir <- "output/validation"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save all candidates
all_candidates_file <- file.path(output_dir, "RAM_all_FMI_candidates.csv")
write.csv(fmi_candidates, all_candidates_file, row.names = FALSE)
cat(sprintf("  ✓ All candidates (%d stocks): %s\n", nrow(fmi_candidates), all_candidates_file))

# Save top 15
top_candidates_file <- file.path(output_dir, "RAM_top15_validation.csv")
write.csv(top_candidates, top_candidates_file, row.names = FALSE)
cat(sprintf("  ✓ Top 15 candidates: %s\n", top_candidates_file))

# Save life history summary
lh_file <- file.path(output_dir, "RAM_life_history_summary.csv")
write.csv(life_history_summary, lh_file, row.names = FALSE)
cat(sprintf("  ✓ Life history summary: %s\n", lh_file))

# Save famous stocks subset
famous_file <- file.path(output_dir, "RAM_famous_stocks.csv")
write.csv(famous_check, famous_file, row.names = FALSE)
cat(sprintf("  ✓ Famous stocks: %s\n", famous_file))

# ------------------------------------------------------------------------------
# 11. FINAL SUMMARY
# ------------------------------------------------------------------------------
cat("\n\n================================================================================\n")
cat("  SUMMARY\n")
cat("================================================================================\n\n")

cat(sprintf("Total stocks in RAM Legacy:        %d\n", n_distinct(stock$stockid)))
cat(sprintf("Stocks with M estimates:           %d\n", nrow(m_data)))
cat(sprintf("Stocks with F time series:         %d\n", nrow(f_summary)))
cat(sprintf("Stocks with BOTH F and M:          %d  ← YOUR FMI VALIDATION POOL\n", nrow(fmi_candidates)))
cat(sprintf("\nTop 15 candidates selected across %d life history categories\n", 
            n_distinct(top_candidates$life_history)))

cat("\n\nLife history distribution in Top 15:\n")
table(top_candidates$life_history)

cat("\n\n✓ DONE. Review the CSV files in output/validation/\n")
cat("  Next step: Run 5-year hindcast validation on each candidate.\n\n")

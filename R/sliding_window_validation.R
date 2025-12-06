#!/usr/bin/env Rscript
# =============================================================================
#  SLIDING WINDOW VALIDATION — CAPRAZLI FMI
#  Statistical validation: Does FMI danger signal predict subsequent decline?
#  
#  Author: Kafkas M. Caprazli
#  ORCID: 0000-0002-5744-8944
# =============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)

# =============================================================================
#  CONFIGURATION
# =============================================================================

DB_PATH <- "data/RAM_DBdata.RData"

# Thresholds
FMI_DANGER <- 1.25
FMI_WARNING <- 1.00
COLLAPSE_THRESHOLD <- 0.5   # B/BMSY below this = overfished
SEVERE_COLLAPSE <- 0.2      # B/BMSY below this = severe collapse

cat("
================================================================================
  SLIDING WINDOW VALIDATION — CAPRAZLI FMI
  Does FMI danger signal predict subsequent stock decline?
================================================================================
\n")

# =============================================================================
#  STEP 1: LOAD RAM LEGACY DATA
# =============================================================================

cat("Loading RAM Legacy database...\n")

if (!file.exists(DB_PATH)) {
  stop("Database not found at: ", DB_PATH)
}

load(DB_PATH)

cat("  Objects loaded:", paste(ls(), collapse = ", "), "\n")

# =============================================================================
#  STEP 2: EXTRACT STOCK METADATA
# =============================================================================

cat("\nExtracting stock metadata...\n")

stock_info <- stock %>%
  select(stockid, stocklong, commonname, scientificname, region) %>%
  distinct()

cat(sprintf("  Stocks in database: %d\n", nrow(stock_info)))

# =============================================================================
#  STEP 3: EXTRACT NATURAL MORTALITY (M)
# =============================================================================

cat("\nExtracting Natural Mortality (M)...\n")

M_values <- bioparams %>%
  filter(grepl("^M-", bioid, ignore.case = TRUE)) %>%
  mutate(M = as.numeric(biovalue)) %>%
  filter(!is.na(M) & M > 0 & M < 5) %>%
  group_by(stockid) %>%
  summarise(M = median(M, na.rm = TRUE), .groups = "drop")

cat(sprintf("  Stocks with M data: %d\n", nrow(M_values)))

# =============================================================================
#  STEP 4: EXTRACT FISHING MORTALITY (F) TIME SERIES
# =============================================================================

cat("\nExtracting Fishing Mortality (F) time series...\n")

# Check what columns exist in timeseries
cat("  Timeseries columns:", paste(names(timeseries)[1:min(10, ncol(timeseries))], collapse = ", "), "...\n")

F_timeseries <- timeseries %>%
  filter(grepl("^F-", tsid, ignore.case = TRUE) | grepl("F-1/T", tsid)) %>%
  mutate(F = as.numeric(tsvalue)) %>%
  filter(!is.na(F) & F > 0 & F < 10) %>%
  select(stockid, tsyear, F) %>%
  group_by(stockid, tsyear) %>%
  summarise(F = median(F, na.rm = TRUE), .groups = "drop")

cat(sprintf("  F data points: %d\n", nrow(F_timeseries)))
cat(sprintf("  Stocks with F data: %d\n", n_distinct(F_timeseries$stockid)))

# =============================================================================
#  STEP 5: EXTRACT BIOMASS (B/BMSY) TIME SERIES
# =============================================================================

cat("\nExtracting Biomass (B/BMSY) time series...\n")

# Check available tsid values for biomass
biomass_tsids <- timeseries %>%
  filter(grepl("div.*msy|bmsy|divmsy", tsid, ignore.case = TRUE)) %>%
  distinct(tsid) %>%
  pull(tsid)

cat("  Available B/BMSY metrics:", paste(head(biomass_tsids, 5), collapse = ", "), "\n")

B_BMSY_timeseries <- timeseries %>%
  filter(grepl("TBdivTBmsy|SSBdivSSBmsy|BdivBmsy|divBmsy", tsid, ignore.case = TRUE)) %>%
  mutate(B_BMSY = as.numeric(tsvalue)) %>%
  filter(!is.na(B_BMSY) & B_BMSY > 0 & B_BMSY < 20) %>%
  select(stockid, tsyear, B_BMSY) %>%
  group_by(stockid, tsyear) %>%
  summarise(B_BMSY = median(B_BMSY, na.rm = TRUE), .groups = "drop")

cat(sprintf("  B/BMSY data points: %d\n", nrow(B_BMSY_timeseries)))
cat(sprintf("  Stocks with B/BMSY data: %d\n", n_distinct(B_BMSY_timeseries$stockid)))

# =============================================================================
#  STEP 6: MERGE ALL DATA AND COMPUTE FMI
# =============================================================================

cat("\nMerging F, M, and B/BMSY data...\n")

analysis_data <- F_timeseries %>%
  inner_join(M_values, by = "stockid") %>%
  inner_join(B_BMSY_timeseries, by = c("stockid", "tsyear")) %>%
  inner_join(stock_info, by = "stockid") %>%
  mutate(
    FMI = F / M,
    log_F = log10(F),
    log_M = log10(M)
  ) %>%
  arrange(stockid, tsyear)

cat(sprintf("  Analysis dataset: %d stock-years\n", nrow(analysis_data)))
cat(sprintf("  Stocks with F + M + B/BMSY: %d\n", n_distinct(analysis_data$stockid)))

if (nrow(analysis_data) == 0) {
  stop("No data after merge. Check column names and data availability.")
}

# =============================================================================
#  STEP 7: BUILD CONTINGENCY TABLE (Main Analysis)
# =============================================================================

cat("\n
================================================================================
  MAIN ANALYSIS: FMI DANGER vs STOCK COLLAPSE
================================================================================
\n")

# For each stock: did FMI ever signal danger? Did stock ever collapse?
stock_summary <- analysis_data %>%
  group_by(stockid, commonname, region, M) %>%
  summarise(
    n_years = n(),
    max_FMI = max(FMI, na.rm = TRUE),
    min_B_BMSY = min(B_BMSY, na.rm = TRUE),
    ever_danger = any(FMI >= FMI_DANGER, na.rm = TRUE),
    ever_warning = any(FMI >= FMI_WARNING, na.rm = TRUE),
    ever_collapsed = any(B_BMSY < COLLAPSE_THRESHOLD, na.rm = TRUE),
    ever_severe = any(B_BMSY < SEVERE_COLLAPSE, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    life_history = case_when(
      M < 0.2 ~ "1_Long-lived (M<0.2)",
      M < 0.4 ~ "2_Medium (0.2≤M<0.4)",
      M < 0.8 ~ "3_Moderate (0.4≤M<0.8)",
      TRUE ~ "4_Fast turnover (M≥0.8)"
    )
  )

cat(sprintf("Stocks in analysis: %d\n", nrow(stock_summary)))

# 2x2 Contingency Table
cat("\n--- CONTINGENCY TABLE ---\n")
cat("(FMI ever ≥ 1.25) vs (B/BMSY ever < 0.5)\n\n")

cont_table <- table(
  "FMI_Danger" = stock_summary$ever_danger,
  "Collapsed" = stock_summary$ever_collapsed
)

print(cont_table)

# Calculate diagnostic metrics
TP <- cont_table["TRUE", "TRUE"]   # Danger + Collapsed
FP <- cont_table["TRUE", "FALSE"]  # Danger + No collapse  
FN <- cont_table["FALSE", "TRUE"]  # No danger + Collapsed
TN <- cont_table["FALSE", "FALSE"] # No danger + No collapse

# Handle possible NA/missing cells
TP <- ifelse(is.na(TP), 0, TP)
FP <- ifelse(is.na(FP), 0, FP)
FN <- ifelse(is.na(FN), 0, FN)
TN <- ifelse(is.na(TN), 0, TN)

sensitivity <- TP / (TP + FN) * 100
specificity <- TN / (TN + FP) * 100
ppv <- TP / (TP + FP) * 100
npv <- TN / (TN + FN) * 100
accuracy <- (TP + TN) / (TP + FP + FN + TN) * 100

cat(sprintf("\n
DIAGNOSTIC METRICS (FMI ≥ %.2f as predictor of B/BMSY < %.1f):
───────────────────────────────────────────────────────────────
  True Positives (Danger + Collapsed):     %d

  False Positives (Danger + No collapse):  %d
  False Negatives (No danger + Collapsed): %d
  True Negatives (No danger + No collapse): %d

  Sensitivity (recall):     %.1f%% of collapses had prior danger signal
  Specificity:              %.1f%% of healthy stocks avoided false alarm
  Positive Predictive Value: %.1f%% of danger signals led to collapse
  Negative Predictive Value: %.1f%% of safe signals stayed safe
  Overall Accuracy:          %.1f%%
───────────────────────────────────────────────────────────────
\n", FMI_DANGER, COLLAPSE_THRESHOLD, TP, FP, FN, TN, 
sensitivity, specificity, ppv, npv, accuracy))

# =============================================================================
#  STEP 8: LIFE HISTORY STRATIFICATION
# =============================================================================

cat("\n--- LIFE HISTORY STRATIFICATION ---\n")

life_history_results <- stock_summary %>%
  group_by(life_history) %>%
  summarise(
    n_stocks = n(),
    n_collapsed = sum(ever_collapsed),
    n_danger = sum(ever_danger),
    n_danger_and_collapsed = sum(ever_danger & ever_collapsed),
    pct_collapsed = mean(ever_collapsed) * 100,
    pct_danger = mean(ever_danger) * 100,
    sensitivity = ifelse(n_collapsed > 0, 
                         sum(ever_danger & ever_collapsed) / n_collapsed * 100, 
                         NA),
    .groups = "drop"
  ) %>%
  arrange(life_history)

print(as.data.frame(life_history_results))

# =============================================================================
#  STEP 9: ROC CURVE ANALYSIS
# =============================================================================

cat("\n--- ROC CURVE ANALYSIS ---\n")

thresholds <- seq(0.25, 4.0, by = 0.1)
roc_data <- data.frame()

for (thresh in thresholds) {
  temp <- stock_summary %>%
    mutate(predicted_danger = max_FMI >= thresh)
  
  tp <- sum(temp$predicted_danger & temp$ever_collapsed, na.rm = TRUE)
  fp <- sum(temp$predicted_danger & !temp$ever_collapsed, na.rm = TRUE)
  fn <- sum(!temp$predicted_danger & temp$ever_collapsed, na.rm = TRUE)
  tn <- sum(!temp$predicted_danger & !temp$ever_collapsed, na.rm = TRUE)
  
  tpr <- ifelse((tp + fn) > 0, tp / (tp + fn), 0)
  fpr <- ifelse((fp + tn) > 0, fp / (fp + tn), 0)
  
  roc_data <- rbind(roc_data, data.frame(
    threshold = thresh,
    TPR = tpr,
    FPR = fpr,
    TP = tp, FP = fp, FN = fn, TN = tn
  ))
}

# Calculate AUC (trapezoidal)
roc_sorted <- roc_data %>% arrange(FPR, TPR)
auc <- 0
for (i in 2:nrow(roc_sorted)) {
  auc <- auc + (roc_sorted$FPR[i] - roc_sorted$FPR[i-1]) * 
               (roc_sorted$TPR[i] + roc_sorted$TPR[i-1]) / 2
}
auc <- abs(auc)

cat(sprintf("ROC AUC: %.3f\n", auc))
cat("  (0.5 = random, 0.7 = acceptable, 0.8 = good, 0.9 = excellent)\n")

# Find optimal threshold (Youden's J)
roc_data$youden_j <- roc_data$TPR - roc_data$FPR
optimal_idx <- which.max(roc_data$youden_j)
optimal_threshold <- roc_data$threshold[optimal_idx]

cat(sprintf("\nOptimal FMI threshold (Youden's J): %.2f\n", optimal_threshold))
cat(sprintf("  At this threshold: Sensitivity=%.1f%%, Specificity=%.1f%%\n",
            roc_data$TPR[optimal_idx]*100, (1-roc_data$FPR[optimal_idx])*100))

# =============================================================================
#  STEP 10: TEMPORAL ANALYSIS — Lead Time
# =============================================================================

cat("\n--- LEAD TIME ANALYSIS ---\n")

# For stocks that collapsed: when did FMI first signal danger?
collapsed_with_timing <- analysis_data %>%
  group_by(stockid) %>%
  arrange(tsyear) %>%
  mutate(
    is_collapsed_year = B_BMSY < COLLAPSE_THRESHOLD,
    is_danger_year = FMI >= FMI_DANGER
  ) %>%
  summarise(
    first_collapse_year = min(tsyear[is_collapsed_year], na.rm = TRUE),
    first_danger_year = min(tsyear[is_danger_year], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.infinite(first_collapse_year)) %>%
  mutate(
    had_warning = !is.infinite(first_danger_year),
    lead_time = ifelse(had_warning, first_collapse_year - first_danger_year, NA)
  )

n_collapsed_total <- nrow(collapsed_with_timing)
n_with_warning <- sum(collapsed_with_timing$had_warning, na.rm = TRUE)
n_warning_before <- sum(collapsed_with_timing$lead_time > 0, na.rm = TRUE)

cat(sprintf("Stocks that reached B/BMSY < 0.5: %d\n", n_collapsed_total))
cat(sprintf("  Had FMI danger signal at some point: %d (%.1f%%)\n", 
            n_with_warning, n_with_warning/n_collapsed_total*100))
cat(sprintf("  Had danger signal BEFORE collapse: %d (%.1f%%)\n",
            n_warning_before, n_warning_before/n_collapsed_total*100))

if (n_warning_before > 0) {
  lead_times <- collapsed_with_timing$lead_time[collapsed_with_timing$lead_time > 0]
  cat(sprintf("\nLead time statistics (danger signal before collapse):\n"))
  cat(sprintf("  Median: %.0f years\n", median(lead_times, na.rm = TRUE)))
  cat(sprintf("  Mean: %.1f years\n", mean(lead_times, na.rm = TRUE)))
  cat(sprintf("  Range: %.0f to %.0f years\n", min(lead_times, na.rm = TRUE), max(lead_times, na.rm = TRUE)))
}

# =============================================================================
#  STEP 11: SAVE RESULTS
# =============================================================================

cat("\nSaving results...\n")

write.csv(analysis_data, "output/sliding_window/analysis_data.csv", row.names = FALSE)
write.csv(stock_summary, "output/sliding_window/stock_summary.csv", row.names = FALSE)
write.csv(roc_data, "output/sliding_window/roc_data.csv", row.names = FALSE)
write.csv(collapsed_with_timing, "output/sliding_window/collapse_timing.csv", row.names = FALSE)

# Summary stats
summary_stats <- data.frame(
  metric = c("N_stocks", "N_collapsed", "N_healthy", 
             "Sensitivity", "Specificity", "PPV", "NPV", "Accuracy",
             "ROC_AUC", "Optimal_threshold"),
  value = c(nrow(stock_summary), sum(stock_summary$ever_collapsed), 
            sum(!stock_summary$ever_collapsed),
            sensitivity, specificity, ppv, npv, accuracy,
            auc, optimal_threshold)
)
write.csv(summary_stats, "output/sliding_window/validation_metrics.csv", row.names = FALSE)

cat("  ✓ analysis_data.csv\n")
cat("  ✓ stock_summary.csv\n")
cat("  ✓ roc_data.csv\n")
cat("  ✓ collapse_timing.csv\n")
cat("  ✓ validation_metrics.csv\n")

# =============================================================================
#  STEP 12: GENERATE PLOTS
# =============================================================================

cat("\nGenerating plots...\n")

# Plot 1: ROC Curve
p1 <- ggplot(roc_data, aes(x = FPR, y = TPR)) +
  geom_line(size = 1.2, color = "steelblue") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(data = roc_data %>% filter(abs(threshold - 1.25) < 0.05),
             color = "red", size = 4) +
  geom_point(data = roc_data %>% filter(abs(threshold - optimal_threshold) < 0.05),
             color = "green", size = 4, shape = 17) +
  annotate("text", x = 0.65, y = 0.25, 
           label = sprintf("AUC = %.3f\nRed = FMI 1.25\nGreen = Optimal %.2f", 
                          auc, optimal_threshold), 
           size = 4, hjust = 0) +
  labs(
    title = "ROC Curve: FMI as Predictor of Stock Collapse",
    subtitle = sprintf("n = %d stocks | Collapse = B/BMSY < 0.5", nrow(stock_summary)),
    x = "False Positive Rate (1 - Specificity)",
    y = "True Positive Rate (Sensitivity)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold")) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1))

ggsave("output/sliding_window/ROC_curve.png", p1, width = 8, height = 8, dpi = 150)
cat("  ✓ ROC_curve.png\n")

# Plot 2: FMI vs Minimum B/BMSY scatter
p2 <- ggplot(stock_summary, aes(x = max_FMI, y = min_B_BMSY)) +
  geom_point(aes(color = life_history), alpha = 0.6, size = 2) +
  geom_vline(xintercept = FMI_DANGER, color = "red", linetype = "dashed", size = 0.8) +
  geom_hline(yintercept = COLLAPSE_THRESHOLD, color = "red", linetype = "dashed", size = 0.8) +
  scale_x_log10(limits = c(0.1, 50)) +
  scale_y_log10(limits = c(0.01, 10)) +
  annotate("text", x = 2, y = 0.02, label = "DANGER\nZONE", color = "red", fontface = "bold") +
  labs(
    title = "Maximum FMI vs Minimum B/BMSY by Stock",
    subtitle = "Each point = one stock's worst exploitation vs worst biomass state",
    x = "Maximum FMI (F/M) reached (log scale)",
    y = "Minimum B/BMSY reached (log scale)",
    color = "Life History"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave("output/sliding_window/FMI_vs_collapse.png", p2, width = 10, height = 8, dpi = 150)
cat("  ✓ FMI_vs_collapse.png\n")

# Plot 3: Life history comparison
lh_plot_data <- life_history_results %>%
  select(life_history, pct_collapsed, pct_danger, sensitivity) %>%
  pivot_longer(cols = c(pct_collapsed, pct_danger, sensitivity),
               names_to = "metric", values_to = "value") %>%
  mutate(metric = case_when(
    metric == "pct_collapsed" ~ "% Collapsed (B/BMSY<0.5)",
    metric == "pct_danger" ~ "% Reached Danger (FMI≥1.25)",
    metric == "sensitivity" ~ "Sensitivity (% caught)"
  ))

p3 <- ggplot(lh_plot_data, aes(x = life_history, y = value, fill = metric)) +
  geom_col(position = "dodge") +
  labs(
    title = "FMI Performance by Life History",
    x = "Life History Category",
    y = "Percentage",
    fill = "Metric"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  ) +
  scale_fill_brewer(palette = "Set2")

ggsave("output/sliding_window/life_history_comparison.png", p3, width = 10, height = 7, dpi = 150)
cat("  ✓ life_history_comparison.png\n")

# =============================================================================
#  FINAL SUMMARY
# =============================================================================

cat("\n
================================================================================
  VALIDATION COMPLETE
================================================================================

KEY RESULTS:
  Stocks analyzed:        %d
  Stocks that collapsed:  %d (%.1f%%)
  
DIAGNOSTIC PERFORMANCE:
  Sensitivity:            %.1f%% (FMI caught this %% of collapses)
  Specificity:            %.1f%% (FMI correctly cleared this %% of healthy stocks)
  Positive Predictive Value: %.1f%% (danger signals that were correct)
  ROC AUC:                %.3f

OPTIMAL THRESHOLD:
  Current threshold:      %.2f

  Optimal (Youden's J):   %.2f

FILES SAVED:
  output/sliding_window/*.csv (5 files)
  output/sliding_window/*.png (3 plots)

================================================================================
\n", 
nrow(stock_summary), 
sum(stock_summary$ever_collapsed), 
mean(stock_summary$ever_collapsed)*100,
sensitivity, specificity, ppv, auc,
FMI_DANGER, optimal_threshold)

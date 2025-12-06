#!/usr/bin/env Rscript
# =============================================================================
#
#  STRATIFIED ROC ANALYSIS — CAPRAZLI FMI
#  Production-grade implementation
#
#  Author: Kafkas M. Caprazli
#  ORCID:  0000-0002-5744-8944
#  Date:   2025-12-06
#
# =============================================================================

# =============================================================================
#  DEPENDENCIES
# =============================================================================

required_packages <- c("dplyr", "tidyr", "purrr", "ggplot2", "pROC", "cli")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing missing package: %s", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

invisible(lapply(required_packages, install_if_missing))

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(ggplot2)
  library(pROC)
  library(cli)
})

# =============================================================================
#  CONFIGURATION
# =============================================================================

CONFIG <- list(
  # Paths
  paths = list(
    db = "data/RAM_DBdata.RData",
    input_cache = "output/sliding_window/stock_summary.csv",
    output_dir = "output/stratified_roc"
  ),
  
  # Analysis parameters
  thresholds = list(
    danger = 1.25,
    warning = 1.00,
    gulland = 1.00
  ),
  
  collapse = list(
    moderate = 0.5,
    severe = 0.2
  ),
  
  roc = list(
    threshold_range = seq(0.1, 6.0, by = 0.05),
    min_stocks = 10,
    min_collapsed = 3
  ),
  
  # Life history classification
  life_history = list(
    breaks = c(0, 0.2, 0.4, 0.8, Inf),
    labels = c(
      "Long-lived (M<0.2)",
      "Medium (0.2-0.4)",
      "Moderate (0.4-0.8)",
      "Fast turnover (M≥0.8)"
    )
  ),
  
  # Visualization
  plot = list(
    width = 10,
    height = 8,
    dpi = 150
  )
)

# =============================================================================
#  LOGGING UTILITIES
# =============================================================================

Logger <- list(
  info    = function(...) cli::cli_alert_info(paste0(...)),
  success = function(...) cli::cli_alert_success(paste0(...)),
  warning = function(...) cli::cli_alert_warning(paste0(...)),
  error   = function(...) cli::cli_alert_danger(paste0(...)),
  header  = function(text) cli::cli_h1(text),
  subheader = function(text) cli::cli_h2(text),
  bullet  = function(...) cli::cli_li(paste0(...))
)

# =============================================================================
#  DATA LOADING MODULE
# =============================================================================

#' Load stock summary from cache or rebuild from RAM Legacy
#'
#' @param config Configuration list
#' @return data.frame with stock summary including max_FMI and ever_collapsed
load_stock_data <- function(config) {
  
  # Try cache first
  if (file.exists(config$paths$input_cache)) {
    Logger$info("Loading from cache: ", config$paths$input_cache)
    data <- read.csv(config$paths$input_cache, stringsAsFactors = FALSE)
    return(validate_stock_data(data))
  }
  
  # Rebuild from RAM Legacy
  Logger$info("Rebuilding from RAM Legacy: ", config$paths$db)
  
  if (!file.exists(config$paths$db)) {
    stop("Database not found: ", config$paths$db)
  }
  
  load(config$paths$db)
  
  stock_info <- stock %>%
    select(stockid, stocklong, commonname, scientificname, region) %>%
    distinct()
  
  M_values <- bioparams %>%
    filter(grepl("^M-", bioid, ignore.case = TRUE)) %>%
    mutate(M = suppressWarnings(as.numeric(biovalue))) %>%
    filter(!is.na(M), M > 0, M < 5) %>%
    group_by(stockid) %>%
    summarise(M = median(M, na.rm = TRUE), .groups = "drop")
  
  F_timeseries <- timeseries %>%
    filter(grepl("^F-", tsid, ignore.case = TRUE)) %>%
    mutate(F = suppressWarnings(as.numeric(tsvalue))) %>%
    filter(!is.na(F), F > 0, F < 10) %>%
    select(stockid, tsyear, F) %>%
    group_by(stockid, tsyear) %>%
    summarise(F = median(F, na.rm = TRUE), .groups = "drop")
  
  B_timeseries <- timeseries %>%
    filter(grepl("TBdivTBmsy|SSBdivSSBmsy|BdivBmsy", tsid, ignore.case = TRUE)) %>%
    mutate(B_BMSY = suppressWarnings(as.numeric(tsvalue))) %>%
    filter(!is.na(B_BMSY), B_BMSY > 0, B_BMSY < 20) %>%
    select(stockid, tsyear, B_BMSY) %>%
    group_by(stockid, tsyear) %>%
    summarise(B_BMSY = median(B_BMSY, na.rm = TRUE), .groups = "drop")
  
  data <- F_timeseries %>%
    inner_join(M_values, by = "stockid") %>%
    inner_join(B_timeseries, by = c("stockid", "tsyear")) %>%
    inner_join(stock_info, by = "stockid") %>%
    mutate(FMI = F / M) %>%
    group_by(stockid, commonname, region, M) %>%
    summarise(
      n_years = n(),
      max_FMI = max(FMI, na.rm = TRUE),
      min_B_BMSY = min(B_BMSY, na.rm = TRUE),
      ever_collapsed = any(B_BMSY < config$collapse$moderate, na.rm = TRUE),
      .groups = "drop"
    )
  
  validate_stock_data(data)
}

#' Validate stock data structure
#'
#' @param data data.frame to validate
#' @return validated data.frame (throws error if invalid)
validate_stock_data <- function(data) {
  required_cols <- c("stockid", "M", "max_FMI", "ever_collapsed")
  missing <- setdiff(required_cols, names(data))
  
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }
  
  if (nrow(data) == 0) {
    stop("Empty dataset after loading")
  }
  
  # Ensure logical type
  data$ever_collapsed <- as.logical(data$ever_collapsed)
  
  data
}

#' Classify stocks by life history
#'
#' @param data data.frame with M column
#' @param config Configuration list
#' @return data.frame with life_history column added
classify_life_history <- function(data, config) {
  data %>%
    mutate(
      life_history = cut(
        M,
        breaks = config$life_history$breaks,
        labels = config$life_history$labels,
        include.lowest = TRUE,
        right = FALSE
      ),
      life_history = as.character(life_history)
    )
}

# =============================================================================
#  ROC ANALYSIS MODULE
# =============================================================================

#' Compute ROC curve using pROC package
#'
#' @param data data.frame with predictor and outcome
#' @param predictor_col Name of predictor column (numeric)
#' @param outcome_col Name of outcome column (logical)
#' @return List with roc object, auc, and optimal threshold
compute_roc_curve <- function(data, 
                               predictor_col = "max_FMI", 
                               outcome_col = "ever_collapsed") {
  
  predictor <- data[[predictor_col]]
  outcome <- data[[outcome_col]]
  

  # Validate inputs
  if (length(unique(outcome)) < 2) {
    return(list(valid = FALSE, reason = "Outcome has no variance"))
  }
  
  if (sum(outcome) < 3) {
    return(list(valid = FALSE, reason = "Fewer than 3 positive cases"))
  }
  
  # Compute ROC using pROC
  roc_obj <- tryCatch(
    pROC::roc(
      response = outcome,
      predictor = predictor,
      levels = c(FALSE, TRUE),
      direction = "<",
      quiet = TRUE
    ),
    error = function(e) NULL
  )
  
  if (is.null(roc_obj)) {
    return(list(valid = FALSE, reason = "ROC computation failed"))
  }
  
  # Find optimal threshold (Youden's J)
  coords <- pROC::coords(roc_obj, "best", best.method = "youden", ret = "all")
  
  list(
    valid = TRUE,
    roc = roc_obj,
    auc = as.numeric(pROC::auc(roc_obj)),
    optimal_threshold = coords$threshold[1],
    optimal_sensitivity = coords$sensitivity[1],
    optimal_specificity = coords$specificity[1],
    n_total = length(outcome),
    n_positive = sum(outcome),
    n_negative = sum(!outcome)
  )
}

#' Compute performance metrics at a specific threshold
#'
#' @param data data.frame with predictor and outcome
#' @param threshold Numeric threshold for classification
#' @param predictor_col Name of predictor column
#' @param outcome_col Name of outcome column
#' @return List with TP, FP, FN, TN, sensitivity, specificity, ppv, npv, accuracy
compute_metrics_at_threshold <- function(data, threshold, 
                                          predictor_col = "max_FMI", 
                                          outcome_col = "ever_collapsed") {
  
  predicted <- data[[predictor_col]] >= threshold
  actual <- data[[outcome_col]]
  
  tp <- sum(predicted & actual, na.rm = TRUE)
  fp <- sum(predicted & !actual, na.rm = TRUE)
  fn <- sum(!predicted & actual, na.rm = TRUE)
  tn <- sum(!predicted & !actual, na.rm = TRUE)
  
  list(
    threshold = threshold,
    TP = tp, FP = fp, FN = fn, TN = tn,
    sensitivity = if ((tp + fn) > 0) tp / (tp + fn) else NA_real_,
    specificity = if ((tn + fp) > 0) tn / (tn + fp) else NA_real_,
    ppv = if ((tp + fp) > 0) tp / (tp + fp) else NA_real_,
    npv = if ((tn + fn) > 0) tn / (tn + fn) else NA_real_,
    accuracy = (tp + tn) / (tp + fp + fn + tn)
  )
}

#' Analyze ROC for multiple life history categories
#'
#' @param data data.frame with life_history column
#' @param config Configuration list
#' @return data.frame with ROC results per category
analyze_stratified_roc <- function(data, config) {
  
  categories <- unique(data$life_history)
  
  results <- map_dfr(categories, function(cat) {
    subset_data <- filter(data, life_history == cat)
    
    # Check minimum sample size
    if (nrow(subset_data) < config$roc$min_stocks) {
      return(tibble(
        life_history = cat,
        valid = FALSE,
        reason = "Insufficient stocks",
        n_stocks = nrow(subset_data)
      ))
    }
    
    if (sum(subset_data$ever_collapsed) < config$roc$min_collapsed) {
      return(tibble(
        life_history = cat,
        valid = FALSE,
        reason = "Insufficient collapsed stocks",
        n_stocks = nrow(subset_data),
        n_collapsed = sum(subset_data$ever_collapsed)
      ))
    }
    
    # Compute ROC
    roc_result <- compute_roc_curve(subset_data)
    
    if (!roc_result$valid) {
      return(tibble(
        life_history = cat,
        valid = FALSE,
        reason = roc_result$reason,
        n_stocks = nrow(subset_data)
      ))
    }
    
    # Get performance at universal threshold
    univ_metrics <- compute_metrics_at_threshold(
      subset_data, 
      config$thresholds$danger
    )
    
    tibble(
      life_history = cat,
      valid = TRUE,
      n_stocks = roc_result$n_total,
      n_collapsed = roc_result$n_positive,
      collapse_rate = roc_result$n_positive / roc_result$n_total,
      auc = roc_result$auc,
      optimal_threshold = roc_result$optimal_threshold,
      optimal_sensitivity = roc_result$optimal_sensitivity,
      optimal_specificity = roc_result$optimal_specificity,
      univ_sensitivity = univ_metrics$sensitivity,
      univ_specificity = univ_metrics$specificity,
      univ_ppv = univ_metrics$ppv
    )
  })
  
  results
}

#' Extract ROC curve points for plotting
#'
#' @param data data.frame with life_history column
#' @return data.frame with FPR, TPR per threshold per category
extract_roc_curves <- function(data) {
  
  categories <- unique(data$life_history)
  
  map_dfr(categories, function(cat) {
    subset_data <- filter(data, life_history == cat)
    
    if (sum(subset_data$ever_collapsed) < 3) return(NULL)
    
    roc_obj <- tryCatch(
      pROC::roc(
        response = subset_data$ever_collapsed,
        predictor = subset_data$max_FMI,
        levels = c(FALSE, TRUE),
        direction = "<",
        quiet = TRUE
      ),
      error = function(e) NULL
    )
    
    if (is.null(roc_obj)) return(NULL)
    
    tibble(
      life_history = cat,
      threshold = roc_obj$thresholds,
      TPR = roc_obj$sensitivities,
      FPR = 1 - roc_obj$specificities
    )
  })
}

# =============================================================================
#  COMPARISON MODULE
# =============================================================================

#' Compare universal vs stratified classifier performance
#'
#' @param data data.frame with life_history column
#' @param stratified_results Results from analyze_stratified_roc()
#' @param config Configuration list
#' @return List with universal and stratified performance
compare_approaches <- function(data, stratified_results, config) {
  
  # Universal approach: single threshold for all
  universal <- compute_metrics_at_threshold(data, config$thresholds$danger)
  universal$approach <- "Universal"
  
  # Stratified approach: optimal threshold per life history
  valid_results <- filter(stratified_results, valid)
  
  threshold_lookup <- setNames(
    valid_results$optimal_threshold,
    valid_results$life_history
  )
  
  data_with_pred <- data %>%
    filter(life_history %in% names(threshold_lookup)) %>%
    mutate(
      threshold = threshold_lookup[life_history],
      predicted = max_FMI >= threshold
    )
  
  tp <- sum(data_with_pred$predicted & data_with_pred$ever_collapsed)
  fp <- sum(data_with_pred$predicted & !data_with_pred$ever_collapsed)
  fn <- sum(!data_with_pred$predicted & data_with_pred$ever_collapsed)
  tn <- sum(!data_with_pred$predicted & !data_with_pred$ever_collapsed)
  
  stratified <- list(
    approach = "Stratified",
    threshold = NA,
    TP = tp, FP = fp, FN = fn, TN = tn,
    sensitivity = if ((tp + fn) > 0) tp / (tp + fn) else NA_real_,
    specificity = if ((tn + fp) > 0) tn / (tn + fp) else NA_real_,
    ppv = if ((tp + fp) > 0) tp / (tp + fp) else NA_real_,
    npv = if ((tn + fn) > 0) tn / (tn + fn) else NA_real_,
    accuracy = (tp + tn) / (tp + fp + fn + tn)
  )
  
  list(
    universal = universal,
    stratified = stratified,
    improvement = list(
      sensitivity = stratified$sensitivity - universal$sensitivity,
      specificity = stratified$specificity - universal$specificity,
      ppv = stratified$ppv - universal$ppv,
      accuracy = stratified$accuracy - universal$accuracy
    )
  )
}

# =============================================================================
#  VISUALIZATION MODULE
# =============================================================================

#' Create stratified ROC curves plot
#'
#' @param roc_curves data.frame from extract_roc_curves()
#' @param stratified_results data.frame from analyze_stratified_roc()
#' @return ggplot object
plot_stratified_roc <- function(roc_curves, stratified_results) {
  
  valid_results <- filter(stratified_results, valid)
  
  optimal_points <- valid_results %>%
    transmute(
      life_history,
      FPR = 1 - optimal_specificity,
      TPR = optimal_sensitivity,
      label = sprintf("%.2f", optimal_threshold)
    )
  
  ggplot(roc_curves, aes(x = FPR, y = TPR, color = life_history)) +
    geom_line(linewidth = 1.1) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
    geom_point(data = optimal_points, size = 4, shape = 17) +
    geom_text(
      data = optimal_points, 
      aes(label = label), 
      vjust = -1, hjust = 0.5, size = 3, show.legend = FALSE
    ) +
    scale_color_brewer(palette = "Set1", name = "Life History") +
    coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    labs(
      title = "ROC Curves by Life History Category",
      subtitle = "Triangles mark optimal thresholds (Youden's J)",
      x = "False Positive Rate (1 - Specificity)",
      y = "True Positive Rate (Sensitivity)"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
}

#' Create threshold comparison bar plot
#'
#' @param stratified_results data.frame from analyze_stratified_roc()
#' @param config Configuration list
#' @return ggplot object
plot_optimal_thresholds <- function(stratified_results, config) {
  
  valid_results <- filter(stratified_results, valid) %>%
    arrange(desc(optimal_threshold))
  
  ggplot(valid_results, aes(
    x = reorder(life_history, optimal_threshold), 
    y = optimal_threshold
  )) +
    geom_col(aes(fill = auc), width = 0.7) +
    geom_hline(
      yintercept = config$thresholds$danger, 
      linetype = "dashed", color = "#E41A1C", linewidth = 1
    ) +
    geom_hline(
      yintercept = config$thresholds$gulland, 
      linetype = "dotted", color = "#FF7F00", linewidth = 1
    ) +
    geom_text(aes(label = sprintf("%.2f", optimal_threshold)), hjust = -0.2, size = 4) +
    annotate(
      "text", x = 0.5, y = config$thresholds$danger + 0.1, 
      label = sprintf("Current (%.2f)", config$thresholds$danger), 
      color = "#E41A1C", hjust = 0, size = 3.5
    ) +
    annotate(
      "text", x = 0.5, y = config$thresholds$gulland + 0.1, 
      label = "Gulland (1.0)", color = "#FF7F00", hjust = 0, size = 3.5
    ) +
    scale_fill_gradient(low = "#9ECAE1", high = "#08519C", name = "AUC", limits = c(0.5, 1)) +
    coord_flip(ylim = c(0, max(valid_results$optimal_threshold) * 1.3)) +
    labs(
      title = "Optimal FMI Threshold by Life History",
      subtitle = "Long-lived species need LOWER threshold; fast-turnover need HIGHER",
      x = NULL,
      y = "Optimal FMI Threshold (F/M)"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
}

#' Create performance comparison plot
#'
#' @param comparison List from compare_approaches()
#' @return ggplot object
plot_performance_comparison <- function(comparison) {
  
  metrics <- c("sensitivity", "specificity", "ppv", "accuracy")
  
  data <- tibble(
    approach = rep(c("Universal", "Stratified"), each = length(metrics)),
    metric = rep(metrics, 2),
    value = c(
      comparison$universal$sensitivity,
      comparison$universal$specificity,
      comparison$universal$ppv,
      comparison$universal$accuracy,
      comparison$stratified$sensitivity,
      comparison$stratified$specificity,
      comparison$stratified$ppv,
      comparison$stratified$accuracy
    )
  ) %>%
    mutate(
      metric = factor(
        metric, 
        levels = metrics, 
        labels = c("Sensitivity", "Specificity", "PPV", "Accuracy")
      )
    )
  
  ggplot(data, aes(x = metric, y = value * 100, fill = approach)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_text(
      aes(label = sprintf("%.0f%%", value * 100)),
      position = position_dodge(width = 0.8), vjust = -0.5, size = 3.5
    ) +
    scale_fill_manual(
      values = c("Universal" = "#FC8D62", "Stratified" = "#66C2A5"),
      name = "Approach"
    ) +
    ylim(0, 105) +
    labs(
      title = "Performance: Universal vs Stratified Thresholds",
      subtitle = sprintf(
        "Specificity: +%.0f pp | PPV: +%.0f pp | Accuracy: +%.0f pp",
        comparison$improvement$specificity * 100,
        comparison$improvement$ppv * 100,
        comparison$improvement$accuracy * 100
      ),
      x = NULL,
      y = "Percentage"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      legend.position = "top",
      panel.grid.minor = element_blank()
    )
}

#' Create AUC comparison plot
#'
#' @param universal_auc Numeric AUC for universal approach
#' @param stratified_results data.frame from analyze_stratified_roc()
#' @return ggplot object
plot_auc_comparison <- function(universal_auc, stratified_results) {
  
  valid_results <- filter(stratified_results, valid)
  
  data <- bind_rows(
    tibble(category = "Universal\n(all stocks)", auc = universal_auc, type = "Universal"),
    valid_results %>% transmute(category = life_history, auc = auc, type = "Stratified")
  )
  
  ggplot(data, aes(x = reorder(category, auc), y = auc, fill = type)) +
    geom_col(width = 0.7) +
    geom_hline(yintercept = 0.7, linetype = "dashed", color = "#2CA02C") +
    geom_hline(yintercept = 0.5, linetype = "dotted", color = "#D62728") +
    geom_text(aes(label = sprintf("%.2f", auc)), vjust = -0.5, size = 4) +
    annotate("text", x = 0.6, y = 0.72, label = "Acceptable (0.7)", hjust = 0, size = 3, color = "#2CA02C") +
    annotate("text", x = 0.6, y = 0.52, label = "Random (0.5)", hjust = 0, size = 3, color = "#D62728") +
    scale_fill_manual(
      values = c("Universal" = "#FC8D62", "Stratified" = "#66C2A5"),
      name = "Approach"
    ) +
    coord_flip(ylim = c(0, 1)) +
    labs(
      title = "AUC by Analysis Approach",
      subtitle = "Stratified analysis reveals improved discrimination per life history",
      x = NULL,
      y = "Area Under ROC Curve (AUC)"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      legend.position = "top",
      panel.grid.minor = element_blank()
    )
}

# =============================================================================
#  OUTPUT MODULE
# =============================================================================

#' Save all results to files
#'
#' @param results Named list of results
#' @param config Configuration list
save_results <- function(results, config) {
  
  output_dir <- config$paths$output_dir
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # CSV outputs
  write.csv(
    results$stratified, 
    file.path(output_dir, "stratified_results.csv"), 
    row.names = FALSE
  )
  write.csv(
    results$roc_curves, 
    file.path(output_dir, "roc_curves.csv"), 
    row.names = FALSE
  )
  write.csv(
    results$thresholds, 
    file.path(output_dir, "proposed_thresholds.csv"), 
    row.names = FALSE
  )
  write.csv(
    results$comparison_df, 
    file.path(output_dir, "performance_comparison.csv"), 
    row.names = FALSE
  )
  
  # Plots
  ggsave(
    file.path(output_dir, "stratified_ROC_curves.png"), 
    results$plots$roc, 
    width = config$plot$width, height = config$plot$height, dpi = config$plot$dpi
  )
  ggsave(
    file.path(output_dir, "optimal_thresholds.png"), 
    results$plots$thresholds, 
    width = config$plot$width, height = 6, dpi = config$plot$dpi
  )
  ggsave(
    file.path(output_dir, "performance_comparison.png"), 
    results$plots$comparison, 
    width = config$plot$width, height = 6, dpi = config$plot$dpi
  )
  ggsave(
    file.path(output_dir, "AUC_comparison.png"), 
    results$plots$auc, 
    width = config$plot$width, height = 6, dpi = config$plot$dpi
  )
  
  invisible(TRUE)
}

#' Generate verdict on publication strategy
#'
#' @param universal_auc Numeric
#' @param stratified_results data.frame
#' @param comparison List from compare_approaches()
#' @return List with recommendation and reason
generate_verdict <- function(universal_auc, stratified_results, comparison) {
  
  valid_results <- filter(stratified_results, valid)
  
  if (nrow(valid_results) == 0) {
    return(list(
      recommendation = "INSUFFICIENT DATA",
      reason = "No life history category had sufficient data for ROC analysis"
    ))
  }
  
  best_auc <- max(valid_results$auc)
  avg_auc <- mean(valid_results$auc)
  spec_improvement <- comparison$improvement$specificity
  
  if (best_auc >= 0.70) {
    return(list(
      recommendation = "COMBINED PAPER",
      reason = sprintf(
        "Best stratified AUC = %.2f (>=0.70). Complete story: problem -> insight -> solution.",
        best_auc
      )
    ))
  }
  
  if (avg_auc > universal_auc + 0.05 || spec_improvement > 0.10) {
    return(list(
      recommendation = "COMBINED PAPER (with caveats)",
      reason = sprintf(
        "Stratification improves performance (AUC: %.2f -> %.2f avg, Spec: +%.0f pp). Frame as 'improved, not solved'.",
        universal_auc, avg_auc, spec_improvement * 100
      )
    ))
  }
  
  list(
    recommendation = "PAPER 1 ONLY",
    reason = sprintf(
      "Stratification provides minimal improvement (AUC: %.2f -> %.2f). Publish screening tool with limitations.",
      universal_auc, avg_auc
    )
  )
}

# =============================================================================
#  MAIN EXECUTION
# =============================================================================

main <- function(config = CONFIG) {
  
  cli::cli_h1("STRATIFIED ROC ANALYSIS - CAPRAZLI FMI")
  
  # ─────────────────────────────────────────────────────────────────────────
  # Load data
  # ─────────────────────────────────────────────────────────────────────────
  Logger$subheader("Loading Data")
  data <- load_stock_data(config)
  data <- classify_life_history(data, config)
  Logger$success(sprintf("Loaded %d stocks", nrow(data)))
  
  # ─────────────────────────────────────────────────────────────────────────
  # Universal ROC
  # ─────────────────────────────────────────────────────────────────────────
  Logger$subheader("Universal ROC Analysis")
  universal_roc <- compute_roc_curve(data)
  
  Logger$info(sprintf("Universal AUC: %.3f", universal_roc$auc))
  Logger$info(sprintf(
    "Optimal threshold: %.2f (Sens=%.0f%%, Spec=%.0f%%)",
    universal_roc$optimal_threshold,
    universal_roc$optimal_sensitivity * 100,
    universal_roc$optimal_specificity * 100
  ))
  
  # ─────────────────────────────────────────────────────────────────────────
  # Stratified ROC
  # ─────────────────────────────────────────────────────────────────────────
  Logger$subheader("Stratified ROC Analysis")
  stratified_results <- analyze_stratified_roc(data, config)
  
  valid_results <- filter(stratified_results, valid)
  for (i in seq_len(nrow(valid_results))) {
    r <- valid_results[i, ]
    Logger$bullet(sprintf(
      "%s: AUC=%.2f, Optimal=%.2f (n=%d)",
      r$life_history, r$auc, r$optimal_threshold, r$n_stocks
    ))
  }
  
  # Extract ROC curves for plotting
  roc_curves <- extract_roc_curves(data)
  
  # ─────────────────────────────────────────────────────────────────────────
  # Compare approaches
  # ─────────────────────────────────────────────────────────────────────────
  Logger$subheader("Comparing Approaches")
  comparison <- compare_approaches(data, stratified_results, config)
  
  Logger$info(sprintf(
    "Universal:  Sens=%.0f%% Spec=%.0f%% PPV=%.0f%%",
    comparison$universal$sensitivity * 100,
    comparison$universal$specificity * 100,
    comparison$universal$ppv * 100
  ))
  Logger$info(sprintf(
    "Stratified: Sens=%.0f%% Spec=%.0f%% PPV=%.0f%%",
    comparison$stratified$sensitivity * 100,
    comparison$stratified$specificity * 100,
    comparison$stratified$ppv * 100
  ))
  Logger$success(sprintf(
    "Improvement: Spec +%.0f pp, PPV +%.0f pp, Acc +%.0f pp",
    comparison$improvement$specificity * 100,
    comparison$improvement$ppv * 100,
    comparison$improvement$accuracy * 100
  ))
  
  # ─────────────────────────────────────────────────────────────────────────
  # Generate plots
  # ─────────────────────────────────────────────────────────────────────────
  Logger$subheader("Generating Visualizations")
  plots <- list(
    roc = plot_stratified_roc(roc_curves, stratified_results),
    thresholds = plot_optimal_thresholds(stratified_results, config),
    comparison = plot_performance_comparison(comparison),
    auc = plot_auc_comparison(universal_roc$auc, stratified_results)
  )
  
  # Build threshold table
  threshold_table <- valid_results %>%
    transmute(
      life_history,
      M_range = case_when(
        grepl("Long-lived", life_history) ~ "< 0.2",
        grepl("Medium", life_history) ~ "0.2 - 0.4",
        grepl("Moderate", life_history) ~ "0.4 - 0.8",
        grepl("Fast", life_history) ~ ">= 0.8"
      ),
      n_stocks,
      optimal_threshold = round(optimal_threshold, 2),
      E_equivalent = round(optimal_threshold / (1 + optimal_threshold), 3),
      auc = round(auc, 3)
    )
  
  # Comparison dataframe
  comparison_df <- tibble(
    approach = c("Universal", "Stratified"),
    sensitivity = c(comparison$universal$sensitivity, comparison$stratified$sensitivity),
    specificity = c(comparison$universal$specificity, comparison$stratified$specificity),
    ppv = c(comparison$universal$ppv, comparison$stratified$ppv),
    accuracy = c(comparison$universal$accuracy, comparison$stratified$accuracy)
  )
  
  # Bundle results
  results <- list(
    stratified = stratified_results,
    roc_curves = roc_curves,
    thresholds = threshold_table,
    comparison = comparison,
    comparison_df = comparison_df,
    universal_auc = universal_roc$auc,
    plots = plots
  )
  
  # ─────────────────────────────────────────────────────────────────────────
  # Save outputs
  # ─────────────────────────────────────────────────────────────────────────
  Logger$subheader("Saving Results")
  save_results(results, config)
  Logger$success("All files saved to ", config$paths$output_dir)
  
  # ─────────────────────────────────────────────────────────────────────────
  # Verdict
  # ─────────────────────────────────────────────────────────────────────────
  verdict <- generate_verdict(universal_roc$auc, stratified_results, comparison)
  
  cli::cli_h1("VERDICT")
  cli::cli_alert_success(verdict$recommendation)
  cli::cli_text(verdict$reason)
  
  cli::cli_h2("Proposed Thresholds")
  print(as.data.frame(threshold_table))
  
  invisible(results)
}

# =============================================================================
#  EXECUTE
# =============================================================================

if (!interactive()) {
  results <- main()
}

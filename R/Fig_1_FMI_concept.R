#!/usr/bin/env Rscript
# =============================================================================
#  FIGURE 1: FMI CONCEPTUAL DIAGRAM (v5 - Target 10/10)
#  
#  Author: Kafkas M. Caprazli
#  ORCID: 0000-0002-5744-8944
# =============================================================================

library(ggplot2)
library(dplyr)

# =============================================================================
#  DESIGN PRINCIPLES FOR 10/10
#  - Clear visual hierarchy (zones > species > labels)
#  - No text collisions anywhere
#  - Labels in empty space with high contrast
#  - Life history context preserved
#  - Self-explanatory without caption
# =============================================================================

CONFIG <- list(
  M_range = c(0.03, 2.8),
  F_range = c(0.03, 2.8),
  
  colors = list(
    sustainable = "#1B5E20",      # Dark green
    fully_exploited = "#E65100",  # Deep orange
    overexploited = "#B71C1C",    # Dark red
    zone_sustainable = "#A5D6A7", # Light green fill
    zone_caution = "#FFE0B2",     # Light orange fill
    zone_danger = "#FFCDD2"       # Light red fill
  ),
  
  width = 10,
  height = 10,
  dpi = 300
)

# =============================================================================
#  SPECIES DATA - positioned for zero overlap
# =============================================================================

species_data <- tibble(
  species = c("Shark", "Rockfish", "Cod", "Tuna", "Herring", "Anchovy"),
  M = c(0.06, 0.08, 0.22, 0.35, 0.60, 1.40),
  F = c(0.045, 0.38, 0.35, 0.18, 0.55, 0.70),
  status = c("sustainable", "overexploited", "overexploited", 
             "sustainable", "fully_exploited", "sustainable"),
  # Label positions: 1=above, 2=below, 3=left, 4=right
  label_pos = c("below", "above", "above", "below", "above", "above")
)

# Calculate label nudges
species_data <- species_data %>%
  mutate(
    nudge_y = case_when(
      label_pos == "above" ~ F * 0.35,
      label_pos == "below" ~ -F * 0.35,
      TRUE ~ 0
    ),
    nudge_x = case_when(
      label_pos == "left" ~ -M * 0.2,
      label_pos == "right" ~ M * 0.2,
      TRUE ~ 0
    )
  )

# =============================================================================
#  BUILD PLOT
# =============================================================================

M_seq <- 10^seq(log10(0.01), log10(5), length.out = 300)

p <- ggplot() +
  
  # === ZONE SHADING (clean bands) ===
  
  # Sustainable: below F/M = 0.75
  geom_ribbon(
    data = tibble(M = M_seq, F = M_seq * 0.75),
    aes(x = M, ymin = 0.001, ymax = F),
    fill = CONFIG$colors$zone_sustainable, alpha = 0.6
  ) +
  
  # Fully exploited: between 0.75 and 1.25
  geom_ribbon(
    data = tibble(M = M_seq, y1 = M_seq * 0.75, y2 = M_seq * 1.25),
    aes(x = M, ymin = y1, ymax = y2),
    fill = CONFIG$colors$zone_caution, alpha = 0.6
  ) +
  
  # Overexploited: above F/M = 1.25
  geom_ribbon(
    data = tibble(M = M_seq, F = M_seq * 1.25),
    aes(x = M, ymin = F, ymax = 20),
    fill = CONFIG$colors$zone_danger, alpha = 0.6
  ) +
  
  # === THRESHOLD LINES ===
  
  geom_abline(slope = 1, intercept = log10(0.75), 
              color = CONFIG$colors$sustainable, linewidth = 1.1, linetype = "dashed") +
  geom_abline(slope = 1, intercept = 0, 
              color = "gray20", linewidth = 1.4) +
  geom_abline(slope = 1, intercept = log10(1.25), 
              color = CONFIG$colors$overexploited, linewidth = 1.1, linetype = "dashed") +
  
  # === LINE LABELS (left side, with white boxes, rotated) ===
  
  annotate("label", x = 0.09, y = 0.09 * 0.75, 
           label = " F/M = 0.75 ", 
           fill = "white", color = CONFIG$colors$sustainable,
           size = 3.3, fontface = "bold", angle = 45,
           label.padding = unit(0.2, "lines"), label.size = 0) +
  
  annotate("label", x = 0.105, y = 0.105, 
           label = " F = M (Gulland) ", 
           fill = "white", color = "gray20",
           size = 3.3, fontface = "bold", angle = 45,
           label.padding = unit(0.2, "lines"), label.size = 0) +
  
  annotate("label", x = 0.075, y = 0.075 * 1.25, 
           label = " F/M = 1.25 ", 
           fill = "white", color = CONFIG$colors$overexploited,
           size = 3.3, fontface = "bold", angle = 45,
           label.padding = unit(0.2, "lines"), label.size = 0) +
  
  # === ZONE LABELS (large, clear, centered in zones) ===
  
  annotate("label", x = 1.6, y = 0.11, 
           label = "SUSTAINABLE", 
           fill = alpha("white", 0.85), color = CONFIG$colors$sustainable,
           size = 5, fontface = "bold",
           label.padding = unit(0.4, "lines"), label.size = 0) +
  
  annotate("label", x = 1.6, y = 1.6, 
           label = "FULLY EXPLOITED", 
           fill = alpha("white", 0.85), color = CONFIG$colors$fully_exploited,
           size = 4.5, fontface = "bold",
           label.padding = unit(0.4, "lines"), label.size = 0) +
  
  annotate("label", x = 0.16, y = 1.4, 
           label = "OVEREXPLOITED", 
           fill = alpha("white", 0.85), color = CONFIG$colors$overexploited,
           size = 5, fontface = "bold",
           label.padding = unit(0.4, "lines"), label.size = 0) +
  
  # === SPECIES POINTS ===
  
  geom_point(data = species_data, 
             aes(x = M, y = F, fill = status),
             shape = 21, size = 5, stroke = 1.1, color = "white") +
  geom_point(data = species_data, 
             aes(x = M, y = F, fill = status),
             shape = 21, size = 5, stroke = 0.6, color = "black") +
  
  # === SPECIES LABELS (with connecting segments for clarity) ===
  
  geom_segment(data = species_data,
               aes(x = M, y = F, 
                   xend = M + nudge_x * 0.6, yend = F + nudge_y * 0.6),
               color = "gray50", linewidth = 0.3) +
  
  geom_label(data = species_data,
             aes(x = M + nudge_x, y = F + nudge_y, label = species),
             size = 3, fontface = "bold",
             fill = "white", color = "gray20",
             label.padding = unit(0.15, "lines"),
             label.size = 0.2, label.r = unit(0.1, "lines")) +
  
  # === LIFE HISTORY ARROW ===
  
  annotate("segment", x = 0.045, xend = 2.2, y = 0.026, yend = 0.026,
           arrow = arrow(length = unit(0.2, "cm"), type = "closed", ends = "last"),
           linewidth = 0.7, color = "gray40") +
  annotate("text", x = 0.045, y = 0.026, 
           label = "Long-lived  ", size = 2.8, hjust = 1, vjust = -0.8,
           color = "gray30", fontface = "italic") +
  annotate("text", x = 2.2, y = 0.026, 
           label = "  Fast turnover", size = 2.8, hjust = 0, vjust = -0.8,
           color = "gray30", fontface = "italic") +
  annotate("text", x = 0.35, y = 0.026, 
           label = "Life History Gradient", size = 2.6, hjust = 0.5, vjust = 1.8,
           color = "gray40") +
  
  # === EXPLANATORY NOTE (bottom right) ===
  
  annotate("text", x = 2.5, y = 0.038,
           label = "Points show example\nstocks across life histories",
           size = 2.4, hjust = 1, vjust = 0, color = "gray50",
           lineheight = 0.9) +
  
  # === SCALES ===
  
  scale_x_log10(
    limits = CONFIG$M_range,
    breaks = c(0.05, 0.1, 0.2, 0.5, 1.0, 2.0),
    labels = c("0.05", "0.1", "0.2", "0.5", "1.0", "2.0"),
    expand = c(0.02, 0)
  ) +
  scale_y_log10(
    limits = CONFIG$F_range,
    breaks = c(0.05, 0.1, 0.2, 0.5, 1.0, 2.0),
    labels = c("0.05", "0.1", "0.2", "0.5", "1.0", "2.0"),
    expand = c(0.02, 0)
  ) +
  scale_fill_manual(
    values = c(
      "sustainable" = CONFIG$colors$sustainable,
      "fully_exploited" = CONFIG$colors$fully_exploited,
      "overexploited" = CONFIG$colors$overexploited
    ),
    guide = "none"
  ) +
  
  # === LABELS ===
  
  labs(
    title = "Fishing Mortality Index (FMI)",
    subtitle = "Exploitation status visualized on log-log mortality axes",
    x = expression(paste("Natural Mortality, ", italic(M), " (", yr^-1, ")")),
    y = expression(paste("Fishing Mortality, ", italic(F), " (", yr^-1, ")"))
  ) +
  
  # === THEME ===
  
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, 
                               margin = margin(b = 4)),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40", 
                                  margin = margin(b = 15)),
    axis.title.x = element_text(size = 11, margin = margin(t = 10)),
    axis.title.y = element_text(size = 11, margin = margin(r = 10)),
    axis.text = element_text(size = 10, color = "gray20"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray80", linewidth = 0.2),
    plot.margin = margin(15, 15, 15, 15),
    panel.border = element_rect(color = "gray40", fill = NA, linewidth = 0.6),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  coord_fixed(ratio = 1, xlim = c(0.035, 2.6), ylim = c(0.035, 2.6), clip = "off")

# =============================================================================
#  SAVE
# =============================================================================

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

ggsave("output/figures/Fig_1_FMI_concept.png", p, 
       width = CONFIG$width, height = CONFIG$height, dpi = CONFIG$dpi,
       bg = "white")

ggsave("output/figures/Fig_1_FMI_concept.pdf", p, 
       width = CONFIG$width, height = CONFIG$height,
       device = cairo_pdf)

ggsave("output/figures/Fig_1_FMI_concept.tiff", p, 
       width = CONFIG$width, height = CONFIG$height, dpi = CONFIG$dpi,
       compression = "lzw")

cat("✓ Fig_1_FMI_concept.png (300 dpi)\n")
cat("✓ Fig_1_FMI_concept.pdf (vector)\n")
cat("✓ Fig_1_FMI_concept.tiff (journal submission)\n")

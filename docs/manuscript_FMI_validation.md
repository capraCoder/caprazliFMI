# Life-history-specific thresholds for the Fishing Mortality Index: validation on 209 stocks

**Kafkas M. Caprazli**

Independent Researcher  
Email: caprazli@gmail.com  
ORCID: 0000-0002-5744-8944

---

## Abstract

The exploitation fraction *E* = *F*/(*F*+*M*) has served as a standard metric for assessing fishing pressure since Gulland (1971), with *E* = 0.5 widely adopted as a precautionary threshold. However, *E* compresses the relationship between fishing mortality (*F*) and natural mortality (*M*) into a single dimension, obscuring magnitude differences across life histories. We introduce the Fishing Mortality Index (FMI), which plots *F* against *M* on log-log axes, preserving both ratio and magnitude information. We validated FMI using 209 stocks from the RAM Legacy Stock Assessment Database, defining collapse as *B*/*B*~MSY~ < 0.5. A universal threshold (FMI = 1.25) achieved 89% sensitivity but only 39% specificity (AUC = 0.72). Life-history stratification substantially improved discrimination: optimal thresholds ranged from 0.45 for fast-turnover species (*M* ≥ 0.8) to 4.91 for long-lived species (*M* < 0.2), with specificity improving to 69% (AUC = 0.71–0.85). Unexpectedly, optimal thresholds increased with longevity, suggesting that long-lived species tolerate higher FMI values before collapse, while fast-turnover collapses are associated with low FMI and likely driven by environmental factors. We recommend life-history-specific threshold calibration for operational FMI applications and propose that FMI be used as a high-sensitivity screening tool rather than a precise predictor.

**Keywords:** fishing mortality, natural mortality, stock assessment, life history, exploitation rate, ROC analysis, RAM Legacy

---

## 1. Introduction

Sustainable fisheries management requires reliable indicators of exploitation status (Hilborn and Walters, 1992). Since Gulland's (1971) foundational work, the exploitation fraction *E* = *F*/(*F*+*M*) has served as a primary metric, with *E* = 0.5 (equivalent to *F* = *M*) widely adopted as a threshold separating sustainable from unsustainable fishing pressure (Patterson, 1992; Zhou et al., 2010). This threshold has intuitive appeal: when fishing mortality equals natural mortality, approximately 63% of the population dies annually, representing a rough upper bound for sustainable yield.

However, the exploitation fraction suffers from a fundamental limitation. By compressing the relationship between *F* and *M* into a single ratio, *E* obscures magnitude differences across life histories. A spiny dogfish (*M* ≈ 0.05) and a Peruvian anchovy (*M* ≈ 1.2) may share the same exploitation fraction, yet the absolute mortality rates—and hence the biological consequences—differ by more than an order of magnitude. This compression limits the utility of *E* for comparative analysis across diverse taxa and ecosystems. Froese (2004) advocated for simple, robust indicators that can be applied across data-limited situations; FMI extends this philosophy by providing visual context that single-value metrics cannot.

We propose the Fishing Mortality Index (FMI), a visualization framework that plots *F* against *M* on log-log axes. This transformation preserves the ratio-based safety thresholds of the Gulland framework while retaining magnitude information. On log-log axes, the *F* = *M* line appears as a 45° diagonal, with parallel iso-ratio lines (e.g., *F*/*M* = 0.75, 1.25) defining exploitation zones. Species from sharks to sardines can be positioned on the same plot, with their distance from the origin encoding life history (turnover rate) and their position relative to threshold lines encoding exploitation status.

The FMI framework is mathematically equivalent to *E* at the *F* = *M* threshold: when *F* = *M*, then *E* = *F*/(*F*+*M*) = *F*/(2*F*) = 0.5. However, FMI provides superior visual discrimination for comparative analysis and enables direct assessment of whether stocks are approaching, at, or beyond critical thresholds.

The objectives of this study were to: (1) validate FMI as a diagnostic tool for stock collapse using a large, independent dataset; (2) evaluate whether a universal FMI threshold applies across life histories; and (3) develop life-history-specific thresholds that improve predictive performance.

---

## 2. Methods

### 2.1 Data source

We obtained stock assessment data from the RAM Legacy Stock Assessment Database version 4.64 (Ricard et al., 2012; RAM Legacy, 2024). The database compiles time series of fishing mortality, biomass, and reference points from formal stock assessments conducted by management agencies worldwide. We extracted stocks meeting the following criteria: (1) natural mortality (*M*) estimate available in the bioparams table; (2) fishing mortality (*F*) time series available; (3) biomass relative to *B*~MSY~ (*B*/*B*~MSY~) time series available. After filtering, 209 stocks with 10,565 stock-years remained for analysis.

### 2.2 FMI calculation

For each stock-year, we calculated FMI as the ratio of fishing mortality to natural mortality:

$$\text{FMI} = \frac{F}{M}$$

We also calculated the maximum FMI observed across each stock's time series (max_FMI) as a summary statistic for classification analysis.

### 2.3 Collapse definition

We defined collapse as any occurrence of *B*/*B*~MSY~ < 0.5 during a stock's time series. This threshold corresponds to the lower limit of the "fully exploited" zone in many management frameworks and represents a substantial departure from target biomass. Using this binary definition, 92 of 209 stocks (44%) experienced collapse at some point in their assessment history.

### 2.4 Life history classification

We stratified stocks by natural mortality into four life history categories:

| Category | *M* range | *n* stocks | Collapsed |
|----------|-----------|------------|-----------|
| Long-lived | < 0.2 | 104 | 41 (39%) |
| Medium | 0.2–0.4 | 72 | 31 (43%) |
| Moderate turnover | 0.4–0.8 | 16 | 11 (69%) |
| Fast turnover | ≥ 0.8 | 17 | 9 (53%) |

### 2.5 ROC analysis

We evaluated diagnostic performance using receiver operating characteristic (ROC) analysis implemented in the pROC package for R (Robin et al., 2011). For each threshold value of max_FMI, we calculated sensitivity (proportion of collapsed stocks correctly identified) and specificity (proportion of healthy stocks correctly identified). We computed the area under the ROC curve (AUC) as an overall measure of discriminatory ability. Optimal thresholds were identified using Youden's J statistic (sensitivity + specificity − 1).

We performed ROC analysis at two levels: (1) universal analysis pooling all 209 stocks; (2) stratified analysis within each life history category.

### 2.6 Lead time analysis

For stocks that collapsed and had prior FMI danger signals (FMI ≥ 1.25), we calculated lead time as the number of years between the first danger signal and the first year of collapse.

### 2.7 Code and data availability

All analysis code is available at https://github.com/capraCoder/caprazliFMI and archived at Zenodo (DOI: 10.5281/zenodo.17844169). The RAM Legacy Stock Assessment Database is available at https://www.ramlegacy.org.

---

## 3. Results

### 3.1 Universal threshold performance

Using a universal threshold of FMI = 1.25, we achieved the following diagnostic performance:

| Metric | Value |
|--------|-------|
| Sensitivity | 89.1% |
| Specificity | 39.3% |
| Positive predictive value | 53.6% |
| Negative predictive value | 82.1% |
| AUC | 0.716 |

FMI detected prior danger signals in 82 of 92 collapsed stocks (89% sensitivity). However, 71 of 117 healthy stocks also breached the threshold at some point (61% false positive rate), resulting in low specificity.

The optimal threshold identified by Youden's J was FMI = 2.63, achieving 74% sensitivity and 61% specificity.

### 3.2 Life history stratification

ROC analysis within life history categories revealed substantial variation in discriminatory performance (Table 2, Figure 2):

| Life history | *n* | Optimal threshold | Sensitivity | Specificity | AUC |
|--------------|-----|-------------------|-------------|-------------|-----|
| Long-lived (*M* < 0.2) | 104 | 4.91 | 78% | 71% | 0.794 |
| Medium (0.2–0.4) | 72 | 2.15 | 81% | 68% | 0.788 |
| Moderate (0.4–0.8) | 16 | 2.45 | 82% | 80% | 0.855 |
| Fast turnover (≥ 0.8) | 17 | 0.45 | 67% | 75% | 0.708 |

Optimal thresholds varied more than 10-fold across life histories, from 0.45 for fast-turnover species to 4.91 for long-lived species. This pattern was opposite to our initial hypothesis: we expected long-lived species to require more conservative (lower) thresholds due to slower recovery capacity, but the data indicated that long-lived species tolerated higher FMI values before collapse.

### 3.3 Comparison of approaches

Applying life-history-specific thresholds improved overall classification performance:

| Approach | Sensitivity | Specificity | PPV | Accuracy |
|----------|-------------|-------------|-----|----------|
| Universal (FMI = 1.25) | 89% | 39% | 54% | 61% |
| Stratified (optimal per category) | 76% | **69%** | **66%** | **72%** |
| **Improvement** | −13 pp | **+30 pp** | **+12 pp** | **+11 pp** |

Stratification traded modest sensitivity loss (−13 percentage points) for substantial specificity gains (+30 pp), reducing false alarms while maintaining acceptable detection rates.

### 3.4 Lead time

Among the 82 collapsed stocks with prior danger signals, 60 (73%) received the signal before collapse (prospective detection). Median lead time was 14 years (range: 1–80 years; mean: 19.9 years), providing a substantial window for management intervention.

---

## 4. Discussion

### 4.1 FMI as a screening tool

Our results support FMI as a high-sensitivity screening tool for fishing-driven stock decline. With 89% sensitivity at the universal threshold, FMI captures the vast majority of stocks that eventually collapse. However, the 39% specificity indicates that FMI functions more like a smoke detector than a precision diagnostic: it rarely misses true positives but frequently triggers for stocks that remain healthy.

This performance profile is appropriate for surveillance applications where the cost of missing a collapse exceeds the cost of false alarms. Fisheries managers can use FMI to identify stocks warranting closer scrutiny, with subsequent assessment confirming or ruling out genuine risk.

### 4.2 The life history threshold paradox

The most unexpected finding was the direction of threshold variation across life histories. We initially hypothesized that long-lived species, with slower population turnover and reduced recovery capacity, would require more conservative thresholds—that is, lower FMI values should trigger concern. This expectation aligns with Cope and Hamel (2015), who demonstrated empirical relationships between fishing mortality reference points and life history traits. Instead, optimal thresholds *increased* with longevity.

This paradox has a statistical explanation. Within long-lived species, many stocks have experienced FMI > 2 or even > 4 without collapsing. The high survival rate at elevated FMI means that discriminating thresholds must be correspondingly high to separate true positives from false positives. In contrast, fast-turnover species frequently collapse even at low FMI values (< 1.0), suggesting that fishing pressure is not the primary driver of their population dynamics.

### 4.3 Environmental drivers in fast-turnover species

The low optimal threshold (0.45) for fast-turnover species, combined with relatively weak AUC (0.708), suggests that FMI—a measure of fishing pressure—has limited predictive value for this life history category. This is consistent with extensive literature demonstrating environmental control of small pelagic populations, including the relationship between El Niño events and anchoveta collapse (Chavez et al., 2003), Pacific Decadal Oscillation effects on sardine (Jacobson & MacCall, 1995), and Kuroshio Current dynamics affecting Japanese anchovy (Watanabe et al., 1995).

FMI measures fishing-driven mortality. For species whose population dynamics are dominated by environmental variability, FMI should not be expected to predict collapse, and its failure to do so is not a methodological weakness but an appropriate null result. For small pelagic management, FMI should be interpreted in conjunction with environmental monitoring rather than as a standalone indicator.

### 4.4 Comparison with existing frameworks

The FMI framework complements rather than replaces existing reference point approaches. Unlike *F*~MSY~-based targets that require stock-specific estimation (ICES, 2022), FMI provides a rapid visual assessment requiring only *F* and *M* estimates. The log-log visualization enables cross-stock comparison that is difficult with traditional metrics. For data-limited situations where full stock assessments are unavailable, length-based approaches (Hordyk et al., 2015; Prince et al., 2015) and simple indicators (Froese, 2004) have proven valuable; FMI occupies a similar niche for stocks where *F* and *M* estimates exist but comprehensive assessment is lacking.

The Gulland threshold (*F* = *M*) appears in FMI as the central diagonal. Our validation confirms that this threshold retains diagnostic value, though life-history calibration improves discrimination. The 1.25 multiplier (FMI = 1.25 as danger threshold) corresponds to *E* = 0.56, modestly more permissive than the *E* = 0.5 Gulland threshold but within the range recommended by subsequent authors (Patterson, 1992). Melnychuk et al. (2016) demonstrated that management interventions improve stock status globally; FMI could serve as a rapid triage tool to identify stocks most urgently requiring such intervention.

### 4.5 Limitations

Several limitations warrant consideration. First, our collapse definition (*B*/*B*~MSY~ < 0.5) is one of several plausible thresholds. Alternative definitions (e.g., < 0.3, or multi-year duration requirements) would yield different sensitivity estimates. Second, natural mortality estimates are themselves uncertain and may be biased in the RAM Legacy database (Maunder et al., 2022). The relationship between *M* and body size (Lorenzen et al., 2022) and the empirical equations used to estimate *M* (Pauly, 1980) introduce additional uncertainty. The anomalously high *M* values for some stocks (e.g., *M* = 1.29 for Scotian Shelf cod) likely reflect estimation errors rather than true biological mortality. Third, our analysis is retrospective; prospective validation on independent data would strengthen confidence in the proposed thresholds. Recent work on empirical validation of stock assessment models (Kell et al., 2024) provides a methodological framework for such evaluation.

### 4.6 Future directions

The FMI framework assumes constant natural mortality. However, environmental stressors—including thermal anomalies, hypoxia, and upwelling variability—can elevate effective mortality beyond baseline *M* values. A logical extension would incorporate environmental indices to dynamically adjust FMI thresholds. During El Niño events or marine heatwaves, the sustainable exploitation zone would contract, signaling managers to reduce fishing pressure even if static FMI values appear acceptable. Development and validation of such a "Dynamic FMI" approach represents a priority for future research.

---

## 5. Conclusions

The Fishing Mortality Index provides a valid screening tool for fishing-driven stock decline, detecting prior danger signals in 89% of collapsed stocks with median lead time of 14 years. Life-history stratification substantially improves specificity (from 39% to 69%) without unacceptable sensitivity loss. Optimal thresholds vary more than 10-fold across life histories, from 0.45 for fast-turnover species to 4.91 for long-lived species. The unexpected direction of this variation—higher thresholds for longer-lived species—reflects the statistical distribution of outcomes rather than biological vulnerability, and the weak FMI performance for fast-turnover species is consistent with environmental rather than fishing control of their dynamics. We recommend that FMI be adopted as a rapid visual diagnostic for exploitation status, with life-history-specific threshold calibration for operational applications.

---

## Acknowledgments

We thank the RAM Legacy Stock Assessment Database team for maintaining and providing access to the global stock assessment repository.

---

## Data availability

The RAM Legacy Stock Assessment Database v4.64 is available at https://www.ramlegacy.org (DOI: 10.5281/zenodo.10499086). Analysis code is available at https://github.com/capraCoder/caprazliFMI and archived at Zenodo (DOI: 10.5281/zenodo.17844169).

---

## Declaration of competing interests

The author declares no competing interests.

---

## Funding

This research received no external funding.

---

## References

Chavez, F.P., Ryan, J., Lluch-Cota, S.E., Ñiquen, M., 2003. From anchovies to sardines and back: multidecadal change in the Pacific Ocean. Science 299, 217–221.

Cope, J.M., Hamel, O.S., 2015. Linking fishing mortality reference points to life history traits: an empirical meta-analytic approach. Can. J. Fish. Aquat. Sci. 72, 175–186. https://doi.org/10.1139/cjfas-2012-060

Froese, R., 2004. Keep it simple: three indicators to deal with overfishing. Fish Fish. 5, 86–91. https://doi.org/10.1111/j.1467-2979.2004.00144.x

Gulland, J.A., 1971. The Fish Resources of the Ocean. Fishing News Books, West Byfleet.

Hilborn, R., Walters, C.J., 1992. Quantitative Fisheries Stock Assessment: Choice, Dynamics and Uncertainty. Chapman and Hall, New York.

Hordyk, A., Prince, J., Babcock, C.R.P., 2015. A novel length-based empirical estimation method of spawning potential ratio (SPR), and tests of its performance, for small-scale, data-poor fisheries. ICES J. Mar. Sci. 72, 217–231. https://doi.org/10.1093/icesjms/fsu004

ICES, 2022. Workshop on ICES Reference Points (WKREF2). ICES Scientific Reports 4:63. https://doi.org/10.17895/ices.pub.19801467

Jacobson, L.D., MacCall, A.D., 1995. Stock-recruitment models for Pacific sardine (*Sardinops sagax*). Can. J. Fish. Aquat. Sci. 52, 566–577.

Kell, L.T., Mosqueira, I., Winker, H., Sharma, R., Kitakado, T., Cardinale, M., et al., 2024. Empirical validation of integrated stock assessment models to ensuring risk equivalence: a pathway to resilient fisheries management. PLOS ONE 19, e0302576. https://doi.org/10.1371/journal.pone.0302576

Lorenzen, K., Camp, E.V., Garlock, T.M., 2022. Natural mortality and body size in fish populations. Fish. Res. 252, 106327. https://doi.org/10.1016/j.fishres.2022.106327

Maunder, M.N., Punt, A.E., Hilborn, R., Hooten, M.B., Branch, T.A., Miranda, J., 2022. A review of estimation methods for natural mortality and implications for fisheries management. Fish. Res. 252, 106319. https://doi.org/10.1016/j.fishres.2021.106319

Melnychuk, M.C., Branch, T.A., Jensen, O.P., Sharma, R., et al., 2016. Fisheries management impacts on target species status. Proc. Natl. Acad. Sci. USA 113, 5085–5090. https://doi.org/10.1073/pnas.1520420113

Patterson, K., 1992. Fisheries for small pelagic species: an empirical approach to management targets. Rev. Fish Biol. Fish. 2, 321–338.

Pauly, D., 1980. On the interrelationships between natural mortality, growth parameters, and mean environmental temperature in 175 fish stocks. J. Cons. Int. Explor. Mer 39, 175–192. https://doi.org/10.1093/icesjms/39.2.175

Prince, J.D., Hordyk, A., Graham, N.A.J., Loneragan, N., et al., 2015. Length-based SPR assessment of eleven Indo-Pacific coral reef fish populations in Palau. Fish. Res. 171, 42–58. https://doi.org/10.1016/j.fishres.2015.06.008

RAM Legacy Stock Assessment Database, 2024. RAM Legacy Stock Assessment Database v4.64. Zenodo. https://doi.org/10.5281/zenodo.10499086

Ricard, D., Minto, C., Jensen, O.P., Baum, J.K., 2012. Examining the knowledge base and status of commercially exploited marine species with the RAM Legacy Stock Assessment Database. Fish Fish. 13, 380–398.

Robin, X., Turck, N., Hainard, A., Tiberti, N., Lisacek, F., Sanchez, J.C., Müller, M., 2011. pROC: an open-source package for R and S+ to analyze and compare ROC curves. BMC Bioinformatics 12, 77.

Watanabe, Y., Zenitani, H., Kimura, R., 1995. Population decline of the Japanese sardine *Sardinops melanostictus* owing to recruitment failures. Can. J. Fish. Aquat. Sci. 52, 1609–1616.

Zhou, S., Smith, A.D.M., Punt, A.E., Richardson, A.J., Gibbs, M., Fulton, E.A., Pascoe, S., Bulman, C., Bayliss, P., Sainsbury, K., 2010. Ecosystem-based fisheries management requires a change to the selective fishing philosophy. Proc. Natl. Acad. Sci. USA 107, 9485–9488.

---

## Figure Captions

**Figure 1.** The Fishing Mortality Index (FMI) framework. Fishing mortality (*F*) is plotted against natural mortality (*M*) on log-log axes. The solid diagonal line represents *F* = *M* (equivalent to exploitation fraction *E* = 0.5, the Gulland threshold). Dashed lines indicate *F*/*M* = 0.75 and *F*/*M* = 1.25. Zones are classified as Sustainable (*F*/*M* < 0.75), Fully Exploited (0.75 ≤ *F*/*M* ≤ 1.25), and Overexploited (*F*/*M* > 1.25). Example species are positioned to illustrate the life history gradient from long-lived (shark) to fast-turnover (anchovy).

**Figure 2.** Receiver operating characteristic (ROC) curves for FMI classification of stock collapse, stratified by life history category. AUC values range from 0.708 (fast turnover) to 0.855 (moderate turnover).

**Figure 3.** Optimal FMI thresholds by life history category with 95% confidence intervals. Thresholds increase from 0.45 for fast-turnover species to 4.91 for long-lived species.

**Figure 4.** Comparison of classification performance between universal threshold (FMI = 1.25) and life-history-stratified thresholds. Stratification improves specificity by 30 percentage points with modest sensitivity trade-off.

---

## Tables

**Table 1.** Diagnostic performance of FMI at universal threshold (1.25) for detecting stock collapse (*B*/*B*~MSY~ < 0.5).

**Table 2.** Life-history-stratified ROC analysis results showing optimal thresholds, sensitivity, specificity, and AUC by category.

**Table 3.** Proposed operational thresholds with exploitation fraction (*E*) equivalents.

| Life history | *M* range | Threshold | *E* equivalent |
|--------------|-----------|-----------|----------------|
| Long-lived | < 0.2 | 4.91 | 0.83 |
| Medium | 0.2–0.4 | 2.15 | 0.68 |
| Moderate | 0.4–0.8 | 2.45 | 0.71 |
| Fast turnover | ≥ 0.8 | 0.45 | 0.31 |

---

*Word count: ~2,950*

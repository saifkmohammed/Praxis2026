# uaim_full_results.R
# U-AIM synthetic data generation, model fitting, validation, scenario testing, 
# sensitivity analysis, and figures.
# Saif Mohammed | GWU Doctoral Praxis | GWU-ID: G41151297

# =============================================================
# 0. Package Setup
# =============================================================

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

packages <- c("car", "boot", "ggplot2", "dplyr", "psych", "openxlsx", "reshape2")
invisible(lapply(packages, install_if_missing))

library(car)
library(boot)
library(ggplot2)
library(dplyr)
library(psych)
library(openxlsx)
library(reshape2)

# ============================================================
# 1. Global Settings
# ============================================================

#set.seed(42) # For Data Tracking

N <- 10000
OUT_CSV <- "synthetic_u_aim.csv"
OUT_XLSX <- "u_aim_full_results.xlsx"
OUT_TXT <- "u_aim_results.txt"

FM_BASELINE <- 0.20
TR_BASELINE <- 0.20
FM_FULL <- 0.80
TR_FULL <- 0.90

# ============================================================
# 2. Helper Functions
# ============================================================

logistic <- function(x) {
  1 / (1 + exp(-x))
}

pct_change <- function(new_value, baseline_value) {
  ((new_value - baseline_value) / baseline_value) * 100
}

stars <- function(p) {
  ifelse(p < 0.001, "***",
         ifelse(p < 0.01, "**",
                ifelse(p < 0.05, "*", "")))
}

# ============================================================
# 3. Function: Generate Synthetic U-AIM Dataset
# Corresponding Chapter Section: 3.3.2 Synthetic Data Generation
# ============================================================

generate_uaim_data <- function(N = 10000, seed = NULL) {
  # set.seed(seed)

  PM <- rnorm(N, 0, 1)
  SZ <- rnorm(N, 0, 1)

  FM <- rbeta(N, 3, 2)

  TR_raw <- rlnorm(N, meanlog = 0.6, sdlog = 0.35)
  TR <- pmin(pmax(TR_raw, 0.05), 2.5)

  alpha0 <- 0.25
  alpha1 <- 0.40
  alpha2 <- 0.35
  alpha3 <- 0.55
  alpha4 <- 0.25
  epsA <- rnorm(N, 0, 0.35)

  AD <- logistic(alpha0 + alpha1 * FM + alpha2 * TR - alpha3 * PM + alpha4 * SZ + epsA)
  AD <- pmin(pmax(AD, 0), 0.99)

  b0 <- 0.60
  b1 <- 0.95
  b2 <- 0.20
  b3 <- 0.12
  b4 <- 0.10
  b5 <- 0.08
  eps1 <- rnorm(N, 0, 0.12)

  lambda <- exp(b0 + b1 * AD + b2 * FM + b3 * TR - b4 * PM + b5 * SZ + eps1)
  INN <- rpois(N, lambda)

  mu0 <- 1.05
  g1 <- 0.22
  g2 <- 0.12
  g3 <- 0.06
  g4 <- 0.08
  eps2 <- rnorm(N, 0, 0.10)

  DV <- mu0 - g1 * AD - g2 * FM - g3 * TR + g4 * PM + eps2
  DV <- pmax(DV, 0.05)

  d0 <- -1.55
  d1 <- 0.85
  d2 <- 0.45
  d3 <- 0.10
  eps3 <- rnorm(N, 0, 0.12)

  rw_mean <- exp(d0 - d1 * AD - d2 * TR + d3 * PM + eps3)
  shape_k <- 10.0
  scale_theta <- rw_mean / shape_k
  RW <- rgamma(N, shape = shape_k, scale = scale_theta)

  data.frame(FM = FM, TR = TR, PM = PM, SZ = SZ, AD = AD, INN = INN, DV = DV, RW = RW)
}

# ============================================================
# 4. Function: Descriptive Statistics
# Corresponding Chapter Section: 4.2 Descriptive Statistics
# ============================================================

descriptive_statistics <- function(df) {
  vars <- c("FM", "TR", "PM", "SZ", "AD", "INN", "DV", "RW")

  out <- data.frame(
    Variable = vars,
    N = sapply(df[vars], function(x) sum(!is.na(x))),
    Mean = sapply(df[vars], mean),
    SD = sapply(df[vars], sd),
    Min = sapply(df[vars], min),
    Q1 = sapply(df[vars], quantile, probs = 0.25),
    Median = sapply(df[vars], median),
    Q3 = sapply(df[vars], quantile, probs = 0.75),
    Max = sapply(df[vars], max),
    Skewness = psych::skew(df[vars]),
    Kurtosis = psych::kurtosi(df[vars])
  )

  rownames(out) <- NULL
  out
}

# ============================================================
# 5. Function: Correlation Matrix with P-Values
# Corresponding Chapter Section: 4.X Correlation Analysis / 3.8.2 Structure Validation
# ============================================================

correlation_with_pvalues <- function(df) {
  vars <- c("FM", "TR", "PM", "SZ", "AD", "INN", "DV", "RW")

  corr <- cor(df[vars], use = "pairwise.complete.obs")
  pmat <- matrix(NA, nrow = length(vars), ncol = length(vars))
  rownames(pmat) <- vars
  colnames(pmat) <- vars

  for (i in seq_along(vars)) {
    for (j in seq_along(vars)) {
      pmat[i, j] <- cor.test(df[[vars[i]]], df[[vars[j]]])$p.value
    }
  }

  corr_sig <- matrix("", nrow = length(vars), ncol = length(vars))
  rownames(corr_sig) <- vars
  colnames(corr_sig) <- vars

  for (i in seq_along(vars)) {
    for (j in seq_along(vars)) {
      corr_sig[i, j] <- paste0(sprintf("%.3f", corr[i, j]), stars(pmat[i, j]))
    }
  }

  list(correlation = corr, p_values = pmat, correlation_with_stars = corr_sig)
}

# ============================================================
# 6. Function: Fit Unified AI Integration Model
# Corresponding Chapter Section: 3.4 Unified Model Specification and 4.3 Regression Results
# ============================================================

fit_uaim_models <- function(df) {
  med <- lm(AD ~ FM + TR + PM + SZ, data = df)

  inn <- glm(INN ~ FM + TR + AD + PM + SZ,
             data = df,
             family = poisson(link = "log"))

  dv <- lm(DV ~ FM + TR + AD + PM + SZ, data = df)

  rw <- glm(RW ~ FM + TR + AD + PM + SZ,
            data = df,
            family = Gamma(link = "log"))

  list(med = med, inn = inn, dv = dv, rw = rw)
}

model_coefficients <- function(models) {
  extract_model <- function(model, model_name) {
    s <- summary(model)$coefficients
    out <- as.data.frame(s)
    out$Term <- rownames(out)
    out$Model <- model_name
    rownames(out) <- NULL
    out
  }

  bind_rows(
    extract_model(models$med, "AD Mediation Model: OLS"),
    extract_model(models$inn, "INN Outcome Model: Poisson"),
    extract_model(models$dv, "DV Outcome Model: OLS"),
    extract_model(models$rw, "RW Outcome Model: Gamma-log")
  )
}

model_fit_statistics <- function(models) {
  data.frame(
    Model = c("AD Mediation Model: OLS",
              "INN Outcome Model: Poisson",
              "DV Outcome Model: OLS",
              "RW Outcome Model: Gamma-log"),
    N = c(nobs(models$med), nobs(models$inn), nobs(models$dv), nobs(models$rw)),
    R2_or_PseudoR2 = c(summary(models$med)$r.squared,
                       NA,
                       summary(models$dv)$r.squared,
                       NA),
    AIC = c(AIC(models$med), AIC(models$inn), AIC(models$dv), AIC(models$rw)),
    BIC = c(BIC(models$med), BIC(models$inn), BIC(models$dv), BIC(models$rw))
  )
}

# ============================================================
# 7. Function: Scenario Prediction and Hypothesis Testing
# Corresponding Chapter Section: 4.4 Scenario Results / 4.5 Hypothesis Testing
# ============================================================

predict_scenario <- function(models, FM_val, TR_val, PM_val = 0, SZ_val = 0) {
  x <- data.frame(FM = FM_val, TR = TR_val, PM = PM_val, SZ = SZ_val)
  AD_hat <- as.numeric(predict(models$med, newdata = x))

  x2 <- data.frame(FM = FM_val, TR = TR_val, AD = AD_hat, PM = PM_val, SZ = SZ_val)

  INN_hat <- as.numeric(predict(models$inn, newdata = x2, type = "response"))
  DV_hat <- as.numeric(predict(models$dv, newdata = x2))
  RW_hat <- as.numeric(predict(models$rw, newdata = x2, type = "response"))

  data.frame(AD = AD_hat, INN = INN_hat, DV = DV_hat, RW = RW_hat)
}

scenario_results <- function(models) {
  scenario_inputs <- data.frame(
    Scenario = c("Baseline",
                 "Governance-Mature",
                 "Governance+Training",
                 "Full Integration"),
    FM = c(0.20, 0.80, 0.80, 0.80),
    TR = c(0.20, 0.20, 0.60, 0.90),
    PM = c(0, 0, 0, 0),
    SZ = c(0, 0, 0, 0)
  )

  preds <- do.call(rbind, lapply(1:nrow(scenario_inputs), function(i) {
    predict_scenario(models,
                     FM_val = scenario_inputs$FM[i],
                     TR_val = scenario_inputs$TR[i],
                     PM_val = scenario_inputs$PM[i],
                     SZ_val = scenario_inputs$SZ[i])
  }))

  out <- cbind(scenario_inputs, preds)

  out$Scenario <- factor(out$Scenario,
      levels = c("Baseline", "Governance-Mature", "Governance+Training",
                 "Full Integration")
  )
  base <- out[out$Scenario == "Baseline", ]

  out$INN_Pct_Change <- pct_change(out$INN, base$INN)
  out$DV_Pct_Change <- pct_change(out$DV, base$DV)
  out$RW_Pct_Change <- pct_change(out$RW, base$RW)

  out
}

hypothesis_tests <- function(scenarios) {
  full <- scenarios[scenarios$Scenario == "Full Integration", ]

  data.frame(
    Hypothesis = c("H1", "H2", "H3"),
    Metric = c("Innovation Output", "Delay Variance", "Rework Rate"),
    Threshold = c(">= 25% increase", ">= 10% reduction", ">= 15% reduction"),
    Observed_Percent_Change = c(full$INN_Pct_Change,
                                full$DV_Pct_Change,
                                full$RW_Pct_Change),
    Decision = c(ifelse(full$INN_Pct_Change >= 25, "PASS", "FAIL"),
                 ifelse(full$DV_Pct_Change <= -10, "PASS", "FAIL"),
                 ifelse(full$RW_Pct_Change <= -15, "PASS", "FAIL"))
  )
}

# ============================================================
# 8. Function: Validation Diagnostics
# Corresponding Chapter Section: 3.8 and 4 Model Validation
# ============================================================

compute_vif <- function(df) {
  vif_model <- lm(AD ~ FM + TR + PM + SZ, data = df)
  data.frame(Variable = names(car::vif(vif_model)),
             VIF = as.numeric(car::vif(vif_model)))
}

residual_diagnostics <- function(models) {
  data.frame(
    Model = c("AD", "DV"),
    Residual_Mean = c(mean(resid(models$med)), mean(resid(models$dv))),
    Residual_SD = c(sd(resid(models$med)), sd(resid(models$dv)))
  )
}

bootstrap_mediation_effect <- function(df, R = 1000) {
  boot_fun <- function(data, indices) {
    d <- data[indices, ]
    m1 <- lm(AD ~ FM + TR + PM + SZ, data = d)
    m2 <- glm(INN ~ FM + TR + AD + PM + SZ,
              data = d,
              family = poisson(link = "log"))

    a_FM <- coef(m1)["FM"]
    a_TR <- coef(m1)["TR"]
    b_AD <- coef(m2)["AD"]

    c(FM_indirect = a_FM * b_AD,
      TR_indirect = a_TR * b_AD)
  }

  b <- boot::boot(data = df, statistic = boot_fun, R = R)
  data.frame(
    Effect = c("FM -> AD -> INN", "TR -> AD -> INN"),
    Mean = colMeans(b$t),
    Lower_95 = apply(b$t, 2, quantile, probs = 0.025),
    Upper_95 = apply(b$t, 2, quantile, probs = 0.975)
  )
}

# ============================================================
# 9. Function: Sensitivity Analysis
# Corresponding Chapter Section: 4.X Sensitivity Analysis
# ============================================================

sensitivity_analysis <- function(models) {
  perturb <- c(-0.30, -0.20, -0.10, 0.00, 0.10, 0.20, 0.30)

  base <- predict_scenario(models, FM_val = 0.50, TR_val = 0.50)

  rows <- list()

  for (p in perturb) {
    FM_new <- 0.50 * (1 + p)
    TR_new <- 0.50

    pred <- predict_scenario(models, FM_val = FM_new, TR_val = TR_new)

    rows[[length(rows) + 1]] <- data.frame(
      Variable = "FM",
      Perturbation = p,
      AD = pred$AD,
      INN = pred$INN,
      DV = pred$DV,
      RW = pred$RW,
      AD_Change = pct_change(pred$AD, base$AD),
      INN_Change = pct_change(pred$INN, base$INN),
      DV_Change = pct_change(pred$DV, base$DV),
      RW_Change = pct_change(pred$RW, base$RW)
    )
  }

  for (p in perturb) {
    FM_new <- 0.50
    TR_new <- 0.50 * (1 + p)

    pred <- predict_scenario(models, FM_val = FM_new, TR_val = TR_new)

    rows[[length(rows) + 1]] <- data.frame(
      Variable = "TR",
      Perturbation = p,
      AD = pred$AD,
      INN = pred$INN,
      DV = pred$DV,
      RW = pred$RW,
      AD_Change = pct_change(pred$AD, base$AD),
      INN_Change = pct_change(pred$INN, base$INN),
      DV_Change = pct_change(pred$DV, base$DV),
      RW_Change = pct_change(pred$RW, base$RW)
    )
  }

  bind_rows(rows)
}

# ============================================================
# 10. Function: Generate Figures
# Corresponding Chapter Section: Chapter 4 Figures
# ============================================================

generate_figures <- function(df, scenarios, models) {
  ggsave("Figure_4_1_FM_Distribution.png",
         ggplot(df, aes(x = FM)) +
           geom_histogram(bins = 30) +
           labs(title = "Distribution of Framework Maturity",
                x = "Framework Maturity (FM)",
                y = "Frequency"),
         width = 9, height = 6, dpi = 300)

  ggsave("Figure_4_2_TR_Distribution.png",
         ggplot(df, aes(x = TR)) +
           geom_histogram(bins = 30) +
           labs(title = "Distribution of Training Investment",
                x = "Training Investment (TR)",
                y = "Frequency"),
         width = 9, height = 6, dpi = 300)
 
   ggsave("Figure_4_3_ DV_Distribution.png",
         ggplot(df, aes(x = DV)) +
           geom_histogram(bins = 30) +
           labs(title = "Distribution of DV",
                x = "Delay Variance (DV)",
                y = "Frequency"),
         width = 9, height = 6, dpi = 300)
   
   ggsave("Figure_4_2_RW_Distribution.png",
          ggplot(df, aes(x = RW)) +
            geom_histogram(bins = 30) +
            labs(title = "Distribution of RW",
                 x = "Rework Rate (RW)",
                 y = "Frequency"),
          width = 9, height = 6, dpi = 300)

  ggsave("Figure_4_3_Innovation_Output_by_Scenario.png",
         ggplot(scenarios, aes(x = Scenario, y = INN)) +
           geom_col() +
           labs(title = "Innovation Output by Scenario",
                x = "Scenario",
                y = "Innovation Output") +
           theme(axis.text.x = element_text(angle = 20, hjust = 1)),
         width = 9, height = 6, dpi = 300)

  ggsave("Figure_4_4_Delay_Variance_by_Scenario.png",
         ggplot(scenarios, aes(x = Scenario, y = DV)) +
           geom_col() +
           labs(title = "Delay Variance by Scenario",
                x = "Scenario",
                y = "Delay Variance") +
           theme(axis.text.x = element_text(angle = 20, hjust = 1)),
         width = 9, height = 6, dpi = 300)

  ggsave("Figure_4_5_Rework_Rate_by_Scenario.png",
         ggplot(scenarios, aes(x = Scenario, y = RW)) +
           geom_col() +
           labs(title = "Rework Rate by Scenario",
                x = "Scenario",
                y = "Rework Rate") +
           theme(axis.text.x = element_text(angle = 20, hjust = 1)),
         width = 9, height = 6, dpi = 300)

  fm_grid <- seq(min(df$FM), max(df$FM), length.out = 100)
  grid_fm <- data.frame(FM = fm_grid, TR = mean(df$TR), PM = 0, SZ = 0)
  grid_fm$AD <- as.numeric(predict(models$med, newdata = grid_fm))

  ggsave("Figure_4_6_AD_vs_FM.png",
         ggplot(grid_fm, aes(x = FM, y = AD)) +
           geom_line(linewidth = 1) +
           labs(title = "Adoption Intensity vs Framework Maturity",
                x = "Framework Maturity (FM)",
                y = "Adoption Intensity (AD)"),
         width = 9, height = 6, dpi = 300)

  tr_grid <- seq(min(df$TR), max(df$TR), length.out = 100)
  grid_tr <- data.frame(FM = mean(df$FM), TR = tr_grid, PM = 0, SZ = 0)
  grid_tr$AD <- as.numeric(predict(models$med, newdata = grid_tr))

  ggsave("Figure_4_7_AD_vs_TR.png",
         ggplot(grid_tr, aes(x = TR, y = AD)) +
           geom_line(linewidth = 1) +
           labs(title = "Adoption Intensity vs Training Investment",
                x = "Training Investment (TR)",
                y = "Adoption Intensity (AD)"),
         width = 9, height = 6, dpi = 300)
}

# ============================================================
# 11. Function: Write Results Workbook and Text Summary
# Corresponding Chapter Section: Complete Chapter 4 Outputs
# ============================================================

export_results <- function(df, desc, corr_obj, coef_tbl, fit_tbl, scenarios,
                           hyp_tbl, vif_tbl, resid_tbl, boot_tbl, sens_tbl) {

  wb <- createWorkbook()

  addWorksheet(wb, "DATA")
  writeData(wb, "DATA", df)

  addWorksheet(wb, "Descriptive Statistics")
  writeData(wb, "Descriptive Statistics", desc)

  addWorksheet(wb, "Correlation Matrix")
  writeData(wb, "Correlation Matrix", corr_obj$correlation)

  addWorksheet(wb, "P Values")
  writeData(wb, "P Values", corr_obj$p_values)

  addWorksheet(wb, "Correlation With Stars")
  writeData(wb, "Correlation With Stars", corr_obj$correlation_with_stars)

  addWorksheet(wb, "Regression Coefficients")
  writeData(wb, "Regression Coefficients", coef_tbl)

  addWorksheet(wb, "Model Fit")
  writeData(wb, "Model Fit", fit_tbl)

  addWorksheet(wb, "Scenario Results")
  writeData(wb, "Scenario Results", scenarios)

  addWorksheet(wb, "Hypothesis Tests")
  writeData(wb, "Hypothesis Tests", hyp_tbl)

  addWorksheet(wb, "VIF")
  writeData(wb, "VIF", vif_tbl)

  addWorksheet(wb, "Residual Diagnostics")
  writeData(wb, "Residual Diagnostics", resid_tbl)

  addWorksheet(wb, "Bootstrap Mediation")
  writeData(wb, "Bootstrap Mediation", boot_tbl)

  addWorksheet(wb, "Sensitivity Analysis")
  writeData(wb, "Sensitivity Analysis", sens_tbl)

  saveWorkbook(wb, OUT_XLSX, overwrite = TRUE)

  sink(OUT_TXT)
  cat("U-AIM Full Results Output\n")
  cat("=========================\n\n")

  cat("1. Descriptive Statistics\n")
  print(desc)

  cat("\n2. Correlation Matrix\n")
  print(round(corr_obj$correlation, 4))

  cat("\n3. Correlation Matrix with Significance Stars\n")
  print(corr_obj$correlation_with_stars)

  cat("\n4. Regression Coefficients\n")
  print(coef_tbl)

  cat("\n5. Model Fit\n")
  print(fit_tbl)

  cat("\n6. Scenario Results\n")
  print(scenarios)

  cat("\n7. Hypothesis Tests\n")
  print(hyp_tbl)

  cat("\n8. VIF Diagnostics\n")
  print(vif_tbl)

  cat("\n9. Residual Diagnostics\n")
  print(resid_tbl)

  cat("\n10. Bootstrap Mediation Effects\n")
  print(boot_tbl)

  cat("\n11. Sensitivity Analysis\n")
  print(sens_tbl)

  sink()
}

# ============================================================
# 12. Main Execution Function
# Corresponding Chapter Section: Complete Reproducible Workflow
# ============================================================

run_uaim_analysis <- function() {

  df <- generate_uaim_data(N = N, seed = 123)
  write.csv(df, OUT_CSV, row.names = FALSE)

  desc <- descriptive_statistics(df)
  corr_obj <- correlation_with_pvalues(df)
  models <- fit_uaim_models(df)

  coef_tbl <- model_coefficients(models)
  fit_tbl <- model_fit_statistics(models)
  scenarios <- scenario_results(models)
  hyp_tbl <- hypothesis_tests(scenarios)
  vif_tbl <- compute_vif(df)
  resid_tbl <- residual_diagnostics(models)
  boot_tbl <- bootstrap_mediation_effect(df, R = 1000)
  sens_tbl <- sensitivity_analysis(models)

  generate_figures(df, scenarios, models)

  export_results(df, desc, corr_obj, coef_tbl, fit_tbl, scenarios,
                 hyp_tbl, vif_tbl, resid_tbl, boot_tbl, sens_tbl)

  cat("\nU-AIM analysis completed successfully.\n")
  cat("Files generated:\n")
  cat("- ", OUT_CSV, "\n")
  cat("- ", OUT_XLSX, "\n")
  cat("- ", OUT_TXT, "\n")
  cat("- Figure_4_1_FM_Distribution.png\n")
  cat("- Figure_4_4_RW_Distribution.png\n")
  cat("- Figure_4_5_Innovation_Output_by_Scenario.png\n")
  cat("- Figure_4_6_Delay_Variance_by_Scenario.png\n")
  cat("- Figure_4_7_Rework_Rate_by_Scenario.png\n")
  cat("- Figure_4_8_AD_vs_FM.png\n")
  cat("- Figure_4_9_AD_vs_TR.png\n")

  invisible(list(
    data = df,
    descriptive = desc,
    correlation = corr_obj,
    models = models,
    coefficients = coef_tbl,
    model_fit = fit_tbl,
    scenarios = scenarios,
    hypotheses = hyp_tbl,
    vif = vif_tbl,
    residuals = resid_tbl,
    bootstrap = boot_tbl,
    sensitivity = sens_tbl
  ))
}

# Run full workflow
results <- run_uaim_analysis()


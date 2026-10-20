U-AIM analysis completed.
Calibration: Dataset A only; external validation: Dataset B only.
Models: INN Poisson; DV OLS; RW OLS. All use AII + FM + TR + PM + SZ.
30 independent multiple imputations in each split.
Bootstrap: 5000 per imputation = 150000 refits per model.
Five-fold CV across 30 imputations; outcome imputation before folds may make CV optimistic.
Use B observed-only validation as the primary independent validation result.
Poisson dispersion >1 suggests checking quasi-Poisson or negative binomial sensitivity.
Statistical association does not establish causation.
All results in UAIM_results.

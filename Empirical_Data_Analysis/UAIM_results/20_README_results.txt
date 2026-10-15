UAIM REPRODUCIBILITY REPORT
Input: /Users/saifalajmi/Downloads/Empirical_Seed_Data.csv 
Full n: 200 A n: 150 B n: 50 
Seed: 20261007; bootstrap: 5000 ; CV folds: 5 
Model families: INN Poisson log; DV OLS; RW OLS
No reverse-normalization; no synthetic or proxy reconstruction.
No causal inference; external validation means geographic externality only if proven.
Check Poisson overdispersion and influential observations before reporting.
  Outcome   N       AIC       BIC      RMSE       MAE R2_observed_vs_predicted Adjusted_R2 Dispersion
1     INN 150 1044.0034 1062.0672 9.1889048 6.5663927                0.9849331          NA   1.106098
2      DV 150  292.2013  313.2757 0.6116464 0.4611710                0.5699738   0.5550423         NA
3      RW 150  250.7555  271.8300 0.5327232 0.3853758                0.5326453   0.5164177         NA
  Outcome       RMSE       MAE        R2         Bias
1     INN 11.1750289 7.1707523 0.9777159 -0.282997055
2      DV  0.6446155 0.4912910 0.5223655  0.003667388
3      RW  0.5525558 0.3973435 0.4971994  0.002960822
  Outcome      RMSE       MAE        R2        Bias Observed_Mean Predicted_Mean
1     INN 9.8592027 7.1188689 0.9470793 -0.98444047     67.340000      66.355560
2      DV 0.7067293 0.5208946 0.5740941 -0.00601638     -1.903756      -1.909773
3      RW 0.5404588 0.4143268 0.5466570  0.02928788      2.223036       2.252324

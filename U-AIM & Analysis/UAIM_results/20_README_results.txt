UAIM REPRODUCIBILITY REPORT
Input: /Users/saifalajmi/Downloads/Empirical_Seed_Data.csv 
Full n: 200 A n: 150 B n: 50 
Seed: 20261007; bootstrap: 5000 ; CV folds: 5 
Model families: INN Poisson log; DV OLS; RW OLS
No reverse-normalization; no synthetic or proxy reconstruction.
No causal inference; external validation means geographic externality only if proven.
Check Poisson overdispersion and influential observations before reporting.
  Outcome   N       AIC       BIC       RMSE        MAE R2_observed_vs_predicted Adjusted_R2 Dispersion
1     INN 150 1044.0034 1062.0672 9.18890476 6.56639266                0.9849331          NA   1.106098
2      DV 150 -260.8274 -239.7530 0.09680758 0.07848421                0.9859388   0.9854506         NA
3      RW 150 -250.9791 -229.9047 0.10003828 0.08005019                0.9753847   0.9745300         NA
  Outcome       RMSE        MAE        R2          Bias
1     INN 11.1750289 7.17075226 0.9777159 -0.2829970546
2      DV  0.1003544 0.08059334 0.9848896  0.0021719778
3      RW  0.1031268 0.08313084 0.9738413  0.0005506676
  Outcome      RMSE        MAE        R2        Bias Observed_Mean Predicted_Mean
1     INN 9.8592027 7.11886890 0.9470793 -0.98444047     67.340000      66.355560
2      DV 0.1084180 0.08697059 0.9840136 -0.03811011     -1.855127      -1.893237
3      RW 0.1071983 0.08415058 0.9741287 -0.00946224      2.253982       2.244519

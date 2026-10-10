# BY: Saif Mohammed / GWU
# UAIM COMPLETE EMPIRICAL ANALYSIS — reproducible R script
# Input: original processed 200-observation dataset
# Dataset A: 150 calibration observations; Dataset B: 50 untouched validation observations
# Models: Poisson(log) INN; OLS DV; OLS RW. Associations, not causal estimates.
# For .xlsx input, install.packages('readxl') once.

args <- commandArgs(trailingOnly=TRUE)
input <- if (length(args)>=1) args[1] else {
  candidates <- c('Empirical_Seed_Data.csv', '~/Downloads/Empirical_Seed_Data.csv')
  found <- candidates[file.exists(path.expand(candidates))]
  if (!length(found)) stop('Cannot find Empirical_Seed_Data.csv; place it in Downloads or pass the file path.')
  path.expand(found[1])
}
outdir <- if (length(args)>=2) args[2] else file.path(dirname(normalizePath(input)), 'UAIM_results')
dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
set.seed(20261007)
B <- 5000L       # final thesis bootstrap replicates
K <- 5L
variables <- c('FM','TR','PM','AII','SZ','INN','DV','RW')
predictors <- c('FM','TR','PM','SZ','AII')

if (grepl('\\.xlsx$', input, ignore.case=TRUE)) {
  if (!requireNamespace('readxl', quietly=TRUE)) stop('Install readxl: install.packages("readxl")')
  d <- as.data.frame(readxl::read_excel(input, sheet=1))
} else d <- read.csv(input, check.names=FALSE, stringsAsFactors=FALSE)
required <- c('Obs_ID',variables,'Split_Group')
if (!all(required %in% names(d))) stop('Missing columns: ', paste(setdiff(required,names(d)),collapse=', '))
for (v in variables) d[[v]] <- as.numeric(d[[v]])
if (anyNA(d[,required])) stop('Missing values in required data; resolve before analysis.')
if (anyDuplicated(d$Obs_ID)) stop('Duplicate Obs_ID values.')
if (nrow(d)!=200L) stop('Expected 200 observations; found ',nrow(d))
a <- d[grepl('Dataset A',d$Split_Group,fixed=TRUE),,drop=FALSE]
b <- d[grepl('Dataset B',d$Split_Group,fixed=TRUE),,drop=FALSE]
if (nrow(a)!=150L || nrow(b)!=50L) stop('Expected A=150 and B=50; got ',nrow(a),', ',nrow(b))
if (any(d$INN < 0 | abs(d$INN-round(d$INN))>1e-8)) stop('INN must be nonnegative integer counts for Poisson GLM')
write.csv(d,file.path(outdir,'00_source_data_unchanged.csv'),row.names=FALSE)

savecsv <- function(x,name) write.csv(x,file.path(outdir,name),row.names=FALSE,na='')
summary_one <- function(x) {
  s <- sd(x); m <- mean(x); z <- if (s>0) (x-m)/s else rep(0,length(x))
  c(N=length(x),Mean=m,SD=s,Median=median(x),Min=min(x),Max=max(x),
    Skewness=mean(z^3),Excess_Kurtosis=mean(z^4)-3)
}
desc <- do.call(rbind,lapply(list(Full=d,A=a,B=b),function(z)
  do.call(rbind,lapply(variables,function(v) summary_one(z[[v]])))))
desc <- data.frame(Group=rep(c('Full','A','B'),each=length(variables)),
                   Variable=rep(variables,3),desc,row.names=NULL,check.names=FALSE)
savecsv(desc,'01_descriptive_statistics.csv')

# Dataset A/B comparability: Welch two-sample t tests (descriptive, not proof of equivalence)
comparison <- do.call(rbind,lapply(variables,function(v){
  t <- t.test(a[[v]],b[[v]])
  data.frame(Variable=v,Mean_A=mean(a[[v]]),Mean_B=mean(b[[v]]),
             Difference_A_minus_B=unname(diff(rev(t$estimate))),
             Welch_t=unname(t$statistic),df=unname(t$parameter),p_value=t$p.value,
             CI_low=t$conf.int[1],CI_high=t$conf.int[2])
}))
savecsv(comparison,'02_dataset_comparability_welch.csv')

# Pairwise Pearson correlations and p-values, calibration data only
cor_mat <- cor(a[,variables]); p_mat <- matrix(NA_real_,length(variables),length(variables),
                                          dimnames=list(variables,variables))
for(i in seq_along(variables)) for(j in seq_along(variables))
  p_mat[i,j] <- cor.test(a[[variables[i]]],a[[variables[j]]])$p.value
write.csv(cor_mat,file.path(outdir,'03_correlations_pearson_A.csv'))
write.csv(p_mat,file.path(outdir,'04_correlation_p_values_A.csv'))

forms <- list(INN=INN~FM+TR+PM+SZ+AII,DV=DV~FM+TR+PM+SZ+AII,
              RW=RW~FM+TR+PM+SZ+AII)
fit_model <- function(target,dat) {
  if(target=='INN') glm(forms[[target]],data=dat,family=poisson(link='log'))
  else lm(forms[[target]],data=dat)
}
fits <- lapply(names(forms),function(y) fit_model(y,a)); names(fits)<-names(forms)
writeLines(capture.output(lapply(fits,summary)),file.path(outdir,'05_full_model_summaries.txt'))

coefficient_table <- function(fit,target) {
  s <- summary(fit)$coefficients
  ci <- suppressMessages(confint.default(fit)) # Wald intervals; transparent and reproducible
  data.frame(Outcome=target,Term=rownames(s),Estimate=s[,1],Std_Error=s[,2],
             Statistic=s[,3],p_value=s[,4],CI95_Low=ci[,1],CI95_High=ci[,2],
             IRR=if(target=='INN') exp(s[,1]) else NA_real_,row.names=NULL)
}
coefs <- do.call(rbind,Map(coefficient_table,fits,names(fits)))
savecsv(coefs,'06_coefficients_CI_tests.csv')

#  coefficients values.
expected <- list(
 INN=c('(Intercept)'=.9152,FM=2.0725,TR=.4995,PM=.0827,SZ=.2024,AII=1.5492),
 DV=c('(Intercept)'=-.0193,FM=-.1621,TR=-.2634,PM=.3031,SZ=-.1112,AII=-2.4989),
 RW=c('(Intercept)'=2.9870,FM=-.5139,TR=.2962,PM=-.2948,SZ=-.0740,AII=-1.7724))
checks <- do.call(rbind,lapply(names(expected),function(y){
 actual <- coef(fits[[y]])[names(expected[[y]])]
 data.frame(Outcome=y,Term=names(actual),Estimated=unname(actual),
  Previously_Reported=unname(expected[[y]]),
  Rounded_4dp_Match=round(unname(actual),4)==unname(expected[[y]]),
  Absolute_Difference=abs(unname(actual)-unname(expected[[y]])))
}))
savecsv(checks,'06b_published_coefficient_reconciliation.csv')
if(!all(checks$Rounded_4dp_Match)) warning('Some coefficients differ from previously rounded values; inspect reconciliation table.')


# Diagnostics and model fit
model_fit <- do.call(rbind,lapply(names(fits),function(y){
 f<-fits[[y]]; obs<-a[[y]]; pred<-as.numeric(predict(f,type='response'))
 resid<-obs-pred
 s<-summary(f)
 data.frame(Outcome=y,N=length(obs),AIC=AIC(f),BIC=BIC(f),
  RMSE=sqrt(mean(resid^2)),MAE=mean(abs(resid)),
  R2_observed_vs_predicted=1-sum(resid^2)/sum((obs-mean(obs))^2),
  Adjusted_R2=if(!inherits(f,'glm')) unname(s$adj.r.squared) else NA_real_,
  Dispersion=if(inherits(f,'glm')) sum(residuals(f,type='pearson')^2)/df.residual(f) else NA_real_)
}))
savecsv(model_fit,'07_model_fit_A.csv')

# HC3 robust SE if sandwich installed (optional)
if(requireNamespace('sandwich',quietly=TRUE) && requireNamespace('lmtest',quietly=TRUE)) {
 robust<-do.call(rbind,lapply(names(fits),function(y){
  tab<-lmtest::coeftest(fits[[y]],vcov.=sandwich::vcovHC(fits[[y]],type='HC3'))
  data.frame(Outcome=y,Term=rownames(tab),Estimate=tab[,1],HC3_SE=tab[,2],
             HC3_Statistic=tab[,3],HC3_p=tab[,4],row.names=NULL)
 }))
 savecsv(robust,'08_HC3_robust_coefficient_tests.csv')
}

# Diagnostics: residual vs fitted, QQ, scale-location, influence, leverage, VIF
pdf(file.path(outdir,'09_regression_diagnostics.pdf'),width=10,height=8,onefile=TRUE)
for(y in names(fits)) {
 f<-fits[[y]]
 par(mfrow=c(2,2),mar=c(4,4,3,1))
 if(!inherits(f,'glm')) {
   plot(f,which=1:4)
 } else {
   r<-residuals(f,type='deviance'); p<-fitted(f)
   plot(p,r,pch=19,cex=.55,xlab='Fitted INN count',ylab='Deviance residual',main='INN residual vs fitted');abline(h=0,lty=2)
   qqnorm(r,main='INN deviance residual QQ');qqline(r)
   plot(p,sqrt(abs(r)),pch=19,cex=.55,xlab='Fitted',ylab='Sqrt abs deviance residual',main='Scale-location')
   plot(cooks.distance(f),type='h',ylab='Cook distance',main='INN influence')
 }
}
dev.off()

vif_manual <- function(dat) {
 x<-dat[,predictors,drop=FALSE]
 sapply(predictors,function(v){others<-setdiff(predictors,v);1/(1-summary(lm(reformulate(others,v),data=x))$r.squared)})
}
savecsv(data.frame(Term=names(vif_manual(a)),VIF=as.numeric(vif_manual(a))),
        '10_VIF_A.csv')

# Bootstrap: resample Dataset A firms, re-estimate all model coefficients
# Percentile 95% CI. No Dataset B observations used for fitting or bootstrap.
boot_rows<-list(); boot_summary<-list()
for(y in names(fits)) {
  term_names<-names(coef(fits[[y]])); mat<-matrix(NA_real_,B,length(term_names),dimnames=list(NULL,term_names))
  for(i in seq_len(B)) {
    idx<-sample.int(nrow(a),nrow(a),replace=TRUE)
    f<-tryCatch(suppressWarnings(fit_model(y,a[idx,,drop=FALSE])),error=function(e)NULL)
    if(!is.null(f)) mat[i,]<-coef(f)[term_names]
  }
  for(term in term_names) {
    x<-mat[,term]; x<-x[is.finite(x)]
    boot_summary[[length(boot_summary)+1]]<-data.frame(Outcome=y,Term=term,
      Original_Estimate=unname(coef(fits[[y]])[term]),Bootstrap_Valid=length(x),
      Bootstrap_Mean=mean(x),Bootstrap_SE=sd(x),
      Percentile_CI_Low=unname(quantile(x,.025)),
      Percentile_CI_High=unname(quantile(x,.975)))
  }
}
savecsv(do.call(rbind,boot_summary),'11_bootstrap_5000_A.csv')

# Repeated? No: one reproducible five-fold CV on Dataset A; pooled out-of-fold predictions.
set.seed(20261007)
fold_id<-sample(rep(seq_len(K),length.out=nrow(a)))
cv<-list()
for(y in names(fits)) {
 p<-rep(NA_real_,nrow(a))
 for(k in seq_len(K)) {
   train<-a[fold_id!=k,,drop=FALSE]; test<-a[fold_id==k,,drop=FALSE]
   f<-fit_model(y,train)
   p[fold_id==k]<-as.numeric(predict(f,newdata=test,type='response'))
 }
 cv[[y]]<-data.frame(Obs_ID=a$Obs_ID,Outcome=y,Fold=fold_id,
                      Observed=a[[y]],Predicted=p,Residual=a[[y]]-p)
}
cvpred<-do.call(rbind,cv);savecsv(cvpred,'12_fivefold_out_of_fold_predictions_A.csv')
metrics <- function(obs,pred) c(RMSE=sqrt(mean((obs-pred)^2)),MAE=mean(abs(obs-pred)),
 R2=1-sum((obs-pred)^2)/sum((obs-mean(obs))^2),Bias=mean(pred-obs))
cvmetrics<-do.call(rbind,lapply(names(cv),function(y)
 data.frame(Outcome=y,t(metrics(cv[[y]]$Observed,cv[[y]]$Predicted)))))
savecsv(cvmetrics,'13_fivefold_CV_metrics_A.csv')

# Strict holdout: predict Dataset B from full Dataset A fitted models, no refitting.
holdout<-do.call(rbind,lapply(names(fits),function(y){
 p<-as.numeric(predict(fits[[y]],newdata=b,type='response'))
 data.frame(Obs_ID=b$Obs_ID,Outcome=y,Observed=b[[y]],Predicted=p,
            Residual=b[[y]]-p)
}))
savecsv(holdout,'14_holdout_predictions_B.csv')
holdmetrics<-do.call(rbind,lapply(names(fits),function(y){
 x<-holdout[holdout$Outcome==y,]
 data.frame(Outcome=y,t(metrics(x$Observed,x$Predicted)),
            Observed_Mean=mean(x$Observed),Predicted_Mean=mean(x$Predicted))
}))
savecsv(holdmetrics,'15_holdout_validation_metrics_B.csv')

# Predictor effect sizes: OLS partial Cohen f2; GLM LR chi-square & deviance reduction.
effects<-do.call(rbind,lapply(names(fits),function(y){
 full<-fits[[y]]
 do.call(rbind,lapply(predictors,function(v){
  # Refit explicitly on calibration data: update(full) can lose local 'dat'
  # captured in fit_model(), causing object 'dat' not found.
  reduced_formula <- reformulate(setdiff(predictors, v), response=y)
  reduced <- if(y=='INN') glm(reduced_formula, data=a, family=poisson(link='log')) else lm(reduced_formula, data=a)
  if(y=='INN') {
    delta<-deviance(reduced)-deviance(full)
    data.frame(Outcome=y,Predictor=v,Effect_Type='LR chi-square',Effect=delta,
               p_value=pchisq(delta,df=1,lower.tail=FALSE))
  } else {
    r2f<-summary(full)$r.squared;r2r<-summary(reduced)$r.squared
    f2<-(r2f-r2r)/(1-r2f)
    p<-anova(reduced,full)$`Pr(>F)`[2]
    data.frame(Outcome=y,Predictor=v,Effect_Type='Partial Cohen f2',Effect=f2,p_value=p)
  }
 }))
}))
savecsv(effects,'16_partial_effect_sizes.csv')

# Exploratory governance-by-complexity moderation; do not label confirmatory unless prespecified.
interaction_fits<-lapply(names(fits),function(y){
 formula<-as.formula(paste(y,'~ FM + TR + PM + SZ + AII + FM:PM'))
 if(y=='INN') glm(formula,data=a,family=poisson(link='log')) else lm(formula,data=a)
});names(interaction_fits)<-names(fits)
interaction_results<-do.call(rbind,lapply(names(fits),function(y){
 f<-interaction_fits[[y]];tab<-summary(f)$coefficients
 data.frame(Outcome=y,Interaction='FM:PM',Estimate=tab['FM:PM',1],SE=tab['FM:PM',2],
            p_value=tab['FM:PM',4],AIC_base=AIC(fits[[y]]),AIC_interaction=AIC(f))
}))
savecsv(interaction_results,'17_exploratory_FM_PM_interactions.csv')

# UAIM decision-support: illustrative inputs set to Dataset A 25th/50th/75th quantiles.
# All other covariates held at Dataset A medians. Associations only; not causal scenarios.
base<-as.data.frame(as.list(sapply(a[,predictors,drop=FALSE],median)))
scenarios<-do.call(rbind,lapply(predictors,function(v){
 do.call(rbind,lapply(c(.25,.5,.75),function(q){
   row<-base;row[[v]]<-unname(quantile(a[[v]],q))
   row$Varied_Input<-v;row$Quantile<-q;row
 }))
}))
for(y in names(fits)) scenarios[[paste0('Predicted_',y)]]<-
 as.numeric(predict(fits[[y]],newdata=scenarios,type='response'))
savecsv(scenarios,'18_UAIM_decision_support_scenarios.csv')

# Visualizations, calibration only
pdf(file.path(outdir,'19_distributions_and_correlations_A.pdf'),width=10,height=8,onefile=TRUE)
par(mfrow=c(2,2))
for(v in variables) {
 hist(a[[v]],freq=FALSE,breaks='FD',col='grey85',border='white',main=paste(v,'Dataset A (n=150)'),xlab=v)
 if(sd(a[[v]])>0) lines(density(a[[v]]),lwd=2)
 abline(v=mean(a[[v]]),lty=2,lwd=2)
}
par(mfrow=c(1,1));image(seq_along(variables),seq_along(variables),cor_mat,
 xlab='',ylab='',axes=FALSE,main='Pearson correlations — Dataset A',zlim=c(-1,1),
 col=colorRampPalette(c('navy','white','firebrick'))(101))
axis(1,at=seq_along(variables),labels=variables)
axis(2,at=seq_along(variables),labels=variables)
dev.off()

# Audit trail and safeguards
capture.output({
 cat('UAIM REPRODUCIBILITY REPORT\n')
 cat('Input:',normalizePath(input),'\n')
 cat('Full n:',nrow(d),'A n:',nrow(a),'B n:',nrow(b),'\n')
 cat('Seed: 20261007; bootstrap:',B,'; CV folds:',K,'\n')
 cat('Model families: INN Poisson log; DV OLS; RW OLS\n')
 cat('No reverse-normalization; no synthetic or proxy reconstruction.\n')
 cat('No causal inference; external validation means geographic externality only if proven.\n')
 cat('Check Poisson overdispersion and influential observations before reporting.\n')
 print(model_fit);print(cvmetrics);print(holdmetrics)
},file=file.path(outdir,'20_README_results.txt'))
cat('Finished. Results written to:',normalizePath(outdir),'\n')

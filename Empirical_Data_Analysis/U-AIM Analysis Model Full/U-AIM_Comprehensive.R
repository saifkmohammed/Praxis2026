# Saif Mohammed
# GWU
# U-AIM | Comprehensive empirical estimation and independent validation
# Input: empirical_data.csv (or choose the file interactively)
# Models: INN Poisson GLM; DV and RW OLS; each with AII, FM, TR, PM, SZ.
# Dataset A: calibration. Dataset B: external validation only.
# No data values are changed except missing DV/RW filled in completed imputation copies.

options(stringsAsFactors=FALSE)
set.seed(20261019)
packages <- c('mice','ggplot2','lmtest','sandwich','car')
for (p in packages) if (!requireNamespace(p,quietly=TRUE)) install.packages(p,repos='https://cloud.r-project.org')
suppressPackageStartupMessages(library(mice))
suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(trailingOnly=TRUE)
input <- if(length(args)>0 && file.exists(args[1])) args[1] else if(file.exists('empirical_data.csv')) 'empirical_data.csv' else if(file.exists('empirical_data(2).csv')) 'empirical_data(2).csv' else file.choose()
d <- read.csv(input,check.names=FALSE)
required <- c('Obs_ID','Split_Group','FM','TR','PM','AII','SZ','INN','DV','RW')
if(!all(required %in% names(d))) stop('Missing columns: ',paste(setdiff(required,names(d)),collapse=', '))
if(anyDuplicated(d$Obs_ID)) stop('Obs_ID must be unique.')
num <- c('FM','TR','PM','AII','SZ','INN','DV','RW')
for(v in num) { d[[v]] <- suppressWarnings(as.numeric(d[[v]])); if(any(!is.finite(d[[v]]) & !is.na(d[[v]]))) stop('Nonfinite value in ',v) }
if(anyNA(d[c('Obs_ID','Split_Group','FM','TR','PM','AII','SZ','INN')])) stop('Missing IDs, split labels, predictors, or INN: review dataset.')
if(any(d$INN < 0 | abs(d$INN-round(d$INN))>1e-8)) stop('INN must be nonnegative integer counts for Poisson GLM.')
A <- d[d$Split_Group=='Dataset A (Calibrate)',,drop=FALSE]
B <- d[d$Split_Group=='Dataset B (Validate)',,drop=FALSE]
if(nrow(A)<10 || nrow(B)<10 || nrow(A)+nrow(B)!=nrow(d)) stop('Unexpected split labels or insufficient sample sizes.')
if(nrow(A)!=150 || nrow(B)!=50) warning('Expected A=150, B=50; found A=',nrow(A),', B=',nrow(B))
output <- 'UAIM_results';dir.create(output,showWarnings=FALSE,recursive=TRUE)
write.csv(data.frame(dataset=c('A','B'),n=c(nrow(A),nrow(B)),missing_DV=c(sum(is.na(A$DV)),sum(is.na(B$DV))),missing_RW=c(sum(is.na(A$RW)),sum(is.na(B$RW)))),file.path(output,'01_data_audit.csv'),row.names=FALSE)
write.csv(d,file.path(output,'original_data_unmodified.csv'),row.names=FALSE)
write.csv(data.frame(variable=num,missing=sapply(d[num],function(x) sum(is.na(x))),mean_observed=sapply(d[num],function(x) mean(x,na.rm=TRUE)),sd_observed=sapply(d[num],function(x) sd(x,na.rm=TRUE))),file.path(output,'02_descriptive_observed.csv'),row.names=FALSE)

# Independently impute each dataset to prevent information leakage.
# PMM preserves observed DV/RW values; observed predictors and INN are never imputed.
impvars <- c('FM','TR','PM','AII','SZ','INN','DV','RW')
make_mi <- function(x,seed) {
  z <- x[,impvars,drop=FALSE]
  meth <- mice::make.method(z);meth[] <- ''
  for(v in c('DV','RW')) if(anyNA(z[[v]])) meth[v] <- 'pmm'
  pred <- mice::make.predictorMatrix(z);diag(pred)<-0
  if(all(meth=='')) {
    # MICE can still create 30 identical complete data sets when no missingness.
    return(replicate(30,z,simplify=FALSE))
  }
  mi <- mice::mice(z,m=30,maxit=20,method=meth,predictorMatrix=pred,seed=seed,printFlag=FALSE)
  saveRDS(mi,file.path(output,paste0('mice_',seed,'.rds')))
  saveRDS(list(chainMean=mi$chainMean,chainVar=mi$chainVar),file.path(output,paste0('mice_chains_',seed,'.rds')))
  lapply(seq_len(30),function(i) mice::complete(mi,i))
}
cat('Imputing A and B independently (30 data sets each)...\n')
Ai <- make_mi(A,20261019);Bi <- make_mi(B,20261020)
for(i in seq_len(30)) {
  write.csv(cbind(A[,c('Obs_ID','Split_Group')],Ai[[i]]),file.path(output,sprintf('completed_A_%02d.csv',i)),row.names=FALSE)
  write.csv(cbind(B[,c('Obs_ID','Split_Group')],Bi[[i]]),file.path(output,sprintf('completed_B_%02d.csv',i)),row.names=FALSE)
}

forms <- list(INN=INN~AII+FM+TR+PM+SZ,DV=DV~AII+FM+TR+PM+SZ,RW=RW~AII+FM+TR+PM+SZ)
fit <- function(nm,dat) if(nm=='INN') glm(forms[[nm]],family=poisson(link='log'),data=dat) else lm(forms[[nm]],data=dat)
getp <- function(f,dat) as.numeric(predict(f,newdata=dat,type='response'))
fits <- lapply(names(forms),function(nm) lapply(Ai,function(z) fit(nm,z)));names(fits)<-names(forms)

# Rubin's rules for each coefficient: pooled beta, total SE, t/FMI and 95% CI.
# mice::pool() uses residual df from each fitted model.
pooled <- do.call(rbind,lapply(names(forms),function(nm) {
  p <- summary(mice::pool(mice::as.mira(fits[[nm]])),conf.int=TRUE,conf.level=.95)
  p$model <- nm;p
}))
write.csv(pooled,file.path(output,'03_pooled_coefficients_hypothesis_tests.csv'),row.names=FALSE)
# Model-level pooled Wald test of all slopes jointly.
joint <- do.call(rbind,lapply(names(forms),function(nm){
  f <- fits[[nm]]
  full <- mice::as.mira(f)
  reduced <- mice::as.mira(lapply(Ai,function(z) if(nm=='INN') glm(INN~1,data=z,family=poisson()) else lm(reformulate('1',response=nm),data=z)))
  # mice::D1() returns a mira test object, not necessarily a 2-D table.
  # Extract from its documented test data.frame rather than x[1, "statistic"].
  x <- tryCatch(mice::D1(full,reduced),error=function(e) e)
  if(inherits(x,'error')) {
    return(data.frame(model=nm,statistic=NA_real_,p_value=NA_real_,
                      note=paste('D1 unavailable:',conditionMessage(x))))
  }
  tab <- tryCatch({
    if(is.list(x) && is.data.frame(x$result)) x$result
    else if(is.list(x) && is.data.frame(x$test)) x$test
    else as.data.frame(x)
  },error=function(e) NULL)
  if(is.null(tab) || nrow(tab)==0L) {
    return(data.frame(model=nm,statistic=NA_real_,p_value=NA_real_,
                      note='D1 returned no tabular result'))
  }
  # D1 commonly names its statistic "F value" and p-value "Pr(>F)".
  stat_col <- intersect(c('F value','F.value','statistic','F','Fstat'),names(tab))
  p_col <- intersect(c('Pr(>F)','Pr..F.','p.value','p_value','p'),names(tab))
  stat <- if(length(stat_col)) suppressWarnings(as.numeric(tab[[stat_col[1]]][1])) else NA_real_
  pv <- if(length(p_col)) suppressWarnings(as.numeric(tab[[p_col[1]]][1])) else NA_real_
  data.frame(model=nm,statistic=stat,p_value=pv,
             note=if(is.na(pv)) paste('Inspect D1 columns:',paste(names(tab),collapse=', '))
                  else 'Pooled multivariate Wald test')
}))
write.csv(joint,file.path(output,'04_joint_hypothesis_tests.csv'),row.names=FALSE)

# In-sample fit metrics and diagnostics (30 imputed calibration fits).
metrics <- function(nm,y,p) {
  if(nm=='INN') {
    dev <- 2*mean(ifelse(y==0,p,y*log(pmax(y,1e-12)/pmax(p,1e-12))-y+p))
    return(c(MAE=mean(abs(y-p)),RMSE=sqrt(mean((y-p)^2)),R2=1-sum((y-p)^2)/sum((y-mean(y))^2),Poisson_deviance=dev))
  }
  c(MAE=mean(abs(y-p)),RMSE=sqrt(mean((y-p)^2)),R2=1-sum((y-p)^2)/sum((y-mean(y))^2),Poisson_deviance=NA_real_)
}
insample <- list();diagnostics <- list()
for(nm in names(forms)) for(i in 1:30) {
  z<-Ai[[i]];f<-fits[[nm]][[i]];p<-getp(f,z)
  insample[[length(insample)+1]]<-data.frame(model=nm,imputation=i,t(metrics(nm,z[[nm]],p)),AIC=AIC(f),BIC=BIC(f))
  if(nm=='INN') {
    diagnostics[[length(diagnostics)+1]]<-data.frame(model=nm,imputation=i,dispersion=sum(residuals(f,type='pearson')^2)/df.residual(f),BP_p=NA_real_,Shapiro_p=NA_real_,max_VIF=max(car::vif(f)))
  } else {
    diagnostics[[length(diagnostics)+1]]<-data.frame(model=nm,imputation=i,dispersion=NA_real_,BP_p=tryCatch(lmtest::bptest(f)$p.value,error=function(e) NA_real_),Shapiro_p=tryCatch(shapiro.test(residuals(f))$p.value,error=function(e) NA_real_),max_VIF=max(car::vif(f)))
  }
}
write.csv(do.call(rbind,insample),file.path(output,'05_in_sample_metrics.csv'),row.names=FALSE)
write.csv(do.call(rbind,diagnostics),file.path(output,'06_model_diagnostics.csv'),row.names=FALSE)

# 5000 nonparametric bootstrap resamples on EACH of the 30 completed A datasets.
# For transparent reporting, bootstrap percentile intervals summarize all 150,000 fits/model.
# Note: this is MI-then-bootstrap, not bootstrap-then-MI; Rubin inference remains primary.
NBOOT <- 5000
boot_summary <- list();set.seed(20261021)
for(nm in names(forms)) {
  terms <- names(coef(fits[[nm]][[1]]))
  bmat <- matrix(NA_real_,nrow=30*NBOOT,ncol=length(terms),dimnames=list(NULL,terms))
  for(i in 1:30) {
    z <- Ai[[i]]
    for(b in seq_len(NBOOT)) {
      idx<-sample.int(nrow(z),nrow(z),replace=TRUE)
      cc<-tryCatch(coef(fit(nm,z[idx,,drop=FALSE])),error=function(e) NULL)
      if(!is.null(cc) && all(terms %in% names(cc))) bmat[(i-1)*NBOOT+b,]<-cc[terms]
    }
  }
  saveRDS(bmat,file.path(output,paste0('bootstrap_',nm,'_150000_coefficients.rds')))
  for(t in terms) {
    v<-bmat[,t];v<-v[is.finite(v)]
    boot_summary[[length(boot_summary)+1]]<-data.frame(model=nm,term=t,valid_fits=length(v),boot_mean=mean(v),boot_sd=sd(v),CI_low=unname(quantile(v,.025)),CI_high=unname(quantile(v,.975)))
  }
  cat('Bootstrap completed:',nm,'\n')
}
write.csv(do.call(rbind,boot_summary),file.path(output,'07_bootstrap_5000_per_imputation.csv'),row.names=FALSE)

# Five-fold CV repeated across all 30 imputations; identical folds per imputation.
# No external B observations used to fit any model.
set.seed(20261022)
fold <- sample(rep(1:5,length.out=nrow(A)))
cv <- list()
for(nm in names(forms)) for(i in 1:30) for(k in 1:5) {
  z<-Ai[[i]];tr<-z[fold!=k,,drop=FALSE];te<-z[fold==k,,drop=FALSE]
  f<-fit(nm,tr);p<-getp(f,te)
  cv[[length(cv)+1]]<-data.frame(model=nm,imputation=i,fold=k,n_train=nrow(tr),n_test=nrow(te),t(metrics(nm,te[[nm]],p)))
}
write.csv(do.call(rbind,cv),file.path(output,'08_five_fold_cross_validation.csv'),row.names=FALSE)
# Caveat: imputation occurs before CV folds; predictive CV may be optimistic because
# imputation of missing outcomes uses other A rows. For strict CV, refit imputation
# within each training fold and apply training-fitted imputation to test rows.

# External validation B: A-only trained model, B separately imputed without A outcome data.
external <- list()
for(nm in names(forms)) for(i in 1:30) {
  z<-Bi[[i]];p<-getp(fits[[nm]][[i]],z)
  external[[length(external)+1]]<-data.frame(model=nm,imputation=i,n=nrow(z),t(metrics(nm,z[[nm]],p)))
  if(i==1) write.csv(data.frame(Obs_ID=B$Obs_ID,observed_or_imputed=z[[nm]],prediction=p,originally_missing=is.na(B[[nm]])),file.path(output,paste0('external_predictions_',nm,'.csv')),row.names=FALSE)
}
write.csv(do.call(rbind,external),file.path(output,'09_external_validation_B.csv'),row.names=FALSE)
# Also report strictly observed-only B outcomes as primary validation evidence.
external_observed <- list()
for(nm in names(forms)) for(i in 1:30) {
  keep<-which(!is.na(B[[nm]]));z<-Bi[[i]][keep,,drop=FALSE]
  external_observed[[length(external_observed)+1]]<-data.frame(model=nm,imputation=i,n_observed=length(keep),t(metrics(nm,z[[nm]],getp(fits[[nm]][[i]],z))))
}
write.csv(do.call(rbind,external_observed),file.path(output,'10_external_validation_B_observed_only.csv'),row.names=FALSE)

# Scenarios use observed calibration medians; vary one variable at a time.
# Scenario shifts are exploratory associations, NOT causal impacts or forecasts.
base <- as.data.frame(as.list(sapply(A[c('AII','FM','TR','PM','SZ')],median,na.rm=TRUE)))
scenarios <- list(baseline=base)
for(v in names(base)) for(change in c(-.2,-.1,.1,.2)) {
  q<-base;q[[v]]<-base[[v]]*(1+change)
  scenarios[[paste0(v,'_',ifelse(change>0,'plus','minus'),abs(change)*100,'pct')]]<-q
}
scenario_rows <- list()
for(nm in names(forms)) for(s in names(scenarios)) {
  preds<-sapply(1:30,function(i) getp(fits[[nm]][[i]],scenarios[[s]]))
  scenario_rows[[length(scenario_rows)+1]]<-data.frame(model=nm,scenario=s,estimate=mean(preds),imputation_low=unname(quantile(preds,.025)),imputation_high=unname(quantile(preds,.975)))
}
write.csv(do.call(rbind,scenario_rows),file.path(output,'11_scenario_analysis.csv'),row.names=FALSE)

# Correlation matrix of predictors and outcomes, averaged over imputations (descriptive).
corvars<-c('AII','FM','TR','PM','SZ','INN','DV','RW')
cor_mean<-Reduce('+',lapply(Ai,function(z) cor(z[corvars])))/30
write.csv(cor_mean,file.path(output,'12_correlation_matrix_A.csv'))
# Visual model diagnostics (first imputation; full numeric diagnostics across all 30 above).
for(nm in names(forms)) {
  f<-fits[[nm]][[1]]
  png(file.path(output,paste0('diagnostics_',nm,'.png')),width=1100,height=850,res=130)
  par(mfrow=c(2,2))
  if(nm=='INN') {
    plot(fitted(f),residuals(f,type='pearson'),xlab='Fitted counts',ylab='Pearson residuals',main='Poisson residuals');abline(h=0,lty=2)
    qqnorm(residuals(f,type='deviance'));qqline(residuals(f,type='deviance'))
    plot(fitted(f),Ai[[1]][[nm]],xlab='Predicted',ylab='Observed',main='Calibration');abline(0,1,lty=2)
    plot(cooks.distance(f),type='h',main='Cook distance')
  } else plot(f)
  dev.off()
}
writeLines(c('U-AIM analysis completed.','Calibration: Dataset A only; external validation: Dataset B only.','Models: INN Poisson; DV OLS; RW OLS. All use AII + FM + TR + PM + SZ.','30 independent multiple imputations in each split.','Bootstrap: 5000 per imputation = 150000 refits per model.','Five-fold CV across 30 imputations; outcome imputation before folds may make CV optimistic.','Use B observed-only validation as the primary independent validation result.','Poisson dispersion >1 suggests checking quasi-Poisson or negative binomial sensitivity.','Statistical association does not establish causation.','All results in UAIM_results.'),file.path(output,'README_results.txt'))
cat('SUCCESS: results written to ',normalizePath(output),'\n')

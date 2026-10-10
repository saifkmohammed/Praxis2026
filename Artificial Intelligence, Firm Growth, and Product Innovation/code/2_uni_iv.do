
local industry naics5
local country EU

foreach data in cognism {

use "$compustatdata", clear
ren fyear year

merge 1:1 gvkey year using "$data/tfpr", keep(1 3) nogen

merge m:1 gvkey using "$data/instrument_firm_bartik_naics", keep(1 3) nogen

merge 1:1 gvkey year using "$data/fluidity.dta", keep(1 3) nogen
ren prodmktfluid fluid

merge 1:1 gvkey year using "$data/gvkey_year_tm_reg.dta", keep(1 3) nogen

merge 1:1 gvkey year using "$data/productpatent_fyear.dta", keep(1 3) nogen
merge 1:1 gvkey year using "$data/productpatent_iyear.dta", keep(1 3) nogen
bysort gvkey: egen npatent_pre=sum((productpatent2_iyear+processpatent2_iyear)*(year<=2010 & year>=2005))
foreach var in productpatent1_iyear productpatent2_iyear productpatent1_fyear productpatent2_fyear processpatent1_iyear processpatent2_iyear processpatent1_fyear processpatent2_fyear {
  replace `var'=0 if `var'==. & npatent_pre>0
}

bysort gvkey: egen ntrademark_pre=sum(ntrademark_reg*(year<=2010))

*market share
gen naics4=substr(naics,1,4)
gen naics5=substr(naics,1,5)
destring sic naics*, replace
bysort $msnaics year: egen indsale=sum(sale)
drop naics4 naics5
*CHANGE level not log
gen marketshare_naics=sale/indsale

tsset gvkey year
gen markup = log(revt/cogs)
gen markup2 = log(revt/xopr)
gen lernerindex = oiadp / sale
gen sga_norm = xsga/sale
gen logemp = log(emp)
gen logsale = log(sale)
egen 	xint_first = rowfirst(xint xintd )
replace xint_first =  0 if xint_first == .
gen roa = ( ib + xint_first)/L.at
gen ros = ( ib + xint_first)/L.sale
gen logsga = log(xsga)
gen logcogs = log(cogs)
gen logxopr = log(xopr)
replace xrd=0 if xrd==.&logsale!=.
gen logrd=log(1+xrd)
gen rdnorm=xrd/sale
gen cashnorm=che/at
replace txditc=0 if txditc<0 | txditc==.
replace prcc_f=prcc_c if prcc_f==.
gen tobinq=(csho*prcc_f+at-ceq-txditc)/at
gen logtm=log(1+ntrademark_reg)
gen logtm2=log(ntrademark_reg)
gen tmoversale=ntrademark_reg/sale
gen logtm_3yr=log(1+ntrademark_reg_3yr)
gen logtm_3yr2=log(ntrademark_reg_3yr)
gen tmoversale_3yr=ntrademark_reg_3yr/sale
gen logprodpat1_fyear=log(1+productpatent1_fyear)
gen logprodpat2_fyear=log(1+productpatent2_fyear)
gen logprodpat1_iyear=log(1+productpatent1_iyear)
gen logprodpat2_iyear=log(1+productpatent2_iyear)
gen logprocesspat1_fyear=log(1+processpatent1_fyear)
gen logprocesspat2_fyear=log(1+processpatent2_fyear)
gen logprocesspat1_iyear=log(1+processpatent1_iyear)
gen logprocesspat2_iyear=log(1+processpatent2_iyear)
*old ######: gen logmv=log(at+csho*prcc_f-txditc) 
gen logmv=log(at+csho*prcc_f-ceq)



*****
keep if year==$year1 | year==$year2 | year==$year3 | year==$year4


global varlist markup markup2 logemp emp sale logsale roa ros sga_norm logsga logcogs logxopr logrd rdnorm fluid selffluid /*
*/ cashnorm marketshare_naics tfpr lernerindex tobinq logtm logtm2 tmoversale logtm_3yr logtm_3yr2 tmoversale_3yr /*
*/ logprodpat1_fyear logprodpat2_fyear logprodpat1_iyear logprodpat2_iyear logprocesspat1_fyear logprocesspat2_fyear logprocesspat1_iyear logprocesspat2_iyear logmv age

keep czone gvkey year $varlist log* comnam state npatent_pre ntrademark_pre

reshape wide $varlist comnam npatent_pre ntrademark_pre, i(gvkey) j(year)

foreach var in $varlist {
gen d_`var'=`var'$year2-`var'$year1
gen d_`var'_pre = `var'$year4-`var'$year3
}

gen year=2010

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob njob_narrowai) keep(1 3) nogen
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp) keep(3) nogen
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<20
drop maxnjob
}

gen share_narrowai2010 = njob_narrowai/njob
gen njob_nonai2010 = njob-njob_narrowai
gen weight = njob
rename njob njob2010 
rename njob_narrowai njob_narrowai2010

replace year=$year2

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob njob_narrowai) keep(1 3) nogen
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp) keep(3) nogen
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<20
drop maxnjob
}

gen share_narrowai2018 = njob_narrowai/njob

rename njob njob2018 
rename njob_narrowai njob_narrowai2018

replace year=$year5

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob njob_narrowai) keep(1 3) nogen
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
*drop if maxnjob<50
drop maxnjob
}

gen share_narrowai2014 = njob_narrowai/njob
drop njob njob_narrowai


gen d_share_narrowai = share_narrowai2018 - share_narrowai2010
gen d_share_narrowai_pre2014 = share_narrowai2014 - share_narrowai2010
gen d_share_narrowai_post2014 = share_narrowai2018 - share_narrowai2014


cap drop year
gen year=2005
merge m:1 czone year using "$data/cz_employment_2005_2017", keep(1 3) keepus(population share_foreignborn) nogen
rename population  population2005

merge m:1 czone   using "$data/cz_employment_$control_year", keep(1 3)  nogen


*** merge dorn data to get state and to get share foreign 
gen yr =2000
merge m:1 czone yr using "$data/workfile_china", keep(1 3) keepus(statefip l_sh_popfborn l_sh_routine33  reg_midatl reg_encen reg_wncen reg_satl reg_escen reg_wscen reg_mount reg_pacif d_tradeusch_pw) nogen
cap drop yyr
tab statefip
sum l_sh_popfborn l_sh_routine33, d

*tech employment share
merge m:1 czone using "$data/share_tech_qwi", keep(1 3) nogen



merge m:1 gvkey using "$data/sic", keep(1 3) nogen
gen sic2 = int(sic/100)
*gen sector = int(naics/10000)
*gen naics4 = int(naics/100)
*gen naics2 = sector
*gen naics3	=int(naics/1000)
*gen naics5	=int(naics/10)

gen log_njob2010=log(njob_nonai2010)


*industry average wage

gen annualwage_ind=.
merge m:1 naics5 using "$data/wage_naics5", keep(1 3) nogen
replace annualwage_ind=a_mean
drop a_mean
merge m:1 naics4 using "$data/wage_naics4", keep(1 3) nogen
replace annualwage_ind=a_mean if annualwage_ind==.
drop a_mean
merge m:1 naics3 using "$data/wage_naics3", keep(1 3) nogen
replace annualwage_ind=a_mean if annualwage_ind==.
drop a_mean
merge m:1 naics2 using "$data/wage_naics2", keep(1 3) nogen
replace annualwage_ind=a_mean if annualwage_ind==.
drop a_mean h_mean
gen log_wage_industry=log(annualwage_ind)




*********************************************************
****************		REGRESSIONS		***************** 
*********************************************************
**********************************************************


*** generate a dummy for firms in the sample + why are we loosing 200+ obs? look tech firms
sum d_logemp, d
sum d_share_narrowai, d
reg d_logemp d_logsale
reg d_logemp d_share_narrowai 
reg d_logemp d_share_narrowai d_logsale
gen itsector = (sector==51 | sector==54)
*gen itsector = (naics3==334 | naics3==511 | naics3==516 | naics3==518 | naics4==5415)
*1400
reg d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  if (njob_nonai2010>1 & itsector==0)
* 1400
reghdfe d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  [aw=weight] if (njob_nonai2010>1 & itsector==0), a($fevar) cluster($clustervar)

***** generate sample dummy : include firms with over 1 jobs and AI producers
*gen include  = (  e(sample)   ==  1)
gen include  = (  e(sample)   ==  1 & log_njob2010!=. & cashnorm2010!=. & logsale2010!=. &  log_wage2010!=. &  share_college!=. &  log_wage_industry!=. & markup2010!=. &  d_tradeusch_pw!=. & share_computerocc$control_year !=. & log_population$control_year !=. & share_female!=. & share_manufacturing!=. & share_finance!=. & share_foreignborn!=. & l_sh_popfborn!=. & l_sh_routine33!=. )
tab include 
sum d_share_narrowai if  include==1, d
drop if include == 0
 

cap drop d_share_narrowai_zero
gen d_share_narrowai_zero = (d_share_narrowai ==0 )
tab d_share_narrowai_zero 
* 56*  - 55% of all obs have zero ai
cap drop d_share_narrowai_zeroneg 
gen d_share_narrowai_zeroneg = (d_share_narrowai ==0  |  (d_share_narrowai < 0 & d_share_narrowai~=. ) )
tab d_share_narrowai_zeroneg 
* 60%
*** who are the firms that have negative ai growth?
list comnam2010 d_share_narrowai emp* logemp2010 logemp2018  if  d_share_narrowai < 0 & d_share_narrowai~=. 
** seem plausible for some of them

*** winsorize
global depvar d_share_narrowai d_logemp d_logsale d_markup d_markup2 d_sga_norm d_roa d_ros d_lernerindex /*
*/ d_logsga d_logcogs d_logxopr d_logrd d_rdnorm d_tfpr markup2010 /*
*/ logsale2010  cashnorm2010 rdnorm2010 roa2010 ros2010 markup22010 tobinq2010 /*
*/ d_fluid d_selffluid d_logtm d_logtm2 d_tmoversale d_logtm_3yr d_logtm_3yr2 d_tmoversale_3yr /*
*/ d_logprodpat1_fyear d_logprodpat2_fyear d_logprodpat1_iyear d_logprodpat2_iyear d_logprocesspat1_fyear d_logprocesspat2_fyear d_logprocesspat1_iyear d_logprocesspat2_iyear d_logmv
gen markup2010_original=markup2010
sum markup2010
replace markup2010=r(mean) if markup2010==.

if $winsor ==1 {

foreach var in $depvar {
sum `var', d
replace `var'=r(p99) if `var'>r(p99)&`var'<.
replace `var'=r(p1) if `var'<r(p1)
sum `var', d
}

}
//

*** define a dummy of adoptoin within each industry
tabstat  d_share_narrowai, by(sic2)
tabstat  d_share_narrowai d_share_narrowai_zeroneg, by(sic2) s(N)
tabstat  d_share_narrowai d_share_narrowai_zeroneg, by(sic2) 

replace  d_share_narrowai_zeroneg  = 1 - d_share_narrowai_zeroneg 
tab d_share_narrowai_zeroneg 
rename 	d_share_narrowai_zeroneg 	ai_adopter
cap drop ai_adopter001
gen 	ai_adopter001 	= ( d_share_narrowai > 0.001 &  d_share_narrowai ~=. ) 
tab ai_adopter001
* 0.001  gives 25%
* 0.0005  gives 32%
* 0.0001  gives 40% - same as zero
 

*** standardize independent variable &  IV ***

sum d_share_narrowai, d

egen 	d_share_narrowai_temp = std(d_share_narrowai)
drop 	d_share_narrowai
rename 	d_share_narrowai_temp d_share_narrowai

sum d_share_narrowai, d


egen 	d_share_narrowai_pre2014_temp = std(d_share_narrowai_pre2014)
drop 	d_share_narrowai_pre2014
rename 	d_share_narrowai_pre2014_temp d_share_narrowai_pre2014

gen d_logsaleperworker = d_logsale - d_logemp

****** 	OLS	***************** 


eststo clear

 
*local ROBUSTNESS  Winsorized
* NotWinsorized_AllVars ai_adopter001 Winsorized


local 	X 		d_share_narrowai
* d_share_narrowai  ai_adopter001
local	Y_list   d_logemp d_logsale d_logsga d_logcogs d_logxopr d_markup d_markup2 d_sga_norm d_roa d_ros d_logrd d_rdnorm d_logsaleperworker d_logemp_pre d_logsale_pre d_marketshare_naics 

***
lab var d_logemp "$\Delta$ Log Employment"
lab var d_logsale "$\Delta$ Log Sales"
lab var d_markup "$\Delta$ Markup (COGS)"
lab var d_markup2 "$\Delta$ Markup (Total Exp)"
lab var d_lernerindex "$\Delta$ Lerner index"
lab var d_roa "$\Delta$ ROA"
lab var d_ros "$\Delta$ ROS"
lab var d_logsaleperworker "Log sales per worker"

lab var d_logrd "$\Delta$ Log R\&D"
lab var d_rdnorm "$\Delta$ R\&D/Sales"

lab var cashnorm2010 "Cash/Assets 2010"
lab var logsale2010 "Log Sales 2010"
lab var d_logsale_pre "1999-2007 sales change"
lab var d_logemp_pre "1999-2007 emp change"

lab var d_share_narrowai "$\Delta$ Share AI Workers"
lab var d_tfpr "Revenue TFP"

lab var d_markup "$\Delta$ Markup (COGS)"
lab var d_markup2 "$\Delta$ Markup (Total Exp)"
lab var d_logcogs "$\Delta$ Log COGS"
lab var d_logxopr "$\Delta$ Log Operating Expense"

lab var logsale2010 "Log Sales 2010"
lab var logemp2010 "Log Employment 2010"
lab var cashnorm2010 "Cash/Assets 2010"
lab var rdnorm2010 "R\&D/Sales 2010"
lab var roa2010 "ROA 2010"
lab var ros2010 "ROS 2010"
lab var markup2010 "Log Markup (COGS) 2010"
lab var markup22010 "Log Markup (Total Exp) 2010"
lab var tobinq2010 "Tobin's Q 2010"

merge 1:1 gvkey using "$dropbox_dir/AI/Data/Fluidity/fluidity_2010_2018", keep(1 3) nogen

merge 1:1 gvkey using "$data/uni_iv", keep(1 3) nogen


merge 1:1 gvkey using "$data/share_misssing_grads", keep(1 3) nogen keepus(share_missing)
sum share_missing,d
gen missing_10pct=(share_missing>r(p90) & share_missing<.)
sum share_missing,d
gen missing_20pct=(share_missing>r(p95) & share_missing<.)

local IV uni_iv_v4c


local 	X 		d_share_narrowai

replace state="F" if state==""


egen 	uni_iv_v4c_temp = std(uni_iv_v4c)
drop 	uni_iv_v4c
rename 	uni_iv_v4c_temp uni_iv_v4c

global controliv uni_cs_v4c uni_top10


*first stage Table 13

lab var `IV' "Instrument"

eststo clear


eststo:  reghdfe `X' `IV'  $controliv  [aw=weight]  if include == 1 & missing_20pct==0 & d_logsale!=., a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "N"
estadd local controlpre "N"
estadd local controlstate "N"
test `IV'  = 0
estadd scalar F_test = r(F)
eststo:   reghdfe `X' `IV' $controliv  $control  $control2  [aw=weight]  if include == 1& missing_20pct==0 & d_logsale!=., a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "Y"
estadd local controlpre "N"
estadd local controlstate "N"
test `IV'  = 0
estadd scalar F_test = r(F)
eststo:   reghdfe `X' `IV' $controliv d_logsale_pre d_logemp_pre   $control  $control2  [aw=weight]  if include == 1& missing_20pct==0& d_logsale!=., a($fevar)  cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "Y"
estadd local controlpre "Y"
estadd local controlstate "N"
test `IV'  = 0
estadd scalar F_test = r(F)
eststo:  reghdfe `X' `IV' $controliv d_logsale_pre d_logemp_pre  $control  $control2  [aw=weight]  if include == 1& missing_20pct==0& d_logsale!=., a($fevar state) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "Y"
estadd local controlpre "Y"
estadd local controlstate "Y"
test `IV'  = 0
estadd scalar F_test = r(F)

esttab using "$table/original/uniiv_firststage_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`IV') ///
stats(naics2_fe controlcs control controlpre controlstate F_test  N , fmt(0 0 0 0 0 %9.1fc  %9.0fc ) labels("Industry FE" "CS Control" "Baseline Controls"  "Control Pre-trend" "State FE" "F Statistic" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Share of AI Workers", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*2SLS Growth Table 5

eststo clear


foreach Y in d_logsale d_logemp d_logmv {
eststo:  ivreghdfe `Y' (`X' = `IV')  $controliv  [aw=weight]  if include == 1 & missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "N"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') $controliv  $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "Y"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') $controliv d_logsale_pre d_logemp_pre   $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "Y"
estadd local controlpre "Y"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') $controliv d_logsale_pre d_logemp_pre  $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar state)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local controlcs "Y"
estadd local control "Y"
estadd local controlpre "Y"
estadd local controlstate "Y"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
}


esttab using "$table/original/uniiv_growth_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe controlcs control controlpre controlstate F_test  N , fmt(0 0 0 0 0 %9.1fc  %9.0fc ) labels("Industry FE" "CS Control" "Baseline Controls"  "Control Pre-trend" "State FE" "F Statistic" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 0 0 1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 



gen logntrademark_pre=log(1+ntrademark_pre2010)
gen lognpatent_pre=log(npatent_pre2010)


*2SLS product innovation Table 7


eststo clear


/* old ###### 

foreach Y in d_logtm {
eststo:  ivreghdfe `Y' (`X' = `IV') logntrademark_pre $controliv  [aw=weight]  if include == 1 & missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
estadd local controlcs "Y"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') logntrademark_pre $controliv $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') logntrademark_pre $controliv d_logsale_pre d_logemp_pre  $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "Y"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') logntrademark_pre $controliv d_logsale_pre d_logemp_pre  $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar state)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "Y"
estadd local controlstate "Y"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
}

foreach Y in d_logprodpat2_fyear {
eststo:  ivreghdfe `Y' (`X' = `IV') lognpatent_pre  $controliv  [aw=weight]  if include == 1 & missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
estadd local controlcs "Y"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') lognpatent_pre $controliv  $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') lognpatent_pre $controliv d_logsale_pre d_logemp_pre $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "Y"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV') lognpatent_pre $controliv d_logsale_pre d_logemp_pre   $control  $control2  [aw=weight]  if include == 1& missing_20pct==0, a($fevar state)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "Y"
estadd local controlstate "Y"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
}

if "`data'"=="cognism" {
foreach Y in sum_degree {
eststo:  ivreghdfe `Y' (`X' = `IV')   $controliv  [aw=weight]  if include == 1 & missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
estadd local controlcs "Y"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV')   $control2 $controliv  [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "N"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV')  $control2 $controliv d_logsale_pre d_logemp_pre   [aw=weight]  if include == 1& missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "Y"
estadd local controlstate "N"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
eststo:  ivreghdfe `Y' (`X' = `IV')  $control2 $controliv d_logsale_pre d_logemp_pre  [aw=weight]  if include == 1& missing_20pct==0, a($fevar state)  ffirst cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlcs "Y"
estadd local controlpre "Y"
estadd local controlstate "Y"
matrix temp_mat = e(first)
matrix list temp_mat	
estadd scalar F_test		= temp_mat[4,1]
}
}

*/

foreach Y in "d_logtm" "d_logprodpat2_fyear" "sum_degree" {

     if ("`Y'" == "d_logtm")             local pre_levels "logntrademark_pre"
     if ("`Y'" == "d_logprodpat2_fyear") local pre_levels "lognpatent_pre"
     if ("`Y'" == "sum_degree") {
         if ("`data'" == "cognism") local pre_levels ""
         else continue
     }
    eststo:  ivreghdfe `Y' (`X' = `IV') `pre_levels' $controliv  [aw=weight]  if missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
    estadd local naics2_fe "Y"
    estadd local control "N"
    estadd local controlcs "Y"
    estadd local controlpre "N"
    estadd local controlstate "N"
    matrix temp_mat = e(first)
    matrix list temp_mat	
    estadd scalar F_test		= temp_mat[4,1]
    eststo:  ivreghdfe `Y' (`X' = `IV') `pre_levels' $controliv $control  $control2  [aw=weight]  if missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
    estadd local naics2_fe "Y"
    estadd local control "Y"
    estadd local controlcs "Y"
    estadd local controlpre "N"
    estadd local controlstate "N"
    matrix temp_mat = e(first)
    matrix list temp_mat	
    estadd scalar F_test		= temp_mat[4,1]
    eststo:  ivreghdfe `Y' (`X' = `IV') `pre_levels' $controliv d_logsale_pre d_logemp_pre  $control  $control2  [aw=weight]  if missing_20pct==0, a($fevar)  ffirst cluster($clustervar)
    estadd local naics2_fe "Y"
    estadd local control "Y"
    estadd local controlcs "Y"
    estadd local controlpre "Y"
    estadd local controlstate "N"
    matrix temp_mat = e(first)
    matrix list temp_mat	
    estadd scalar F_test		= temp_mat[4,1]
    eststo:  ivreghdfe `Y' (`X' = `IV') `pre_levels' $controliv d_logsale_pre d_logemp_pre  $control  $control2  [aw=weight]  if missing_20pct==0, a($fevar state)  ffirst cluster($clustervar)
    estadd local naics2_fe "Y"
    estadd local control "Y"
    estadd local controlcs "Y"
    estadd local controlpre "Y"
    estadd local controlstate "Y"
    matrix temp_mat = e(first)
    matrix list temp_mat	
    estadd scalar F_test		= temp_mat[4,1]
}

esttab using "$table/original/uniiv_product_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe controlcs control controlpre controlstate F_test  N , fmt(0 0 0 0 0 %9.1fc  %9.0fc ) labels("Industry FE" "CS Control" "Baseline Controls"  "Control Pre-trend" "State FE" "F Statistic" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("Trademarks" "Product Patents" "Change in Product Mix", pattern(1 0 0 0 1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*Pre-trend Table 12

eststo clear
foreach Y in d_logsale_pre d_logemp_pre d_logmv_pre {
	
eststo:  reghdfe `Y'  `IV' $controliv $control  $control2 if include == 1& missing_20pct==0, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlstate "N"
	
eststo:  reghdfe `Y'  `IV'  $controliv $control  $control2  if include == 1& missing_20pct==0, a($fevar state) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlstate "Y"
}
	
esttab using "$table/original/uniiv_pretrend_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`IV') ///
stats(naics2_fe control controlstate  N , fmt(0 0 %9.0fc ) labels("Industry FE" "Baseline Controls" "State FE" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales, 2000--2008" "$\Delta$ Log Employment, 2000--2008" "$\Delta$ Log Market Value, 2000--2008", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


eststo clear
foreach Y in d_logsale d_logemp d_logmv {

eststo:  reghdfe `Y'  `IV' $controliv  if include == 1& missing_20pct==0 [aw=weight], a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
estadd local controlstate "N"
	
eststo:  reghdfe `Y'  `IV' $controliv $control  $control2 if include == 1& missing_20pct==0 [aw=weight], a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlstate "N"
	
eststo:  reghdfe `Y'  `IV'  $controliv $control  $control2  if include == 1& missing_20pct==0 [aw=weight], a($fevar state) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local controlstate "Y"
}
	
esttab using "$table/original/uniiv_reducedform_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`IV') ///
stats(naics2_fe control controlstate  N , fmt(0 0 %9.0fc ) labels("Industry FE" "Baseline Controls" "State FE" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales, 2000--2008" "$\Delta$ Log Employment, 2000--2008" "$\Delta$ Log Market Value, 2000--2008", pattern(1 0 0 1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*binscatter Figure A4:

*old ###### binscatter d_logsale uni_iv_v4c if include == 1& missing_20pct==0 [aw=weight], absorb($fevar) control($controliv $control  $control2) xtitle("Instrument") ytitle("Change in Log Sales, 2010--2018")

binscatter d_logsale uni_iv_v4c if missing_20pct==0 [aw=weight], absorb($fevar) control($controliv $control  $control2 d_logsale_pre d_logemp_pre) xtitle("Instrument") ytitle("Change in Log Sales, 2010--2018")

graph export "$draft/_figures/binscatter_iv_sales.pdf", as(pdf) replace

*old ###### binscatter d_logemp uni_iv_v4c if include == 1& missing_20pct==0 [aw=weight], absorb($fevar) control($controliv $control  $control2) xtitle("Instrument") ytitle("Change in Log Employment, 2010--2018")

binscatter d_logemp uni_iv_v4c if missing_20pct==0 [aw=weight], absorb($fevar) control($controliv $control  $control2 d_logsale_pre d_logemp_pre) xtitle("Instrument") ytitle("Change in Log Employment, 2010--2018")

graph export "$draft/_figures/binscatter_iv_emp.pdf", as(pdf) replace

*old ###### binscatter d_logmv uni_iv_v4c if include == 1& missing_20pct==0 [aw=weight], absorb($fevar) control($controliv $control  $control2) xtitle("Instrument") ytitle("Change in Log Market Value, 2010--2018")

binscatter d_logmv uni_iv_v4c if missing_20pct==0 [aw=weight], absorb($fevar) control($controliv $control  $control2 d_logsale_pre d_logemp_pre) xtitle("Instrument") ytitle("Change in Log Market Value, 2010--2018")

graph export "$draft/_figures/binscatter_iv_mv.pdf", as(pdf) replace



}






























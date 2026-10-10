                  *************************************************************
* Main Code for:
* 
* OLS regressions
* 
*************************************************************

*************************************************************
* I. Initial Code Settings/Directories
*************************************************************

drop _all
set more off
clear
clear matrix
clear mata
set mem 4000m
set matsize 7000
set maxvar 10000
set linesize 254
capture log close

capture ereturn clear
capture est store clear
capture matrix drop _all

* set directory to read/write data

global name alex
* alex tania

*cluster by
global clustervar naics5

*Fixed effect
global fevar naics2

*market share
global msnaics naics5


if "$name"=="alex" {
global dropbox_dir "/Users/alexxihe/Dropbox"
}

if "$name"=="tania" {
global dropbox_dir "~\\Dropbox"
}
//

global data          "$dropbox_dir/AI/Code/AI replication/data"
global compustatdata "$data/Compustat20200227"
global cognismdata   "$data/ai_firm_map_2021"
global table         "$dropbox_dir/AI/Code/AI replication/draft/_tables"

global control_year		2010
global year1 2010
global year2 2018
global year3 2000
global year4 2008
global year5 2014

local industry naics5

*whether run industry regressions or not
local indreg 1

*winsorize
global winsor 1

use "$data/bg_compustat_byfirmcz", clear

keep if year<2012
bysort gvkey: egen njobtotal=sum(njob_nonai)
bysort gvkey czone: egen njob_nonai_czone=sum(njob_nonai)
collapse njobtotal njob_nonai_czone, by (gvkey czone)
gen share=njob_nonai_czone/njobtotal

gsort gvkey -share
by gvkey: gen rank=_n
gen czone2010 = czone if rank==1

keep gvkey czone share czone2010

merge m:1 czone using "$data/share_tech_qwi", keep(1 3) nogen

gen year=2010
merge m:1 czone year using "$data/cz_employment_2005_2017", keep(1 3) keepus(share_female share_college share_manufacturing share_finance share_foreignborn share_computerocc)

collapse share_* czone2010 [aw=share], by (gvkey)

ren czone2010 czone

save "$data/instrument_firm_bartik_naics", replace

*bg or cognism
foreach data in cognism bg {

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
*Tobin's Q: definition follows Lee, Shin, Stulz RFS 2021
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


global varlist markup markup2 logemp emp sale logsale roa ros sga_norm logsga logcogs logxopr logrd rdnorm fluid selffluid cashnorm marketshare_naics tfpr lernerindex tobinq logtm logtm2 tmoversale logtm_3yr logtm_3yr2 tmoversale_3yr logprodpat1_fyear logprodpat2_fyear logprodpat1_iyear logprodpat2_iyear logprocesspat1_fyear logprocesspat2_fyear logprocesspat1_iyear logprocesspat2_iyear logmv age

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


/*** merge 2010 variables as controls
preserve
use	 "$data/cz_employment_2005_2017",clear

keep 	if year == $control_year

*** get controls for CZ rgressions
keep 	czone population employment share_female share_college share_manufacturing share_finance log_wage share_foreignborn share_computerocc  
*sum 	population employment share_female share_college share_manufacturing share_finance log_wage, d
rename population		 	 population$control_year
rename employment		 	 employment$control_year
rename share_female		 	 share_female$control_year
rename share_college	 	 share_college$control_year
rename share_manufacturing	 share_manufacturing$control_year
rename share_finance		 share_finance$control_year
rename log_wage		 		 log_wage$control_year
rename share_foreignborn     share_foreignborn$control_year
rename share_computerocc     share_computerocc$control_year

* generate controls
gen  log_population$control_year = log(population$control_year)
* generate weight for regressions: CZ/US populaitn to follow DOrn's China syndrom paper
save  "$data/cz_employment_$control_year", replace
restore
*/

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

sum d_logemp, d
sum d_share_narrowai, d
reg d_logemp d_logsale
reg d_logemp d_share_narrowai 
reg d_logemp d_share_narrowai d_logsale
gen itsector = (sector==51 | sector==54)
reg d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  if (njob_nonai2010>1 & itsector==0)
reghdfe d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  [aw=weight] if (njob_nonai2010>1 & itsector==0), a($fevar) cluster($clustervar)

***** generate sample dummy : include firms with over 1 jobs and AI producers
gen include  = (  e(sample)   ==  1 & log_njob2010!=. & cashnorm2010!=. & logsale2010!=. &  log_wage2010!=. &  share_college!=. &  log_wage_industry!=. & markup2010!=. &  d_tradeusch_pw!=. & share_computerocc$control_year !=. & log_population$control_year !=. & share_female!=. & share_manufacturing!=. & share_finance!=. & share_foreignborn!=. & l_sh_popfborn!=. & l_sh_routine33!=. )
tab include 
sum d_share_narrowai if  include==1, d
drop if include == 0
 
cap drop d_share_narrowai_zero
gen d_share_narrowai_zero = (d_share_narrowai ==0 )
tab d_share_narrowai_zero 
cap drop d_share_narrowai_zeroneg 
gen d_share_narrowai_zeroneg = (d_share_narrowai ==0  |  (d_share_narrowai < 0 & d_share_narrowai~=. ) )
tab d_share_narrowai_zeroneg 
list comnam2010 d_share_narrowai emp* logemp2010 logemp2018  if  d_share_narrowai < 0 & d_share_narrowai~=. 

*** winsorize
global depvar d_share_narrowai d_logemp d_logsale d_markup d_markup2 d_sga_norm d_roa d_ros d_lernerindex d_logsga d_logcogs d_logxopr d_logrd d_rdnorm d_tfpr markup2010 logsale2010  cashnorm2010 rdnorm2010 roa2010 ros2010 markup22010 tobinq2010 d_fluid d_selffluid d_logtm d_logtm2 d_tmoversale d_logtm_3yr d_logtm_3yr2 d_tmoversale_3yr d_logprodpat1_fyear d_logprodpat2_fyear d_logprodpat1_iyear d_logprodpat2_iyear d_logprocesspat1_fyear d_logprocesspat2_fyear d_logprocesspat1_iyear d_logprocesspat2_iyear d_logmv
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

save "$data/reg_sample_`data'", replace

*** standardize independent variable &  IV ***

sum d_share_narrowai [aw=weight], d

gen byte ai_invest_pos = (d_share_narrowai> r(p75) & d_share_narrowai<.)

*old ######: sum d_share_narrowai, d
sum d_share_narrowai [aw=weight], d

gen byte ai_invest_top10 = (d_share_narrowai >= r(p90) & d_share_narrowai<.)

egen 	d_share_narrowai_temp = std(d_share_narrowai)
drop 	d_share_narrowai
rename 	d_share_narrowai_temp d_share_narrowai

sum d_share_narrowai, d

egen 	d_share_narrowai_pre2014_temp = std(d_share_narrowai_pre2014)
drop 	d_share_narrowai_pre2014
rename 	d_share_narrowai_pre2014_temp d_share_narrowai_pre2014

sum d_share_narrowai, d

gen d_logsaleperworker = d_logsale - d_logemp

****** 	OLS	***************** 

eststo clear

local 	X 		d_share_narrowai
local	Y_list   d_logemp d_logsale d_logsga d_logcogs d_logxopr d_markup d_markup2 d_sga_norm d_roa d_ros d_logrd d_rdnorm d_logsaleperworker d_logemp_pre d_logsale_pre d_marketshare_naics 

*basic controls
*global control log_njob2010 cashnorm2010 logsale2010 log_wage2010  share_college  log_wage_industry markup2010 rdnorm2010

*additional controls
*global control2  d_tradeusch_pw share_computerocc$control_year log_population$control_year share_female share_manufacturing share_finance share_foreignborn   l_sh_popfborn l_sh_routine33

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


*summary stats (Table A5)

*normalize trademarks (patents) by the change in the total number of trademarks (patents) from 2010 to 2018 to adjust for truncation in recent years
gen d_logprodpat2_norm = d_logprodpat2_fyear + 0.85
gen d_logprocesspat2_norm = d_logprocesspat2_fyear + 0.76

reghdfe d_logsale d_share_narrowai [aw=weight] if include == 1, a($fevar) cluster($clustervar)
latabstat d_share_narrowai d_logsale d_logemp d_logmv d_logsaleperworker d_tfpr d_logtm d_logprodpat2_norm d_logprocesspat2_norm emp2010 sale2010 cashnorm2010 age2010 if e(sample)==1, s(count mean sd p1 p5 p10 p25 median p75 p90 p95 p99) col(stat) format(%9.2g)


*********************************************************
**************** Table 	3 & A10: OLS	***************** 
*********************************************************
**********************************************************


eststo clear
foreach Y in d_logsale d_logemp d_logmv {
eststo:  reghdfe `Y' `X'    [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe `Y' `X'   $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}
	
esttab using "$table/original/table_ols_weighted_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe control r2_a N , fmt(0 0 %9.3fc %9.0fc ) labels("Industry FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*********************************************************
**************** Table 	A18, A16: OLS with additional controls***************** 
*********************************************************

replace state="F" if state == ""

eststo clear
foreach Y in d_logsale d_logemp d_logmv {
eststo:  reghdfe `Y' `X'  $control $control2 [aw=weight] if include == 1, a($fevar state) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local statefe "Y"
estadd local naics3_fe "N"
eststo:  reghdfe `Y' `X'   $control $control2 tobinq2010 [aw=weight] if include == 1, a($fevar state) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local statefe "Y"
estadd local naics3_fe "N"
}
	
esttab using "$table/original/table_ols_control_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X' tobinq2010) ///
stats(naics2_fe control statefe naics3_fe r2_a N , fmt(0 0 0 0  %9.3fc %9.0fc ) labels("Industry FE" "Controls" "State FE" "NAICS3 FE" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 

eststo clear
foreach Y in d_logsale d_logemp d_logmv {

eststo:  reghdfe `Y' `X'  $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local naics3_fe "N"
estadd local naics4_fe "N"
estadd local naics5_fe "N"
estadd local control "Y"
eststo:  reghdfe `Y' `X'   $control $control2 [aw=weight] if include == 1, a(naics3) cluster($clustervar)
estadd local naics2_fe "N"
estadd local naics3_fe "Y"
estadd local naics4_fe "N"
estadd local naics5_fe "N"
estadd local control "Y"
eststo:  reghdfe `Y' `X'   $control $control2 [aw=weight] if include == 1, a(naics4) cluster($clustervar)
estadd local naics2_fe "N"
estadd local naics3_fe "N"
estadd local naics4_fe "Y"
estadd local naics5_fe "N"
estadd local control "Y"
eststo:  reghdfe `Y' `X'   $control $control2 [aw=weight] if include == 1, a(naics5) cluster($clustervar)
estadd local naics2_fe "N"
estadd local naics3_fe "N"
estadd local naics4_fe "N"
estadd local naics5_fe "Y"
estadd local control "Y"
}
	
esttab using "$table/original/table_ols_naicsfe_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe naics3_fe naics4_fe naics5_fe control r2_a N , fmt(0 0 0 0 0  %9.3fc %9.0fc ) labels("NAICS2 FE" "NAICS3 FE" "NAICS4 FE" "NAICS5 FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 0 0 1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 



merge m:1 naics5 using "$data/naics5_pretrend", keep(1 3) nogen

gen include_pre=(include==1 & d_logemp_pre!=. & d_logemp_indpre!=.)

****************************************************************
****************************************************************
**** Table A17: Control for pretrend ******
****************************************************************
****************************************************************

eststo clear
foreach Y in d_logsale d_logemp d_logmv {
*old ######: eststo:  reghdfe `Y' `X'  $control  $control2 d_logsale_indpre d_logemp_indpre [aw=weight] if include == 1, a($fevar) cluster($clustervar)
eststo:  reghdfe `Y' `X'  $control  $control2 d_logsale_indpre d_logemp_indpre [aw=weight] if include_pre == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local indpre "Y"
estadd local firmpre "N"

*old ######: eststo:  reghdfe `Y' `X'  $control  $control2 d_logsale_pre d_logemp_pre [aw=weight]  if include == 1, a($fevar)  cluster($clustervar)
eststo:  reghdfe `Y' `X'  $control  $control2 d_logsale_pre d_logemp_pre [aw=weight]  if include_pre == 1, a($fevar)  cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
estadd local indpre "N"
estadd local firmpre "Y"
}
	
esttab using "$table/original/table_controlpretrend_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe control indpre firmpre  N , fmt(0 0 0 0  %9.0fc ) labels("Industry FE" "Controls" "Industry pre-trend" "Firm pre-trend" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*********************************************************
**************** Table 4: Heterogeneity by Size ***************** 
*********************************************************
**********************************************************

egen quantile=xtile(njob2010), n(3) by(naics2)
*new ###### ??????:egen quantile=xtile(logemp2010), n(3) by(naics2)

forv i=1/3 {
gen `X'_q`i'=`X'*(quantile==`i')
lab var `X'_q`i' "$\Delta$  Share AI Workers*Size Tercile `i'"
}

eststo clear
foreach Y in d_logsale d_logemp d_logmv {
eststo:  reghdfe `Y' `X'_q*    [aw=weight] if include == 1, a(naics2#quantile) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
test `X'_q1 = `X'_q3
estadd scalar F_sum = r(F)
estadd scalar p_sum = r(p)

eststo:  reghdfe `Y' `X'_q*   $control $control2 [aw=weight] if include == 1, a(naics2#quantile) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
test `X'_q1 = `X'_q3
estadd scalar F_sum = r(F)
estadd scalar p_sum = r(p)
}

esttab using "$table/original/table_ols_firmsize_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X'_q*) ///
stats(naics2_fe control r2_a N F_sum p_sum, fmt(0 0 %9.3fc %9.0fc %9.1fc %9.3fc) labels("NAICS2*Size tercile FE" "Controls" "Adj R-Squared" "Observations" "T-test statistic" "T-test p value") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment"  "$\Delta$ Log Market Value", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*********************************************************
**************** Table 8, A25: OLS Productivity ***************** 
*********************************************************
**********************************************************

local Xearly d_share_narrowai_pre2014 
lab var d_share_narrowai_pre2014 "$\Delta$ Share AI Workers 2010-2014"

eststo clear
foreach Y in d_logcogs d_logxopr d_logsaleperworker d_tfpr {
eststo:  reghdfe `Y' `X'   [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe `Y' `X'   $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}

gen lognpatent_pre=log(npatent_pre2010)

foreach Y in logprocesspat2_fyear {
eststo:  reghdfe d_`Y' `X' lognpatent_pre [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe d_`Y' `X' lognpatent_pre  $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}

esttab using "$table/original/table_ols_productivity_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe control r2_a N , fmt(0 0 %9.3fc %9.0fc ) labels("Industry FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("COGS" "Operating Expense" "per Worker" "TFP" "Process Patents", pattern(1 0 1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 



*Table A27: J curve

eststo clear
foreach Y in d_logsaleperworker d_tfpr {
eststo:  reghdfe `Y' `Xearly'   [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe `Y' `Xearly'   $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}


esttab using "$table/original/table_ols_productivity_`data'_jcurve.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`Xearly') ///
stats(naics2_fe control r2_a N , fmt(0 0 %9.3fc %9.0fc ) labels("Industry FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("per Worker" "TFP", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*********************************************************
**************** Table 6: OLS Trademark	***************** 
*********************************************************
**********************************************************

gen logntrademark_pre=log(1+ntrademark_pre2010)

eststo clear
foreach Y in logtm {
eststo:  reghdfe d_`Y' `X' logntrademark_pre [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
*old ######: eststo:  reghdfe d_`Y' `X' logntrademark_pre $control [aw=weight] if include == 1, a($fevar) cluster($clustervar) 
eststo:  reghdfe d_`Y' `X' logntrademark_pre $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}

foreach Y in logprodpat2_fyear {
eststo:  reghdfe d_`Y' `X' lognpatent_pre [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe d_`Y' `X' lognpatent_pre  $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}

foreach Y in sum_degree {
eststo:  reghdfe `Y' `X' if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
*old ######: eststo:  reghdfe `Y' `X' $control2 if include == 1, a($fevar) cluster($clustervar)
eststo:  reghdfe `Y' `X' $control $control2 if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}

esttab using "$table/original/table_ols_tmpatent_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe control N , fmt(0 0 %9.0fc ) labels("Industry FE" "Controls" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("Trademarks" "Product Patents" "Change in Product Mix", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*Table A13: top AI-investing firms

lab var ai_invest_pos "Top 25\% in AI Investment"
lab var ai_invest_top10 "Top 10\% in AI Investment"

eststo clear
foreach Y in d_logsale d_logemp d_logmv {
eststo:  reghdfe `Y' ai_invest_pos    [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe `Y' ai_invest_pos    $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}
	
esttab using "$table/original/table_ols_posai_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(ai_invest_pos) ///
stats(naics2_fe control r2_a N , fmt(0 0 %9.3fc %9.0fc ) labels("Industry FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 

eststo clear
foreach Y in d_logsale d_logemp d_logmv {
eststo:  reghdfe `Y' ai_invest_top10    [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe `Y' ai_invest_top10   $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}
	
esttab using "$table/original/table_ols_top10ai_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(ai_invest_top10) ///
stats(naics2_fe control r2_a N , fmt(0 0 %9.3fc %9.0fc ) labels("Industry FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


*********************************************************
**************** Industry level ***************** 
*********************************************************
**********************************************************


if `indreg'== 1 {

preserve
*all compustat sample

local indlevel naics5

use "$compustatdata", clear
ren fyear year
gen naics5=substr(naics,1,5)
destring sic naics*, replace
bysort naics5: egen emp2010=sum(emp*(year==2010))
bysort naics5: egen emp2018=sum(emp*(year==2018))
bysort naics5: egen sale2010=sum(sale*(year==2010))
bysort naics5: egen sale2018=sum(sale*(year==2018))
collapse emp2010 emp2018 sale2010 sale2018, by(naics5)
gen d_emp_all=log(emp2018/emp2010)
gen d_sale_all=log(sale2018/sale2010)
save "$data/compustat_bynaics5", replace

foreach ind in naics5 {

use "$compustatdata", clear
ren fyear year
gen naics4=substr(naics,1,4)
gen naics5=substr(naics,1,5)
destring sic naics*, replace
bysort `ind' year: egen totalsale=sum(sale)
gen share=sale/totalsale
bysort `ind': egen sale2010=sum(sale*(year==2010))

gsort `ind' year -sale
by `ind' year: gen rank=_n
bysort `ind' year: egen top1sale=sum(sale*(rank==1))
gen top1share=top1sale/totalsale

bysort `ind' year: egen hhi=sum(share^2)

collapse hhi top1share, by(`ind' year)
keep if year==2010 | year==2018
reshape wide hhi top1share, i(`ind') j(year)
gen d_hhi = hhi2018-hhi2010
gen d_top1share=top1share2018-top1share2010
keep d_* `ind'

save "$data/compustat_concentration_`ind'", replace

}

restore

local indlevel naics5

eststo clear
collapse (sum) njob2010 njob2018 njob_narrowai2010 njob_narrowai2018 emp2010 emp2018 sale2010 sale2018 /*
*/ emp$year3 emp$year4 sale$year3 sale$year4 (mean) naics2 log_wage2010, by(`indlevel')

gen d_emp=log(emp2018/emp2010)
gen d_sale=log(sale2018/sale2010)
gen d_share_narrowai = njob_narrowai2018/njob2018-njob_narrowai2010/njob2010
gen d_logsaleperworker=log(sale2018/emp2018)-log(sale2010/emp2010)
gen d_emp_pre=log(emp$year4 / emp$year3 )
gen d_sale_pre=log(sale$year4 /sale$year3 )
gen logsale2010=log(sale2010)
gen logemp2010=log(emp2010)

merge 1:1 `indlevel' using "$data/compustat_by`indlevel'", keep(1 3) nogen

gen d_logsaleperworker_all=d_sale_all-d_emp_all

*** standardize independent variable ***

sum d_share_narrowai, d

egen 	d_share_narrowai_temp = std(d_share_narrowai)
drop 	d_share_narrowai
rename 	d_share_narrowai_temp d_share_narrowai
sum d_share_narrowai, d

lab var d_share_narrowai "$\Delta$ Share AI Workers"

local 	X 		d_share_narrowai
global controlind  logsale2010 logemp2010 log_wage2010

*keep if controls are non-missing
keep if log_wage2010!=.

**************************************************************
**************** Table 9, A29: Industry employment and sales and concentration***************** 
****************************************************************

foreach Y in d_sale_all d_emp_all {

eststo: reghdfe `Y' d_share_narrowai [aw=njob2010], a(naics2) vce(robust)
estadd local naics2_fe "Y"
estadd local control "N"

eststo: reghdfe `Y' d_share_narrowai $controlind [aw=njob2010], a(naics2) vce(robust)
estadd local naics2_fe "Y"
estadd local control "Y"
}

merge 1:1 `indlevel' using "$data/compustat_concentration_`indlevel'", keep(1 3) nogen

foreach Y in d_hhi d_top1share {

eststo: reghdfe `Y' d_share_narrowai [aw=njob2010], a(naics2) 
estadd local naics2_fe "Y"
estadd local control "N"

eststo: reghdfe `Y' d_share_narrowai $controlind [aw=njob2010], a(naics2) 
estadd local naics2_fe "Y"
estadd local control "Y"

}

esttab using "$table/original/table_industrylevel_concentration_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe control   N , fmt(0 0   %9.0fc ) labels("Industry Sector FE" "Controls" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("Log Sales" "Log Employment" "HHI" "Top Firm Market Share", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


}
}



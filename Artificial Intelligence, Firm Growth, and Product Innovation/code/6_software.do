                  *************************************************************
* Main Code for:
* 
* Using the AI measure incorporating software
* 
*************************************************************

*bg or cognism
local data cognism

use "$compustatdata", clear
ren fyear year

merge 1:1 gvkey year using "$data/tfpr", keep(1 3) nogen

merge m:1 gvkey using "$data/instrument_firm_bartik_naics", keep(1 3) nogen

*market share
destring sic naics, replace
gen naics4=int(naics/100)
gen naics5=int(naics/10)
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
*gen roa = (oiadp+recch+invch+apalch)/L.at
egen 	xint_first = rowfirst(xint xintd )
replace xint_first =  0 if xint_first == .
gen roa = ( ib + xint_first)/L.at
gen ros = ( ib + xint_first)/L.sale
gen logsaleperworker = log(sale/emp)
gen logsga = log(xsga)
gen logcogs = log(cogs)
gen logxopr = log(xopr)
replace xrd=0 if xrd==.&logsale!=.
gen logrd=log(1+xrd)
gen rdnorm=xrd/sale
gen cashnorm=che/at
replace txditc=0 if txditc<0 | txditc==.
gen tobinq=(csho*prcc_f+at-ceq-txditc)/at
replace prcc_f=prcc_c if prcc_f==.
*old ######: gen logmv=log(at+csho*prcc_f-txditc) 
gen logmv=log(at+csho*prcc_f-ceq)

*****
keep if year==$year1 | year==$year2 | year==$year3 | year==$year4


global varlist markup markup2 logemp emp sale logsale roa ros logsaleperworker sga_norm logsga logcogs logxopr logrd rdnorm /*
*/ cashnorm marketshare_naics tfpr lernerindex tobinq logmv age

keep czone gvkey year $varlist log* comnam state

reshape wide $varlist comnam, i(gvkey) j(year)

foreach var in $varlist {
gen d_`var'=`var'$year2-`var'$year1
gen d_`var'_pre = `var'$year4-`var'$year3
}

gen year=2010

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat", keepus(njob njob_narrowai) keep(1 3) nogen
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp) keep(3) nogen
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
merge 1:1 gvkey year using "$data/ai_firm_map_aitech", keepus(share_software share_both) keep(1 3) nogen 
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
ren share_software share_software2010
ren share_both share_both2010

replace year=$year2

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat", keepus(njob njob_narrowai) keep(1 3) nogen
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp) keep(3) nogen
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
merge 1:1 gvkey year using "$data/ai_firm_map_aitech", keepus(share_software share_both) keep(1 3) nogen 
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<20
drop maxnjob
}

gen share_narrowai2018 = njob_narrowai/njob

rename njob njob2018 
rename njob_narrowai njob_narrowai2018
ren share_software share_software2018
ren share_both share_both2018

replace year=$year5

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat", keepus(njob njob_narrowai) keep(1 3) nogen
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop maxnjob
}

gen share_narrowai2014 = njob_narrowai/njob
drop njob njob_narrowai


gen d_share_narrowai = share_narrowai2018 - share_narrowai2010
gen d_share_narrowai_pre2014 = share_narrowai2014 - share_narrowai2010
gen d_share_narrowai_post2014 = share_narrowai2018 - share_narrowai2014
gen d_share_software = share_software2018 - share_software2010
gen d_share_both = share_both2018 - share_both2010

*gen d_fluid = fluid2018 - fluid2010

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
reg d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  if (njob_nonai2010>1 & itsector==0)
reghdfe d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  [aw=weight] if (njob_nonai2010>1 & itsector==0), a($fevar) cluster($clustervar)

***** generate sample dummy : include firms with over 1 jobs and AI producers
gen include  = (  e(sample)   ==  1 & log_njob2010!=. & cashnorm2010!=. & logsale2010!=. & /*
*/ log_wage2010!=. &  share_college!=. &  log_wage_industry!=. & markup2010!=. &  d_tradeusch_pw!=. /*
*/ & share_computerocc$control_year !=. & log_population$control_year !=. & share_female!=. & /*
*/ share_manufacturing!=. & share_finance!=. & share_foreignborn!=. & l_sh_popfborn!=. & l_sh_routine33!=. )
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
global depvar d_share_narrowai d_logemp d_logsale d_markup d_markup2 d_sga_norm d_roa d_ros d_lernerindex /*
*/ d_logsaleperworker d_logsga d_logcogs d_logxopr d_logrd d_rdnorm d_tfpr markup2010 /*
*/ logsale2010  cashnorm2010 rdnorm2010 roa2010 ros2010 markup22010 tobinq2010 d_share_software d_share_both d_logmv
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

*** standardize independent variable &  IV ***

sum d_share_narrowai d_share_software d_share_both, d

egen 	d_share_narrowai_temp = std(d_share_narrowai)
drop 	d_share_narrowai
rename 	d_share_narrowai_temp d_share_narrowai

egen 	d_share_software_temp = std(d_share_software)
drop 	d_share_software
rename 	d_share_software_temp d_share_software

egen 	d_share_both_temp = std(d_share_both)
drop 	d_share_both
rename 	d_share_both_temp d_share_both

egen 	d_share_narrowai_pre2014_temp = std(d_share_narrowai_pre2014)
drop 	d_share_narrowai_pre2014
rename 	d_share_narrowai_pre2014_temp d_share_narrowai_pre2014

sum d_share_narrowai, d

****** 	OLS	***************** 


eststo clear

 
*local ROBUSTNESS  Winsorized
* NotWinsorized_AllVars ai_adopter001 Winsorized


local 	X 		d_share_software
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
lab var d_share_both "$\Delta$ Share AI Workers"

local 	X 		d_share_both

*********************************************************
**************** Table A14	***************** 
*********************************************************
**********************************************************

eststo clear
foreach Y in d_logsale d_logemp d_logmv {
eststo:  reghdfe `Y' `X'  [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "N"
eststo:  reghdfe `Y' `X'  $control $control2 [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"
}


esttab using "$table/original/table_ols_both_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe control r2_a N , fmt(0 0 %9.3fc %9.0fc ) labels("Industry FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Log Sales" "$\Delta$ Log Employment" "$\Delta$ Log Market Value", pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 




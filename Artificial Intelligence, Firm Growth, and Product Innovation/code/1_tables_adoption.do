
 *************************************************************
* Main Code for:
* 
* Which firms adopt AI (Table 2 and A4)
* 
*************************************************************


local industry naics5

local country EU


*bg or cognism
foreach data in cognism bg {


use "$compustatdata", clear
ren fyear year

merge 1:1 gvkey year using "$data/tfpr", keep(1 3) nogen

* industry IV
merge m:1 gvkey using "$data/instrument_firm_bartik_naics", keep(1 3) nogen

*market share
destring sic naics, replace
*gen sic3=int(sic/10)
gen naics4=int(naics/100)
gen naics5=int(naics/10)
bysort $msnaics year: egen indsale=sum(sale)
drop naics4 naics5
*CHANGE level not log
gen marketshare_naics=sale/indsale

tsset gvkey year
gen markup = log(revt/cogs)
gen markup2 = log(revt/xopr)
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

* adding two lines below ######
replace txditc=0 if txditc<0 | txditc==.
replace prcc_f=prcc_c if prcc_f==.

gen tobinq=(csho*prcc_f+at-ceq-txditc)/at
gen salesgrowth=logsale - L.logsale
gen leverage_market = (dltt+dlc)/ (at- ceq + csho * prcc_f)

*****
keep if year==$year1 | year==$year2 | year==$year3 | year==$year4


global varlist markup markup2 logemp emp logsale roa ros logsaleperworker sga_norm logsga logcogs logxopr logrd rdnorm cashnorm sale marketshare_naics tfpr tobinq salesgrowth age leverage_market

keep czone gvkey year $varlist log* comnam state

reshape wide $varlist comnam, i(gvkey) j(year)

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

cap drop year
gen year=2005
merge m:1 czone year using "$data/cz_employment_2005_2017", keep(1 3) keepus(population share_foreignborn) nogen
rename population  population2005

merge m:1 czone   using "$data/cz_employment_$control_year", keep(1 3)  nogen


*** merge dorn data to get state and to get share foreign 
gen yr =2000
merge m:1 czone yr using "$data/workfile_china", keep(1 3) keepus(statefip l_sh_popfborn l_sh_routine33  reg_midatl reg_encen reg_wncen reg_satl reg_escen reg_wscen reg_mount reg_pacif d_tradeusch_pw) nogen
cap drop yyr
*tab statefip
*sum l_sh_popfborn l_sh_routine33, d

*tech employment share
merge m:1 czone using "$data/share_tech_qwi", keep(1 3) nogen



merge m:1 gvkey using "$data/sic", keep(1 3) nogen
gen sic2 = int(sic/100)

gen log_njob2010=log(njob_nonai2010)



*********************************************************
******  DROP OBERVATIONS NOT IN THE SAMPLE	*********
*********************************************************

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
reghdfe d_share_narrowai     [aw=weight] if (njob_nonai2010>1 & itsector==0), a($fevar) cluster($clustervar)

***** generate sample dummy : include firms with over 1 jobs and AI producers
gen include  = (  e(sample)   ==  1)
tab include 
 
sum d_share_narrowai if  include==1, d
*we are dropping those not in ols regression sample XXX
drop if include != 1 

 
*********************************************************
******  WINSORIZE AND DO OTHER MANIPULATIONS	*********
*********************************************************



*** winsorize
global depvar d_share_narrowai d_logemp d_logsale d_markup d_markup2 d_sga_norm d_roa d_ros /*
*/d_logsaleperworker d_logsga d_logcogs d_logxopr d_logrd d_rdnorm  logsale2010  cashnorm2010 rdnorm2010 roa2010 ros2010 markup2010 markup22010  logsaleperworker2010 tfpr2010

if $winsor ==1 {

foreach var in $depvar {
sum `var', d
replace `var'=r(p99) if `var'>r(p99)&`var'<. & include == 1
replace `var'=r(p1) if `var'<r(p1) & include == 1
sum `var', d
}

}
 

** standardize  IV measure
sum d_share_narrowai, d

egen 	d_share_narrowai_temp = std(d_share_narrowai) 
drop 	d_share_narrowai
rename 	d_share_narrowai_temp d_share_narrowai


local StatsVars  logsale2010  cashnorm2010 rdnorm2010 tfpr2010 markup2010 tobinq2010 leverage_market2010 roa2010 age2010

lab var logsale2010 "Log Sales 2010"
lab var logemp2010 "Log Employment 2010"
lab var marketshare_naics2010 "Market Share 2010"
lab var cashnorm2010 "Cash/Assets 2010"
lab var rdnorm2010 "R\&D/Sales 2010"
lab var roa2010 "ROA 2010"
lab var ros2010 "ROS 2010"
lab var markup2010 "Log Markup 2010"
lab var markup22010 "Log Markup (Total Exp) 2010"
lab var tfpr2010 "Revenue TFP 2010"
lab var logsaleperworker2010 "Log Sales per Worker 2010"
lab var tobinq2010 "Tobin's Q 2010"
lab var age2010 "Firm Age 2010"
lab var leverage_market2010 "Market Leverage 2010"


**************************************************************************
**************************************************************************
************** Table 2 : Which firms adopt? ***************** 
************************************************************************* 
************************************************************************** 

drop if logemp2010==. | logsale2010==.

local 	X 		d_share_narrowai

* keeping the sample consistent across all columns ######
reghdfe `X' `StatsVars' [aw=njob2010] , absorb($fevar) cluster($clustervar)
gen validobs  = (  e(sample)   ==  1)

eststo clear

foreach var in `StatsVars' {
*old ###### eststo: reghdfe `X' `var' [aw=njob2010] , absorb($fevar) vce(robust) 
eststo: reghdfe `X' `var' [aw=njob2010] if validobs, absorb($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
}

*old ###### eststo: reghdfe `X' `StatsVars' [aw=njob2010] , absorb($fevar) vce(robust) 
eststo: reghdfe `X' `StatsVars' [aw=njob2010] if validobs, absorb($fevar) cluster($clustervar)
estadd local naics2_fe "Y"

esttab using "$table/original/adoption_`data'_naics2.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
stats(naics2_fe r2_a N , fmt(0 %9.3fc %9.0fc ) labels("Industry FE" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
drop(_cons)  ///
mgroups("$\Delta$ Share of AI Workers,  2010--2018", pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


}







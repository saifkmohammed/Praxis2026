                  *************************************************************
* Main Code for:
* 
* Control general IT and robots
* 
*************************************************************

*bg or cognism
foreach data in cognism bg {

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

*****
keep if year==$year1 | year==$year2 | year==$year3 | year==$year4


global varlist markup markup2 logemp emp sale logsale roa ros logsaleperworker sga_norm logsga logcogs logxopr logrd rdnorm /*
*/ cashnorm marketshare_naics tfpr lernerindex age

keep czone gvkey year $varlist log* comnam state

reshape wide $varlist comnam, i(gvkey) j(year)

foreach var in $varlist {
gen d_`var'=`var'$year2-`var'$year1
gen d_`var'_pre = `var'$year4-`var'$year3
}

gen year=2010

merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob_robot) keep(1 3) nogen

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob njob_narrowai) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_it", keepus(njob_it) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_data", keepus(njob_data njob_dataanalysis) keep(1 3) nogen
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp) keep(3) nogen
gen njob_bg=njob
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_it", keepus(njob njob_it) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_data", keepus(njob_data njob_dataanalysis) keep(1 3) nogen
ren njob njob_bg
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<20
drop maxnjob
}

gen share_narrowai2010 = njob_narrowai/njob
gen share_robot2010 = njob_robot/njob_bg
gen share_it2010 = njob_it/njob_bg
gen share_data2010=njob_data/njob_bg
gen share_dataana2010=njob_dataanalysis/njob_bg
gen njob_nonai2010 = njob-njob_narrowai
gen weight = njob
rename njob njob2010 
rename njob_narrowai njob_narrowai2010
rename njob_it njob_it2010
rename njob_robot njob_robot2010
rename njob_data njob_data2010
rename njob_dataanalysis njob_dataana2010
drop njob_bg

replace year=$year2

merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob_robot) keep(1 3) nogen

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob njob_narrowai) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_it", keepus(njob_it) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_data", keepus(njob_data njob_dataanalysis) keep(1 3) nogen
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp) keep(3) nogen
gen njob_bg=njob
}

if "`data'"=="cognism" {
merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_it", keepus(njob njob_it) keep(1 3) nogen
merge 1:1 gvkey year using "$data/bg_compustat_data", keepus(njob_data njob_dataanalysis) keep(1 3) nogen
ren njob njob_bg
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<20
drop maxnjob
}

gen share_narrowai2018 = njob_narrowai/njob
gen share_robot2018 = njob_robot/njob_bg
gen share_it2018 = njob_it/njob_bg
gen share_data2018=njob_data/njob_bg
gen share_dataana2018=njob_dataanalysis/njob_bg

rename njob njob2018 
rename njob_it njob_it2018
rename njob_narrowai njob_narrowai2018
rename njob_robot njob_robot2018
rename njob_data njob_data2018
rename njob_dataanalysis njob_dataana2018

replace year=$year5

if "`data'"=="bg" {
merge 1:1 gvkey year using "$data/bg_compustat_allai", keepus(njob njob_narrowai) keep(1 3) nogen
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
gen d_share_it = share_it2018 - share_it2010
gen d_share_robot = share_robot2018 - share_robot2010
gen d_share_data = share_data2018 - share_data2010
gen d_share_dataana = share_dataana2018 - share_dataana2010


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
*gen itsector = (naics3==334 | naics3==511 | naics3==516 | naics3==518 | naics4==5415)
*1400
reg d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  if (njob_nonai2010>1 & itsector==0)
* 1400
reghdfe d_logemp d_share_narrowai log_njob2010 cashnorm2010 logsale2010  [aw=weight] if (njob_nonai2010>1 & itsector==0), a($fevar) cluster($clustervar)

***** generate sample dummy : include firms with over 1 jobs and AI producers
*gen include  = (  e(sample)   ==  1)
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
*/ d_logsaleperworker d_logsga d_logcogs d_logxopr d_logrd d_rdnorm d_tfpr markup2010 /*
*/ d_share_it d_share_robot d_share_data d_share_dataana
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

sum d_share_narrowai, d

egen 	d_share_it_temp = std(d_share_it)
drop 	d_share_it
rename 	d_share_it_temp d_share_it

egen 	d_share_robot_temp = std(d_share_robot)
drop 	d_share_robot
rename 	d_share_robot_temp d_share_robot

egen 	d_share_data_temp = std(d_share_data)
drop 	d_share_data
rename 	d_share_data_temp d_share_data

egen 	d_share_dataana_temp = std(d_share_dataana)
drop 	d_share_dataana
rename 	d_share_dataana_temp d_share_dataana

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
lab var d_logsale_pre "2000-2008 sales change"
lab var d_logemp_pre "2000-2008 emp change"
lab var d_marketshare_naics  "Market Share"
lab var d_share_narrowai "$\Delta$ Share AI Workers"
lab var d_share_it  "$\Delta$ Share Non-AI IT Workers"
lab var d_share_robot "$\Delta$ Share Robot Workers"
lab var d_share_data "$\Delta$ Share Non-AI Data Workers"
lab var d_share_dataana "$\Delta$ Share Non-AI Data Analysis Workers"
lab var d_tfpr "Revenue TFP"
lab var d_markup "$\Delta$ Markup (COGS)"
lab var d_markup2 "$\Delta$ Markup (Total Exp)"
lab var d_logcogs "$\Delta$ Log COGS"
lab var d_logxopr "$\Delta$ Log Operating Expense"

*********************************************************
**************** Table 	A15	***************** 
*********************************************************
**********************************************************

eststo clear

foreach Z in d_share_it d_share_robot d_share_data d_share_dataana {

foreach Y in d_logsale d_logemp {


eststo:  reghdfe `Y' `X'   $control $control2 `Z' [aw=weight] if include == 1, a($fevar) cluster($clustervar)
estadd local naics2_fe "Y"
estadd local control "Y"

}
}
	
esttab using "$table/original/table_`data'_controlitrobot.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X' d_share_it d_share_robot d_share_data*) ///
stats(naics2_fe control r2_a N , fmt(0 0 %9.3fc %9.0fc ) labels("Industry FE" "Controls" "Adj R-Squared" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("Sales" "Employment" "Sales" "Employment" "Sales" "Employment" "Sales" "Employment", pattern(1 1 1 1 1 1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 






}



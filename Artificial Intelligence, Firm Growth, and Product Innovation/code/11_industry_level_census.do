
global year1 2012
global year2 2017
global year3 2000
global year4 2008
global year5 2014

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
gen logsaleperworker = log(sale/emp)
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


global varlist markup markup2 logemp emp sale logsale roa ros logsaleperworker sga_norm logsga logcogs logxopr logrd rdnorm fluid selffluid cashnorm marketshare_naics tfpr lernerindex tobinq logtm logtm2 tmoversale logtm_3yr logtm_3yr2 tmoversale_3yr logprodpat1_fyear logprodpat2_fyear logprodpat1_iyear logprodpat2_iyear logprocesspat1_fyear logprocesspat2_fyear logprocesspat1_iyear logprocesspat2_iyear logmv age

keep czone gvkey year $varlist log* comnam state npatent_pre ntrademark_pre

reshape wide $varlist comnam npatent_pre ntrademark_pre, i(gvkey) j(year)

foreach var in $varlist {
gen d_`var'=`var'$year2-`var'$year1
gen d_`var'_pre = `var'$year4-`var'$year3
}

gen year=$year1

merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<20
drop maxnjob

gen share_narrowai$year1 = njob_narrowai/njob
gen njob_nonai$year1 = njob-njob_narrowai
gen weight = njob
rename njob njob$year1 
rename njob_narrowai njob_narrowai$year1

replace year=$year2

merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<20
drop maxnjob

gen share_narrowai$year2  = njob_narrowai/njob

rename njob njob$year2  
rename njob_narrowai njob_narrowai$year2 

replace year=$year5

merge 1:1 gvkey year using "$cognismdata", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
*drop if maxnjob<50
drop maxnjob

gen share_narrowai2014 = njob_narrowai/njob
drop njob njob_narrowai


gen d_share_narrowai = share_narrowai$year2  - share_narrowai$year1
gen d_share_narrowai_pre2014 = share_narrowai2014 - share_narrowai$year1
gen d_share_narrowai_post2014 = share_narrowai$year2  - share_narrowai2014


cap drop year
gen year=2005
merge m:1 czone year using "$data/cz_employment_2005_2017", keep(1 3) keepus(population share_foreignborn) nogen
rename population  population2005

merge m:1 czone   using "$data/cz_employment_$control_year", keep(1 3)  nogen

gen yr =2000
merge m:1 czone yr using "$data/workfile_china", keep(1 3) keepus(statefip l_sh_popfborn l_sh_routine33  reg_midatl reg_encen reg_wncen reg_satl reg_escen reg_wscen reg_mount reg_pacif d_tradeusch_pw) nogen
cap drop yyr
tab statefip
sum l_sh_popfborn l_sh_routine33, d

*tech employment share
merge m:1 czone using "$data/share_tech_qwi", keep(1 3) nogen

merge m:1 gvkey using "$data/sic", keep(1 3) nogen
gen sic2 = int(sic/100)

gen log_njob$year1 =log(njob_nonai$year1)

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
reg d_logemp d_share_narrowai log_njob$year1 cashnorm$year1 logsale$year1  if (njob_nonai$year1 >1 & itsector==0)
reghdfe d_logemp d_share_narrowai log_njob$year1 cashnorm$year1 logsale$year1  [aw=weight] if (njob_nonai$year1 >1 & itsector==0), a($fevar) cluster($clustervar)

gen include  = (  e(sample)   ==  1 & log_njob$year1!=. & cashnorm$year1 !=. & logsale$year1!=. &  log_wage2010 !=. &  share_college!=. &  log_wage_industry!=. & markup$year1!=. &  d_tradeusch_pw!=. & share_computerocc$control_year !=. & log_population$control_year !=. & share_female!=. & share_manufacturing!=. & share_finance!=. & share_foreignborn!=. & l_sh_popfborn!=. & l_sh_routine33!=. )
tab include 
sum d_share_narrowai if  include==1, d
drop if include == 0

cap drop d_share_narrowai_zero
gen d_share_narrowai_zero = (d_share_narrowai ==0 )
tab d_share_narrowai_zero 
cap drop d_share_narrowai_zeroneg 
gen d_share_narrowai_zeroneg = (d_share_narrowai ==0  |  (d_share_narrowai < 0 & d_share_narrowai~=. ) )
tab d_share_narrowai_zeroneg 
list comnam$year1 d_share_narrowai emp* logemp$year1 logemp$year2   if  d_share_narrowai < 0 & d_share_narrowai~=. 

*** winsorize
global depvar d_share_narrowai d_logemp d_logsale d_markup d_markup2 d_sga_norm d_roa d_ros d_lernerindex /*
*/ d_logsaleperworker d_logsga d_logcogs d_logxopr d_logrd d_rdnorm d_tfpr markup$year1 /*
*/ logsale$year1  cashnorm$year1 rdnorm$year1 roa$year1 ros$year1 markup2$year1 tobinq$year1 /*
*/ d_fluid d_selffluid d_logtm d_logtm2 d_tmoversale d_logtm_3yr d_logtm_3yr2 d_tmoversale_3yr /*
*/ d_logprodpat1_fyear d_logprodpat2_fyear d_logprodpat1_iyear d_logprodpat2_iyear d_logprocesspat1_fyear d_logprocesspat2_fyear d_logprocesspat1_iyear d_logprocesspat2_iyear d_logmv
gen markup$year1_original =markup$year1
sum markup$year1
replace markup$year1 =r(mean) if markup$year1 ==.

if $winsor ==1 {

foreach var in $depvar {
sum `var', d
replace `var'=r(p99) if `var'>r(p99)&`var'<.
replace `var'=r(p1) if `var'<r(p1)
sum `var', d
}

}
//

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

sum d_share_narrowai [aw=weight], d

gen byte ai_invest_pos = (d_share_narrowai> r(p75) & d_share_narrowai<.)

sum d_share_narrowai , d

gen byte ai_invest_top10 = (d_share_narrowai >= r(p90) & d_share_narrowai<.)

egen 	d_share_narrowai_temp = std(d_share_narrowai)
drop 	d_share_narrowai
rename 	d_share_narrowai_temp d_share_narrowai

sum d_share_narrowai, d


egen 	d_share_narrowai_pre2014_temp = std(d_share_narrowai_pre2014)
drop 	d_share_narrowai_pre2014
rename 	d_share_narrowai_pre2014_temp d_share_narrowai_pre2014

sum d_share_narrowai, d

****** 	OLS	***************** 
eststo clear

local 	X 		d_share_narrowai
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
lab var cashnorm$year1  "Cash/Assets 2010"
lab var logsale$year1  "Log Sales 2010"
lab var d_logsale_pre "1999-2007 sales change"
lab var d_logemp_pre "1999-2007 emp change"
lab var d_share_narrowai "$\Delta$ Share AI Workers"
lab var d_tfpr "Revenue TFP"
lab var d_markup "$\Delta$ Markup (COGS)"
lab var d_markup2 "$\Delta$ Markup (Total Exp)"
lab var d_logcogs "$\Delta$ Log COGS"
lab var d_logxopr "$\Delta$ Log Operating Expense"
lab var logsale$year1  "Log Sales 2010"
lab var logemp$year1  "Log Employment 2010"
lab var cashnorm$year1  "Cash/Assets 2010"
lab var rdnorm$year1  "R\&D/Sales 2010"
lab var roa$year1  "ROA 2010"
lab var ros$year1  "ROS 2010"
lab var markup$year1  "Log Markup (COGS) 2010"
lab var markup2$year1  "Log Markup (Total Exp) 2010"
lab var tobinq$year1  "Tobin's Q 2010"

*********************************************************
**************** Industry level ***************** 
*********************************************************
**********************************************************

local indlevel naics5

foreach year in $year1  $year2 {
foreach var in markup markup2 tfpr {
bysort `indlevel': egen totalweight`year'=sum((`var'`year'!=.)*sale`year')
bysort `indlevel': egen total`year'=sum(`var'`year'*sale`year')
gen `var'_`year' = total`year'/totalweight`year'
drop total`year' totalweight`year'
}
}

eststo clear
collapse (sum) njob$year1  njob$year2  njob_narrowai$year1  njob_narrowai$year2  emp$year1  emp$year2  sale$year1  sale$year2  /*
*/ emp$year3 emp$year4 sale$year3 sale$year4 (mean) naics2 markup_* markup2_* tfpr_* log_wage2010 , by(`indlevel')

gen d_emp=log(emp$year2 /emp$year1 )
gen d_sale=log(sale$year2 /sale$year1 )
gen d_share_narrowai = njob_narrowai$year2 /njob$year2 -njob_narrowai$year1 /njob$year1 
gen d_markup=markup_$year2 -markup_$year1 
gen d_markup2=markup2_$year2 -markup2_$year1 
gen d_tfpr=tfpr_$year2 -tfpr_$year1 
gen d_logsaleperworker=log(sale$year2 /emp$year2 )-log(sale$year1 /emp$year1 )

gen d_emp_pre=log(emp$year4 / emp$year3 )
gen d_sale_pre=log(sale$year4 /sale$year3 )
gen logsale$year1 =log(sale$year1 )
gen logemp$year1 =log(emp$year1 )

*** standardize independent variable &  IV ***

sum d_share_narrowai, d

egen 	d_share_narrowai_temp = std(d_share_narrowai)
drop 	d_share_narrowai
rename 	d_share_narrowai_temp d_share_narrowai
sum d_share_narrowai, d

lab var d_share_narrowai "$\Delta$ Share AI Workers"

local 	X 		d_share_narrowai
global controlind  logsale$year1  markup_$year1  markup2_$year1  logemp$year1  log_wage2010

*keep if controls are non-missing
keep if markup_$year1 !=.&markup2_$year1 !=.&log_wage2010 !=.

**************************************************************
****************Table A30: Census ***************** 
****************************************************************

*change years to 2012 and 2017

merge 1:1 `indlevel' using "$data/sales_naics5_wide", keep(1 3) nogen
merge 1:1 `indlevel' using "$data/concentration_naics5_wide", keep(1 3) nogen

foreach var in d_logsale_census d_logemp_census d_largest4 d_largest8 d_largest20 d_hhindex {
sum `var', d
replace `var'=r(p99) if `var'>r(p99)&`var'<.
replace `var'=r(p1) if `var'<r(p1)
sum `var', d
}

foreach var in d_largest4 d_largest8 d_largest20 {
	replace `var'=`var'/100
}
replace d_hhindex=d_hhindex/1000

eststo clear

foreach Y in d_logsale_census d_logemp_census d_hhindex d_largest8 {
	
eststo: reghdfe `Y' d_share_narrowai [aw=njob$year1 ], a(naics2) vce(robust)
estadd local naics2_fe "Y"
estadd local control "N"

eststo: reghdfe `Y' d_share_narrowai $controlind [aw=njob$year1 ], a(naics2) vce(robust)
estadd local naics2_fe "Y"
estadd local control "Y"

}


esttab using "$table/original/table_concentration_census_`data'.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(`X') ///
stats(naics2_fe control   N , fmt(0 0   %9.0fc ) labels("Industry Sector FE" "Controls" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("Log Sales" "Log Employment" "HHI" "4 Largest Firms Sales Share", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


global year1 2010
global year2 2018
global year3 2000
global year4 2008
global year5 2014

















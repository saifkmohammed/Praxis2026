
**************************************************************************
**************************************************************************
************** Figure 1 ***************** 
************************************************************************* 
************************************************************************** 


*Panel a

use "$cognismdata", clear

merge m:1 gvkey using "$data/crsp_shrcd", keep(3)
keep if exchcd>0 & exchcd<4 & ( shrcd<14 | shrcd==18 | shrcd==31 )

collapse (sum) aiempl totalempl, by(year)
gen share_narrow=aiempl/totalempl

lab var share_narrow "Share of AI workers"

tw connected share_narrow year if year>2006 & year<2019, ytitle(Share of AI workers) xlabel(2007(1)2018)  /*
*/ ylabel(0(0.0005)0.0030) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) 


*Panel b


use "$data/bg_compustat_allai", clear

merge m:1 gvkey using "$data/crsp_shrcd", keep(3)
keep if exchcd>0 & exchcd<4 & ( shrcd<14 | shrcd==18 | shrcd==31 )

collapse (mean) share_allai (sum) njob njob_narrowai, by (year)

replace njob_narrow=njob_narrow/njob
lab var njob_narrow "Share of AI workers"

tw (connected njob_narrow year), ytitle("Share of AI workers") xlabel(2007(1)2018)  /*
*/ graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) 



**************************************************************************
**************************************************************************
************** Figure 2 ***************** 
************************************************************************* 
************************************************************************** 


*Panel a

use "$cognismdata", clear
ren aiempl njob_narrowai
ren totalempl njob

merge m:1 gvkey using "$data/crsp_shrcd", keep(3) nogen
keep if exchcd>0 & exchcd<4 & ( shrcd<14 | shrcd==18 | shrcd==31 )

merge m:1 gvkey using "$data/naics2", keep(3) nogen
replace naics2=31 if naics2==32 | naics2==33
replace naics2=44 if naics2==45
replace naics2=48 if naics2==49
drop if naics2==99

collapse (sum) njob njob_narrowai, by (naics2 year) 

gen share=njob_narrow/njob

gen period=1 if year<2015
replace period=2 if year>=2015
collapse (mean) share* (sum) njob*, by(naics2 period)
reshape wide share* njob*, i(naics2) j(period)

gen ind="Accomodation & Food Svcs" if naics2==72
replace ind= "Admin Support" if naics2==56
replace ind = "Agriculture" if naics2==11
replace ind = "Arts/Entertainment" if naics2== 71
replace ind = "Construction" if naics2==23
replace ind = "Education Svcs" if naics2==61
replace ind = "Finance/Insurance" if naics2==52
replace ind = "Health Care" if naics2==62
replace ind = "Information" if naics2==51
replace ind = "Manufacturing" if naics2==31
replace ind = "Mining" if naics2==21
replace ind = "Other Svcs" if naics2==81
replace ind = "Prof & Business Svcs" if naics2==54
replace ind = "Real Estate" if naics2==53
replace ind = "Retail Trade" if naics2==44
replace ind = "Transportation/Warehousing" if naics2==48
replace ind = "Utilities" if naics2==22
replace ind = "Wholesale" if naics2==42

graph hbar share1 share2, over(ind, lab(labsize(small))) /*
*/ graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ legend(label(1 "2007-2014") label(2 "2015-2018")) bar(1, fcolor("navy") lcolor(black) lwidth(vvthin)) bar(2, fcolor("255 197 1") lcolor(black) lwidth(vvthin))


*Panel b


use "$data/bg_compustat_allai", clear

merge m:1 gvkey using "$data/crsp_shrcd", keep(3) nogen
keep if exchcd>0 & exchcd<4 & ( shrcd<14 | shrcd==18 | shrcd==31 )

merge m:1 gvkey using "$data/naics2", keep(3) nogen
replace naics2=31 if naics2==32 | naics2==33
replace naics2=44 if naics2==45
replace naics2=48 if naics2==49
drop if naics2==99

collapse (sum) njob njob_narrowai (mean) share_narrowai, by (naics2 year) 

gen share=njob_narrow/njob

gen period=1 if year<2015
replace period=2 if year>=2015
collapse (mean) share* (sum) njob*, by(naics2 period)
reshape wide share* njob*, i(naics2) j(period)

gen ind="Accomodation & Food Svcs" if naics2==72
replace ind= "Admin Support" if naics2==56
replace ind = "Agriculture" if naics2==11
replace ind = "Arts/Entertainment" if naics2== 71
replace ind = "Construction" if naics2==23
replace ind = "Education Svcs" if naics2==61
replace ind = "Finance/Insurance" if naics2==52
replace ind = "Health Care" if naics2==62
replace ind = "Information" if naics2==51
replace ind = "Manufacturing" if naics2==31
replace ind = "Mining" if naics2==21
replace ind = "Other Svcs" if naics2==81
replace ind = "Prof & Business Svcs" if naics2==54
replace ind = "Real Estate" if naics2==53
replace ind = "Retail Trade" if naics2==44
replace ind = "Transportation/Warehousing" if naics2==48
replace ind = "Utilities" if naics2==22
replace ind = "Wholesale" if naics2==42

*continuous measure
graph hbar share_narrowai1 share_narrowai2, over(ind, lab(labsize(small))) /*
*/ graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ legend(label(1 "2007-2014") label(2 "2015-2018")) bar(1, fcolor("navy") lcolor(black) lwidth(vvthin)) bar(2, fcolor("255 197 1") lcolor(black) lwidth(vvthin))

graph hbar share1 share2, over(ind, lab(labsize(small))) /*
*/ graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) /*
*/ legend(label(1 "2007-2014") label(2 "2015-2018")) bar(1, fcolor("navy") lcolor(black) lwidth(vvthin)) bar(2, fcolor("255 197 1") lcolor(black) lwidth(vvthin))


**************************************************************************
**************************************************************************
************** Figure 3 ***************** 
************************************************************************* 
************************************************************************** 


*number of lags (post period)
local nperiodlag 5

*number of leads (pre period)
local nperiodlead 2 
 
use "$compustatdata", clear
merge m:1 gvkey using "$data/iv/reg_sample_cognism2021", keep(3) keepus(yr) nogen
ren fyear year

merge 1:1 gvkey year using "$data/tfpr", keep(1 3) nogen

destring sic naics, replace
gen sector = int(naics/10000)
gen naics4 = int(naics/100)
gen naics2 = sector
gen naics3	=int(naics/1000)
gen naics5	=int(naics/10)
bysort naics5 year: egen indsale=sum(sale)
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
egen statenum=group(state)
gen logmv=log(at+csho*prcc_f-txditc)

merge 1:1 gvkey year using "$data/ai_firm_map", keepus(aiemp total) keep(1 3) nogen
ren aiempl njob_narrowai
ren totalempl njob
bysort gvkey: egen maxnjob=max(njob)
drop if maxnjob<50
drop maxnjob

gen share_narrowai = njob_narrowai/njob
gen njob_nonai = njob-njob_narrowai
gen weight = njob

gen log_njob=log(njob_nonai)

*create lags and leads

tsset gvkey year

forv i=`nperiodlead'(-1)1 {
gen d_share_narrowai_lead`i' = F`i'.share_narrowai-L.F`i'.share_narrowai
}

forv i=0/`nperiodlag' {
gen d_share_narrowai_lag`i' = L`i'.share_narrowai-L.L`i'.share_narrowai
}

gen itsector = (sector==51 | sector==54)

reghdfe logemp d_share_narrowai*  [aw=weight] if (njob_nonai>1 & itsector==0 & year>2009), a(sector#year gvkey) cluster($clustervar)
gen include  = (  e(sample)   ==  1)
drop if include == 0

*** winsorize
global depvar logsale logemp marketshare logmv

foreach var in $depvar {
sum `var', d
replace `var'=r(p99) if `var'>r(p99)&`var'<.
replace `var'=r(p1) if `var'<r(p1)
sum `var', d
}

forv i=0/`nperiodlag' {
sum d_share_narrowai_lag`i', d
replace d_share_narrowai_lag`i'=r(p99) if d_share_narrowai_lag`i'>r(p99)&d_share_narrowai_lag`i'<.
replace d_share_narrowai_lag`i'=r(p1) if d_share_narrowai_lag`i'<r(p1)
sum d_share_narrowai_lag`i', d
}

forv i=1/`nperiodlead' {
sum d_share_narrowai_lead`i', d
replace d_share_narrowai_lead`i'=r(p99) if d_share_narrowai_lead`i'>r(p99)&d_share_narrowai_lead`i'<.
replace d_share_narrowai_lead`i'=r(p1) if d_share_narrowai_lead`i'<r(p1)
sum d_share_narrowai_lead`i', d
}
//


forv i=`nperiodlead'(-1)1 {
sum d_share_narrowai_lead`i', d
egen 	d_share_narrowai_temp = std(d_share_narrowai_lead`i')
drop 	d_share_narrowai_lead`i'
rename 	d_share_narrowai_temp d_share_narrowai_lead`i'
lab var d_share_narrowai_lead`i' "Change in Share of AI Workers `i' Years Later"
}

forv i=0/`nperiodlag' {
sum d_share_narrowai_lag`i', d
egen 	d_share_narrowai_temp = std(d_share_narrowai_lag`i')
drop 	d_share_narrowai_lag`i'
rename 	d_share_narrowai_temp d_share_narrowai_lag`i'
lab var d_share_narrowai_lag`i' "Change in Share of AI Workers `i' Years Ago"

}

eststo clear
lab var logemp "Log employment"
lab var logsale "Log sales"
lab var marketshare "Market share"

foreach y in logsale logemp logmv {
 eststo: reghdfe `y' d_share_narrowai*  [aw=weight], a(sector#year statenum#year gvkey) cluster($clustervar)

}
















****************************************
****Table 10: Predict future hiring*********************
****************************************

use "$data/iv/edu_hiring", clear

keep if year<=2010
bysort gvkey university_herds: egen sum1=sum(all_grads)
bysort gvkey: egen sum2=sum(all_grads)
gen share_pre2010=sum1/sum2
bysort gvkey university_herds: egen sum3=sum(stem_grads)
bysort gvkey: egen sum4=sum(stem_grads)
gen share_pre2010_stem=sum3/sum4
collapse share_pre2010*, by (gvkey university_herds)
merge 1:m gvkey university_herds using "$data/iv/edu_hiring", nogen
keep if year>2010
drop if university_herds==.
bysort gvkey university_herds: egen sum1=sum(all_grads)
bysort gvkey: egen sum2=sum(all_grads)
gen share_post2010=sum1/sum2
bysort gvkey university_herds: egen sum3=sum(stem_grads)
bysort gvkey: egen sum4=sum(stem_grads)
gen share_post2010_stem=sum3/sum4
bysort gvkey university_herds: egen sum5=sum(ai_grads)
bysort gvkey: egen sum6=sum(ai_grads)
gen share_post2010_ai=sum5/sum6
collapse share_pre2010* share_post2010*, by (gvkey university_herds)
replace share_pre2010=0 if share_pre2010==.
replace share_pre2010_stem=0 if share_pre2010_stem==.

merge 1:1 gvkey university_herds using "$data/iv/edu_stock_2010_unique", keep(1 3) nogen
bysort gvkey: egen total=sum(all_grads)
bysort gvkey: egen totalstem=sum(stem_grads)
gen share_2010=all_grads/total
gen share_2010_stem=stem_grads/totalstem
replace share_2010=0 if share_2010==.
replace share_2010_stem=0 if share_2010_stem==.

reg share_post2010 share_pre2010
reghdfe share_post2010 share_pre2010, a(gvkey)
reghdfe share_post2010 share_pre2010, a(gvkey university_herds)
reghdfe share_post2010 share_pre2010, a(gvkey university_herds) cluster(gvkey)
reghdfe share_post2010 share_pre2010, a(gvkey university_herds) cluster(university_herds)

reg share_post2010_ai share_pre2010
reghdfe share_post2010_ai share_pre2010, a(gvkey)
reghdfe share_post2010_ai share_pre2010, a(gvkey university_herds)
reghdfe share_post2010_ai share_pre2010, a(gvkey university_herds) cluster(gvkey)
reghdfe share_post2010_ai share_pre2010, a(gvkey university_herds) cluster(university_herds)

reg share_post2010_ai share_pre2010_stem
reghdfe share_post2010_ai share_pre2010_stem, a(gvkey)
reghdfe share_post2010_ai share_pre2010_stem, a(gvkey university_herds)

lab var share_pre2010 "Share of Pre-2010 Hires"
lab var share_pre2010_stem "Share of Pre-2010 STEM Hires"
lab var share_2010 "Share of 2010 Workers"
lab var share_2010_stem "Share of 2010 STEM Workers"

eststo clear

eststo: reghdfe share_post2010 share_pre2010, a(gvkey university_herds) cluster(university_herds)
estadd local firm_fe "Y"
estadd local uni_fe "Y"

eststo: reghdfe share_post2010 share_2010, a(gvkey university_herds) cluster(university_herds)
estadd local firm_fe "Y"
estadd local uni_fe "Y"

eststo: reghdfe share_post2010_ai share_pre2010, a(gvkey university_herds) cluster(university_herds)
estadd local firm_fe "Y"
estadd local uni_fe "Y"

eststo: reghdfe share_post2010_ai share_2010, a(gvkey university_herds) cluster(university_herds)
estadd local firm_fe "Y"
estadd local uni_fe "Y"

eststo: reghdfe share_post2010_ai share_pre2010_stem, a(gvkey university_herds) cluster(university_herds)
estadd local firm_fe "Y"
estadd local uni_fe "Y"

eststo: reghdfe share_post2010_ai share_2010_stem, a(gvkey university_herds) cluster(university_herds)
estadd local firm_fe "Y"
estadd local uni_fe "Y"

esttab using "$table/original/university_network.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(share*) ///
stats(firm_fe uni_fe N , fmt(0 0 %9.0fc ) labels("Firm FE" "University FE" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("Share of Post-2010 Hires" "Share of Post-2010 AI Hires", pattern(1 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


****************************************
****Table 11: predict AI hiring*********************
****************************************


use "$data/iv/edu_hiring", clear
drop if university_herds==.
collapse (sum) all_grads stem_grads ai_grads, by (university gvkey year)

merge m:1 university_herds using "$data/iv/Reseracher_IV_uni_level", keep(3)

gen all_grads_aihub=all_grads if aihub_uni==1

collapse (sum) all_grads all_grads_aihub, by (gvkey year)

gen all_grads_2005=all_grads if year==2005
gen all_grads_2010=all_grads if year==2010
gen all_grads_aihub_2005=all_grads_aihub if year==2005
gen all_grads_aihub_2010=all_grads_aihub if year==2010

collapse (sum) all_grads*, by (gvkey)

gen d_share_aihub= all_grads_aihub_2010/all_grads_2010 - all_grads_aihub_2005/all_grads_2005

merge m:1 gvkey using "$data/reg_sample_cognism", keep(3) nogen 

merge 1:1 gvkey using "$data/uni_iv", keep(1 3) nogen

replace state="N" if state==""

lab var uni_iv_v4c "Instrument"

eststo clear 

eststo: reg d_share_aihub uni_iv_v4c, cluster(naics5)
estadd local cscontrol "N"
estadd local indfe "N"
estadd local control "N"
estadd local statefe "N"

eststo: reg d_share_aihub uni_iv_v4c uni_cs_v4c uni_top10, cluster(naics5)
estadd local cscontrol "Y"
estadd local indfe "N"
estadd local control "N"
estadd local statefe "N"

eststo: reghdfe d_share_aihub uni_iv_v4c uni_cs_v4c uni_top10, absorb(naics2) cluster(naics5)
estadd local cscontrol "Y"
estadd local indfe "Y"
estadd local control "N"
estadd local statefe "N"

eststo: reghdfe d_share_aihub uni_iv_v4c uni_cs_v4c uni_top10 $control $control2, absorb(naics2) cluster(naics5)
estadd local cscontrol "Y"
estadd local indfe "Y"
estadd local control "Y"
estadd local statefe "N"

eststo: reghdfe d_share_aihub uni_iv_v4c uni_cs_v4c uni_top10 $control $control2, absorb(naics2 state) cluster(naics5)
estadd local cscontrol "Y"
estadd local indfe "Y"
estadd local control "Y"
estadd local statefe "Y"

esttab using "$table/original/predict_university.tex", replace label f booktabs style(tex) alignment (c) nofloat ///
noobs nodepvars nomtitles ///
hlinechar(`=char(151)') ///
varwidth(30) modelwidth (12) collabels(none)  legend  ///
cells(b(star fmt(3)) se(par fmt(3)))   /// 
keep(uni_iv_v4c) ///
stats(cscontrol indfe control statefe N , fmt(0 0 %9.0fc ) labels("CS Control" "NAICS2 FE" "Baseline Control" "State FE" "Observations") ) ///
star(* 0.10 ** 0.05 *** 0.01)  ///
mgroups("$\Delta$ Share of Fresh Graduates Hired from AI Hubs 2005-2010", pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})  ) 


****************************************
****Figure 5*********************
****************************************


use "$data/iv/university_ai_post2010", clear
merge m:1 university_herds using "$data/iv/Reseracher_IV_uni_level", keepus(aihub_uni) keep(1 3) nogen
ren university_herds inst_id

merge m:1 inst_id using "$data/iv/instid_to_ipeds", keep(1 3) nogen
ren ipeds_unitid unitid 

collapse (sum) all_grads stem_grads ai_grads (max) aihub_uni, by (unitid year)
ren year academicyear

merge 1:1 unitid academicyear using "$data/iv/delta_public_00_12.dta", keep(1 3) nogen
ren academicyear year

*corr all_grads total_full_time totaldegrees if year==2010

*correlation of all grads with full time students
corr all_grads total_full_time
*correlation=0.67

*correlation of all grads with fte (including part-time)
corr all_grads fte_count
*correlation=0.64

foreach var in masterdegrees bachelordegrees doctordegrees {
	replace `var'=0 if `var'==.
}
gen fraction=all_grads/totaldegrees

*ratio of all grads in Cognism divided by all graduates in IPEDS
sum fraction, d

merge 1:1 unitid year using "$data/iv/herds_expenditure", keep(1 3) nogen

*correlation of all grads with total R&D expenditure
corr all_grads expenditure_all
*correlation=0.88

gen share_aigrads=ai_grads/all_grads
gen share_stemgrads=stem_grads/all_grads
gen share_computer=expenditure_computer/expenditure_all
*correlation of share of AI grads with share of computer science R&D expenditure
corr share_aigrads share_computer
*correlation=0.19

*correlation of share of STEM grads with share of computer science R&D expenditure
corr share_stemgrads share_computer
*correlation=0.15

collapse (sum) ai_grads all_grads stem_grads, by (year aihub_uni)
gen share_ai=ai_grads/all_grads

tw (connected share_ai year if aihub_uni==1) (connected share_ai year if aihub_uni==0, lp(dash)) if year>=2006 & year <=2018, legend(order(1 2) label(1 AI-strong universities) label(2 Non-AI-strong universities)) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) ytitle("Share of AI grads") xlab(2006(2)2018)

graph export "$draft/_figures/share_ai_aihub.pdf", as(pdf) replace



****************************************
****Figure 4*********************
****************************************


import delimited "$data/iv/ai_cs_uni_panel.csv", clear 

ren uni_name inst_name_long

merge m:1 inst_name_long using "$data/iv/Reseracher_IV_uni_level", keep(3) nogen

ren university_herds inst_id
merge m:1 inst_id using "$data/iv/instid_to_ipeds", keep(1 3) nogen
ren ipeds_unitid unitid 

collapse (sum) num* , by (unitid year)
ren year academicyear
merge 1:1 unitid academicyear using "$data/iv/delta_public_00_12.dta", keep(1 3) nogen
ren academicyear year
merge 1:1 unitid year using "$data/iv/herds_expenditure", keep(1 3) nogen

gen lognresearcher=log(num_ai+num_cs+num_other)
gen logexpenditure=log(expenditure_all)

corr lognresearcher logexpenditure

binscatter lognresearcher logexpenditure if year==2010, n(50) xtitle("Log R&D expenditure") ytitle("Log number of researchers")

graph export "$draft/_figures/mag_validation.pdf", as(pdf) replace



*========================================================================

* Artificial Intelligence, Firm Growth, and Product Innovation 

* Authors: T. Babina, A. Fedyk, A. He, J. Hodson

* Journal of Financial Economics (2023)

* MAIN Do-File for replication all results in the paper

*========================================================================
* Initialize Settings
*========================================================================


*install binscatter and latabstat
ssc install latab
ssc install binscatter
ssc install maptile

* Clear contents
qui {
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
}

* Define globals
qui {
    * Set random seed to make results exactly replicable for reghdfe
    * (Otherwise, results could differ in the third digit. Occassionally second digit as well)
    set seed 501924

    *cluster by
    global clustervar "naics5"

    *Fixed effect
    global fevar "naics2"

    *market share
    global msnaics "naics5"

    *years
    global control_year 2010
    global year1 2010
    global year2 2018
    global year3 2000
    global year4 2008
    global year5 2014

    *winsorize
    global winsor 1
}

* Project Directories
qui {
    * set directory to read/write data (ross, alex, tania)
    global name "alex"

    if ("$name"=="alex") {
        global dropbox "/Users/alexxihe/Dropbox"
        global project "$dropbox/AI/Code/AI replication"
    }

    if ("$name"=="tania") {
        global dropbox "~\\Dropbox"
        global project "${dropbox}/AI/Code/AI replication"
    }

    if ("$name"=="ross") {
        global project "/accounts/grad/ross.chu/Desktop/projects/gsr_fedyk/AIGrowthJFE"
    }

    global table         "$project/draft/_tables"
	global draft         "$project/draft"
    global data          "$project/data"
    global compustatdata "${data}/Compustat20200227"
    global cognismdata   "${data}/ai_firm_map_2021"
}

*basic controls
*old ###### global control log_njob2010 cashnorm2010 logsale2010 log_wage2010  share_college  log_wage_industry markup2010 rdnorm2010
global control log_njob2010 cashnorm2010 logsale2010 log_wage2010  share_college  log_wage_industry age2010

*additional controls
*old ###### global control2  d_tradeusch_pw share_computerocc2010 log_population2010 share_female share_manufacturing share_finance share_foreignborn l_sh_popfborn l_sh_routine33
global control2  share_computerocc2010 share_female share_manufacturing share_finance l_sh_popfborn l_sh_routine33

*========================================================================
* Run scripts to replicate results
*========================================================================

* Baseline Regressions: Tables 3, 4, 6, 8, 9, A5, A10, A13, A16, A17, A18, A25, A27, A29
do "$project/0_baseline_regression.do"

* Adoption of AI: Tables 2, A4
do "$project/1_tables_adoption.do"

* Instrumenting AI Adoption with university-level exposure: Tables 5, 7, 12, 13 + Figure A4
do "$project/2_uni_iv.do"

* Analysis by sector: Table A7
do "$project/3_bysector.do"

* Analysis for IT sector: Table A8
do "$project/3b_itsector.do"

* Continuous measures: Table A11 - Panel 1
do "$project/4a_continuous_measure_all.do"

* Continuous measures (narrow): Table A11 - Panel 2
do "$project/4b_continuous_measure_narrow.do"

* General Controls for IT industry: Table A15
do "$project/5_control_general_it.do"

* Software Industry: Table A14
do "$project/6_software.do"

* Cutoffs: Table A12
do "$project/7_cutoff.do"

* Robustness Checks: Table A6, A9
do "$project/8_robustness_jfe.do"

* Robustness Checks with IV: Tables 14, A20, A21, A22, A23, A26
do "$project/9_uni_iv_robustness.do"

* Split Periods: Table A19
do "$project/10_splitperiod.do"

* Industry-Level Census: Table A30
do "$project/11_industry_level_census.do"

* Instrument Checks: Figures 4, 5, Table 10, 11
do "$project/12_instrument_check.do"

* Figure 1, 2, 3
do "$project/13_figure.do"


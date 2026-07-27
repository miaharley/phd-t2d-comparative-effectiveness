/*==============================================================================
DO FILE NAME:			A4 - sex cumulative incidence.do

AUTHOR:					Mia Harley

VERSION:				v1

LAST UPDATED: 			10/2025								
					
DESCRIPTION OF FILE:	Creates adjusted cox kaplan meier plots
*=============================================================================*/

* Log
cap log close
log using $Logdir\A2b_sex_cumulative_incidence.log, replace

********************************************************************************
** Convert unadjusted cox model to risk at 3 years **
********************************************************************************
local outcome mace

* Overall
use "$Datadir/derived/study_cohort.dta", clear

* Create end of follow-up for each outcome
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

stset end_followup_mace, fail(mace) origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup $full_adj_covariates
stcurve, failure at1(treatmentgroup=1) at2(treatmentgroup=2) at3(treatmentgroup=3) ///
	ylabel(.0(.05)0.10) ///
	xlabel(.0(3)6) ///
    ytitle("proportion with MACE") ///
    xtitle("years since initiating on second-line medication") ///
	title("Cumulative incidence of MACE in study population") ///
	legend(order(1 "SU" 2 "DPP4i" 3 "SGLT2i"))
graph save "Graph" "$Outputdir/cox_failure_mace_overall.gph", replace

* Female
use "$Datadir/derived/study_cohort.dta", clear
keep if gender==2

* Create end of follow-up for each outcome
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

stset end_followup_mace, fail(mace) origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup $full_adj_covariates
stcurve, failure at1(treatmentgroup=1) at2(treatmentgroup=2) at3(treatmentgroup=3) ///
	ylabel(.0(.05)0.10) ///
	xlabel(.0(3)6) ///
    ytitle("proportion with MACE") ///
    xtitle("years since initiating on second-line medication") ///
	title("Cumulative incidence of MACE in the White group") ///
	legend(order(1 "SU" 2 "DPP4i" 3 "SGLT2i"))
graph save "Graph" "$Outputdir/cox_failure_mace_female.gph", replace

* Male
use "$Datadir/derived/study_cohort.dta", clear
keep if gender==1

* Create end of follow-up for each outcome
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

stset end_followup_mace, fail(mace) origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup $full_adj_covariates
stcurve, failure at1(treatmentgroup=1) at2(treatmentgroup=2) at3(treatmentgroup=3) ///
	ylabel(.0(.05)0.10) ///
	xlabel(.0(3)6) ///
    ytitle("proportion with MACE") ///
    xtitle("years since initiating on second-line medication") ///
	title("Cumulative incidence of MACE in the South Asian group") ///
	legend(order(1 "SU" 2 "DPP4i" 3 "SGLT2i"))
graph save "Graph" "$Outputdir/cox_failure_mace_male.gph", replace


log close
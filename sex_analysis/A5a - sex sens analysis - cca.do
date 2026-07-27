/*==============================================================================
DO FILE NAME:			A5a - sex sens analysis - cca.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		03/2025
					
DESCRIPTION OF FILE:	Sensitivity analysis complete case analysis to handle missing data
*=============================================================================*/

* Log
cap log close
log using $Logdir\A5a_sex_sens_analysis_cca.log, replace

* Set dataset and outcomes
local dataset cca
local outcomes mace

********************************************************************************
** Get hazard ratios for each outcome - non-age stratified **
********************************************************************************

foreach outcome in `outcomes' {
 
use $study_cohort_cca, clear
 
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

* Create excel file
putexcel set "$Outputdir/Sex sens analysis - cca.xlsx", sheet("`outcome'") modify

* Run sex hazard ratio program
run "$Dodir\_sex hazard ratios program.do"
prog_sex_hrs, ///
	dataset("`dataset'") ///
	outcome("`outcome'")
}

********************************************************************************
** Get hazard ratios for each outcome - age stratified **
********************************************************************************

foreach outcome in `outcomes' {
 
use "$Datadir/derived/study_cohort_`dataset'.dta", clear
 
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

* Create excel file
putexcel set "$Outputdir/Sex sens analysis - cca.xlsx", sheet("`outcome'_subgroup") modify

* Run sex hazard ratio program
run "$Dodir\_sex age hazard ratios program.do"
prog_sex_age_hrs, ///
	dataset("`dataset'") ///
	outcome("`outcome'")
}

log close

/*==============================================================================
DO FILE NAME:			A6 - ethnicity main analysis.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		03/2025
					
DESCRIPTION OF FILE:	Main analysis for all outcomes using mi to handle missing data and intention to treat as the exposure definition
*=============================================================================*/

* Log
cap log close
log using $Logdir\A6_ethnicity_main_analysis.log, replace

* Set dataset and outcomes
local dataset mi
local outcomes mace mi stroke hf cvddeath

********************************************************************************
** Get hazard ratios for each outcome **
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
putexcel set "$Outputdir\Ethnicity main analysis.xlsx", sheet("`outcome'") modify

* Run ethnicity hazard ratio
run "$Dodir\A5 - ethnicity hazard ratios pr.do"
prog_ethnicity_hrs, ///
	dataset("`dataset'") ///
	outcome("`outcome'")
}

log close
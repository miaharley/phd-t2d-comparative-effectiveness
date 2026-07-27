/*==============================================================================
DO FILE NAME:			A5b - sex sens analysis - as treated.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		08/2025
					
DESCRIPTION OF FILE:	Sensitivity analysis using as treated exposure definition
*=============================================================================*/

* Log
cap log close
log using $Logdir\A5b_sex_sens_analysis_as_treated.log, replace

* Set dataset and outcomes
local dataset mi
local outcomes mace

********************************************************************************
** Get hazard ratios for each outcome **
********************************************************************************

foreach outcome in `outcomes' {
 
use"$Datadir/derived/study_cohort_`dataset'.dta", clear

* Create end of follow-up
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' = min(`outcome'_date, enddate, epiend)
format end_followup_`outcome' %td
replace `outcome'_date =. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop epistart epiend followup_days_`outcome'
drop if followup_years_`outcome'==0

* Create excel file
putexcel set "$Outputdir/Sex sens analysis - as treated.xlsx", sheet("`outcome'") modify

* Run sex hazard ratio
run "$Dodir\_sex hazard ratios program.do"
prog_sex_hrs, ///
	dataset("`dataset'") ///
	outcome("`outcome'")
}

log close

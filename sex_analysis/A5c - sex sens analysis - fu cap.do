/*==============================================================================
DO FILE NAME:			A5c - sex sens analysis - fu cap.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		08/2025
					
DESCRIPTION OF FILE:	Sensitivity analysis capping follow up at 3.5 years
*=============================================================================*/

* Log
cap log close
log using $Logdir\A5c_sex_sens_analysis_fucap.log, replace

* Set dataset and outcomes
local dataset mi
local outcomes mace

********************************************************************************
** Get hazard ratios for each outcome **
********************************************************************************

foreach outcome in `outcomes' {
 
use "$Datadir/derived/study_cohort_`dataset'.dta", clear

* Create end of follow-up
cap drop end_followup_`outcome'  followup_years_`outcome'
gen fucap = firstissue + 1278.4
format fucap %td
gen end_followup_`outcome' = min(`outcome'_date, enddate, fucap)
format end_followup_`outcome' %td
replace `outcome'_date =. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop fucap followup_days_`outcome'
drop if followup_years_`outcome'==0

* Create excel file
putexcel set "$Outputdir/Sex sens analysis - fucap.xlsx", sheet("`outcome'") modify

* Run sex hazard ratio
run "$Dodir\_sex hazard ratios program.do"
prog_sex_hrs, ///
	dataset("`dataset'") ///
	outcome("`outcome'")
}

log close
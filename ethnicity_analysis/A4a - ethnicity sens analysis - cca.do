/*==============================================================================
DO FILE NAME:			A8 - ethnicity sens analysis - cca.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		08/2025
					
DESCRIPTION OF FILE:	Sensitivity analysis complete case analysis to handle missing data
*=============================================================================*/

* Log
cap log close
log using $Logdir\A4a_ethnicity_sens_analysis_cca.log, replace

* Set dataset and outcomes
local dataset cca
local outcomes mace

********************************************************************************
** Get hazard ratios for each outcome **
********************************************************************************

foreach outcome in `outcomes' {
 
use"$Datadir/derived/study_cohort_cca.dta", clear
 
* Create end of follow-up
cap drop end_followup_`outcome' followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

* Create excel file
putexcel set "$Outputdir/Ethnicity sens analysis - cca.xlsx", sheet("`outcome'") modify

* Run ethnicity hazard ratio
run "$Dodir\_ethnicity hazard ratios program.do"
prog_ethnicity_hrs, ///
	dataset("`dataset'") ///
	outcome("`outcome'")
}

log close

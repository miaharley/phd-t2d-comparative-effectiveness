/*=========================================================================
DO FILE NAME:			C3i - comorbidities.do

AUTHOR:					Mia Harley

DATE CREATED: 			04/2024

DATE LAST UPDATED: 		11/2024
						
DATASETS CREATED:      	comorbidity_x.dta
					
DESCRIPTION OF FILE:	identifies people who have comorbidities prior to entering the cohort
*=========================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Set up log
cap log close
log using $Logdir/C3i_covariate_comorbidities.log, replace

********************************************************************************
** Create cormorbidity variables **
********************************************************************************

foreach comorbidity in $comorbidities {

* Open dataset with all Aurum extracted records
use "$Datadir/intermediate/`comorbidity'.dta", clear 

* Keep first event per patient
bysort patid (`comorbidity'_eventdate): keep if _n == 1

* Merge with study cohort
merge m:1 patid using $included, keep(match using) nogen

* Keep events happening before the index date
replace `comorbidity'_eventdate = . if `comorbidity'_eventdate>firstissue

* Mark individuals with a history of comorbidity
gen `comorbidity' = 1 if `comorbidity'_eventdate < .
recode `comorbidity' .=0
count if `comorbidity'==1
label variable `comorbidity' "`comorbidity' before study entry"

* Keep only required variables
keep patid `comorbidity'
duplicates drop

************************
*  Tidy and save data  *
************************

label data "Pre-existing `comorbidity'"
save "$Datadir/derived/comorbidity_`comorbidity'.dta", replace

}

log close
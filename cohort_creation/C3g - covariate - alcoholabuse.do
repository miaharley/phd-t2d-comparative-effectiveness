/*==============================================================================
DO FILE NAME:			C3g - covariate - alcohol abuse.do

AUTHOR:					Mia Harley

DATE CREATED: 			02/2025

DATE LAST UPDATED: 		02/2025

DATASETS CREATED:      	covariate_alcoholabuse.dta
					
DESCRIPTION OF FILE:	idenitfies evidence of alcohol abuse based on medical codes for alcohol abuse and alcohol prescriptions
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Set up log
cap log close
log using $Logdir/C3g_covariate_alcoholabuse.log, replace

********************************************************************************
** Mark for alcohol abuse based on medical codes **
********************************************************************************

* Open dataset with all extracted clinical records
use "$Datadir/intermediate/alcoholabuse.dta", clear
rename alcoholabuse_eventdate eventdate

* Keep first event per patient
bysort patid (eventdate): keep if _n == 1

* Merge with study cohort
merge m:1 patid using $included, keep(match using) nogen

* Keep events happening before the index date
replace eventdate = . if eventdate>firstissue

* Mark individuals with previous alcohol abuse codes
replace alcoholabuse = 1 if eventdate < .
replace alcoholabuse = 0 if eventdate==.
recode alcoholabuse .=0
count if alcoholabuse==1
label variable alcoholabuse "Evidence of alcohol abuse before study entry"

* Tidy and save
rename eventdate alcoholabuse_eventdate
save "$Datadir/derived/covariate_alcoholabuse.dta", replace

********************************************************************************
** Add alcohol therapy codes **
********************************************************************************

* Open dataset with all extracted clinical records
use "$Datadir/intermediate/alcohol_therapeutics.dta", clear

* Keep first event per patient
bysort patid (issuedate): keep if _n == 1

* Merge with study cohort
merge m:1 patid using $included, keep(match using) nogen

* Drop prescriptions after index
replace issuedate = . if issuedate>firstissue

* Mark individuals with previous alcohol therapeutics codes
gen alcohol_therapeutics = 1 if issuedate < .
replace alcohol_therapeutics = 0 if issuedate==.
recode alcohol_therapeutics .=0

* Merge in alcohol abuse variable
merge 1:1 patid using "$Datadir/derived/covariate_alcoholabuse.dta", nogen
replace alcoholabuse=1 if alcohol_therapeutics==1

* Tidy and save
keep patid alcoholabuse
label data "Evidence of alcohol abuse before study entry"
save "$Datadir/derived/covariate_alcoholabuse.dta", replace

log close

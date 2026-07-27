/*==============================================================================
DO FILE NAME:			C5b - outcome - hba1c.do

AUTHOR:					Mia Harley

DATE CREATED: 			01/2025

DATE LAST UPDATED:		03/2025
						
DATASETS CREATED:       outcome_mace.dta
					
DESCRIPTION OF FILE:	identifies MACE events for study population in study period in CPRD data
*=============================================================================*/

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C5b_outcome_hba1c.log, replace

********************************************************************************
** Take nearest recording within -180 days of first issue **
********************************************************************************
use $included, clear

* Merge with hba1c recordings
merge 1:m patid using "$Datadir/intermediate/hba1c_clean.dta", keep(match) nogen

* Drop recordings after first issue
drop if eventdate > firstissue

* Calculate distance between recording and first issue
gen _distance = firstissue-eventdate
drop if _distance > 180

* Only keep recording that is closest to first issue
sort patid _distance
by patid: keep if _n==1
count //167,204

* Tidy and save
rename value_hba1c hba1c_outcome_baseline
keep patid hba1c_outcome_baseline
save "$Datadir/temporary/outcome_hba1c_baseline.dta", replace


********************************************************************************
** Take nearest recording within +/-90 days after 12 months follow up **
********************************************************************************
use $included, clear

* Get date for 1 year follow-up
gen followup = firstissue +  365
format followup %td

* Drop people whose end date is before 1 year of follow up
drop if enddate < followup  //35,794

* Merge with hba1c recordings
merge 1:m patid using "$Datadir/intermediate/hba1c_clean.dta", keep(match) nogen

* Calculate distance between recording and 1 year follow-up
gen _distance = eventdate-followup
gen _absdistance = abs(_distance)
drop _distance
rename _absdistance _distance
drop if _distance > 90

* Only keep recording that is closet to 1 year follow up
sort patid _distance
by patid: keep if _n==1

* Rename hba1c 1 year
rename value_hba1c hba1c_outcome_1yr

* Merge with baseline hba1c recordings
merge 1:1 patid using "$Datadir/temporary/outcome_hba1c_baseline.dta", nogen

* Merge back in study cohort to retreive people with missing data
merge 1:1 patid using $included, keep(match using) nogen

* Tidy and save
keep patid hba1c_outcome_baseline hba1c_outcome_1y
save "$Datadir/derived/outcome_hba1c.dta", replace

log close



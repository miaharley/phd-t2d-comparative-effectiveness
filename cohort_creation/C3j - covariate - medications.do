/*=========================================================================
DO FILE NAME:			C3j - covariate - medications.do

AUTHOR:					Mia Harley

DATE CREATED: 			04/2024

DATE CREATED: 			11/2024

DATASETS CREATED:      	medication_x.dta
					
DESCRIPTION OF FILE:	identifies people who have records of medication 1 year prior to entering the cohort
*=========================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Set up log
cap log close
log using $Logdir/C3j_covariate_medications.log, replace

********************************************************************************
** Create medication variables **
********************************************************************************

foreach medication in $medications {

* Open dataset with all extracted records
use "$Datadir/intermediate/`medication'.dta", clear
keep patid issuedate

* Merge with study cohort
merge m:1 patid using $included, keep(match using) nogen

* Drop prescriptions after index date
drop if issuedate > firstissue

* Only keep prescription that is nearest to index date
gen days_diff = firstissue - issuedate
sort patid days_diff
by patid: keep if _n==1

* Drop prescription that occur more than 1 year before index date
drop if days_diff > 365
drop days_diff

* Mark individuals with a history of medication
gen `medication' = 1
label variable `medication' "`medication' before study entry"

* Remerge with study cohort
merge m:1 patid using $included, nogen
recode `medication' .=0

* Rename issuedate `medication'_issuedate
rename issuedate `medication'_issuedate

* Get counts
tab `medication'

* Keep only required variables
keep patid `medication'
duplicates drop

************************
*  Tidy and save data  *
************************

label data "Record of `medication' in year before baseline"
save "$Datadir/derived/medication_`medication'.dta", replace

}

log close
clear all
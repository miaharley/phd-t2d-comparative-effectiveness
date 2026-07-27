/*==============================================================================
DO FILE NAME:			C6b - exclusion - prev cvd.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2024

DATE LAST UPDATED:		11/2024
						
DATASETS CREATED:       excl_prev_mace
					
DESCRIPTION OF FILE:	creates a flag for each exclusion criteria (0,1)
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C6b_exclusion_prev_cvd.log, replace

********************************************************************************
** Exclusion 3 - CVD event before index **
********************************************************************************
* Get all records of CVD outcomes
foreach outcome in mi stroke hf ihd {
	use "$Datadir/intermediate//`outcome'.dta", clear
	rename `outcome'_eventdate epistart
	append using "$Datadir/intermediate//`outcome'_hes.dta"
	rename epistart eventdate 
	merge m:1 patid using $included, keep(match) nogen
	bysort patid (eventdate): keep if _n==1
	keep if eventdate < firstissue
	keep patid
	gen prev_`outcome'=1
	save "$Datadir/temporary//exclusion_`outcome'.dta", replace
}

* Start with study population (ensures one row per patient)
use $included, clear
keep patid

* Merge each CVD outcome
foreach outcome in mi stroke hf ihd {
	merge 1:1 patid using "$Datadir/temporary//exclusion_`outcome'.dta", nogen
}

* Replace missing with 0 (patient didn't have that outcome)
foreach outcome in mi stroke hf ihd {
	replace prev_`outcome' = 0 if prev_`outcome' == .
}

* Create combined CVD variable (any of the four)
gen prev_cvd = 0
replace prev_cvd = 1 if prev_mi == 1 | prev_stroke == 1 | prev_hf == 1 | prev_ihd == 1

* Check
tab prev_cvd
tab prev_mi prev_cvd
tab prev_stroke prev_cvd
tab prev_hf prev_cvd
tab prev_ihd prev_cvd

* Keep only needed variables
keep patid prev_mi prev_stroke prev_hf prev_ihd prev_cvd

* Verify one row per patient
duplicates report patid
assert _N == _N  // Should have same number of rows as unique patients

* Save
save "$Datadir/derived/excl_prev_cvd.dta", replace

* Erase temporary files
erase "$Datadir/temporary/exclusion_mi.dta"
erase "$Datadir/temporary/exclusion_stroke.dta"
erase "$Datadir/temporary/exclusion_hf.dta"
erase "$Datadir/temporary/exclusion_ihd.dta"

log close
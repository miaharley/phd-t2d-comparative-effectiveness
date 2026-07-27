/*==============================================================================
DO FILE NAME:			C6a - exclusion - prev antidiabetics.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2024

DATE LAST UPDATED:		11/2024
						
DATASETS CREATED:       excl_prev_antidiabetics
					
DESCRIPTION OF FILE:	creates a flag for each exclusion criteria (0,1)
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C6a_exclusion_prev_antidiabetics.log, replace

********************************************************************************
** Split up metformin prescriptions to avoid I/O errors **
********************************************************************************

use "$Datadir/intermediate/antidiabetics_exceptmetformin.dta", clear
keep patid issuedate
drop if issuedate > td($studyend) 
gen issueyear = year(issuedate)

preserve
keep if issueyear < 1950
drop issueyear
merge m:1 patid using $included, keep(match) nogen
drop if issuedate >= firstissue
save "$Datadir/temporary/antidiabetics_exceptmetformin_1.dta", replace
restore

preserve
keep if issueyear >= 1950 & issueyear < 1990
drop issueyear
merge m:1 patid using $included, keep(match) nogen
drop if issuedate >= firstissue
save "$Datadir/temporary/antidiabetics_exceptmetformin_2.dta", replace
restore

preserve
keep if issueyear >= 1990 & issueyear < 2000
drop issueyear
merge m:1 patid using $included, keep(match) nogen
drop if issuedate >= firstissue
save "$Datadir/temporary/antidiabetics_exceptmetformin_2.dta", replace
restore

preserve
keep if issueyear >= 2000 & issueyear < 2010
drop issueyear
merge m:1 patid using $included, keep(match) nogen
drop if issuedate >= firstissue
save "$Datadir/temporary/antidiabetics_exceptmetformin_3.dta", replace
restore

preserve
keep if issueyear >= 2010 & issueyear < 2020
drop issueyear
merge m:1 patid using $included, keep(match) nogen
drop if issuedate >= firstissue
save "$Datadir/temporary/antidiabetics_exceptmetformin_4.dta", replace
restore

preserve
keep if issueyear >= 2020
drop issueyear
merge m:1 patid using $included, keep(match) nogen
drop if issuedate >= firstissue
save "$Datadir/temporary/antidiabetics_exceptmetformin_5.dta", replace
restore

use "$Datadir/temporary/antidiabetics_exceptmetformin_1.dta", clear
append using "$Datadir/temporary/antidiabetics_exceptmetformin_2.dta"
append using "$Datadir/temporary/antidiabetics_exceptmetformin_3.dta"
append using "$Datadir/temporary/antidiabetics_exceptmetformin_4.dta"
append using "$Datadir/temporary/antidiabetics_exceptmetformin_5.dta"

********************************************************************************
** Exclusion 2 - Use of any antidiabetics (except metformin) before index **
********************************************************************************

* Only keep one prescription per patient (nearest to index), to have list of patients with prev ad records
gen days_diff = abs(issuedate - firstissue)
sort patid days_diff
by patid: keep if _n==1

* Check that there is only record per patient
preserve
keep patid 
count
duplicates report
restore

* Create a flag for previous antidiabetics
gen prev_antidiabetics=1

* Re-merge in study cohort to recover people who do not have record of previous antidiabetics
merge 1:1 patid using $included, nogen
replace prev_antidiabetics=0 if prev_antidiabetics==.

* Tidy and save
keep patid prev_antidiabetics
save "$Datadir/derived/excl_prev_antidiabetics.dta", replace

log close
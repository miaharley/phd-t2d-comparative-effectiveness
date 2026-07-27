/*==============================================================================
DO FILE NAME:			C3h - covariate - healthcare.do

AUTHOR:					Mia Harley

DATE CREATED: 			10/2024

DATE LAST UPDATED: 		11/2024

DATASETS CREATED:      	healthcare.dta
					
DESCRIPTION OF FILE:	determines healthcare utilization in the year before baseline
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Set up log
cap log close
log using $Logdir/C3h_covariate_healthcare.log, replace

********************************************************************************
** Extract all consultation records **
********************************************************************************
	
	* Loop through observation files
	foreach file of numlist 1/$no_Consultation {
		use "$Datadir/raw//${file_stub}_Extract_Consultation_`file'", clear
		noi di "Merging Consultation File `file'"
		
		* Extract all codes related to condition
		merge m:1 conssourceid using "$Codelistdir/cl_aurum_consultations.dta"
		rename _merge _merge_x
		merge m:1 consmedcodeid using "$Codelistdir/cl_aurum_consultations_snomed.dta"
		keep if _merge==3 | _merge_x==3
		drop _merge _merge_x
		
		* Only keep records for second line initiators
		merge m:1 patid using $included, keep(match) nogen
		
		* Only keep consultations in the year before index
		drop if consdate>firstissue
		gen days_diff = firstissue - consdate
		keep if days_diff <365
		drop days_diff
		
		* Drop events on the same date
		sort patid consdate
		bysort patid consdate: drop if _n > 1
		
		* Drop unncessary variables and compress to save memory
		compress
		
		* Remove duplicate records/ no event date
		capture duplicates drop
		capture drop if enterdate==.
	
	* Append files pt 1
	if `file' == 1{
	save "$Datadir/intermediate/consultations.dta", replace
	}	
	if (`file' > 1 & `file' <= 40) {
		append using "$Datadir/intermediate/consultations.dta"
		save "$Datadir/intermediate/consultations.dta", replace	
	}
	}
	
********************************************************************************
** Identify consultation rate in study cohort **
********************************************************************************
use "$Datadir/intermediate/consultations.dta", clear

* Merge with study cohort to recover patients with no consultations in year before index
merge m:1 patid using $included, keep(using match) nogen

* Drop events on the same date (from multiple appended files)
sort patid consdate
bysort patid consdate: drop if _n > 1

* Count number of consultations per patid
sort patid
by patid: egen number_consultations = count(consdate)
replace number_consultations=0 if number_consultations==.

* Keep one observation per patient
bysort patid: keep if _n == 1
keep patid number_consultations

* Create a variable indicating 
gen healthcare_util=0
label variable healthcare_util "Binary variable indicating >10 consultations in year before baseline"
replace healthcare_util=1 if number_consultations>10

* Tdy and save
label data "Healthcare utilisation in year before baseline"
keep patid healthcare
save "$Datadir/derived/covariate_healthcare.dta", replace

log close	

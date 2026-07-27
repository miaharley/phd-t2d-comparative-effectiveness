/*==============================================================================
DO FILE NAME:			C5a - outcome - CVD events.do

AUTHOR:					Mia Harley

DATE CREATED:			09/2024

LAST UPDATED: 			02/2025
						
DATASETS CREATED:       outcome_mace.dta
					
DESCRIPTION OF FILE:	identifies MACE events for study population in study period in CPRD data
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C5a_outcome_cvdevents.log, replace

********************************************************************************
**  Combine Aurum and HES cardiovascular events **
********************************************************************************

* Combine Aurum and HES for MI and Stroke
foreach outcome in mi stroke {
use "$Datadir/intermediate//`outcome'.dta", clear
rename `outcome'_eventdate epistart
append using "$Datadir/intermediate//`outcome'_hes.dta"
rename epistart eventdate 
gen `outcome'=1
keep patid eventdate `outcome' incident
save "$Datadir/temporary//`outcome'.dta", replace
}

* Combine Aurum, HES and ONS for MI and Stroke
use "$Datadir/intermediate//hf_ons.dta", clear
rename deathdate epistart
append using "$Datadir/intermediate//hf_hes.dta"
rename epistart eventdate 
gen hf=1
keep patid eventdate hf
save "$Datadir/temporary//hf.dta", replace


* Create CVD death component
use "$Datadir/intermediate/cvddeath_ons.dta", clear
rename deathdate eventdate
gen cvddeath=1
keep patid eventdate cvddeath
save "$Datadir/temporary/cvddeath.dta", replace // so fits into loop below

* Create composite MACE outcome variable
use "$Datadir/temporary/cvddeath.dta", clear
append using "$Datadir/temporary/mi.dta"
append using "$Datadir/temporary/stroke.dta"
append using "$Datadir/temporary/hf.dta"
gen mace=1
save "$Datadir/temporary/mace.dta", replace


********************************************************************************
**  Identify all events that occurred after index and before study end **
********************************************************************************
foreach outcome in mi stroke hf cvddeath mace {
	
	* Use dataset with events
	use "$Datadir/temporary/`outcome'.dta", clear
	
		 if inlist("`outcome'", "mace", "mi", "stroke") {
		drop if incident=="0"
	}
	
	* Merge events with study cohort and patient file
	merge m:1 patid using $included, keep(match using) nogen
	merge m:1 patid using "$Datadir/raw//${file_stub}_Extract_Patient_1.dta", keep(match) nogen
	
	* Drop events that occur before index
	replace eventdate=. if eventdate < firstissue

	* Drop events that occur more than a week after death date
	gen death_date_7 = death_date + 7
	format death_date_7 %td
	replace eventdate=. if eventdate > death_date_7

	* If cvd event occured within a week after reported death date, then use death date as cvd date
	replace eventdate = death_date if eventdate > death_date & eventdate < death_date_7

	* Drop events that occur after end date (minimum of death date, end of registration, lcd)
	replace eventdate=. if eventdate > enddate
	
	* Check all remaining events are after index and before enddate
	assert (eventdate >= firstissue & eventdate <= enddate) if eventdate!=.

	* Keep first event per patient
	bysort patid (eventdate): keep if _n == 1
 
	* Create binary variables indicating in-study MACE events
	replace `outcome'=0 if eventdate==.
	label variable `outcome' "`outcome' event in study period"
	rename eventdate `outcome'_date

	* Keep only required variables
	keep patid `outcome' `outcome'_date

	* Tidy 
	label data "Outcome events - `outcome'"
	save "$Datadir/derived/outcome_`outcome'.dta", replace

	erase "$Datadir/temporary/`outcome'.dta"
}



log close
clear all
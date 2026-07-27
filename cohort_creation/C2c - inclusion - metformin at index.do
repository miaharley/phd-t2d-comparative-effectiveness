/*==============================================================================
DO FILE NAME:			C2c - inclusion - metformin at index.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2024

DATE LAST UPDATED:		09/2025
						
DATASETS CREATED:       metformin_at_index
					
DESCRIPTION OF FILE:	creates a flag for each exclusion criteria (0,1)
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C2c_inclusion_metformin_at_index.log, replace

********************************************************************************
** Split up metformin prescriptions to avoid I/O errors **
********************************************************************************

use "$Datadir/intermediate/metformin.dta", clear
keep patid issuedate
drop if issuedate > td($studyend) 
drop if issuedate < td(01jan2014) 
gen issueyear = year(issuedate)

forvalues y = 2014/2022 {
preserve
keep if issueyear == `y'
drop issueyear
merge m:1 patid using "$Datadir\intermediate\2ndline_initiators.dta", keep(match) nogen
drop if issuedate > firstissue
save "$Datadir/temporary/metformin_`y'.dta", replace
restore
}

********************************************************************************
** Metformin prescription in 90 days before index **
********************************************************************************

* Append all metformin prescriptions among second-line initiators
use "$Datadir/temporary/metformin_2014.dta", clear
forvalues y = 2015/2022 {
append using "$Datadir/temporary/metformin_`y'.dta"
}

* Only keep one prescription per patient that is nearest to index date
gen days_diff = firstissue - issuedate
sort patid days_diff
by patid: keep if _n==1

* Only keep metformin prescriptions that are within 90 days of index, so now should have a list of people with a metformin prescription in the 90 days before their first issue of 2nd line treatment
drop if days_diff > 90

* Create marker for metformin at index
gen metformin = 1

* Remerge secondline initiators to recover people on dual therapy (sglt2i+metf or dpp4i+metf)
merge 1:1 patid using $included, nogen
replace metformin = 1 if (dmrxclass==3 |  dmrxclass==4)
replace metformin = 0 if metformin==.

* Only keep people with metformin prescription
keep if metformin==1

* Tidy and save
keep patid metformin
save "$Datadir/intermediate/metformin_at_index.dta", replace

log close

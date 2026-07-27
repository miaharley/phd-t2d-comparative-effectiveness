/*==============================================================================
DO FILE NAME:			C2a - inclusion - t2d diagnosis.do

AUTHOR:					Mia Harley

DATE CREATED: 			02/2025

DATE LAST UPDATED: 		02/2025
					
DESCRIPTION OF FILE:	Create a dataset of people with valid record of type 2 diabetes diagnosis
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir\C2a_inclusion_t2d_diagnosis.log, replace

********************************************************************************
** Diagnosed with type 2 diabetes **
********************************************************************************
use "$Datadir\raw\\${file_stub}_Extract_Patient_1.dta", clear
merge 1:m patid using "$Datadir\intermediate\t2dm_diagnosis.dta", keep(match) nogen

* Generate date of birth from birth year and month
gen day = 1
gen mon = mob
replace mon = 7 if mob ==. | mob ==0
gen dob = mdy(mon,day,yob)
format dob %td
drop day mon mob

* Drop events that occurred below the age of 18
gen age_t2d_diagnosis = floor((eventdate - dob)/365.25)
drop if age_t2d_diagnosis <18

* Keep first event per patient for patients with multiple codes
bysort patid (eventdate): keep if _n == 1
count // 991,048

* Tidy and save
rename eventdate t2ddiagnosisdate
keep patid t2ddiagnosisdate dob
save "$Datadir\intermediate\t2d_patients.dta", replace

log close
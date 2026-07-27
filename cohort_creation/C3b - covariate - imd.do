/*==============================================================================
DO FILE NAME:			C3b - covariate - imd.do

AUTHOR:					Mia Harley

DATE CREATED: 			02/2025

DATE UPDATED:			02/2025
						
DATASETS CREATED:      	covariate_imd.dta
					
DESCRIPTION OF FILE:	assigns imd to each patient in study cohort
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C3b_covariate_imd.log, replace

********************************************************************************
** Merge IMD files with study cohort **
********************************************************************************

use $included, clear

* Merge with patient-level IMD
merge 1:1 patid using "$Datadir\raw\linked\patient_2019_imd_22_001969.dta", keep(master match) nogen
rename e2019_imd_5 imd

* Where patient-level IMD missing, sub in practice-level IMD
merge 1:1 patid using "$Datadir/raw//${file_stub}_Extract_Patient_1.dta", keep(master match) keepusing(pracid) nogen
merge m:1 pracid using "$Datadir\raw\linked\practice_imd_22_001969.dta", keep(master match) nogen
replace imd=e2019_imd_5 if imd==.

* Tidy and save
keep patid imd
save "$Datadir/derived/covariate_imd.dta", replace

log close
clear all


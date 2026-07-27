/*==============================================================================
DO FILE NAME:			C6e - exclusion - hba1c lessthan 48.do

AUTHOR:					Mia Harley

DATE CREATED: 			10/2025

DATE LAST UPDATED:		11/2024
						
DATASETS CREATED:       excl_hba1c_lessthan_48
					
DESCRIPTION OF FILE:	creates a flag for each exclusion criteria (0,1)
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C6e_exclusion_hba1c_lessthan_48.log, replace

********************************************************************************
** Exclusion 5 - HbA1c <6.5 at index **
********************************************************************************

* Get HbA1c at baseline
use $included, clear
merge 1:1 patid using "$Datadir/derived/covariate_hba1c.dta", keep(match) nogen

* Create flag for hab1c less than 48
gen hba1c_lessthan_48=0
replace hba1c_lessthan_48=1 if hba1c<48

* Tidy and save
keep patid hba1c_lessthan_48
save "$Datadir/derived/excl_hba1c_lessthan_48.dta", replace

log close
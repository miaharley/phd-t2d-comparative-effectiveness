/*==============================================================================
DO FILE NAME:			C6c - exclusion - missing sex.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2024

DATE LAST UPDATED:		11/2024
						
DATASETS CREATED:       excl_missing_sex
					
DESCRIPTION OF FILE:	creates a flag for each exclusion criteria (0,1)
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C6c_exclusion_missing_sex.log, replace

********************************************************************************
** Exclusion 6 - Missing sex **
********************************************************************************

use $included, clear

* Flag if invalid gender
gen missing_sex=0
replace missing_sex=1 if gender == . //
replace missing_sex=1 if gender == 3 //

* Tidy and save
keep patid missing_sex
save "$Datadir/derived/excl_missing_sex.dta", replace

log close
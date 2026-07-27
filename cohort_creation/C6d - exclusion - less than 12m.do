/*==============================================================================
DO FILE NAME:			C6d - exclusion - less than 12m.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2024

DATE LAST UPDATED:		11/2024
						
DATASETS CREATED:       excl_lessthan_12m
					
DESCRIPTION OF FILE:	creates a flag for each exclusion criteria (0,1)
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C6d_exclusion_less_than_12m.log, replace

********************************************************************************
** Exclusion 5 - <12 months continuous registration before index **
********************************************************************************

* Merge study cohort excl with patient and practice files to get info on registration start and end dates
use $included, clear
merge 1:1 patid using "$Datadir\raw\\${file_stub}_Extract_Patient_1.dta", keep(match) nogen
merge m:m pracid using "$Datadir\raw\\${file_stub}_Extract_Practice_1.dta", keep(match) nogen

* Create variable for follow-up time before first issuedate
gen prior_follow_up = firstissue - regstart

* Create flag for less than 12 months registration
gen lessthan_12m=0

* Flag anyone whose registration starts after firstissue
replace lessthan_12m=1 if regstart > firstissue

* Flag people with less than 12 months follow-up before first issuedate
replace lessthan_12m=1 if prior_follow_up <365 // #does this also ensure continuous follow up???

* Tidy and save
keep patid lessthan_12m
save "$Datadir/derived/excl_lessthan_12m.dta", replace

log close
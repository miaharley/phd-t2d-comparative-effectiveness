/*==============================================================================
DO FILE NAME:			C5c - outcome - allcause mortality.do

AUTHOR:					Mia Harley

DATE CREATED:			03/2025

LAST UPDATED: 			03/2025
						
DATASETS CREATED:       outcome_allcm.dta
					
DESCRIPTION OF FILE:	identifies MACE events for study population in study period in CPRD data
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C5c_outcome_allcause_mortality.log, replace

********************************************************************************
**  Select earliest death date from CPRD and ONS **
********************************************************************************
use $included, clear

* Create event indicator for all-cause mortality
gen allcm=0
replace allcm=1 if death_date == enddate // death_date is the earliest death date from CPRD Aurum and ONS
gen allcm_date=death_date if allcm==1
format allcm_date %td

* Tidy and save
keep patid allcm allcm_date
save "$Datadir/derived/outcome_allcm.dta", replace

log close

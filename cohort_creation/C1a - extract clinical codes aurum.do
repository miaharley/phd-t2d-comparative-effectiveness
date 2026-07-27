/*==============================================================================
DO FILE NAME:			C1a - extract clinical codes aurum.do

AUTHOR:					Mia Harley

DATE CREATED: 			05/2024

DATE LAST UPDATED: 		05/2024					
					
DESCRIPTION OF FILE:	extracts all medical records for all inclusions, exclusions and confounders from observation files
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir\C1a_extract_clinical_codes_aurum.log, replace

********************************************************************************
** Extract diagnostic codes **
********************************************************************************

* Cycle through Observation files pt. 1
foreach condition in alcoholabuse  {
	
	* Loop through observation files
	foreach file of numlist 1/$no_Observation {
		use "$Datadir/raw//${file_stub}_Extract_Observation_`file'", clear
		noi di "Merging Observation File `file'"
		
		* Extract all codes related to condition
		merge m:1 medcodeid using "$Codelistdir/cl_aurum_`condition'.dta", keep(match) nogen
		noi di "Merging `disease' codelist"
		
		* Drop unncessary variables and compress to save memory
		compress
		
		* Remove duplicate records/ no event date
		drop if eventdate==.
	
	* Append files pt 1
	if `file' == 1{
	save "$Datadir/temporary/`condition'_1.dta", replace
	}	
	if (`file' > 1 & `file' <= 40) {
		append using "$Datadir/temporary/`condition'_1.dta"
		save "$Datadir/temporary/`condition'_1.dta", replace	
	}
	* Append files pt 2
	if `file' == 41{
	save "$Datadir/temporary/`condition'_2.dta", replace
	}	
	if (`file' > 41 & `file' <= 80) {
		append using "$Datadir/temporary/`condition'_2.dta"
		save "$Datadir/temporary/`condition'_2.dta", replace
	}		
	* Append files pt 3
	if `file' == 81{
		save "$Datadir/temporary/`condition'_3.dta", replace
	}	
	if (`file' > 81 & `file' <= 120) {
		append using "$Datadir/temporary/`condition'_3.dta"
		save "$Datadir/temporary/`condition'_3.dta", replace
	}
	* Append files pt 3
	if `file' == 121{
		save "$Datadir/temporary/`condition'_4.dta", replace
	}	
	if `file' > 121 {
		append using "$Datadir/temporary/`condition'_4.dta"
		save "$Datadir/temporary/`condition'_4.dta", replace
	}		
	} 
	
	******************
	* Append data files
	foreach file of numlist 1/4 {
		use "$Datadir/temporary/`condition'_`file'.dta", clear
	
		if `file' == 1{	
		save "$Datadir/intermediate/`condition'.dta", replace
		}
		if `file' > 1{	
			append using "$Datadir/intermediate/`condition'.dta"
		}
		save "$Datadir/intermediate/`condition'.dta", replace
	
		erase "$Datadir/temporary/`condition'_`file'.dta"	
		} 	


rename eventdate `condition'_eventdate

* Tidy and save
label data "All records of `condition'"
save "$Datadir/intermediate/`condition'.dta", replace

}

log close
clear all
/*==============================================================================
DO FILE NAME:			C1b - extract prescriptions.do

AUTHOR:					Mia Harley

DATE CREATED: 			05/2024

DATE UPDATED: 			11/2024
					
DESCRIPTION OF FILE:	extracts all drug issues for all exposures, exclusions and confounders from drug issue files
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir\C1b_extract_prescriptions_aurum.log, replace

/*******************************************************************************
Extract prescription codes
*******************************************************************************/

* Cycle through Drug Issue files
foreach drugclass in nicotine_replacement {
	
	* Loop through drug issue files
	foreach file of numlist 1/$no_DrugIssue {  
		noi di "Merging Drug Issue File `file'"
		use "$Datadir\raw\\${file_stub}_Extract_DrugIssue_`file'", clear

		* Extract all records of medication
		merge m:1 prodcodeid using "$Codelistdir\cl_aurum_`drugclass'.dta", keep(match) nogen
		noi di "Merging Product Codelist `drugclass'"
		
		* Drop unneccessary variables and compress to save memory
		drop estnhscost enterdate
		compress

		* Remove duplicate records/ no issue date
		capture drop if issuedate==.
	
	* Append files pt 1
	if `file' == 1{
	save "$Datadir/temporary/`drugclass'_1.dta", replace
	}	
	if (`file' > 1 & `file' <= 40) {
		append using "$Datadir/temporary/`drugclass'_1.dta"
		save "$Datadir/temporary/`drugclass'_1.dta", replace	
	}
	* Append files pt 2
	if `file' == 41{
	save "$Datadir/temporary/`drugclass'_2.dta", replace
	}	
	if (`file' > 41 & `file' <= 80) {
		append using "$Datadir/temporary/`drugclass'_2.dta"
		save "$Datadir/temporary/`drugclass'_2.dta", replace
	}		
	* Append files pt 3
	if `file' == 81{
		save "$Datadir/temporary/`drugclass'_3.dta", replace
	}	
	if (`file' > 81 & `file' <= 120) {
		append using "$Datadir/temporary/`drugclass'_3.dta"
		save "$Datadir/temporary/`drugclass'_3.dta", replace
	}
	* Append files pt 3
	if `file' == 121{
		save "$Datadir/temporary/`drugclass'_4.dta", replace
	}	
	if `file' > 121 {
		append using "$Datadir/temporary/`drugclass'_4.dta"
		save "$Datadir/temporary/`drugclass'_4.dta", replace
	}		
	} 

	****************************************************************************
	* Append data parts
	foreach file of numlist 1/4 {
		use "$Datadir/temporary/`drugclass'_`file'.dta", clear
	
		if `file' == 1{	
			save "$Datadir/intermediate/`drugclass'.dta", replace
		}
		if `file' > 1{	
			append using "$Datadir/intermediate/`drugclass'.dta"
			duplicates drop
		}
		label data "All `drugclass' prescriptions in extract population"
		save "$Datadir/intermediate/`drugclass'.dta", replace
	
		erase "$Datadir/temporary/`drugclass'_`file'.dta"	
		} 	
			
	* Tidy and save
	label data "All records of `drugclass'"
	save "$Datadir/intermediate/`drugclass'.dta", replace
			
}

log close

clear all
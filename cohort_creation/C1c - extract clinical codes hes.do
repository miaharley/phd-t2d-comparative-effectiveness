/*==============================================================================
DO FILE NAME:			C1c - extract clinical codes hes.do

AUTHOR:					Mia Harley

DATE CREATED: 			02/2025

DATE LAST UPDATED: 		02/2025				
					
DESCRIPTION OF FILE:	extracts medical records from hes
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir\C1c_extract_clinical_codes_hes.log, replace

********************************************************************************
** Extract codes using codelists from episodes files **
********************************************************************************

foreach condition in hf stroke {
	
	* Use episodes file
	use "$Datadir\raw\linked\hes_diagnosis_epi_22_001969.dta", clear
	drop if epistart==""
	drop if patid==""
	
	* Reformat date vars
	g epistart1 = date(epistart, "YMD")
	g epiend1 = date(epiend, "YMD")
	drop epistart epiend
	rename (epistart1 epiend1) (epistart epiend)
	format (epistart epiend) %td 
	
	* Extract all codes related to condition
	merge m:1 icd using "$Codelistdir/cl_hes_`condition'.dta", keep(match) nogen
	noi di "Merging `condition' codelist"
	
	* Tidy and save
	label data "All hes records of `condition'"
	save "$Datadir\intermediate\\`condition'_hes.dta", replace
	
}

********************************************************************************
** Extract codes for MI from episodes files **
********************************************************************************

* Use episodes file
use "$Datadir\raw\linked\hes_diagnosis_epi_22_001969.dta", clear
drop if epistart==""
drop if patid==""
	
* Reformat date vars
g epistart1 = date(epistart, "YMD")
g epiend1 = date(epiend, "YMD")
drop epistart epiend
rename (epistart1 epiend1) (epistart epiend)
format (epistart epiend) %td 

* Extract all codes related to condition
keep if (strmatch(icd,"I21*")) | (strmatch(icd,"I22*")) | (strmatch(icd,"I23*"))
	
* Tidy and save
label data "All hes records of mi"
save "$Datadir\intermediate\\mi_hes.dta", replace

********************************************************************************
** Extract records of heart failure from ONS **
********************************************************************************

use "$Datadir\raw\linked\death_patient_22_001969.dta", clear
drop if patid==""
drop if reg_date_of_death==""
g deathdate = date(reg_date_of_death, "YMD")
format deathdate %td
rename s_cod_code_1 icd
keep if (strmatch(icd,"I50*")) | (strmatch(icd,"I130")) | (strmatch(icd, "I132")) | (strmatch(icd, "I110"))
keep patid icd deathdate
save "$Datadir/intermediate/hf_ons.dta", replace

********************************************************************************
** Extract records of MI from ONS **
********************************************************************************

use "$Datadir\raw\linked\death_patient_22_001969.dta", clear
drop if patid==""
drop if reg_date_of_death==""
g deathdate = date(reg_date_of_death, "YMD")
format deathdate %td
rename s_cod_code_1 icd
keep if (strmatch(icd,"I21*")) | (strmatch(icd,"I22*")) | (strmatch(icd,"I23*"))
keep patid icd deathdate
save "$Datadir/intermediate/mi_ons.dta", replace


********************************************************************************
** Extract records of stroke from ONS **
********************************************************************************

use "$Datadir\raw\linked\death_patient_22_001969.dta", clear
drop if patid==""
drop if reg_date_of_death==""
g deathdate = date(reg_date_of_death, "YMD")
format deathdate %td
rename s_cod_code_1 icd
keep if (strmatch(icd,"I60*")) | (strmatch(icd,"I61*")) | (strmatch(icd,"I62*")) | (strmatch(icd,"I63*"))| (strmatch(icd,"I64*"))
keep patid icd deathdate
save "$Datadir/intermediate/stroke_ons.dta", replace

********************************************************************************
** Extract records of cardiovascular death from ONS **
********************************************************************************

use "$Datadir\raw\linked\death_patient_22_001969.dta", clear
drop if patid==""
drop if reg_date_of_death==""
g deathdate = date(reg_date_of_death, "YMD")
format deathdate %td
rename s_cod_code_1 icd
keep if strmatch(icd,"I*")
keep patid icd deathdate
save "$Datadir/intermediate/cvddeath_ons.dta", replace

log close
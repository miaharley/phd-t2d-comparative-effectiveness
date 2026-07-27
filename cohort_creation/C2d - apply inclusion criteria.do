/*==============================================================================
DO FILE NAME:			C2d - apply inclusion criteria.do

AUTHOR:					Mia Harley

DATE CREATED: 			11/2024

DATE LAST UPDATED: 		02/2025

DATASETS CREATED:		included.dta
					
DESCRIPTION OF FILE:	Apply inclusion criteria to created included population
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C2d_apply_inclusion_criteria.log, replace


********************************************************************************
** Inclusion Criteria **
********************************************************************************

* Inclusion 1 - Acceptable patients in CPRD Aurum extract
* Inclusion 2 - Eligible for HES linkage
* Inclusion 3 - Valid type 2 diabetes diagnosis 
* Inclusion 4 - Initiated second-line during study period
* Inclusion 5 - Metformin prescription in 90 days before index

********************************************************************************
** Apply inclusion criteria **
********************************************************************************

putexcel set "$Outputdir/Figure 1 - study cohort flow chart.xlsx", sheet("Sheet1") modify

* 1. Acceptable patients in Aurum
use "$Datadir\raw\\${file_stub}_Extract_Patient_1.dta", clear
drop acceptable
destring (patienttypeid), replace
merge 1:1 patid using "$Datadir\denominator files\202312_CPRDAurum\202312_CPRDAurum_AcceptablePats.dta", keep(match) nogen
keep if acceptable==1
putexcel A3 = "Acceptable patients aurum extract"
count //1,024,030
putexcel B3 = "`r(N)'"

* 2. Eligible for HES linkage
merge 1:1 patid using "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\raw\linked\22_001969_linkage_eligibility_aurum.dta", keep(match) nogen
keep if hes_apc_e==1
putexcel A4 = "Eligible for HES linkage"
count //854,222
putexcel B4 = "`r(N)'"

* 3. Type 2 diabetes diagnosis
merge 1:1 patid using "$Datadir\intermediate\t2d_patients.dta", keep(match) nogen
putexcel A5 = "Valid type 2 diabetes diagnosis linkage"
count //813,941
putexcel B5 = "`r(N)'" 

* 4. Initiated on second-line during study period
merge 1:1 patid using "$Datadir\intermediate\2ndline_initiators.dta", keep(match) nogen
putexcel A6 = "Initiated second-line during study period"
drop if firstissue < t2ddiagnosisdate
count //184,281
putexcel B6 = "`r(N)'" 

* 5. Metformin prescription in 90 days before index
merge 1:1 patid using "$Datadir/intermediate/metformin_at_index.dta", keep(match) nogen
putexcel A7 = "Metformin prescription in 90 days before index"
count
putexcel B7 = "`r(N)'" 
save "$Datadir\temporary\included.dta", replace

********************************************************************************
** Define end date **
********************************************************************************
* Get death date from ONS
use "$Datadir\raw\linked\death_patient_22_001969.dta", clear
drop if reg_date_of_death==""
g deathdate_ons = date(reg_date_of_death, "YMD")
format deathdate_ons %td
sort patid deathdate_ons
by patid: keep if _n==1

* Merge ONS and included population
merge 1:1 patid using "$Datadir\temporary\included.dta", keep(match using) nogen

* Identify end of registration date 
gen float cprd_ddate_1 = daily(cprd_ddate, "DMY")
format cprd_ddate_1 %td
drop cprd_ddate
rename cprd_ddate_1 cprd_ddate

* Create variable for study end date
gen studyend = td(01feb2022)
format studyend %td

* Create variable for death date
gen death_date =  min(deathdate_ons, deathdate, emis_death, cprd_ddate)
format death_date %td

* Change the format of last collection date
gen lcd1 = date(lcd, "YMD")
format lcd1 %td
drop lcd
rename lcd1 lcd

* Get minimum of end dates
gen enddate = min(studyend, regend, lcd, death_date)
format enddate %td

* Label gender
label define gender 1 "Male" 2 "Female" 3 "Indeterminate"
label values gender gender

********************************************************************************
** Check dates line up **
********************************************************************************

* Create flag for low quality data
gen flag=0

* Flag if invalid date of birth
replace flag=1 if dob==.
replace flag=1 if dob < td(01jan1900)
replace flag=1 if enddate < dob
replace flag=1 if dob > regstart
replace flag=1 if dob > firstissue

* Flag if start and end dates are incorrect order
replace flag=1 if enddate < firstissue
replace flag=1 if enddate < regstart

* Get age at end of follow-up
gen age_endfu = (enddate - dob) / 365.25
replace flag=1 if age_endfu <18
replace flag=1 if age_endfu >110

* Drop people with poor quality data
drop if flag==1
count //181,958

* Tidy and save data
keep patid treatmentgroup death_date firstissue gender dob dmrxclass enddate t2ddiagnosisdate
label data "T2D patients initiated on second-line during study period"
save "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\derived\included.dta", replace

********************************************************************************
** Create included population precovid **
********************************************************************************

use $included, clear

gen precovid = td(31jan2020)

drop if firstissue >= precovid

gen new_enddate = min(enddate, precovid)
format new_enddate %td
drop enddate
rename new_enddate enddate

drop precovid
save "$Datadir/derived/included_precovid.dta", replace

log close
clear all
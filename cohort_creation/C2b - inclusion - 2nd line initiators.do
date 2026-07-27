/*==============================================================================
DO FILE NAME:			C2b - inclusion - 2nd line initiators.do

AUTHOR:					Mia Harley

DATE CREATED: 			02/2024

DATE LAST UPDATED: 		11/2024
					
DESCRIPTION OF FILE:	Creates a dataset of patients who initiated on second-line during study period 
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir\C2b_inclusion_2nd_line_initiators.log, replace

********************************************************************************
** Identify people who initiated on an SU, SGLT2i or DPP4i in study period **
********************************************************************************

* Append datasets with drug issues for exposures
use "$Datadir\intermediate\su.dta", clear
append using "$Datadir\intermediate\dpp4i.dta"
append using "$Datadir\intermediate\sglt2i.dta"

* Generate variable for treatment group
gen treatmentgroup=.
replace treatmentgroup=1 if dmrxclass==5
replace treatmentgroup=2 if (dmrxclass==3 | dmrxclass==8)
replace treatmentgroup=3 if (dmrxclass==4 | dmrxclass==10)

* Label treatment group variable
label define treatmentgroup 1 "SU" 2 "DPP4i" 3 "SGLT2i"
label values treatmentgroup treatmentgroup

* Generate variable denoting first prescription of 2nd line per patient
sort patid issuedate
gen earliest_date=0
bysort patid (issuedate): replace earliest_date = 1 if _n == 1

* Remove people that started on two treatments on the same day
sort patid issuedate treatmentgroup
bysort patid issuedate (treatmentgroup): gen multiple_treatments = treatmentgroup[1] != treatmentgroup[_N]
replace earliest_date = 0 if multiple_treatments==1 & earliest_date==1
drop multiple_treatments

* Only keep first prescription per patient 
drop if earliest_date==0
drop earliest_date
rename issuedate firstissue

* Only keep people who's first prescription occurs during study period
drop if firstissue > td($studyend) 
drop if firstissue < td($studystart)

* Merge with patient file to mob and yob
merge 1:1 patid using "$Datadir\raw\\${file_stub}_Extract_Patient_1.dta", keep(match) keepusing(mob yob)

* Generate date of birth from birth year and month
gen day = 1
gen mon = mob
replace mon = 7 if mob ==. | mob ==0
gen dob = mdy(mon,day,yob)
format dob %td
drop day mon mob

* Get age at index	
gen age_index = floor((firstissue - dob)/365.25)

* Only keep people who initiated on first-line aged and over
drop if age_index < 18

* Check that there is only record per patient
preserve
keep patid 
duplicates report
restore

* Tidy and save
count
keep patid firstissue treatmentgroup dmrxclass
save "$Datadir\intermediate\2ndline_initiators.dta", replace

log close
/*==============================================================================
DO FILE NAME:			C3e - covariate - egfr.do

AUTHOR:					Mia Harley, adapted from code by Angel Wong

DATE CREATED: 			08/2024

DATE UPDATED:			10/2025
						
DATASETS CREATED:      	covariate_egfr.dta
					
DESCRIPTION OF FILE:	determines peoples egfr at index
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

cap log close
log using $Logdir/C3e_covariate_egfr.log, replace

********************************************************************************
** Angel's program for processing serum creatine measurements **
********************************************************************************

/*******************************************************************************
#A1. Identify test records for serum creatinine results.
*******************************************************************************/

use "$Datadir/intermediate/scr.dta", clear
format %td obsdate

/*******************************************************************************
#A3. Drop unnecessary vars and label variables.
*******************************************************************************/	
	
merge m:1 numunitid using "$Datadir/lookups/num_unit.dta", keep(match master) nogen
	
capture destring value, replace
rename value SCr
	 
*rename variables and add labels
rename numunitid    unit 			// unit of measure
rename numrangelow  rangeFrom 	//"normal range from"
rename numrangehigh rangeTo		//"normal range to"
	
label variable SCr "SCr: SCr result"
label variable unit "unit of measure"	
label variable rangeFrom "rangeFrom: normal range from"
label variable rangeTo "rangeTo: normal range to"

/*******************************************************************************
#A4. Drop any duplicate records
	 Drop records with missing dates or SCr results
*******************************************************************************/	
duplicates drop

* drop if eventdate missing 
* but check if sysdate available and replace missing eventdate with sysdate if available
replace obsdate=enterdate if (obsdate==. & enterdate!=.)
gen obsdate1=obsdate

drop obsdate 
rename obsdate1 obsdate
drop if obsdate==.
	
* drop if creatinine value is missing or zero
drop if SCr==0 
drop if SCr==.

/*******************************************************************************
#A6. Drop records with SCr values that are very low or very high
*******************************************************************************/
* drop improbable values for SCr i.e. <20 or >3000
gen improbable=0
recode improbable 0=1 if SCr<20 | SCr>3000

drop if improbable==1
drop improbable	

/*******************************************************************************
#B2. Calculate age at event
*******************************************************************************/	
merge m:1 patid using "$Datadir\raw\\${file_stub}_Extract_Patient_1.dta", keep(match) keepusing(yob gender) nogen

generate eventyr = year(obsdate)
count if eventyr==yob 
drop if eventyr==yob // drop if test result is in the same year as patient born

* make an age at event
gen ageAtEvent=0
replace ageAtEvent=eventyr - yob - 1 if obsdate<mdy(07,01,eventyr) // round down if eventdate in first half of year
replace ageAtEvent=eventyr - yob if obsdate>=mdy(07,01,eventyr)	

/*******************************************************************************
#B3. Deal with duplicate records
*******************************************************************************/
*drop enterdate and medcodeid so the only same day duplicates are those with different values for data2
drop enterdate medcodeid 
duplicates drop

/*******************************************************************************
#B4. Calculate eGFR
*******************************************************************************/
* calculate egfr using ckd-epi
* first multiply by 0.95 (for assay - fudge factor) and divide by 88.4 (to convert umol/l to mg/dl)
* DN "fudge factor"
gen SCr_adj=(SCr*0.95)/88.4

gen min=.
replace min=SCr_adj/0.7 if gender==2
replace min=SCr_adj/0.9 if gender==1
replace min=min^-0.329 if gender==2
replace min=min^-0.411 if gender==1
replace min=1 if min<1

gen max=.
replace max=SCr_adj/0.7 if gender==2
replace max=SCr_adj/0.9 if gender==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^ageAtEvent)
replace egfr=egfr*1.018 if gender==2
label var egfr "egfr calculated using CKD-EPI formula with no eth + fudge"
	
* categorise into ckd stages
egen egfr_cat= cut(egfr), at(0, 15, 30, 45, 60, 5000)
label define EGFR 0"stage 5" 15"stage 4" 30"stage 3b" 45"stage 3a" 60"no CKD"
label values egfr_cat EGFR
label var egfr_cat "eGFR category calc without eth + DN fudge factor"

* * recode with appropriate category as reference
recode egfr_cat 0=5 15=4 30=3 45=2 60=0, generate(ckd)
label define ckd 0"no CKD" 2"stage 3a" 3"stage 3b" 4"stage 4" 5"stage 5"
label values ckd ckd
label var ckd "CKD stage calc without eth + DN fudge factor"

* Tidy and save
rename scr_eventdate eventdate
rename ckd egfr_ckd
keep patid eventdate egfr egfr_cat egfr_ckd
save "$Datadir/intermediate/egfr_clean.dta", replace
	
********************************************************************************
** Select nearest recording to baseline for each individual **
********************************************************************************

use "$Datadir/intermediate/egfr_clean.dta", clear
merge m:1 patid using $included, keep(match) nogen

* Drop recordings that are after index or more than two years before
drop if eventdate > firstissue //n=1,660,468 
gen _distance = eventdate-firstissue
gen _absdistance = abs(_distance)
drop _distance
rename _absdistance _distance
drop if _distance >730  //n=1,332,401
count //n=756,798

* Keep nearest recording to baseline
bysort patid (_distance): keep if _n==1

* Merge back in study cohort to retreive people with missing hba1c
merge 1:1 patid using $included, keep (match using) nogen
count if egfr==.
count if egfr!=.

* Tidy and save
keep patid egfr egfr_cat egfr_ckd
save "$Datadir/derived/covariate_egfr.dta", replace

log close

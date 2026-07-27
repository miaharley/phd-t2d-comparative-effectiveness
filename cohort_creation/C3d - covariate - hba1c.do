/*==============================================================================
DO FILE NAME:			C3d - covariate - hba1c.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024

DATE UPDATED:			03/2025
						
DATASETS CREATED:      	covariate_hba1c.dta
					
DESCRIPTION OF FILE:	determines peoples hba1c at index
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

cap log close
log using $Logdir/C3d_covariate_hba1c.log, replace

********************************************************************************
** Patrick's program for processing HbA1c measurements **
********************************************************************************

/*******************************************************************************
================================================================================
1. Extract HbA1c records from observation files
================================================================================
*******************************************************************************/

use "$Datadir/intermediate/hba1c.dta", clear

/*******************************************************************************
2. Identify measures that can be used, recorded with appropriate units
	- IFCC (ideal, mmol/mol)
	- DCCT (%, need to be converted to mmol/mol)
*******************************************************************************/ 

	/***************************************************************************
	2a. Merge lookup file to get units associated with HbA1c measures, drop 
		observations with missing value or date
	***************************************************************************/
	merge m:1 numunitid using "$Datadir/lookups/num_unit.dta", keep(match master) nogen
	rename description units
	gen unitslower = lower(units)

	destring value, replace
	
	* drop observations that are missing either a value or date 
	foreach var of varlist value obsdate {
		drop if `var' == .
	}

	/*******************************************************************************
	2b. Find observations which are HbA1c measures in appropriate units. Drop the rest.
	*******************************************************************************/
	* search units for indicators of non-hba1c measures
	loc exterm " "*hba0*" "*hbao*" "*total*" "*tot.*" "*unknown*" "
	gen marker = 0 
	foreach word in `exterm' {
		replace marker = 1 if strmatch(unitslower, "`word'")
	}

	drop if marker == 1

	* further trim observations to appropriate units
	local interm " "%" "*dcct*" "*per*cent*" "*ifcc*" "*mmol/mol*" "*mmol/m*"  "*mmoles/mol*" "*mmols*" "*mm/m*" "*hba1c*" "*iu/l*" "*mmol/l*" "
	gen marker2 = 0
	foreach word in `interm' {
		replace marker2 = 1 if strmatch(unitslower, "`word'")
	}
	keep if marker2 == 1

	* group units into categorical variable (0=IFCC(mmol/mol), 1=DCCT(%), 2=to be determined...)
	gen units_simple = .

	local interm " "*mmol/mol*" "*mm/m*" "*ifcc*" "*mmol/mol*" "*mmol/m*"  "*mmoles/mol*" "*mmols*" "*mm/m*" "*mmol/l*" "
	foreach word in `interm' {
		replace units_simple = 0 if strmatch(unitslower, "`word'")
	}

	* note: iu/l values will be converted to % in subsequent code
	local interm " "%" "*dcct*" "*per*cent*" "*iu/l*" "
	foreach word in `interm' {
		replace units_simple = 1 if strmatch(unitslower, "`word'")
	}

	replace units_simple = 2 if units_simple == .

	lab def units_simple 0 "mmol/mol" 1 "%" 2 "unknown - investigate"
	lab val units_simple units_simple

/*********************************************************************************
3. Remove measurements outside the acceptable ranges pre-specified
	- IFCC (mmol/mol): acceptable range 20 - 200
	- DCCT (%): acceptable range 4 - 20.4
*********************************************************************************/ 
	
	/*******************************************************************************
	3a. Take care of IFCC (mmol/mol) values
	*******************************************************************************/
	drop if value > 200 & units_simple == 0
	drop if value < 20 & units_simple == 0

	/*******************************************************************************
	3b. Take care of DCCT (%) values
	*******************************************************************************/
	* convert iu/l into %
	replace value = (2.59 + value) / 1.59 if unitslower == "iu/l" 
	* drop measures outside acceptable range
	drop if value > 20.4 & units_simple == 1
	drop if value < 4 & units_simple == 1

	/*******************************************************************************
	3c. Take care of uknown values (which appear to be HbA1c measures in both units)
	*******************************************************************************/
	capture {
		* assert that no values fall within the overlap between acceptable mmol/mol and % observations
		assert value < 20 | value > 20.4 if units_simple == 2
	}
			
	if _rc!=0 {
		noi display in red "***************Not Completed*****************************************************************************"
		noi display in red "***************Program ended*****************************************************************************"
		noi display in red "***************>=1 value in overlap zone between IFCC and DCCT measure (20-20.4 units)*******************"
		noi display in red "***************Consider dropping observations in units_simple==2 category*********************************"
	}

	* re-categorise observations with unclear units to either IFCC or DCCT based on acceptable ranges
	replace units_simple = 0 if units_simple == 2 & value >= 20 & value <= 200
	replace units_simple = 1 if units_simple == 2 & value >= 4 & value < 20

	* drop out-of-range unknown values
	drop if units_simple == 2

	
/*********************************************************************************
4. Reduce to one HbA1c measure per day, prioritising HbA1c measured in mmol/mol. 
	Convert % to mmol/mol and use this if mmol/mol was not recorded on the same day.
	Take average of values if >1 measure on the same day. However, drop the measures 
	if the difference between these minimum and maximum measures on the same day is 
	> 22 mmol/mol (2%)
*********************************************************************************/ 
	
	/*******************************************************************************
	4a. Take the mmol/mol observation if both mmol/mol and % are recorded on same day
	*******************************************************************************/
	* generate unit specific variables
	gen hba1c_mmol = value if units_simple == 0
	gen hba1c_percent = value if units_simple == 1

	/* keep the mmol/mol measure when both are recorded under one parentobsid
	sort patid parentobsid obsdate units_simple
	by patid parentobsid obsdate: keep if _n==1*/

	/*******************************************************************************
	4b. - Convert % to mmol/mol for values recorded as %
		- Drop duplicates on patient, date, and hba1c (mmol/mol)
	*******************************************************************************/
	replace hba1c_mmol = int(10.929*(value - 2.14)) if units_simple == 1
	* round HbA1c to closest integer
	replace hba1c_mmol = round(hba1c_mmol, 1)

	capture {
		* assert that converted % to mmol/mol values are within reasonable range
		assert hba1c_mmol >= 20 & hba1c_mmol <= 200
	}
			
	if _rc!=0 {
		noi display in red "***************Not Completed*****************************************************************************"
		noi display in red "***************Program ended*****************************************************************************"
		noi display in red "***************Converted HbA1c from % to mmol/mol are not within acceptable range************************"
		noi display in red "***************Investigate*******************************************************************************"
	}

	* drop duplicates on patid obsdate and hba1c in mmol/mol
	bysort patid obsdate hba1c_mmol: keep if _n == 1

	/*******************************************************************************
	4c. Take average HbA1c when >1 are recorded on same day, unless difference is 
		>22 mmol/mol (2%)
	*******************************************************************************/
	* take the average hba1c measure if >1 measure on the same day and measures fall within 22 mmol/mol (2%) difference of each other
	bysort patid obsdate: egen av_a1c = mean(hba1c_mmol) 
	bysort patid obsdate: egen max_a1c = max(hba1c_mmol) 
	bysort patid obsdate: egen min_a1c = min(hba1c_mmol)

	gen diff = max_a1c - min_a1c

	gen a1c_use = .
	replace a1c_use = av_a1c if diff <= 22

	* drop measures on same day if there is > 22 mmol/mol variation between them
	drop if a1c_use == .

	* get rid of duplicates, using the mean HbA1c if >1 measure on same day
	duplicates drop patid obsdate a1c_use, force

	/*******************************************************************************
	4d. Clean up variables and save final dataset
	*******************************************************************************/
	keep patid obsdate units_simple a1c_use unitslower medcodeid term

	rename units_simple gp_units
	label var gp_units "original units hba1c was measured with by GP"

	rename obsdate eventdate
	label var eventdate "date of hba1c measure"

	rename a1c_use value_hba1c
	label var value_hba1c "hba1c (mmol/mol)"

	keep patid eventdate value_hba1c gp_units unitslower medcodeid term

	save "$Datadir/intermediate/hba1c_clean.dta", replace
	
********************************************************************************
** Estimate hba1c measurement at index for each person using algorithm **
********************************************************************************

*Algorithm:
*Take median of recordings within 0-3 months before index (best)
*Take median of recordings within 3-6 months before index  (second best)
*Take median of recordings within 6 month - 1 year before index  (third best)
*Take median of recordings within 1-2 years before index  (least best)

use "$Datadir/intermediate/hba1c_clean.dta", clear
merge m:1 patid using $included, keep(match) nogen

* Drop recordings that are after index or more than two years before
drop if eventdate > firstissue //n=1,660,468 
gen _distance = eventdate-firstissue
gen _absdistance = abs(_distance)
drop _distance
rename _absdistance _distance
drop if _distance >730  //n=1,332,401
count //n=756,798

* Define priority of recordings
gen _priority = 1 if _distance>=0 & _distance<=90 // within 3 months
replace _priority = 2 if _distance>90 & _distance<=180 // within 3-6 months
replace _priority = 3 if _distance>180 & _distance<=365 // within 6 months - 1 yr
replace _priority = 4 if _distance>365 & _distance<=730 // within 1-2 yrs

* Get the median recording within each priority
sort patid _priority _distance
bysort patid _priority: egen hba1c_med = median(value_hba1c)
replace hba1c_med = ceil(hba1c_med)

* Only keep the median recording within the first priority level per patient
sort patid _priority _distance
by patid: keep if _n==1

* Create standardised hba1c category using measurement in mmol/mol
gen hba1c_cat=.
replace hba1c_cat=1 if hba1c_med <53
replace hba1c_cat=2 if hba1c_med >=53 & hba1c_med <75
replace hba1c_cat=3 if hba1c_med >=75 & hba1c_med <.

* Merge back in study cohort to retreive people with missing hba1c
merge 1:1 patid using $included, keep (match using) nogen
count if hba1c_med!=. //173,929
count if hba1c_med==. // 2,629

* Tidy and save
rename hba1c_med hba1c
keep patid hba1c hba1c_cat
save "$Datadir/derived/covariate_hba1c.dta", replace

log close
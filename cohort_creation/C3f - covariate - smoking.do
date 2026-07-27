/*==============================================================================
DO FILE NAME:			C3f - covariate - smoking.do

AUTHOR:					Mia Harley, adapted Patrick/ Amgel's adaptation of KB's algorithm

DATE CREATED: 			09/2024

DATE LAST UPDATED: 		11/2024

DATASETS CREATED:      	covariate_smoking.dta
					
DESCRIPTION OF FILE:	determines smoking status using an algorithm that sorts through all smoking records
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Set up log
cap log close
log using $Logdir/C3f_covariate_smoking.log, replace

********************************************************************************
** Set locals to be used in algorithm **
********************************************************************************

local obsfile "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\intermediate\smoking.dta"
local smokingstatusvar smokstatus
local index firstissue
local therapyfile "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\intermediate\nicotine_replacement.dta"

********************************************************************************
** Code copied from Patrick/ Angel's do files **
********************************************************************************

/*********************
*********************
****Modified on 22 April 2020 by Angel Wong
****line 74 & 84 (sort on `smokingstatusvar' too)
****line 73 & 80 to recode non smoker for better sorting later on
****to take into account those with different smokstatus recorded on the same date/ same _absdistance -> take the worst case (current smoker) first

Label:

0  non-smoker
1  current smoker
2  ex-smoker
9  nonspecified - depends on
   quantity
12  current/ex-smoker

NB: in my dataset, only 0.13% records which unspecified smoking status
Of them, only 6% has value recorded (quantity not well recorded but this algorithm still takes it into account)
*********************
*********************/
/*cap prog drop pr_getsmokingstatus_Aurum
program define pr_getsmokingstatus_Aurum

syntax, obsfile(string) [icdfile(string)] therapyfile(string) smokingstatusvar(string) index(string)



noi di
noi di in yellow _dup(5) "*"
noi di in yellow "Assign smoking status (from clinical codes),"
noi di in yellow "based on nearest status pre index date:"
noi di in yellow _dup(5) "*"


qui{



****************************************************************************************
*GET SMOKING STATUS FROM ICD CODES AND PRESCRIPTIONS FOR NICOTINE REPLACEMENT
****************************************************************************************
if "`icdfile'"!="" {
	preserve
	merge 1:m patid using `icdfile', keep(match) nogen
	gen eventdate=date(epistart, "DMY")
	format eventdate %td
	keep patid eventdate `index' `smokingstatusvar'
	tempfile icddata
	save `icddata'
	restore
}

preserve*/

use $included, clear
merge 1:m patid using `therapyfile', keep(match) nogen
rename issuedate eventdate
keep patid eventdate `index' `smokingstatusvar'
tempfile therapydata
save `therapydata'

****************************************************************************************
*GET SMOKING STATUS FROM CODES, AND SUPPLEMENT WITH QUANTITY FROM OBSERVATION FILE
****************************************************************************************
use $included, clear
merge 1:m patid using `obsfile', keep(match master) nogen

* Update smoking status using quantity with unit (per-day) if the codes are not specified (coded as 39)
destring value, replace
replace `smokingstatusvar' = 0 if `smokingstatusvar'== 9 & numunitid == "39" & value == 0
replace `smokingstatusvar' = 1 if `smokingstatusvar'== 9 & numunitid == "39" & value > 0
drop eventdate
rename obsdate eventdate

drop if `smokingstatusvar' == 9

keep patid `index' eventdate `smokingstatusvar' 

if "`icdfile'"!="" {
	append using `icddata'
}

append using `therapydata'

*********************************************************
*ASSIGN STATUS BASED ON INDEX DATE, USING ALGORITHM BELOW
*********************************************************
*Algorithm:
*Take the nearest status in the period -1y to +1month from index if available (best)
*if not, then take nearest in the period +1month to +1y after index if available(second best)*
*if not, then take any nearest before -1y from index if available (third best)
*if not, then take nearest after +1y from index (least best)

gen _distance = eventdate-`index'
gen _priority = 1 if _distance>=-365 & _distance<=30
replace _priority = 2 if _distance>30 & _distance<=365
replace _priority = 3 if _distance<-365
replace _priority = 4 if _distance>365 & _distance<.
gen _absdistance = abs(_distance)
gen _nonspecific = (`smokingstatusvar'==12)

recode `smokingstatusvar' 0=9 //new
sort patid _priority _absdistance _nonspecific `smokingstatusvar'  //new

*Patients nearest status is non-smoker, but have history of smoking, recode to ex-smoker.
by patid: gen b4=1 if eventdate<=eventdate[1]
drop if b4==.

recode `smokingstatusvar' 9=0 //new
by patid: egen ever_smok=sum(`smokingstatusvar') 
by patid: replace `smokingstatusvar' = 2 if ever_smok>0 & `smokingstatusvar'==0

sort patid _priority _absdistance _nonspecific `smokingstatusvar'  //new
by patid: replace `smokingstatusvar' = `smokingstatusvar'[1] 
drop  _distance _priority _absdistance _nonspecific  
by patid: keep if _n==1

*Recode smoking status as current smoker if not certain whether it's current/former smoker
recode `smokingstatusvar' 12=1

* Re-merge with study cohort to retrieve people with no recordings
merge 1:1 patid using $included, keep(match using) nogen

* Tidy and save
keep patid smokstatus
rename smokstatus smoking
save "$Datadir/derived/covariate_smoking.dta", replace

log close

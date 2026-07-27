/*==============================================================================
DO FILE NAME:			C4b - exposure - determine exposure periods.do

AUTHOR:					Mia Harley,  adapted from Marleen's do files

DATE VERSION CREATED: 	03/2024

DATE LAST UPDATED: 		11/2024
						
DATASETS CREATED:       sulf_exposure.dta
						dpp4i_exposure.dta
						sglt2i_exposure.dta
					
DESCRIPTION OF FILE:	Determines exposure periods for each issue of 2nd line treatment during study period
*===============================================================================*/

clear all

* Log
cap log close
log using $Logdir/C4b_determine_exposure_periods.log, replace


********************************************************************************
** Set up looping through each drug class (SGLT2is, DPP4is and SUs)** 
********************************************************************************

local drug su dpp4i sglt2i
di `"`drug'"'

********************************************************************************
** Determine exposure periods for each class of medication **
********************************************************************************

foreach drugclass in `drug'{

* Start with file with all prescriptions for 2nd line medication in study period (checked)
use "$Datadir\intermediate\\`drugclass'_instudy.dta", clear

* Generate a prescription counter for each patient
sort patid issuedate 
by patid: gen prescription = _n
order patid issuedate prescription

* Generate variable for gaps between prescription issue dates
noi di "generate variable of gaps between prescription issue dates"
by patid (issuedate): gen pres_gap = issuedate - issuedate[_n - 1]
order pres_gap, after(issuedate)
replace pres_gap =. if prescription == 1 //*** 0, as expected

g dm = mofd(issuedate)
format dm %tm

* Use duration variable where available (length variable = duration but has values <7 and >100 as missing). use calculated quantity/daily dose where duration not available. where neither are available, use median for each dru
noi di "Generate exp_dur as duration where plausible, quantity/DD or median length for each drug"
gen exp_dur = sum_length
replace exp_dur = sum_days if exp_dur ==.
egen median_dur = median(sum_length), by(drugsubstancename)
replace exp_dur = (median_dur) if exp_dur ==.
drop median_dur

assert exp_dur !=.

* Generate exposure end dates
noi di "Generate exposure end dates"
gen end_pres = issuedate + exp_dur
format (end_pres) %td
order exp_dur end_pres, after(issuedate)

assert end_pres > issuedate

* Generate variable to denote the number of days of overlap
noi di "Generate variable to denote the number of days of overlap"
sort patid prescription
gen overlap_len = end_pres[_n - 1] - issuedate
replace overlap_len =. if prescription == 1
order overlap_len, after(end_pres)
assert overlap_len ==. if prescription == 1
assert overlap_len !=. if prescription != 1

* Generate variable with number of overlap days to add to each prescription
noi di "Generate variable with number of overlap days to add to each prescription"
gen sum_overlap1 = overlap_len
sort patid prescription

* Add up all previous overlaps/ gaps in prescriptions for each patient and makes sure sum can't be negative
noi di "adds up all previous overlaps/gaps in each patient, limit sum_overlap1 so cannot be negative"
bysort patid (prescription) : replace sum_overlap1 = sum(overlap_len)
bysort patid (prescription) : replace sum_overlap1 = 0 if sum_overlap1 < 0 
order sum_overlap1, after(overlap_len)

* Set overlap to 0 for the first prescription or where there is no overlap
gen sum_overlap = cond(_n == 1 | sum_overlap1 == 0, sum_overlap, .)
order sum_overlap, after(overlap_len)

* Add overlap to previous accrued sum overlap len
replace sum_overlap = sum_overlap[_n - 1] + overlap_len if missing(sum_overlap) 

* Do not allow sum overlap to exceed 90 days
replace sum_overlap = 90 if sum_overlap > 90

* Generate end_exp which is the end date of the prescription plus any previously accrued overlap
gen end_exp = end_pres + sum_overlap
format end_exp %td

* Create a variable denoting if prescription belongs to same episode as last
noi di "Generate episode denoting if prescription belongs to same episode as previous Rx"
sort patid prescription
gen episode = 1 if end_exp[_n - 1] >= issuedate & prescription != 1
order episode, after(overlap_len)

* Drop unneccessary variables
drop sum_overlap1

* Label and save data
label data "Exposure periods for `drugclass' in study period"
save "$Datadir\intermediate\\`drugclass'_exposure.dta", replace

}

log close 
clear all
/*=========================================================================
DO FILE NAME:			C4a - exposure - prepare prescriptions.do

AUTHOR:					Mia Harley, adapted from Marleen's do files

DATE CREATED: 			02/2024

DATE LAST UPDATED: 		11/2024
						
DATASETS CREATED:       sulf_instudy.dta
						dpp4i_instudy.dta
						sglt2i_instudy.dta
					
DESCRIPTION OF FILE:	Clean and conducts quality checks on issues for 2nd line treatment during study period
*=========================================================================*/

clear all

* Log
cap log close
log using $Logdir/C4a_prepare_prescriptions.log, replace

*******************************************************************************
** Save dosages look up file as dta **
*******************************************************************************

/*import delimited "$lookupsaurum\common_dosages.txt", clear
save "$Datadir/derived/common_dosages.dta", replace*/

*******************************************************************************
** Set up looping through each drug class (SGLT2is, DPP4is and SUs)** 
*******************************************************************************

local drug su dpp4i sglt2i
di `"`drug'"'

*******************************************************************************
** Get all prescriptions for study cohort in study period **
*******************************************************************************

foreach drugclass in `drug'{

* Start with file with all prescriptions for 2nd line medication
use "$Datadir/intermediate/`drugclass'.dta", clear

* Merge with study cohort file with inclusion and exclusion criteria applied
merge m:1 patid using $included, keep(match) nogen

* Merge with common dosages filee to get dosage information
merge m:1 dosageid using "$Datadir/lookups/common_dosages.dta", keep(match master) nogen

* Only keep prescriptions during study period
assert issuedate >= td($studystart)
drop if issuedate > td($studyend)

*******************************************************************************
** Clean and conduct quality checks **
*******************************************************************************

* Check there are no issues with missing drugsubstancename
sort drugsubstancename
assert drugsubstancename !=""

* Check for weird issue and enterdates
noi di "Check for missing issuedates and issuedates before dob'"
count if missing(issuedate) //***0
count if issuedate < dob //***0

* Replace implausible quantities as missing
noi di "Replace quantities < 5 and > 1000 as missing"
gen quantity2 = quantity
replace quantity2 =. if quantity2 < 5 |quantity2 > 1000

* Replace values > 100 and < 7 in duration variable as missing
noi di "Replace durations < 7 and > 100 as missing"
gen length = duration
replace length =. if length < 7 //***replaces all the 0s
replace length =. if length > 100
tab length 

* Find duplicates in terms of patid, prodcodeid, issuedate and duplicates in terms of all variables
noi di "Tag duplicates in terms of patid, issuedate and prodcodeid, and duplicates in terms of all variables"
duplicates tag patid issuedate prodcodeid, generate(duplicate)

noi di "Count duplicates in terms of patid, issuedate and prodcodeid"
tab duplicate

duplicates tag, gen(duplicate_all)

noi di "Count duplicates in terms of all variables"
tab duplicate_all
count if duplicate != duplicate_all

* Flag those where there are differences in other variables (other than patid, date, product)
gen dup_flag = 1 if duplicate != duplicate_all

noi di "Generate counter = _N and counter2 = _n"
sort patid issuedate prodcodeid
by patid issuedate prodcodeid : gen counter = _N
by patid issuedate prodcodeid : gen counter2 = _n

* Fill in missing lengths, quantities and doses from duplicates in terms of patid, date, product
noi di "Fill in missing lengths from duplicates in terms of patid, date, product"
sort patid issuedate prodcode
gen length2 = length
by patid issuedate prodcode: replace length2 = length2[_n - 1] if length2 ==. & dup_flag == 1 & dup_flag[_n - 1] == 1
by patid issuedate prodcode: replace length2 = length2[_n + 1] if length2 ==. & dup_flag == 1 & dup_flag[_n + 1] == 1

noi di "fill in missing quantities from duplicates in terms of patid, date, product"
sort patid issuedate prodcode
by patid issuedate prodcode: replace quantity2 = quantity2[_n - 1] if quantity2 ==. & dup_flag == 1 & dup_flag[_n - 1] == 1
by patid issuedate prodcode: replace quantity2 = quantity2[_n + 1] if quantity2 ==. & dup_flag == 1 & dup_flag[_n + 1] == 1

noi di "fill in missing daily doses from duplicates in terms of patid, date, product"
sort patid issuedate prodcode
gen daily_dose2 = daily_dose
by patid issuedate prodcode: replace daily_dose2 = daily_dose2[_n - 1] if daily_dose2 ==. & dup_flag == 1 & dup_flag[_n - 1] == 1
by patid issuedate prodcode: replace daily_dose2 = daily_dose2[_n + 1] if daily_dose2 ==. & dup_flag == 1 & dup_flag[_n + 1] == 1

* Generate exposure duration from quantity and daily dose. Replace implausible values as missing
noi di "Generate exposure duration from quantity and daily dose. Replace implausible values as missing"
gen days = quantity2 / daily_dose2
replace days = round(days,1)
order days, after(duration)
tab days
replace days =. if days > 120
replace days =. if days < 7

* Combine length and quantity of "duplicate" prescriptions 
noi di "Combine length and quantity of duplicate prescriptions "
bysort patid issuedate prodcodeid : egen sum_quant = sum(quantity2) if duplicate >= 1
bysort patid issuedate prodcodeid : egen sum_length = sum(length2) if duplicate >= 1
bysort patid issuedate prodcodeid : egen sum_days = sum(days) if duplicate >= 1
order (sum_quant sum_length sum_days), after(quantity)

* Keep "last" observations where duplicate
noi di "keep last observations where duplicate"
keep if counter == counter2
drop counter2 dup_flag duplicate_all duplicate

* Insert quantity and length to sum_quant or sum_length variables where these are missing
noi di "insert quantity and length to sum_quant or sum_length variables where these are missing"
replace sum_quant = quantity2 if sum_quant ==.
replace sum_quant =. if sum_quant < 10
replace sum_length = length2 if sum_length ==.
replace sum_length =. if sum_length < 7
replace sum_days =. if sum_days == 0
replace sum_days = days if sum_days ==. 
//sum_quant and sum_length are now the "correct" lengths and quantities

tab sum_quant
tab sum_length
tab sum_days

noi di "count if duration == 0 & days ==. "
count if duration == 0 & days ==. 

gen diff_duration = days - sum_length
tab diff_duration

noi di "count if diff_duration != 0 "
count if diff_duration != 0 
order diff_duration, after(days)

* Label and save data
label data "All `drugclass' prescriptions in study period"
save "$Datadir\intermediate\\`drugclass'_instudy.dta", replace

}

log close 
clear all

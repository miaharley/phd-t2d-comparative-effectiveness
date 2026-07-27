/*==============================================================================
DO FILE NAME:			C4c - exposure - identify treatment episodes.do

AUTHOR:					Mia Harley,  adapted from Marleen's do files

DATE CREATED: 			03/2024

DATE LAST UPDATED: 		11/2024
						
DATASETS CREATED:       2ndline_treatmentepisodes_`x'd.dta
					
DESCRIPTION OF FILE:	Identifies treatment episodes for 2nd line treatment during study period
*===============================================================================*/

clear all

* Log
cap log close
log using $Logdir/C4c_treatment_episodes.log, replace

********************************************************************************
** Combine exposure files for each class of medication **
********************************************************************************

* Append datafiles
use "$Datadir\intermediate\su_exposure.dta", clear
append using "$Datadir\intermediate\dpp4i_exposure.dta"
append using "$Datadir\intermediate\sglt2i_exposure.dta"

* Generate a variable for treatment class (combining single and dual therapies w/ metformin)
gen treatmentclass=.
replace treatmentclass=1 if dmrxclass==5
replace treatmentclass=2 if (dmrxclass==3 | dmrxclass==8)
replace treatmentclass=3 if (dmrxclass==4 | dmrxclass==10)

* Label treatment group variable
label define treatmentclass 1 "SU" 2 "DPP4i" 3 "SGLT2i"
label values treatmentclass treatmentclass
lab var treatmentclass "Class of treatment"
order treatmentclass, after(issuedate)

* Tidy and save
compress
save "$Datadir\intermediate\2ndline_exposure.dta", replace

********************************************************************************
** Identify treatment episodes **
********************************************************************************
use "$Datadir\intermediate\2ndline_exposure.dta", clear

* Drop all unnecessary variables, only keep patid, issue date, end of exposure date and treatment class
keep patid issuedate end_exp treatmentclass
order patid treatmentclass issuedate end_exp

* Create counter for each prescription by date and class
sort patid issuedate
bysort patid treatmentclass (issuedate): gen episode = _n

* Reshape data so that start and end date for each issue are different observations
rename (issuedate end_exp) (date1 date2)
reshape long date, i(patid treatmentclass episode) j(startend)

* Encode the start and end for ranking the order
gen startend2 = 0 if startend == 1
replace startend2 = 1 if startend == 2

* Sort by patid, treatment class, date (and within date, start and end), subtract number of preceding end dates from number of preceding starts
by patid treatmentclass (date startend2), sort: gen int in_proc = sum(startend == 1) - sum(startend == 2)
replace in_proc = 1 if in_proc > 1

by patid treatmentclass (date): gen block_num = 1 if in_proc == 1 & in_proc[_n - 1] != 1 //**1s now denote start of new block
by patid treatmentclass (date): replace block_num = sum(block_num) //***count number of blocks per patient

* Check that a patient's first date is the start of a block (1) and the last date is an end of a block (2)
by patid treatmentclass block_num (date), sort: assert startend == 1 if _n == 1
by patid treatmentclass block_num (date): assert startend == 2 if _n == _N

* Keep only start and end of blocks
by patid treatmentclass block_num (date): keep if _n == 1 | _n == _N

* Reshape data
drop episode in_proc startend2 
reshape wide date, i(patid treatmentclass block_num) j(startend)

* Create counter for each episode
bysort patid treatmentclass (date1): gen episode = _n
keep patid episode date1 date2 treatmentclass

* Merge in patient data to get registration start and end date
merge m:1 patid using $included, keepusing(firstissue enddate treatmentgroup) keep(match) nogen
assert treatmentgroup==treatmentclass if date1==firstissue

* Generate variable init denoting initiation
sort patid treatmentclass date1
bysort patid treatmentclass (date1): gen init = 1 if (episode == 1) | date1 - date2[_n - 1] > 365

* Generate variable to denote month of episode start
g dm = mofd(date1)
format dm %tm

* Check that for each issue the exposure end date (date2) occurs before the exposure start date (date1) of next issue
bysort patid treatmentclass (date1): assert date2 < date1[_n + 1]

********************************************************************************
** Assess discontinuations, allowing 60 day grace periods **
********************************************************************************

* Reshape data to identify gaps
reshape long date, i(patid episode treatmentclass) j(startend)
format date %td

gen startend2 = 0 if startend == 1
replace startend2 = 1 if startend == 2

* Flag startdates that are < 60 days after previous enddate
by patid treatmentclass (date startend2), sort: gen no_gap = 1 if startend == 1 & (date - date[_n - 1] <= 60) 

* Flag end dates that are followed by start date within x days
replace no_gap = 1 if startend == 2 & no_gap[_n + 1] == 1

* Flag if episode belongs to the same treatment block as other episodes
egen no_gap_max = max(no_gap), by (patid treatmentclass episode)

* Only keep issue dates that are >60 days apart
keep if no_gap ==.

* Drop unncessary variables 
drop no_gap no_gap_max episode startend2 dm init

* Change the episode no as rx and reshape back to wide form, so that there each observation is an episode
egen rx = seq(), f(1) b(2)
reshape wide date, i(patid treatmentclass rx) j(startend)

* Generate variable to denote month of episode start
g dm = mofd(date1)
format dm %tm

* Add 60 days onto end of exposure date (in line with grace period)
replace date2 = date2 + 60
bysort patid treatmentclass (date1): assert date2 < date1[_n + 1]

* Replace date2 with registration end or death if this occurs first
replace date2 = enddate if enddate < date2

* Tidy and save
rename (date1 date2) (epistart epiend)
keep patid treatmentclass epistart epiend
save "$Datadir\derived\2ndline_treatmentepisodes.dta", replace

log close
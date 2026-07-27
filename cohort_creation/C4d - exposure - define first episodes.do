/*==============================================================================
DO FILE NAME:			C4d - exposure - define first episodes.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2025

DATE LAST UPDATED: 		03/2025
						
DATASETS CREATED:       2ndline_firstepisode.dta
					
DESCRIPTION OF FILE:	Defines start and end date of first episode of 2nd line treatment, including treatment switching
*===============================================================================*/

clear all

* Log
cap log close
log using $Logdir/C4d_define_first_episode.log, replace

********************************************************************************
** Check for other antidiabetic prescriptions **
********************************************************************************
* Get up all extracted records of antidiabetics excluding metformin
use "$Datadir/intermediate/antidiabetics_exceptmetformin.dta", clear
keep patid issuedate dmrxclass

* Create variable for treatment class
gen treatmentclass=9
replace treatmentclass=1 if dmrxclass==5
replace treatmentclass=2 if (dmrxclass==3 | dmrxclass==8)
replace treatmentclass=3 if (dmrxclass==4 | dmrxclass==10)

* Label treatment class variable
label define treatmentclass 1 "SU" 2 "DPP4i" 3 "SGLT2i" 4 "Other"
label values treatmentclass treatmentclass
lab var treatmentclass "Class of treatment"

* Keep records for included population
merge m:1 patid using $included, keepusing(firstissue enddate treatmentgroup) keep(match) nogen

* Drop records outside follow up period
drop if issuedate < firstissue
drop if issuedate > enddate

* Drop records of exposure medication
drop if treatmentclass==treatmentgroup

* Keep earliest in-study issue
bysort patid (issuedate): keep if _n == 1

* Tidy and save
rename treatmentclass treatmentclass_x
keep patid issuedate treatmentclass_x dmrxclass
save "$Datadir/temporary/antidiabetics_exceptmetformin_instudy.dta", replace

********************************************************************************
** Combine exposure files for each class of medication **
********************************************************************************
use "$Datadir\derived\2ndline_treatmentepisodes.dta", clear

* Count days between each treatment episode
sort patid epistart
bysort patid (epistart): gen daysdiff = epistart[_n + 1] - epiend

* Make sure there are no overlapping episodes of the same class
bysort patid (epistart): assert treatmentclass != treatmentclass[_n + 1] if daysdiff <0

* End previous episode at the start of new treatment episode
gen treatmentswitch=.
sort patid epistart
bysort patid (epistart): replace treatmentswitch=1 if daysdiff <0
bysort patid (epistart): replace epiend = epistart[_n + 1] if treatmentswitch==1

* Keep first treatment episode per patient
bysort patid (epistart): keep if _n == 1
drop daysdiff treatmentswitch

* Check first episode aligns with firstissue, treatment group and is before enddate
merge 1:1 patid using $included, keepusing(firstissue enddate treatmentgroup) keep(match) nogen
assert treatmentclass == treatmentgroup
assert epistart == firstissue
assert epiend <= enddate

* Merge in dataset with other antidiabetic drug issues
merge 1:1 patid using "$Datadir/temporary/antidiabetics_exceptmetformin_instudy.dta", keep(master match)
assert treatmentclass != treatmentclass_x
gen treatmentswitch=.
replace treatmentswitch=1 if issuedate < epiend
replace epiend=issuedate if treatmentswitch==1

* Tidy and save
keep patid treatmentclass epistart epiend
save "$Datadir\derived\2ndline_firstepisode.dta", replace

log close

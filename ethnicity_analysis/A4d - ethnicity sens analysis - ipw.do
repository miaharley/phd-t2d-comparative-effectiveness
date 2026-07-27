/*==============================================================================
DO FILE NAME:			A11 - ethnicity sens analysis - ipw

AUTHOR:					Mia Harley

DATE CREATED: 			03/2025
						
DATA UPDATED:      		03/2025
					
DESCRIPTION OF FILE:	Creates PS scores, runs ipw
*=============================================================================*/

* Log
cap log close
log using $Logdir/A4d_ethnicity_sens_analysis_ipw.log, replace

* Set dataset and outcomes
local outcomes mace

foreach outcome in `outcomes' {
		
********************************************************************************
** Generate PS scores ***
********************************************************************************
use $study_cohort_cca, clear

* Create end of follow-up
cap drop end_followup_`outcome' followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

* Create new ethnicity variable for IPW
gen eth_new=1 if (ethnicity==1 | ethnicity==4 | ethnicity==5 | ethnicity==6)
replace eth_new=2 if ethnicity==2
replace eth_new=3 if ethnicity==3

* Create model for treatment allocation
mlogit treatmentgroup ethnicity age_index gender##eth_new i.imd##eth_new i.region##eth_new bmi##eth_new hba1c##eth_new egfr##eth_new alcoholabuse##eth_new i.smoking##eth_new healthcare##eth_new af##eth_new pad##eth_new hypertension##eth_new neuropathy##eth_new retinopathy##eth_new cancer##eth_new liverdisease##eth_new crd##eth_new ra##eth_new dementia##eth_new smi##eth_new cmd##eth_new acei##eth_new arb##eth_new ccb##eth_new diuretics##eth_new statins##eth_new antiplat##eth_new anticoag##eth_new antipsych##eth_new, base

* Predict propensity scores for each treatment class
predict ps1 ps2 ps3, pr

* Identify the max and min pscore by exposure for trimming
forval z = 1/3 {
bysort treatmentgroup: su ps`z', detail
bysort treatmentgroup: egen min_ps`z' = min(ps`z')
bysort treatmentgroup: egen max_ps`z' = max(ps`z')
	
* Trim the tails
egen ps`z'_lower_tail =  max(min_ps`z')
egen ps`z'_upper_tail =  min(max_ps`z')
drop if ps`z' < ps`z'_lower_tail
drop if ps`z' > ps`z'_upper_tail
drop min_ps`z' max_ps`z' ps`z'_lower_tail ps`z'_upper_tail
}

* Calculate weights: 1/ probability of treatment received
gen ipw = 1/ps1 if treatmentgroup == 1
replace ipw = 1/ps2 if treatmentgroup == 2
replace ipw =1/ps3 if treatmentgroup == 3


********************************************************************************
** Create table **
********************************************************************************
putexcel set "$Outputdir/Ethnicity sens analysis - ipw.xlsx", sheet("`outcome'") modify

putexcel B1 = "White"
putexcel C1 = "South Asian"
putexcel D1 = "Black"
putexcel E1 = "TOTAL"

putexcel A2 = "DPP4i vs SU (ref)"
putexcel A4 = "SGLT2i vs SU (ref)"
putexcel A6 = "SGLT2i vs DPP4i (ref)"

********************************************************************************
** Overall analyses (no interaction term) **
********************************************************************************

stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup, base

* DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel E3 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* SGLT2i vs SU
lincom 3.treatmentgroup, eform
putexcel E5 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
putexcel E7 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

********************************************************************************
** Interaction term analyses **
********************************************************************************

stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup##ethnicity, base

* White DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel B3 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* White SGLT2i vs SU
lincom 3.treatmentgroup, eform
putexcel B5 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* White SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
putexcel B7 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* South Asian DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#2.ethnicity, eform
putexcel C3 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* South Asian SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#2.ethnicity, eform
putexcel C5  = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* South Asian SGLT2i vs DPP4i
lincom (3.treatmentgroup + 3.treatmentgroup#2.ethnicity) - (2.treatmentgroup + 2.treatmentgroup#2.ethnicity), eform
putexcel C7 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")
	
* Black DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#3.ethnicity, eform
putexcel D3  = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Black SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#3.ethnicity, eform
putexcel D5 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Black SGLT2i vs DPP4i
lincom (3.treatmentgroup + 3.treatmentgroup#3.ethnicity) - (2.treatmentgroup + 2.treatmentgroup#3.ethnicity), eform
putexcel D7 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

********************************************************************************
** Wald test for interaction **
********************************************************************************
stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup##i.ethnicity, base

* DPP4i vs SU
test 2.treatmentgroup#1.ethnicity 2.treatmentgroup#2.ethnicity 2.treatmentgroup#3.ethnicity
putexcel B2 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))

* SGLT2i vs SU
test 3.treatmentgroup#1.ethnicity 3.treatmentgroup#2.ethnicity 3.treatmentgroup#3.ethnicity
putexcel B4 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))

* SGLT2i vs DPP4i
stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox ib2.treatmentgroup##i.ethnicity, base
test 3.treatmentgroup#1.ethnicity 3.treatmentgroup#2.ethnicity 3.treatmentgroup#3.ethnicity 
putexcel B6 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))
}

log close
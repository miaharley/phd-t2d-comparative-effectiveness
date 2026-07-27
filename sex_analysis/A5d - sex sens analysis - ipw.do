/*==============================================================================
DO FILE NAME:			A5c - sex sens analysis - ipw

AUTHOR:					Mia Harley

DATE CREATED: 			03/2025
						
DATA UPDATED:      		03/2025
					
DESCRIPTION OF FILE:	Creates PS scores, gets hazard ratios adjusting for ipw
*=============================================================================*/

* Log
cap log close
log using $Logdir/A5c_sex_sens_analysis_ipw.log, replace

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

* Create model for treatment allocation
mlogit treatmentgroup ethnicity age_index ethnicity##gender i.imd##gender i.region##gender i.bmi_cat##gender i.hba1c_cat##gender alcoholabuse##gender i.smoking##gender healthcare##gender af##gender pad##gender hypertension##gender ckd##gender neuropathy##gender retinopathy##gender cancer##gender liverdisease##gender crd##gender ra##gender dementia##gender smi##gender cmd##gender acei##gender arb##gender ccb##gender diuretics##gender statins##gender antiplat##gender anticoag##gender antipsych##gender, base

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
putexcel set "$Outputdir/Sex sens analysis - ipw.xlsx", sheet("`outcome'") modify

putexcel B1 = "Male"
putexcel C1 = "Female"
putexcel D1 = "TOTAL"

putexcel A2 = "DPP4i vs SU (ref)"
putexcel A4 = "SGLT2i vs SU (ref)"
putexcel A6 = "SGLT2i vs DPP4i (ref)"

********************************************************************************
** No interaction term **
********************************************************************************

stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup, base

* DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel D3 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* SGLT2i vs SU
lincom 3.treatmentgroup, eform
putexcel D5 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
putexcel D7 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

********************************************************************************
** Interaction term **
********************************************************************************

stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup##i.gender, base

* Male DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel B3 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Male SGLT2i vs SU
lincom 3.treatmentgroup, eform
putexcel B5 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Male SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
putexcel B7 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#2.gender, eform
putexcel C3 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#2.gender, eform
putexcel C5  = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female SGLT2i vs DPP4i
lincom (3.treatmentgroup + 3.treatmentgroup#2.gender) - (2.treatmentgroup + 2.treatmentgroup#2.gender), eform
putexcel C7 = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

********************************************************************************
** Wald test for interaction **
********************************************************************************

stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup##i.gender, base

* DPP4i vs SU
test 2.treatmentgroup#1.gender 2.treatmentgroup#2.gender
putexcel B2 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))

* SGLT2i vs SU
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B4 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))

* SGLT2i vs DPP4i
stset end_followup_`outcome' [pweight = ipw], fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox ib2.treatmentgroup##i.gender, base
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B6 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))
}

log close
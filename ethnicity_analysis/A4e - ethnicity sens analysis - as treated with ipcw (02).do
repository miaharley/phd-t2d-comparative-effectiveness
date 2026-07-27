/*==============================================================================
DO FILE NAME:			A12 - ethnicity sens analysis - as treated with ipcw

AUTHOR:					Mia Harley

DATE CREATED: 			10/2025
						
DATA UPDATED:      		10/2025
					
DESCRIPTION OF FILE:	Estimates propability of censoring weights
*=============================================================================*/

* Log
cap log close
log using $Logdir/A4e_ethnicity_sens_analysis_ipcw_weights.log, replace

* Identify if follow up ends due to change in treatment
use $study_cohort_cca, clear

* Create end of follow-up
local outcome mace
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' = min(`outcome'_date, enddate, epiend)
format end_followup_`outcome' %td
replace `outcome'_date =. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

* Create variable for reason for end of follow up (1=mace event, 2=non-informative censoring, 3=informative censoring)
gen end_followup_reason = 3 if end_followup_mace== epiend
replace end_followup_reason = 2 if end_followup_mace==enddate
replace end_followup_reason = 1 if end_followup_mace==mace_date

* Set as survival data
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid)

* Split data into person-month intervals
stsplit interval, every(30)

* Identify last interval for each patient
bysort patid (interval): gen last_interval = 1 if _n == _N

* Flag intervals where informative censoring occured
gen inform_cens = 0
replace inform_cens = 1 if end_followup_reason==3 & last_interval==1

********************************************************************************
* Model denominator censoring probability with covariates
********************************************************************************
* Take spline of _t
mkspline _t_sp = _t, cubic nknots(4)

* Model denominator censoring probability with all baseline covariates
logit inform_cens $full_adj_covariates _t_sp1 _t_sp2 _t_sp3
	
* Predict probability of censoring in interval using denominator model
predict pr_censor_denom if e(sample)

* Set censoring probability to 0 for intervals where event occurred
replace pr_censor_denom = 0 if _d == 1

* Calculate probability of not being censored in interval
gen pr_uncensored_denom = 1 - pr_censor_denom

* Cumulative probability of not being censored in interval
sort patid _t
by patid: gen cum_pr_uncensored_denom = pr_uncensored_denom if _n==1
by patid: replace cum_pr_uncensored_denom = pr_uncensored_denom*cum_pr_uncensored_denom[_n-1] if _n!=1
summ cum_pr_uncensored_denom, detail

* Should be between 0 and 1, and should decrease over time
assert cum_pr_uncensored_denom >= 0 & cum_pr_uncensored_denom <= 1

********************************************************************************
* Model numerator censoring probability without covariates (stabilization)
********************************************************************************

* Model numerator censoring probability with just treatment group and time
logit inform_cens i.treatmentgroup _t_sp1 _t_sp2 _t_sp3 
	
* Predict probability of censoring in interval using numerator model
predict pr_censor_numer if e(sample)

* Set censoring probability to 0 for intervals where event occurred
replace pr_censor_numer = 0 if _d == 1

* Calculate probability of not being censored in interval
gen pr_uncensored_numer = 1 - pr_censor_numer

* Cumulative probability of not being censored in interval
sort patid _t
by patid: gen cum_pr_uncensored_numer = pr_uncensored_numer if _n==1
by patid: replace cum_pr_uncensored_numer = pr_uncensored_numer*cum_pr_uncensored_numer[_n-1] if _n!=1
summ cum_pr_uncensored_numer, detail

* Should be between 0 and 1, and should decrease over time
assert cum_pr_uncensored_numer >= 0 & cum_pr_uncensored_numer <= 1

********************************************************************************
* Calculate stabilized weights
********************************************************************************

* Stabilized weight = numerator / denominator
gen sw_ipcw = cum_pr_uncensored_numer / cum_pr_uncensored_denom

* Check for extreme weights
count if sw_ipcw < 0.1 //n=0
count if sw_ipcw > 10 //n=250

* Truncate at 1st and 99th percentiles to reduce influence of outliers
_pctile sw_ipcw, p(1 99)
local p1 = r(r1)
local p99 = r(r2)

display "1st percentile: `p1'"
display "99th percentile: `p99'"

gen sw_ipcw_trunc = sw_ipcw
replace sw_ipcw_trunc = `p1' if sw_ipcw < `p1'
replace sw_ipcw_trunc = `p99' if sw_ipcw > `p99' & !missing(sw_ipcw)

* Compare before and after truncation
summ sw_ipcw sw_ipcw_trunc, detail

* Histogram after truncation
histogram sw_ipcw_trunc, width(0.1) frequency ///
    title("Distribution of Truncated IPCW Weights in overall population") ///
    xtitle("Weight") ytitle("Frequency")
	
* Same bins for fair comparison
histogram sw_ipcw_trunc if _st, ///
    by(treatmentgroup, total row(1)) ///
    width(0.1) start(0) percent ///
    xtitle("IPCW (truncated)") ytitle("Percent") ///
    title("IPCW weights by treatment (faceted)")
	
* Overlaid histograms with transparency
twoway (histogram sw_ipcw_trunc if treatment==1, width(0.1) ///
            fcolor(red%30) lcolor(red) frequency) ///
       (histogram sw_ipcw_trunc if treatment==2, width(0.1) ///
            fcolor(blue%30) lcolor(blue) frequency) ///
       (histogram sw_ipcw_trunc if treatment==3, width(0.1) ///
            fcolor(green%30) lcolor(green) frequency), ///
       legend(label(1 "SU") label(2 "DPP4i") label(3 "SGLT2i")) ///
       title("Distribution of Truncated IPCW Weights by Treatment") ///
       xtitle("Weight") ytitle("Frequency")
	   
* Separate histograms in panels (easier to read)
histogram sw_ipcw_trunc, width(0.1) frequency ///
    by(treatment, ///
       title("Distribution of weights by treatment group") ///
       note("") ///
       legend(off)) ///
    xtitle("Weight") ytitle("Frequency")
	
* Save dataset wtih weights
save "$Datadir/derived/study_cohort_ipcw.dta", replace

********************************************************************************
** Create table **
********************************************************************************
putexcel set "$Outputdir/Ethnicity sens analysis - as treated ipcw.xlsx", sheet("mace") modify

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

use "$Datadir/derived/study_cohort_ipcw.dta", clear
stset end_followup_mace [pweight=sw_ipcw_trunc], fail(mace) origin(firstissue) enter(firstissue)
stcox i.treatmentgroup $full_adj_covariates, base cluster(patid)

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

* Stcox on dataset with multiple observations per patient with weights (clustered by patid) (but without patid in stset)
use "$Datadir/derived/study_cohort_ipcw.dta", clear
stset end_followup_mace [pweight=sw_ipcw_trunc], fail(mace) origin(firstissue) enter(firstissue)
stcox i.treatmentgroup##i.ethnicity $full_adj_covariates, base cluster(patid)

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
* DPP4i vs SU
test 2.treatmentgroup#1.ethnicity 2.treatmentgroup#2.ethnicity 2.treatmentgroup#3.ethnicity
putexcel B2 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))

* SGLT2i vs SU
test 3.treatmentgroup#1.ethnicity 3.treatmentgroup#2.ethnicity 3.treatmentgroup#3.ethnicity
putexcel B4 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))

* SGLT2i vs DPP4i
stset end_followup_mace [pweight=sw_ipcw_trunc], fail(mace) origin(firstissue) enter(firstissue)
stcox ib2.treatmentgroup##i.ethnicity $full_adj_covariates, base cluster(patid)
test 3.treatmentgroup#1.ethnicity 3.treatmentgroup#2.ethnicity 3.treatmentgroup#3.ethnicity 
putexcel B6 = ("Test for interaction: p-value=" + string(r(p), "%9.3f"))

log close
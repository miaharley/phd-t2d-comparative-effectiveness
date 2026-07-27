/*==============================================================================
DO FILE NAME:			A4b - sex subgroup forestplot.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2025
						
DATA UPDATED:      		08/2025
					
DESCRIPTION OF FILE:	Creates excel file for subgroup analysis forest plot
*=============================================================================*/

* Log
cap log close
log using $Logdir\A4b_sex_subgroup_forest_plot.log, replace

********************************************************************************
** Set locals **
********************************************************************************

local under55 3
local over55 14

local male 1
local female 2

local su 1
local dpp4i 2
local sglt2i 3

local outcome mace

********************************************************************************
** Create table **
********************************************************************************
putexcel set "$Outputdir\Sex subgroup forest plot.xlsx", sheet("Sheet1") modify

putexcel A1 = "variable"
putexcel B1 = "sample_A"
putexcel C1 = "sample_B"
putexcel D1 = "point_estimate"
putexcel E1 = "low"
putexcel F1 = "high"
putexcel G1 = "hr_ci"
putexcel H1 = "p_interaction"

putexcel A`under55' = "≤55 years"
putexcel A`over55' = ">55 years"

foreach age_group in over55 under55 {
putexcel A`=``age_group''+1' = "DPP4i vs SU"
putexcel A`=``age_group''+2' = "Male"
putexcel A`=``age_group''+3' = "Female"
putexcel A`=``age_group''+4' = "SGLT2i vs SU"
putexcel A`=``age_group''+5' = "Male"
putexcel A`=``age_group''+6' = "Female"
putexcel A`=``age_group''+7' = "SGLT2i vs DPP4i"
putexcel A`=``age_group''+8' = "Male"
putexcel A`=``age_group''+9' = "Female"
}

********************************************************************************
** Get event numbers and sample sizes **
********************************************************************************

foreach age_group in over55 under55 {
	
use "$Datadir/derived/study_cohort.dta", clear

* Create end of follow-up for each outcome
cap drop end_followup_mace  followup_years_mace
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

if "`age_group'"=="under55" {
keep if age_index <= 55
}

if "`age_group'"=="over55" {
keep if age_index > 55
}

* Get event and sample for each treatment and sex group
foreach sex in male female{
foreach treatmentgroup in su dpp4i sglt2i{
	
count if treatmentgroup==``treatmentgroup'' & gender==``sex'' & `outcome'==1
local events `r(N)'
count if treatmentgroup==``treatmentgroup'' & gender==``sex''
local total `r(N)'
local `sex'_`treatmentgroup'_n = string(`events', "%9.0f") + "/" + string(`total', "%9.0f")
}
}

* DPP4i vs SU
putexcel B`=``age_group''+2' = "`male_dpp4i_n'"
putexcel C`=``age_group''+2' = "`male_su_n'"
putexcel B`=``age_group''+3' = "`female_dpp4i_n'"
putexcel C`=``age_group''+3' = "`female_su_n'"
* SGLT2is vs SU
putexcel B`=``age_group''+5' = "`male_sglt2i_n'"
putexcel C`=``age_group''+5' = "`male_su_n'"
putexcel B`=``age_group''+6' = "`female_sglt2i_n'"
putexcel C`=``age_group''+6' = "`female_su_n'"
* SGLT2is vs DPP4i
putexcel B`=``age_group''+8' = "`male_sglt2i_n'"
putexcel C`=``age_group''+8' = "`male_dpp4i_n'"
putexcel B`=``age_group''+9' = "`female_sglt2i_n'"
putexcel C`=``age_group''+9' = "`female_dpp4i_n'"

}

********************************************************************************
** Get hazard ratios **
********************************************************************************

foreach age_group in over55 under55 {
use "$Datadir/derived/study_cohort_mi.dta", clear

* Create end of follow-up for each outcome
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

if "`age_group'"=="under55" {
keep if age_index <= 55
}

if "`age_group'"=="over55" {
keep if age_index > 55
}
	
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox i.treatmentgroup##i.gender $full_adj_covariates, base

* Male DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel D`=``age_group''+2' = `=r(estimate)'
putexcel E`=``age_group''+2' = `=r(lb)'
putexcel F`=``age_group''+2' = `=r(ub)'
putexcel G`=``age_group''+2' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#2.gender, eform
putexcel D`=``age_group''+3' = `=r(estimate)'
putexcel E`=``age_group''+3' = `=r(lb)'
putexcel F`=``age_group''+3' = `=r(ub)'
putexcel G`=``age_group''+3' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Test for interaction DPP4i vs SU
mi test 2.treatmentgroup#1.gender 2.treatmentgroup#2.gender
putexcel H`=``age_group''+1' = (string(r(p),"%9.4f"))

* Male SGLT2i vs SU
lincom 3.treatmentgroup, eform
putexcel D`=``age_group''+5' = `=r(estimate)'
putexcel E`=``age_group''+5' = `=r(lb)'
putexcel F`=``age_group''+5' = `=r(ub)'
putexcel G`=``age_group''+5' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#2.gender, eform
putexcel D`=``age_group''+6' = `=r(estimate)'
putexcel E`=``age_group''+6' = `=r(lb)'
putexcel F`=``age_group''+6' = `=r(ub)'
putexcel G`=``age_group''+6' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Test for interaction SGLT2i vs SU
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel H`=``age_group''+4' = (string(r(p),"%9.4f"))

* Male SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
putexcel D`=``age_group''+8' = `=r(estimate)'
putexcel E`=``age_group''+8' = `=r(lb)'
putexcel F`=``age_group''+8' = `=r(ub)'
putexcel G`=``age_group''+8' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female SGLT2i vs DPP4i
lincom (3.treatmentgroup+ 3.treatmentgroup#2.gender) - (2.treatmentgroup+ 2.treatmentgroup#2.gender), eform
putexcel D`=``age_group''+9' = `=r(estimate)'
putexcel E`=``age_group''+9' = `=r(lb)'
putexcel F`=``age_group''+9' = `=r(ub)'
putexcel G`=``age_group''+9' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Test for interaction SGLT2i vs DPP4i
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox ib2.treatmentgroup##i.gender $full_adj_covariates, base
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel H`=``age_group''+7' = (string(r(p),"%9.4f"))

}

log close

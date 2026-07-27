/*==============================================================================
DO FILE NAME:			A7 - ethnicity forest plot.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		03/2025
					
DESCRIPTION OF FILE:	Main analysis for all outcomes using mi to handle missing data and intention to treat as the exposure definition
*=============================================================================*/

* Log
cap log close
log using $Logdir\A7_ethnicity_forest_plot.log, replace

********************************************************************************
** Set locals **
********************************************************************************

local mace 3
local mi 17
local stroke 31
local hf 45
local cvddeath 59

local white 1
local southasian 2
local black 3

local su 1
local dpp4i 2
local sglt2i 3

********************************************************************************
** Create table **
********************************************************************************
putexcel set "$Outputdir\Ethnicity forest plot.xlsx", sheet("Sheet1") modify

putexcel A1 = "variable"
putexcel B1 = "sample_A"
putexcel C1 = "sample_B"
putexcel D1 = "point_estimate"
putexcel E1 = "low"
putexcel F1 = "high"
putexcel G1 = "hr_ci"
putexcel H1 = "p_interaction"

putexcel A`mace' = "MACE"
putexcel A`mi' = "Myocardial infarction"
putexcel A`stroke' = "Stroke"
putexcel A`hf' = "Heart failure hospitalisation"
putexcel A`cvddeath' = "Cardiovascular death"

foreach outcome in mace mi stroke hf cvddeath {
putexcel A`=``outcome''+1' = "DPP4i vs SU"
putexcel A`=``outcome''+2' = "White"
putexcel A`=``outcome''+3' = "South Asian"
putexcel A`=``outcome''+4' = "Black"
putexcel A`=``outcome''+5' = "SGLT2i vs SU"
putexcel A`=``outcome''+6' = "White"
putexcel A`=``outcome''+7' = "South Asian"
putexcel A`=``outcome''+8' = "Black"
putexcel A`=``outcome''+9' = "SGLT2i vs DPP4i"
putexcel A`=``outcome''+10' = "White"
putexcel A`=``outcome''+11' = "South Asian"
putexcel A`=``outcome''+12' = "Black"
}

********************************************************************************
** Get event numbers and sample sizes **
********************************************************************************

use "$Datadir/derived/study_cohort.dta", clear

foreach outcome in mace mi stroke cvddeath hf {

cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

* Get event and sample for each treatment and ethnic group
foreach ethnicity in white southasian black{
foreach treatmentgroup in su dpp4i sglt2i{
	
count if treatmentgroup==``treatmentgroup'' & ethnicity==``ethnicity'' & `outcome'==1
local events `r(N)'
count if treatmentgroup==``treatmentgroup'' & ethnicity==``ethnicity''
local total `r(N)'
local `ethnicity'_`treatmentgroup'_n = string(`events', "%9.0f") + "/" + string(`total', "%9.0f")
}
}

* DPP4i vs SU
putexcel B`=``outcome''+2' = "`white_dpp4i_n'"
putexcel C`=``outcome''+2' = "`white_sglt2i_n'"
putexcel B`=``outcome''+3' = "`southasian_dpp4i_n'"
putexcel C`=``outcome''+3' = "`southasian_su_n'"
putexcel B`=``outcome''+4' = "`black_dpp4i_n'"
putexcel C`=``outcome''+4' = "`black_su_n'"
* SGLT2is vs SU
putexcel B`=``outcome''+6' = "`white_sglt2i_n'"
putexcel C`=``outcome''+6' = "`white_su_n'"
putexcel B`=``outcome''+7' = "`southasian_sglt2i_n'"
putexcel C`=``outcome''+7' = "`southasian_su_n'"
putexcel B`=``outcome''+8' = "`black_sglt2i_n'"
putexcel C`=``outcome''+8' = "`black_su_n'"
* SGLT2is vs DPP4i
putexcel B`=``outcome''+10' = "`white_sglt2i_n'"
putexcel C`=``outcome''+10' = "`white_dpp4i_n'"
putexcel B`=``outcome''+11' = "`southasian_sglt2i_n'"
putexcel C`=``outcome''+11' = "`southasian_dpp4i_n'"
putexcel B`=``outcome''+12' = "`black_sglt2i_n'"
putexcel C`=``outcome''+12' = "`black_dpp4i_n'"

}
	
********************************************************************************
** Get hazard ratios **
********************************************************************************

foreach outcome in mace mi cvddeath stroke hf {
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
	
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox i.treatmentgroup##i.ethnicity $full_adj_covariates, base

* White DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel D`=``outcome''+2' = `=r(estimate)'
putexcel E`=``outcome''+2' = `=r(lb)'
putexcel F`=``outcome''+2' = `=r(ub)'
putexcel G`=``outcome''+2' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* South Asian DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#2.ethnicity, eform
putexcel D`=``outcome''+3' = `=r(estimate)'
putexcel E`=``outcome''+3' = `=r(lb)'
putexcel F`=``outcome''+3' = `=r(ub)'
putexcel G`=``outcome''+3' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Black DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#3.ethnicity, eform
putexcel D`=``outcome''+4' = `=r(estimate)'
putexcel E`=``outcome''+4' = `=r(lb)'
putexcel F`=``outcome''+4' = `=r(ub)'
putexcel G`=``outcome''+4' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Test for interaction DPP4i vs SU
mi test 2.treatmentgroup#1.ethnicity 2.treatmentgroup#2.ethnicity 2.treatmentgroup#3.ethnicity
putexcel H`=``outcome''+1' = (string(r(p),"%9.2f"))

* White SGLT2i vs SU
lincom 3.treatmentgroup, eform
putexcel D`=``outcome''+6' = `=r(estimate)'
putexcel E`=``outcome''+6' = `=r(lb)'
putexcel F`=``outcome''+6' = `=r(ub)'
putexcel G`=``outcome''+6' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* South Asian SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#2.ethnicity, eform
putexcel D`=``outcome''+7' = `=r(estimate)'
putexcel E`=``outcome''+7' = `=r(lb)'
putexcel F`=``outcome''+7' = `=r(ub)'
putexcel G`=``outcome''+7' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Black SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#3.ethnicity, eform
putexcel D`=``outcome''+8' = `=r(estimate)'
putexcel E`=``outcome''+8' = `=r(lb)'
putexcel F`=``outcome''+8' = `=r(ub)'
putexcel G`=``outcome''+8' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Test for interaction SGLT2i vs SU
mi test 3.treatmentgroup#1.ethnicity 3.treatmentgroup#2.ethnicity 3.treatmentgroup#3.ethnicity
putexcel H`=``outcome''+5' = (string(r(p),"%9.2f"))

* White SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
putexcel D`=``outcome''+10' = `=r(estimate)'
putexcel E`=``outcome''+10' = `=r(lb)'
putexcel F`=``outcome''+10' = `=r(ub)'
putexcel G`=``outcome''+10' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* South Asian SGLT2i vs DPP4i
lincom (3.treatmentgroup+ 3.treatmentgroup#2.ethnicity) - (2.treatmentgroup+ 2.treatmentgroup#2.ethnicity), eform
putexcel D`=``outcome''+11' = `=r(estimate)'
putexcel E`=``outcome''+11' = `=r(lb)'
putexcel F`=``outcome''+11' = `=r(ub)'
putexcel G`=``outcome''+11' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Black SGLT2i vs DPP4i
lincom (3.treatmentgroup+ 3.treatmentgroup#3.ethnicity) - (2.treatmentgroup+ 2.treatmentgroup#3.ethnicity), eform
putexcel D`=``outcome''+12' = `=r(estimate)'
putexcel E`=``outcome''+12' = `=r(lb)'
putexcel F`=``outcome''+12' = `=r(ub)'
putexcel G`=``outcome''+12' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Test for interaction SGLT2i vs DPP4i
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox ib2.treatmentgroup##i.ethnicity $full_adj_covariates, base
mi test 3.treatmentgroup#1.ethnicity 3.treatmentgroup#2.ethnicity 3.treatmentgroup#3.ethnicity
putexcel H`=``outcome''+9' = (string(r(p),"%9.2f"))

}

log close

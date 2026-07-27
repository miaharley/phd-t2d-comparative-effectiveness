/*==============================================================================
DO FILE NAME:			A5 - sex hazard ratios pr.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		03/2025
					
DESCRIPTION OF FILE:	Creates table 2b with HRs for each sex group and overall
*=============================================================================*/

cap prog drop prog_sex_hrs

program define prog_sex_hrs

syntax, dataset(string) outcome(string) ///

********************************************************************************
** Set up excel **
********************************************************************************

putexcel B1 = "Male"
putexcel C1 = "Female"
putexcel D1 = "TOTAL"

putexcel A2 = "DPP4i vs SU"
putexcel A3 = "Unadjusted"
putexcel A4 = "Partially adjusted"
putexcel A5 = "Adjusted"

putexcel A6 = "SGLT2i vs SU"
putexcel A7 = "Unadjusted"
putexcel A8 = "Partially adjusted"
putexcel A9 = "Adjusted"

putexcel A10 = "SGLT2i vs DPP4i"
putexcel A11 = "Unadjusted"
putexcel A12 = "Partially adjusted"
putexcel A13 = "Adjusted"

********************************************************************************
** No interaction term **
********************************************************************************
local unadjusted i.treatmentgroup
local partially $part_adj_covariates
local fully $full_adj_covariates

local unadjusted_row 3
local partially_row 4
local fully_row 5

foreach model in unadjusted partially fully {
	
if strpos("`dataset'", "cca") > 0 {	
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox ``model'', base
}

else if strpos("`dataset'", "mi") > 0 {
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox ``model'', base
}
* DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel D``model'_row' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* SGLT2i vs SU
lincom 3.treatmentgroup, eform
local x = ``model'_row'+4
putexcel D`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* DPP4i vs SGLT2i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
local x = ``model'_row'+8
putexcel D`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")
}

********************************************************************************
** Interaction term **
********************************************************************************

local unadjusted
local partially $part_adj_covariates
local fully $full_adj_covariates

foreach model in unadjusted partially fully {

if strpos("`dataset'", "cca") > 0 {	
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup##i.gender ``model'', base
}

if strpos("`dataset'", "mi") > 0 {	
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox i.treatmentgroup##i.gender ``model'', base
}

* Male DPP4i vs SU
lincom 2.treatmentgroup, eform
putexcel B``model'_row' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Male SGLT2i vs SU
lincom 3.treatmentgroup, eform
local x = ``model'_row'+4
putexcel B`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Male SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
local x = ``model'_row'+8
putexcel B`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#2.gender, eform
putexcel C``model'_row' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#2.gender, eform
local x = ``model'_row'+4
putexcel C`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female SGLT2i vs DPP4i
lincom (3.treatmentgroup+ 3.treatmentgroup#2.gender) - (2.treatmentgroup+ 2.treatmentgroup#2.gender), eform
local x = ``model'_row'+8
putexcel C`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")
	
}

********************************************************************************
** Wald test for interaction **
********************************************************************************
if strpos("`dataset'", "cca") > 0 {	
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup##i.gender $full_adj_covariates, base
* DPP4i vs SU
test 2.treatmentgroup#1.gender 2.treatmentgroup#2.gender
putexcel B2 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs SU
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B6 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs DPP4i
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox ib2.treatmentgroup##i.gender $full_adj_covariates, base
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B10 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
}

if strpos("`dataset'", "mi") > 0 {	
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox i.treatmentgroup##i.gender $full_adj_covariates, base
* DPP4i vs SU
mi test 2.treatmentgroup#1.gender 2.treatmentgroup#2.gender
putexcel B2 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs SU
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B6 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs DPP4i
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox ib2.treatmentgroup##i.gender $full_adj_covariates, base
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender 
putexcel B10 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
}

end

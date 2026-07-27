/*==============================================================================
DO FILE NAME:			A8 - sex age hazard ratios pr.do

AUTHOR:					Mia Harley

DATE CREATED: 			08/2024
						
DATA UPDATED:      		03/2025
					
DESCRIPTION OF FILE:	Creates table 2b with HRs for each sex group and overall
*=============================================================================*/

cap prog drop prog_sex_age_hrs

program define prog_sex_age_hrs

syntax, dataset(string) outcome(string) ///

********************************************************************************
** Set up excel **
********************************************************************************

putexcel B1 = "Male under 55"
putexcel C1 = "Female under 55"
putexcel D1 = "Male over 55"
putexcel E1 = "Female over 55"

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
** Analysis with interaction term **
********************************************************************************

local unadjusted i.treatmentgroup i.gender
local partially $part_adj_covariates
local fully $full_adj_covariates

local unadjusted_row 3
local partially_row 4
local fully_row 5

gen age_group =.
replace age_group=1 if age_index <= 55
replace age_group=2 if age_index > 55

* Under 55
preserve
keep if age_index <= 55

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

* Femaile SGLT2i vs DPP4i
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
putexcel B2 = ("P-interaction=" + string(r(p),"%9.4f"))
* SGLT2i vs SU
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B6 = ("P-interaction=" + string(r(p),"%9.4f"))
* SGLT2i vs DPP4i
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox ib2.treatmentgroup##i.gender $full_adj_covariates, base
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B10 = ("P-interaction=" + string(r(p),"%9.4f"))
}

if strpos("`dataset'", "mi") > 0 {	
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox i.treatmentgroup##i.gender $full_adj_covariates, base
* DPP4i vs SU
mi test 2.treatmentgroup#1.gender 2.treatmentgroup#2.gender
putexcel B2 = ("P-interaction=" + string(r(p),"%9.4f"))
* SGLT2i vs SU
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel B6 = ("P-interaction=" + string(r(p),"%9.4f"))
* SGLT2i vs DPP4i
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox ib2.treatmentgroup##i.gender $full_adj_covariates, base
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender 
putexcel B10 = ("P-interaction=" + string(r(p),"%9.4f"))
}

restore

* Over 55
preserve
keep if age_index > 55

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
putexcel D``model'_row' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Male SGLT2i vs SU
lincom 3.treatmentgroup, eform
local x = ``model'_row'+4
putexcel D`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Male SGLT2i vs DPP4i
lincom 3.treatmentgroup - 2.treatmentgroup, eform
local x = ``model'_row'+8
putexcel D`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female DPP4i vs SU
lincom 2.treatmentgroup + 2.treatmentgroup#2.gender, eform
putexcel E``model'_row' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Female SGLT2i vs SU
lincom 3.treatmentgroup + 3.treatmentgroup#2.gender, eform
local x = ``model'_row'+4
putexcel E`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")

* Femaile SGLT2i vs DPP4i
lincom (3.treatmentgroup+ 3.treatmentgroup#2.gender) - (2.treatmentgroup+ 2.treatmentgroup#2.gender), eform
local x = ``model'_row'+8
putexcel E`x' = (string(r(estimate),"%9.2f") + " (" + string(r(lb),"%9.2f") + "-" + string(r(ub),"%9.2f") + ")")
	
}

********************************************************************************
** Wald test for interaction **
********************************************************************************
if strpos("`dataset'", "cca") > 0 {	
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox i.treatmentgroup##i.gender $full_adj_covariates, base
* DPP4i vs SU
test 2.treatmentgroup#1.gender 2.treatmentgroup#2.gender
putexcel D2 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs SU
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel D6 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs DPP4i
stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
stcox ib2.treatmentgroup##i.gender $full_adj_covariates, base
test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel D10 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
}

if strpos("`dataset'", "mi") > 0 {	
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox i.treatmentgroup##i.gender $full_adj_covariates, base
* DPP4i vs SU
mi test 2.treatmentgroup#1.gender 2.treatmentgroup#2.gender
putexcel D2 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs SU
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender
putexcel D6 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
* SGLT2i vs DPP4i
mi stset end_followup_`outcome', fail(`outcome') origin(firstissue) enter(firstissue) id(patid) scale(365.25)
mi estimate, post: stcox ib2.treatmentgroup##i.gender $full_adj_covariates, base
mi test 3.treatmentgroup#1.gender 3.treatmentgroup#2.gender 
putexcel D10 = ("Test for interaction: p-value=" + string(r(p),"%9.4f"))
}

restore

end

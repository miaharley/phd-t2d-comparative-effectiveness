/*==============================================================================
DO FILE NAME:			A1 - ethnicity baseline characteristics.do

AUTHOR:					Mia Harley

DATE CREATED: 			09/2024
						
DATASETS UPDATED:      	11/2024   	

DESCRIPTION OF FILE:	populates table 1 baseline characteristics
*=============================================================================*/

* Log
cap log close
log using $Logdir/A1_ethnicity_baseline_characteristics.log, replace

********************************************************************************
** Create locals
********************************************************************************
local covariates gender imd region bmi_cat hba1c_cat ckd_egfr alcoholabuse smoking

local white 1
local southasian 2
local black 3

local su 1
local dpp4i 2
local sglt2i 3
local total 4
local treatmentgroups su dpp4i sglt2i

* Set levels for categorical variables (including missing category)
local treatmentgroups_no 3
local gender_levels 2
local ethnicity_levels 7
local imd_levels 6
local region_levels 9
local smoking_levels 4
local alcoholabuse_levels 2
local bmi_cat_levels 5
local hba1c_cat_levels 4
local ckd_egfr_levels 3

********************************************************************************
** Create seperate datasets for each ethnicity **
********************************************************************************
* Overall 
use $study_cohort, clear
save "$Datadir/temporary/study_cohort_overall.dta", replace

* Ethnic specific
preserve
keep if ethnicity==1
save "$Datadir/temporary/study_cohort_white.dta", replace
restore
preserve
keep if ethnicity==2
save "$Datadir/temporary/study_cohort_southasian.dta", replace
restore
keep if ethnicity==3
save "$Datadir/temporary/study_cohort_black.dta", replace

********************************************************************************
** Create Table 1 **
********************************************************************************

foreach ethnicgroup in overall white southasian black {

use "$Datadir/temporary/study_cohort_`ethnicgroup'.dta", clear

if "`ethnicgroup'"=="overall" {
	local ethnic_cat ethnicity white southasian black other mixed notstated missing
	local ethnicity_var ethnicity
}

else {
	local ethnic_cat ""
	local ethnicity_var ""
}

* Locate excel file for Table 1
putexcel set "$Outputdir/Ethnicity baseline characteristics.xlsx", sheet("`ethnicgroup'") modify

* Set column locals
local su_n B
local dpp4i_n C
local sglt2i_n D
local total_n E

* Set row local
local row 1

* Put column names into excel
foreach treatmentgroup in `treatmentgroups' total {
		putexcel ``treatmentgroup'_n'`row' = "`treatmentgroup'"
}


* Create locals for row names
local rownames sample age_index gender male female `ethnic_cat' imd 1 2 3 4 5 missing year_index 2015 2016 2017 2018 2019 2020 2021 2022 region 1 2 3 4 5 6 7 8 9 t2dduration_years hba1c_cat 1 2 3 missing bmi_cat underweight normal overweight obese missing ckd_egfr no yes missing alcoholabuse no yes smoking non-smoker current former missing healthcare 1to10 morethan10 comorbidities $comorbidities medications $medications 

* Put row names into excel and create locals for row numbers
foreach rowname in `rownames' {
	local row = `row'+1
	putexcel A`row' = "`rowname'"
	local `rowname' `row'
}


********************************************************************************
** Fill in Table 1: sample size counts
********************************************************************************

* In all treatmentgroups
count
local n = `r(N)'
local p = `r(N)'*100/`r(N)'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel `total_n'`sample' = "`n_p'"

* By treatment group 
tab treatmentgroup , matcell(treatmentgroup)
matrix treatmentgroup_t = treatmentgroup
foreach treatmentgroup in `treatmentgroups' {
	local n = treatmentgroup_t[``treatmentgroup'',1]
	local p = treatmentgroup_t[``treatmentgroup'',1]*100/`r(N)'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel ``treatmentgroup'_n'`sample' = "`n_p'"
}

********************************************************************************
** Age
********************************************************************************

* Overall
preserve
collapse (mean) mean_age=age_index (sd) sd_age=age_index
mkmat mean_age sd_age
local mean = mean_age[1,1]
local sd = sd_age[1,1]
local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
putexcel `total_n'`age_index' = "`mean_sd'"
restore

* By treatment group 
preserve
collapse (mean) mean_age=age_index (sd) sd_age=age_index, by(treatmentgroup)
mkmat mean_age sd_age
foreach treatmentgroup in `treatmentgroups' {
	local mean = mean_age[``treatmentgroup'',1]
	local sd = sd_age[``treatmentgroup'',1]
	local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
	putexcel ``treatmentgroup'_n'`age_index' = "`mean_sd'"
}
restore

********************************************************************************
** T2D duration
********************************************************************************

* Overall
preserve
collapse (mean) mean_t2dduration_years=t2dduration_years (sd) sd_t2dduration_years=t2dduration_years
mkmat mean_t2dduration_years sd_t2dduration_years
local mean = mean_t2dduration_years[1,1]
local sd = sd_t2dduration_years[1,1]
local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
putexcel `total_n'`t2dduration_years' = "`mean_sd'"
restore

* By treatment group 
preserve
collapse (mean) mean_t2dduration_years=t2dduration_years (sd) sd_t2dduration_years=t2dduration_years, by(treatmentgroup)
mkmat mean_t2dduration_years sd_t2dduration_years
foreach treatmentgroup in `treatmentgroups' {
	local mean = mean_t2dduration_years[``treatmentgroup'',1]
	local sd = sd_t2dduration_years[``treatmentgroup'',1]
	local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
	putexcel ``treatmentgroup'_n'`t2dduration_years' = "`mean_sd'"
}
restore

********************************************************************************
** Year of initiation on second-line
********************************************************************************

* Overall
count
local total = `r(N)'
foreach year of numlist 2015/2022 { 
count if year_index==`year'
local n = `r(N)'
local p = `r(N)'*100/`total'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel `total_n'`year' = "`n_p'"
}
* By treatment group
	foreach treatmentgroup in `treatmentgroups' {
	count if treatmentgroup == ``treatmentgroup''
	local total = `r(N)'
	foreach year of numlist 2015/2022 { 
		count if year_index==`year'
		local n = `r(N)'
		local p = `r(N)'*100/`total'
		local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
		putexcel ``treatmentgroup'_n'`year' = "`n_p'"
	}
	}
********************************************************************************
** Median years follow up
********************************************************************************/*

* Overall
gen followup_days = end_followup - firstissue
gen followup_years = followup_days/365.25
summarize followup_years, detail
local median = r(p50)
local p25 = r(p25)
local p75 = r(p75)
local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
putexcel `total_n'`median_followup' = "`median_iqr'"

* By treatment group
	foreach treatmentgroup in `treatmentgroups' {
	summarize followup_years if treatmentgroup == ``treatmentgroup'', detail
	local median = r(p50)
	local p25 = r(p25)
	local p75 = r(p75)
	local iqr = `=`p75' - `p25''
	local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + " - " + string(`p75', "%9.1f") + ")"
	putexcel ``treatmentgroup'_n'`median_followup' = "`median_iqr'"
	}	
*/
********************************************************************************
** Categorical variables
********************************************************************************

foreach variable in `ethnicity_var' `covariates' {

	* Overall
	foreach variablelevel of numlist 1/``variable'_levels' {
		tab `variable', m matcell(`variable')
		local n = `variable'[`variablelevel',1]
		count
		local p = `n'*100/`r(N)'
		local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
		local x = ``variable'' + `variablelevel'
		putexcel `total_n'`x'= "`n_p'"
				
		* By treatment group
		foreach treatmentgroup in `treatmentgroups' {
			tab `variable' treatmentgroup, m matcell(`variable'_treatmentgroup)
			local n = `variable'_treatmentgroup[`variablelevel',``treatmentgroup'']
			count if treatmentgroup==``treatmentgroup''
			local p = `n'*100/`r(N)'
			local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
			putexcel ``treatmentgroup'_n'`x' = "`n_p'"
} 
}
	tab `variable' treatmentgroup, m
}

********************************************************************************
** Healthcare utilization
********************************************************************************
* Overall
* 1-10 consultations
count if healthcare==0
local n = r(N)
count
local p = `n'*100/`r(N)'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel `total_n'`1to10' =  "`n_p'"
* >10 consultations
count if healthcare==1
local n = r(N)
count
local p = `n'*100/`r(N)'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel `total_n'`morethan10' =  "`n_p'"

	* By treatment group
	foreach treatmentgroup in `treatmentgroups' {
		* 1-10 consultations
		tab healthcare treatmentgroup, m matcell(healthcare_treatmentgroup)
		local n = healthcare_treatmentgroup[1,``treatmentgroup'']
		count if treatmentgroup==``treatmentgroup''
		local p = `n'*100/`r(N)'
		local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
		putexcel ``treatmentgroup'_n'`1to10' = "`n_p'"	
		* >10 consultations
		tab healthcare treatmentgroup, m matcell(healthcare_treatmentgroup)
		local n = healthcare_treatmentgroup[2,``treatmentgroup'']
		count if treatmentgroup==``treatmentgroup''
		local p = `n'*100/`r(N)'
		local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
		putexcel ``treatmentgroup'_n'`morethan10' = "`n_p'"	
	}

********************************************************************************
** Binary variables
********************************************************************************
foreach variable in $comorbidities $medications {
	
	* Overall
	count if `variable'==1
	local n = r(N)
	count
	local p = `n'*100/`r(N)'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel `total_n'``variable'' = "`n_p'"
	
	* By treatment group
	foreach treatmentgroup in `treatmentgroups' {
		tab `variable' treatmentgroup, m matcell(`variable'_treatmentgroup)
		local n = `variable'_treatmentgroup[2,``treatmentgroup'']
		count if treatmentgroup==``treatmentgroup''
		local p = `n'*100/`r(N)'
		local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
		putexcel ``treatmentgroup'_n'``variable'' = "`n_p'"	
	}
}
erase "$Datadir/temporary/study_cohort_`ethnicgroup'.dta"
}

log close
/*==============================================================================
DO FILE NAME:			A2 - create table 1.do

AUTHOR:					Mia Harley

DATE CREATED: 			09/2024
						
DATASETS UPDATED:      	11/2024   	

DESCRIPTION OF FILE:	populates table 1 baseline characteristics
*=============================================================================*/


********************************************************************************
** Create locals
********************************************************************************
local covariates gender ethnicity imd region year_index bmi_cat hba1c_cat ckd_egfr alcoholabuse smoking

local dpp4i 0
local sglt2i 1
local total 2
local treatmentgroups dpp4i sglt2i

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
local year_index_levels 8
local ckd_egfr_levels 3

* Set column locals
local dpp4i_n B
local sglt2i_n C
local total_n D

use $study_cohort_hte, clear

* Locate excel file for Table 1
putexcel set "$Outputdir\HTE baseline characteristics.xlsx", sheet("Sheet1") modify

* Put in column headings
putexcel B1 = "DPP4i"
putexcel C1 = "SGLT2i"
putexcel D1 = "TOTAL"

* Put in row headings
local row 1

* Create locals for row names
local rownames sample age_index gender male female ethnicity white southasian black other mixed notstated missing imd 1 2 3 4 5 missing region 1 2 3 4 5 6 7 8 9 year_index 2015 2016 2017 2018 2019 2020 2021 2022 years_t2d hba1c_cat 1 2 3 missing bmi_cat underweight normal overweight obese missing ckd_egfr no yes missing alcoholabuse yes no smoking non-smoker current former missing healthcare 1to10 morethan10 comorbidities $comorbidities medications $medications 

* Put row names into excel and create locals for each rowname
foreach rowname in `rownames' {
	local row = `row'+1
	putexcel A`row' = "`rowname'"
	local `rowname' `row'
}

********************************************************************************
** Sample size counts
********************************************************************************

* In all treatmentgroups
count
local total = `r(N)'
local p = `r(N)'*100/`r(N)'
local n_p = string(`total', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel `total_n'`sample' = "`n_p'"

* By treatment group 
foreach treatmentgroup in `treatmentgroups' {
preserve
keep if treatmentgroup==``treatmentgroup''
count
local n = `r(N)'
local p = `r(N)'*100/`total'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``treatmentgroup'_n'`sample' = "`n_p'"
restore
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
foreach treatmentgroup in `treatmentgroups' {
preserve
keep if treatmentgroup==``treatmentgroup''
collapse (mean) mean_age=age_index (sd) sd_age=age_index
mkmat mean_age sd_age
local mean = mean_age[1,1]
local sd = sd_age[1,1]
local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
putexcel ``treatmentgroup'_n'`age_index' = "`mean_sd'"
restore
}

********************************************************************************
** T2D duration
********************************************************************************

* Overall
preserve
collapse (mean) mean_years_t2d=years_t2d (sd) sd_years_t2d=years_t2d
mkmat mean_years_t2d sd_years_t2d
local mean = mean_years_t2d[1,1]
local sd = sd_years_t2d[1,1]
local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
putexcel `total_n'`years_t2d' = "`mean_sd'"
restore

* By treatment group 
foreach treatmentgroup in `treatmentgroups' {
preserve
keep if treatmentgroup==``treatmentgroup''
collapse (mean) mean_years_t2d=years_t2d (sd) sd_years_t2d=years_t2d
mkmat mean_years_t2d sd_years_t2d
local mean = mean_years_t2d[1,1]
local sd = sd_years_t2d[1,1]
local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
putexcel ``treatmentgroup'_n'`years_t2d' = "`mean_sd'"
restore
}


********************************************************************************
** Categorical variables
********************************************************************************

foreach variable in `covariates' {
	
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
			preserve
			keep if treatmentgroup==``treatmentgroup''
			tab `variable', m matcell(`variable')
			local n = `variable'[`variablelevel',1]
			count
			local p = `n'*100/`r(N)'
			local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
			local x = ``variable'' + `variablelevel'
			putexcel ``treatmentgroup'_n'`x'= "`n_p'"
			restore

} 
}

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
			preserve
			keep if treatmentgroup==``treatmentgroup''
			
			* 1-10 consultations
			count if healthcare==0
			local n = r(N)
			count
			local p = `n'*100/`r(N)'
			local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
			putexcel ``treatmentgroup'_n'`1to10' =  "`n_p'"

			* >10 consultations
			count if healthcare==1
			local n = r(N)
			count
			local p = `n'*100/`r(N)'
			local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
			putexcel ``treatmentgroup'_n'`morethan10' =  "`n_p'"
			restore
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
			preserve
			keep if treatmentgroup==``treatmentgroup''
			count if `variable'==1
			local n = r(N)
			count
			local p = `n'*100/`r(N)'
			local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
			putexcel ``treatmentgroup'_n'``variable'' = "`n_p'"
			restore
		}
}
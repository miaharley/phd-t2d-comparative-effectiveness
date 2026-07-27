/*==============================================================================
DO FILE NAME:			A2 - baseline characteristics missing vs no missing.do

AUTHOR:					Mia Harley

DATE CREATED: 			09/2024
						
DATASETS UPDATED:      	11/2024
					
DESCRIPTION OF FILE:	creates a table of baseline characteristics comparing study population before and after individuals with missing covariates have been removed
*=============================================================================*/

* Log
cap log close
log using $Logdir\A2_baseline_characteristics_missing_nomissing.log, replace

********************************************************************************
** Create table of characteristics for missing vs no missing
********************************************************************************
* Set locals
local covariates gender imd region bmi_cat hba1c_cat ckd_egfr alcoholabuse smoking

* Locate excel file for Table 1
putexcel set "$Outputdir/Baseline characteristics missing vs no missing.xlsx", sheet("Sheet1") modify

* Set row local
local row 1

* Set column locals
local missing B
local nomissing C

* Put column names into excel
putexcel `missing'`row' = "Missing"
putexcel `nomissing'`row' = "No missing"

* Create locals for row names
local rownames sample treatmentgroup su dpp4i sglt2i age_index gender male female ethnicity white southasian black other mixed notstated imd 1 2 3 4 5 region 1 2 3 4 5 6 7 8 9 year_index 2015 2016 2017 2018 2019 2020 2021 2022 t2dduration_years hba1c_cat 1 2 3 bmi_cat underweight normal overweight obese ckd_egfr no yes alcoholabuse yes no smoking non-smoker current former healthcare 1to10 morethan10 comorbidities $comorbidities medications $medications 

* Put row names into excel and create locals for row numbers
foreach rowname in `rownames' {
	local row = `row'+1
	putexcel A`row' = "`rowname'"
	local `rowname' `row'
}

* Set levels for categorical variables
local treatmentgroup_levels 3
local gender_levels 2
local ethnicity_levels 6
local imd_levels 5
local region_levels 9
local smoking_levels 3
local alcoholabuse_levels 2
local bmi_cat_levels 4
local hba1c_cat_levels 3
local ckd_egfr_levels 2

foreach file in missing nomissing {
	
	if "`file'"=="missing" {
	use $study_cohort, clear	
}

	if "`file'"=="nomissing" {
	use $study_cohort_cca, clear
	}
	
	* Set column locals
	local missing B
	local nomissing C

	* Sample size counts
	count
	putexcel ``file''`sample'= `r(N)', nformat(number)
	
	* Age
	preserve
	collapse (mean) mean_age=age_index (sd) sd_age=age_index
	mkmat mean_age sd_age
	local mean = mean_age[1,1]
	local sd = sd_age[1,1]
	local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
	putexcel ``file''`age_index' = "`mean_sd'"
	restore
	
	* Type 2 diabetes duration
	preserve
	collapse (mean) mean_t2dduration_years=t2dduration_years (sd) sd_t2dduration_years=t2dduration_years
	mkmat mean_t2dduration_years sd_t2dduration_years
	local mean = mean_t2dduration_years[1,1]
	local sd = sd_t2dduration_years[1,1]
	local mean_sd = string(`mean', "%9.1f") + " (" + string(`sd', "%9.1f") + ")"
	putexcel ``file''`t2dduration_years' = "`mean_sd'"
	restore
	
	* Overall
	count
	local total = `r(N)'
	foreach year of numlist 2015/2022 { 
	count if year_index==`year'
	local n = `r(N)'
	local p = `r(N)'*100/`total'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel ``file''`year' = "`n_p'"
	}
	
	* Categorical variables
	foreach variable in gender ethnicity treatmentgroup `covariates' {
		foreach variablelevel of numlist 1/``variable'_levels' {
			tab `variable', matcell(`variable')
			local n = `variable'[`variablelevel',1]
			count
			local p = `n'*100/`r(N)'
			local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
			local x = ``variable'' + `variablelevel'
			putexcel ``file''`x'= "`n_p'"
		}
	}
	
	* Healthcare utilization
	* 1-10 consultations
	count if healthcare==0
	local n = r(N)
	count
	local p = `n'*100/`r(N)'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel ``file''`1to10' =  "`n_p'"
	* >10 consultations
	count if healthcare==1
	local n = r(N)
	count
	local p = `n'*100/`r(N)'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel ``file''`morethan10' =  "`n_p'"
	
	* Binary variables
	foreach variable in $comorbidities $medications {
		count if `variable'==1
		local n = r(N)
		count
		local p = `n'*100/`r(N)'
		local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
		putexcel ``file''``variable'' = "`n_p'"
	}
	
	
}

log close
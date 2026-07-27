/*==============================================================================
DO FILE NAME:			A1 - create table 1.do

AUTHOR:					Mia Harley

DATE CREATED: 			09/2024
						
DATASETS UPDATED:      	11/2024   	

DESCRIPTION OF FILE:	populates table 1 baseline characteristics
*=============================================================================*/

* Log
cap log close
log using $Logdir/A1a_create_table_1.log, replace

********************************************************************************
** Create locals
********************************************************************************
local covariates ethnicity imd region year_index bmi_cat hba1c_cat ckd_egfr alcoholabuse smoking

local male 1
local female 2

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
local year_index_levels 8
local ckd_egfr_levels 3

********************************************************************************
** Create seperate datasets for each ethnicity **
********************************************************************************
* Overall 
use $study_cohort, clear
save "$Datadir/temporary/study_cohort_overall.dta", replace

* Sex specific
preserve
keep if gender==1
save "$Datadir/temporary/study_cohort_male.dta", replace
restore
keep if gender==2
save "$Datadir/temporary/study_cohort_female.dta", replace


********************************************************************************
** Create Table 1 **
********************************************************************************

foreach sex in overall male female {

use "$Datadir/temporary/study_cohort_`sex'.dta", clear

if "`sex'"=="overall" {
	local sex_cat gender male female
	local sex_var gender
}

else {
	local sex_cat ""
	local sex_var ""
}

* Locate excel file for Table 1
putexcel set "$Outputdir/Sex baseline characteristics.xlsx", sheet("`sex'") modify

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
local rownames sample age_index `sex_cat' ethnicity white southasian black other mixed notstated missing imd 1 2 3 4 5 missing region 1 2 3 4 5 6 7 8 9 year_index 2015 2016 2017 2018 2019 2020 2021 2022 t2dduration_years hba1c_cat 1 2 3 missing bmi_cat underweight normal overweight obese missing ckd_egfr no yes missing alcoholabuse yes no smoking non-smoker current former missing healthcare 1to10 morethan10 comorbidities $comorbidities medications $medications 

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
** Categorical variables
********************************************************************************

foreach variable in `sex_var' `covariates' {

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

}

erase "$Datadir/temporary/study_cohort_overall.dta"
erase "$Datadir/temporary/study_cohort_male.dta"
erase "$Datadir/temporary/study_cohort_female.dta"

log close

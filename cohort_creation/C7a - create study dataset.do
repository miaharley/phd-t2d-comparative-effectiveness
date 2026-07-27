/*==============================================================================
DO FILE NAME:			C7a - create study cohort.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2024

DATE LAST UPDATED:		02/2025
						
DATASETS CREATED:       study_cohort.dta
					
DESCRIPTION OF FILE:	creates study cohort by merging included and excluded and adds all variables
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C7a_create_study_cohort.log, replace

********************************************************************************
** Exclusion Criteria **
********************************************************************************

* Exclusion 1 - CVD event before index
* Exclusion 2 - Antidiabetics except metformin before index
* Exclusion 3 - <12 months registration before index 
* Exclusion 4 - Missing sex

********************************************************************************
** Apply exclusion criteria to get final study cohort **
********************************************************************************
putexcel set "$Outputdir/Figure 1 - study cohort flow chart.xlsx", sheet("Sheet1") modify

* Create locals for columns
local title A
local incl B
local excl C

use $included, clear
gen excl=0
count 
local total_included `r(N)'

* 1. CVD before index
merge 1:1 patid using "$Datadir/derived/excl_prev_cvd.dta", keep(master match) nogen
replace excl=1 if prev_cvd==1
putexcel A9 = "CVD before index"
count if prev_cvd==1
local n `r(N)'
local p = `n'*100/`total_included'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel C9 = "`n_p'"

* 2. Antidiabetics except metformin before index
merge 1:1 patid using "$Datadir/derived/excl_prev_antidiabetics.dta", keep(master match) nogen
replace excl=1 if prev_antidiabetics==1
putexcel A10 = "Antidiabetics before index"
count if prev_antidiabetics==1
local n `r(N)'
local p = `n'*100/`total_included'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel C10 = "`n_p'"

* 3. <12 months registration before index  
merge 1:1 patid using "$Datadir/derived/excl_lessthan_12m.dta", keep(master match) nogen
replace excl=1 if lessthan_12m==1
putexcel A11 = "<12m registration before index "
count if lessthan_12m==1
local n `r(N)'
local p = `n'*100/`total_included'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel C11 = "`n_p'"

* 4. Missing sex 
merge 1:1 patid using "$Datadir/derived/excl_missing_sex.dta", keep(master match) nogen
replace excl=1 if missing_sex==1
putexcel A12 = "Missing sex"
count if missing_sex==1
local n `r(N)'
local p = `n'*100/`total_included'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel C12 = "`n_p'"

* 5. HbA1c <48
merge 1:1 patid using "$Datadir/derived/excl_hba1c_lessthan_48.dta", keep(master match) nogen
replace excl=1 if hba1c_lessthan_48==1
putexcel A13 = "HbA1c"
count if hba1c_lessthan_48==1
local n `r(N)'
local p = `n'*100/`total_included'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel C13 = "`n_p'"

* TOTAL EXCLUDED
putexcel A14 = "Total excluded"
count if excl==1
local n `r(N)'
local p = `n'*100/`total_included'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel C14 = "`n_p'"

drop if excl==1
drop excl hba1c_lessthan_48 missing_sex lessthan_12m prev_antidiabetics prev_cvd
save $study_cohort, replace

********************************************************************************
** Get final study population counts **
********************************************************************************

local white 0
local southasian 1
local black 2

local overall_row 16
local white_row 21
local southasian_row 26
local black_row 31

foreach ethnicgroup in overall white southasian black {
	
use $study_cohort, clear
merge 1:1 patid using "$Datadir/derived/covariate_ethnicity.dta", keep(master match) nogen
count
local total `r(N)'

if "`ethnicgroup'" == "overall" {
	
}

else {
keep if eth5 == ``ethnicgroup''
}

* Total in ethnic group
putexcel `title'``ethnicgroup'_row'= "`ethnicgroup' population"
count
local total_ethnicgroup `r(N)'
local p = `total_ethnicgroup'*100/`total'
local n_p = string(`total_ethnicgroup', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel `incl'``ethnicgroup'_row'= "`n_p'"

* SU users
local row = ``ethnicgroup'_row'+1
putexcel `title'`row' = "SU users"
count if treatmentgroup==1
local n `r(N)'
local p = `n'*100/`total_ethnicgroup'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel `incl'`row'= "`n_p'"

* DPP4i users
local row = `row'+1
putexcel `title'`row' = "DPP4i users"
count if treatmentgroup==2
local n `r(N)'
local p = `n'*100/`total_ethnicgroup'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel `incl'`row'= "`n_p'"

* SGLT2i users
local row = `row'+1
putexcel `title'`row' = "SGLT2i users"
count if treatmentgroup==3
local n `r(N)'
local p = `n'*100/`total_ethnicgroup'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel `incl'`row'= "`n_p'"
}


********************************************************************************
** Add in all variables **
********************************************************************************

use $study_cohort, clear

* Get region variable
merge 1:1 patid using "$Datadir/raw//${file_stub}_Extract_Patient_1.dta", keep(match) keepusing(pracid) nogen
merge m:1 pracid using "$Datadir/raw//${file_stub}_Extract_Practice_1.dta", keep(match) keepusing(region) nogen
destring region, replace

* Create variable for diabetes duration an index
gen t2dduration_days = firstissue - t2ddiagnosisdate
gen t2dduration_years = t2dduration_days / 365.25
drop t2dduration_days

* Get age at index	
gen age_index = floor((firstissue - dob)/365.25)

* Get calendar year of index	
gen year_index = year(firstissue)

* Save
save $study_cohort, replace


* Add covariates
foreach covariate in $covariates {
	use $study_cohort, clear
	merge 1:1 patid using "$Datadir/derived/covariate_`covariate'.dta", keep(master match) nogen
	save $study_cohort, replace
	}
	
* Add comorbidity variables
foreach comorbidity in $comorbidities {
	use $study_cohort, clear
	merge 1:1 patid using "$Datadir/derived/comorbidity_`comorbidity'.dta", keep(master match) nogen
	save $study_cohort, replace
	}
		
* Add medication variables 
foreach medication in $medications {
	use $study_cohort, clear
	merge 1:1 patid using "$Datadir/derived/medication_`medication'.dta", keep(master match) nogen
	save $study_cohort, replace
	}

* Add outcome variables
foreach outcome in mace hf stroke cvddeath mi hba1c {
use $study_cohort, clear
merge 1:1 patid using "$Datadir/derived/outcome_`outcome'.dta", keep(master match) nogen
save $study_cohort, replace
	}

* Rename and recode ethnicity variable
gen ethnicity =.
replace ethnicity=1 if eth5==0
replace ethnicity=2 if eth5==1
replace ethnicity=3 if eth5==2
replace ethnicity=4 if eth5==3
replace ethnicity=5 if eth5==4
replace ethnicity=6 if eth5==5
label define ethnicity 1 "1. White" 2 "2. South Asian" 3 "3. Black" 4 "4. Other" 5 "5. Mixed" 6 "6. Not Stated"
label values ethnicity ethnicity

* Create variable for ckd
gen ckd_egfr = .
replace ckd_egfr = 1 if egfr_ckd==0
replace ckd_egfr = 2 if (egfr_ckd==2 | egfr_ckd==3 | egfr_ckd==4 | egfr_ckd==5)

* Drop unneccesary variables
drop eth5 eth16 dmrxclass egfr_ckd

* Get end of episode for as-treated
merge 1:m patid using "$Datadir\derived\2ndline_firstepisode.dta", keep(master match) nogen
assert treatmentgroup==treatmentclass
drop treatmentclass

* Create spline for duration of diabetes and age
mkspline age_index_sp = age_index, cubic nknots(4)
mkspline t2dduration_years_sp = t2dduration_years, cubic nknots(4)
mkspline hba1c_sp = hba1c, cubic nknots(4)
mkspline bmi_sp = bmi, cubic nknots(4)
mkspline egfr_sp = egfr, cubic nknots(4)

********************************************************************************
** Get counts for missing covariate data **
********************************************************************************

gen total_missing=0

* Use excel file for study cohort flow diagram
putexcel set "$Outputdir/Figure 1 - study cohort flow chart.xlsx", sheet("Missing covariate data") modify

* Create row local 
local row = 15

* Get counts for missing in each covariate
foreach variable in ethnicity imd bmi smoking hba1c egfr {
local row = `row'+1
putexcel `title'`row' = "Missing `variable'"
count if `variable'==.
local n `r(N)'
count
local p = `n'*100/`r(N)'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel `excl'`row' = "`n_p'"
replace total_missing=1 if `variable'==.
}

* Get counts for missing overall
local row = `row'+1
putexcel `title'`row' = "Total with any missing covariate data"
count if total_missing==1
local n `r(N)'
count
local p = `n'*100/`r(N)'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + "%)"
putexcel `excl'`row' = "`n_p'"

* Save
save $study_cohort, replace

********************************************************************************
** Create complete case analysis dataset **
********************************************************************************

use $study_cohort, clear
drop if total_missing==1
count

save $study_cohort_cca, replace

log close
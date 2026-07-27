/*==============================================================================
DO FILE NAME:			C7b - multiple imputation.do

AUTHOR:					Mia Harley

DATE CREATED: 			03/2025

DATE LAST UPDATED:		08/2025
						
DATASETS CREATED:      	study_cohort_mi.dta
					
DESCRIPTION OF FILE:	runs multiple imputation to fill in missing covariate data
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

* Log
cap log close
log using $Logdir/C7b_multiple_imputation.log, replace

********************************************************************************
** Run multiple imputation ***
********************************************************************************
local su 1
local dpp4i 2
local sglt2i 3

use "$Datadir/derived/study_cohort.dta", clear

* Create end of follow up variable for mace
local outcome mace
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'

* Stratify by treatment group
foreach treatmentgroup in su dpp4i sglt2i {
		preserve
		keep if treatmentgroup==``treatmentgroup''
		
		stset end_followup_mace, failure(mace)
		sts generate cumhaz = na
		
		* Set up multiple imputation
		mi set mlong
		
		* Register variable for imputation and prediction
		mi register imputed $imputedordervarlist $imputedcatvarlist $imputedcontvarlist
		mi register regular $regularvarlist treatmentgroup mace
		
		* Impute
		mi impute chained (ologit) $imputedordervarlist (mlogit) $imputedcatvarlist (regress) $imputedcontvarlist  = $regularvarlist treatmentgroup mace, add(10) augment
		
		if _rc!=0 {
		noi di in red "Errors in MI model: check out imputed variables and independent variables"
		}	
		
		if "`treatmentgroup'"=="su" {
			save "$Datadir/derived/study_cohort_mi.dta", replace
		}
		
		else {
			mi append using "$Datadir/derived/study_cohort_mi.dta"
			save "$Datadir/derived/study_cohort_mi.dta", replace
		}
		restore
	}

********************************************************************************
** Reprogramme categorical variables ***
********************************************************************************
	
use "$Datadir/derived/study_cohort_mi.dta", clear
	
cap drop bmi_cat
cap drop hba1c_cat

cap drop hba1c_sp*
cap drop bmi_sp*
cap drop egfr_sp*

/** Categorise BMI (White, Other, Mixed, Not stated)
mi passive: gen bmi_cat=0 if (ethnicity==1 | ethnicity==4 | ethnicity==5 | ethnicity==6) & bmi<18.5
mi passive: replace bmi_cat=1 if (ethnicity==1 | ethnicity==4 | ethnicity==5 | ethnicity==6) & (bmi>=18.5 & bmi<25)
mi passive: replace bmi_cat=2 if (ethnicity==1 | ethnicity==4 | ethnicity==5 | ethnicity==6) & (bmi>=25 & bmi<30)
mi passive: replace bmi_cat=3 if (ethnicity==1 | ethnicity==4 | ethnicity==5 | ethnicity==6) & (bmi>=30 & bmi<.)

* Categorise BMI (non-white)
mi passive: replace bmi_cat=0 if (ethnicity==2 | ethnicity==3) & bmi<18.5
mi passive: replace bmi_cat=1 if (ethnicity==2 | ethnicity==3) & (bmi>=18.5 & bmi<23)
mi passive: replace bmi_cat=2 if (ethnicity==2 | ethnicity==3) & (bmi>=23 & bmi<27.5)
mi passive: replace bmi_cat=3 if (ethnicity==2 | ethnicity==3) & (bmi>=27.5 & bmi<.)

* Categorise HbA1c
mi passive: gen hba1c_cat=.
mi passive: replace hba1c_cat=1 if hba1c <53
mi passive: replace hba1c_cat=2 if hba1c >=53 & hba1c <75
mi passive: replace hba1c_cat=3 if hba1c >=75 & hba1c <.*/

* Creat splines for continuous imputed variables
foreach var in egfr hba1c bmi {
_pctile `var' if _mi_m == 0 & !missing(`var'), nq(100)
local `var'_knots "`r(r5)' `r(r35)' `r(r65)' `r(r95)'"
local `var'_p5 = r(r5)
local `var'_p35 = r(r35)
local `var'_p65 = r(r65)
local `var'_p95 = r(r95)

display "`var' knots: ``var'_p5', ``var'_p35', ``var'_p65', ``var'_p95'"

mi xeq: mkspline `var'_sp = `var', cubic knots(``var'_p5' ``var'_p35' ``var'_p65' ``var'_p95')

mi register passive `var'_sp*

}

save "$Datadir/derived/study_cohort_mi.dta", replace

log close

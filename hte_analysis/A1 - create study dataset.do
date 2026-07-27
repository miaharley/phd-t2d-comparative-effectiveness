/*==============================================================================
DO FILE NAME:			A1 - create study dataset.do

AUTHOR:					Mia Harley

DATE CREATED: 			09/2025
						
DATASETS UPDATED:      	01/2026   	

DESCRIPTION OF FILE:	creates HTE study dataset
*=============================================================================*/

********************************************************************************
** Study cohort with HbA1c after 12 months follow up **
********************************************************************************

use $study_cohort, clear

* Create duration of type 2 diabetes variable
gen years_t2d = abs((firstissue-t2ddiagnosisdate)/365.25)

* Only keep neccessary variables
keep patid pracid ethnicity gender years_t2d region imd age_index year_index firstissue treatmentgroup death_date enddate bmi egfr hba1c bmi_cat hba1c_cat ckd_egfr alcoholabuse smoking healthcare_util af pad hypertension neuropathy retinopathy cancer liverdisease crd ra dementia smi cmd acei arb ccb diuretics statins antiplat anticoag antipsych hba1c_outcome_baseline hba1c_outcome_1yr total_missing

order patid pracid ethnicity gender years_t2d region imd age_index year_index firstissue treatmentgroup death_date enddate bmi egfr hba1c bmi_cat hba1c_cat ckd_egfr alcoholabuse smoking healthcare_util af pad hypertension neuropathy retinopathy cancer liverdisease crd ra dementia smi cmd acei arb ccb diuretics statins antiplat anticoag antipsych hba1c_outcome_baseline hba1c_outcome_1yr total_missing

* Create change in hba1c outcome var
gen hba1c_change = hba1c_outcome_1yr - hba1c_outcome_baseline

* Create indicator for non-missing outcome
gen c=1 if hba1c_change!=.
replace c=0 if hba1c_change==.

* Recode gender 0, 1
codebook gender
replace gender=0 if gender==1
replace gender=1 if gender==2
label define gender_labels 0 "Male" 1 "Female" 
label values gender gender_labels
codebook gender

* Only keep DPP4i and SGLT2i and recode treatmentgroup
keep if treatmentgroup==2 | treatmentgroup==3
codebook treatmentgroup
replace treatmentgroup=0 if treatmentgroup==2
replace treatmentgroup=1 if treatmentgroup==3
label define treatmentgroup_labels 0 "DPP4i" 1 "SGLT2i" 
label values treatmentgroup treatmentgroup_labels

* Remove people who start treatment less than 12 months before the study end date
drop if firstissue > date("01feb2021", "DMY")

* Save dataset with missing cases
count
save "$Datadir\derived\study_cohort_hte.dta", replace

* Complete case hte dataset
drop if total_missing==1
count
save "$Datadir\derived\study_cohort_hte_cca.dta", replace

/*********************************************************************************
** Study cohort with MACE events at 3 years follow up **
********************************************************************************

use $study_cohort, clear

* Only keep neccessary variables
keep patid pracid gender ethnicity t2ddiagnosisdate region imd age_index year_index firstissue treatmentgroup death_date enddate bmi hba1c egfr alcoholabuse smoking healthcare_util af pad hypertension neuropathy retinopathy cancer liverdisease crd ra dementia smi cmd acei arb ccb diuretics statins antiplat anticoag antipsych mace_date mace

order patid pracid gender ethnicity t2ddiagnosisdate region imd age_index year_index firstissue treatmentgroup death_date enddate bmi hba1c egfr alcoholabuse smoking healthcare_util af pad hypertension neuropathy retinopathy cancer liverdisease crd ra dementia smi cmd acei arb ccb diuretics statins antiplat anticoag antipsych mace_date mace

* Create end of follow-up for each outcome
local outcome mace
cap drop end_followup_`outcome'  followup_years_`outcome'
gen end_followup_`outcome' =  min(enddate, `outcome'_date)
format end_followup_`outcome' %td
replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
replace `outcome'=0 if `outcome'_date==.
gen followup_days_`outcome' = end_followup_`outcome' - firstissue
gen followup_years_`outcome' = followup_days_`outcome'/365.25
drop followup_days_`outcome'
drop if followup_years_`outcome'==0

* Create variable for event after 3 years follow up
gen followup_3yrs = firstissue + 1096
format followup_3yrs %td
gen event_3yrs=.
replace event_3yrs=1 if mace==1 & (mace_date<=followup_3yrs)
replace event_3yr=0 if (end_followup_`outcome'>followup_3yrs)
replace event_3yr=0 if mace==0 & (end_followup_`outcome'==followup_3yrs)

* Create variable for censoring
gen cens = 1 if mace==0
replace cens=0 if mace==1

* Create indicator for non-missing outcome
gen c=1
replace c=0 if event_3yr==.

* Only keep SU and DPP4i initiators for now
keep if treatmentgroup==1 | treatmentgroup==2

save "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\hte\Matt\hte_study_cohort_mace.dta", replace=*/
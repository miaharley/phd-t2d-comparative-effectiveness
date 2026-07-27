/*=========================================================================
DO FILE NAME:			_globals_sex.do

AUTHOR:					Mia Harley

DATE CREATED: 			11/2023

DATE LAST UPDATED: 		08/2025
						
DESCRIPTION OF FILE:	Global macros to set up file paths					
*=========================================================================*/

clear all

* Set directories
global Aurumbuild "2023_09"
global Projectdir "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness"
global Dodir "$Projectdir\sex\dofiles"
global Outputdir "C:\Users\lsh1703855\OneDrive - London School of Hygiene and Tropical Medicine\PhD\4. Sex differences in comparative effectiveness\Output"
global Extractdir "Z:\GPRD_GOLD\Mia\Aurum extract Nov 2023\results\part1_Extract"
global Datadir "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness"
global Logdir "$Projectdir\sex\logfiles"
global Codelistdir "$Projectdir\codelists"
global Denominator "J:\EHR Share\3 Database guidelines and info\" 
global lookupsaurum "$Denominator\CPRD Aurum\Lookups\\${Aurumbuild}"

* Set study dates
glob studystart 01jan2015
glob studyend 01feb2022

* Comorbidities and medications
glob comorbidities af pad hypertension neuropathy retinopathy cancer liverdisease crd ra dementia smi cmd
glob medications acei arb ccb diuretics statins antiplat anticoag antipsych

* Study cohort datasets
glob included = "$Datadir\derived\included.dta"
glob included_precovid = "$Datadir\derived\included_precovid.dta"
glob study_cohort = "$Datadir\derived\study_cohort.dta"
glob study_cohort_cca = "$Datadir\derived\study_cohort_cca.dta"
glob study_cohort_mi = "$Datadir\derived\study_cohort_mi.dta"
glob study_cohort_withcvd = "$Datadir\derived\study_cohort_withcvd.dta"
glob study_cohort_withcvd_cca = "$Datadir\derived\study_cohort_withcvd_cca.dta"
glob study_cohort_withcvd_mi = "$Datadir\derived\study_cohort_withcvd_mi.dta"

* Adjustment models
glob part_adj_covariates i.treatmentgroup i.ethnicity i.gender i.imd i.year_index age_index_sp1 age_index_sp2 age_index_sp3 t2dduration_years_sp1 t2dduration_years_sp2 t2dduration_years_sp3 i.region
glob full_adj_covariates $part_adj_covariates egfr_sp1 egfr_sp2 egfr_sp3 hba1c_sp1 hba1c_sp2 hba1c_sp3 bmi_sp1 bmi_sp2 bmi_sp3 i.smoking alcoholabuse healthcare $comorbidities $medications

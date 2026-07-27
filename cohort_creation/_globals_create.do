/*==============================================================================
DO FILE NAME:			_globals_create.do

AUTHOR:					Mia Harley

DATE CREATED: 			11/2023

DATE LAST UPDATED: 		02/2025
						
DESCRIPTION OF FILE:	Global macros to set up file paths					
*==============================================================================*/

clear all

* Set directories
global Aurumbuild "2023_09"
global Projectdir "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness"
global Dodir "$Projectdir\create\dofiles"
global Outputdir "C:\Users\lsh1703855\OneDrive - London School of Hygiene and Tropical Medicine\PhD\3. Ethnic differences in comparative effectiveness\Output"
global Extractdir "Z:\GPRD_GOLD\Mia\Aurum extract Nov 2023\results\part1_Extract"
global Datadir "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness"
global Logdir "$Projectdir\create\logfiles"
global Codelistdir "$Projectdir\codelists"
global Denominator "J:\EHR Share\3 Database guidelines and info\" 
global lookupsaurum "$Denominator\CPRD Aurum\Lookups\\${Aurumbuild}"

* Set file names
glob file_stub 			= 	"Nov23"
glob file_Patient 		= 	"${file_stub}_Extract_Patient_"
glob file_Practice 		=	"${file_stub}_Extract_Practice_"
glob file_Staff			=	"${file_stub}_Extract_Staff_"
glob file_Consultation 	= 	"${file_stub}_Extract_Consultation_"
glob file_Observation	= 	"${file_stub}_Extract_Observation_"
glob file_Referral 		= 	"${file_stub}_Extract_Referral_"
glob file_Problem 		= 	"${file_stub}_Extract_Problem_"
glob file_DrugIssue		= 	"${file_stub}_Extract_DrugIssue_"

* Specify number of files
glob no_Patient = 1
glob no_Practice = 1
glob no_Staff = 1
glob no_Consultation = 37
glob no_Observation = 163
glob no_Referral = 1
glob no_Problem = 4
glob no_DrugIssue = 167

* Set study dates
glob studystart 01jan2015
glob studyend 01feb2022

* Exposures, covariates and outcomes
glob exposures su dpp4i sglt2i metformin
glob covariates ethnicity imd bmi hba1c egfr alcoholabuse smoking healthcare
glob comorbidities af pad hypertension neuropathy retinopathy cancer liverdisease crd ra dementia smi cmd
glob medications acei arb ccb diuretics statins antiplat anticoag antipsych
glob outcomes mi hf stroke ihd cvddeath 
glob outcomes_all allcvd mace mi stroke cvddeath hf ihd

* Codes to be extracted
glob clinical_codes_aurum t2dm_diagnosis ethnicity bmi alcoholabuse smoking hba1c scr mi hf stroke ihd $comorbidities
glob prescriptions_aurum $exposures antidiabetics_exceptmetformin alcohol_therapeutics nicotine_replacement $medications

* Study cohort datasets
glob included = "$Datadir\derived\included.dta"
glob included_precovid = "$Datadir\derived\included_precovid.dta"
glob study_cohort = "$Datadir\derived\study_cohort.dta"
glob study_cohort_cca = "$Datadir\derived\study_cohort_cca.dta"
glob study_cohort_mi = "$Datadir\derived\study_cohort_mi.dta"
glob study_cohort_withcvd = "$Datadir\derived\study_cohort_withcvd.dta"
glob study_cohort_withcvd_cca = "$Datadir\derived\study_cohort_withcvd_cca.dta"
glob study_cohort_withcvd_mi = "$Datadir\derived\study_cohort_withcvd_mi.dta"

* Variables for imputation
glob imputedcatvarlist ethnicity smoking
glob imputedordervarlist imd
glob imputedcontvarlist hba1c bmi egfr
glob regularvarlist cumhaz gender age_index t2dduration_years year_index healthcare $comorbidities $medications //region excluded due to errors
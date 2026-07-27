/*==============================================================================
DO FILE NAME:			_globals_hte.do

AUTHOR:					Mia Harley

DATE CREATED: 			11/2023

DATE LAST UPDATED: 		02/2025
						
DESCRIPTION OF FILE:	Global macros to set up file paths					
*==============================================================================*/

clear all

* Set directories
global Aurumbuild "2023_09"
global Projectdir "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness"
global Dodir "$Projectdir\hte\dofiles"
global Outputdir "C:\Users\lsh1703855\OneDrive - London School of Hygiene and Tropical Medicine\PhD\6. Heterogenous treatment effects\Output"
global Extractdir "Z:\GPRD_GOLD\Mia\Aurum extract Nov 2023\results\part1_Extract"
global Datadir "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness"
global Logdir "$Projectdir\hte\logfiles"
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
glob study_cohort = "$Datadir\derived\study_cohort.dta"
glob study_cohort_cca = "$Datadir\derived\study_cohort_cca.dta"
global study_cohort_hte = "$Datadir\derived\study_cohort_hte.dta"
global study_cohort_hte_cca = "$Datadir\derived\study_cohort_hte_cca.dta"

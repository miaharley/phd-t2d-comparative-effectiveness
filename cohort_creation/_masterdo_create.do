/*==============================================================================
DO FILE NAME:			_masterdo_create.do

AUTHOR:					Mia Harley

VERSION:				v1

LAST UPDATED: 			09/2024

DATASETS CREATED:								
					
DESCRIPTION OF FILE:	This do file runs all create do files
*==============================================================================*/

*** Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

*** 0. Import extract data /*
do "$Dodir/C0a - import data extract aurum.do"
do "$Dodir/C0b - import data extract hes.do"
*/

*** 1. Extract medical codes and drug issues /*
do "$Dodir\C1a - extract clinical codes aurum.do"
do "$Dodir\C1b - extract prescriptions.do"
do "$Dodir\C1c - extract clinical codes hes.do"
*/

*** 2. Apply inclusion criteria
do "$Dodir\C2a - inclusion - t2d diagnosis.do"
do "$Dodir\C2b - inclusion - 2nd line initiators.do"
do "$Dodir\C2c - inclusion - metformin at index.do"
do "$Dodir\C2d - apply inclusion criteria.do"

*** 3. Create covariates
do "$Dodir\C3a - covariate - ethnicity.do"
do "$Dodir\C3b - covariate - imd.do"
do "$Dodir\C3c - covariate - bmi.do"
do "$Dodir\C3d - covariate - hba1c.do"
do "$Dodir\C3e - covariate - egfr.do"
do "$Dodir\C3f - covariate - smoking.do"
do "$Dodir\C3g - covariate - alcoholabuse.do"
do "$Dodir\C3h - covariate - healthcare.do"
do "$Dodir\C3i - covariate - comorbidities.do"
do "$Dodir\C3j - covariate - medications.do"

*** 4. Identify treatment episodes
do "$Dodir\C4a - exposure - prepare prescriptions.do"
do "$Dodir\C4b - exposure - determine exposure periods.do"
do "$Dodir\C4c - exposure - identify treatment episodes.do"
do "$Dodir\C4d - exposure - define first episodes.do"

*** 5. Create outcome variables
do "$Dodir\C5a - outcome - cvd events.do"
do "$Dodir\C5b - outcome - hba1c.do"
do "$Dodir\C5c - outcome - allcause mortality.do"

*** 6. Create exclusion criteria
do "$Dodir\C6a - exclusion - prev antidiabetics.do"
do "$Dodir\C6b - exclusion - prev cvd.do"
do "$Dodir\C6c - exclusion - missing sex.do"
do "$Dodir\C6d - exclusion - less than 12m.do"
do "$Dodir\C6e - exclusion - hba1c lessthan 48.do"

*** 7. Create study datasets
do "$Dodir\C7a - create study dataset.do"
do "$Dodir\C7b - multiple imputation.do"
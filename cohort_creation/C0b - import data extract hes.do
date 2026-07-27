/*==============================================================================
DO FILE NAME:			C0b - import data extract hes.do

AUTHOR:					Mia Harley

DATE CREATED: 			02/2025

DATE LAST UPDATED: 		02/2025					
					
DESCRIPTION OF FILE:	extracts all medical records for all inclusions, exclusions and confounders from observation files
*=============================================================================*/

* Linkage eligibility file
import delimited using "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\linked data delivery\22_001969_Type2_delivery\Results\Aurum_linked\Final\22_001969_linkage_eligibility_aurum.txt", clear stringcols(1 2 3)
save "$Datadir\raw\linked\22_001969_linkage_eligibility_aurum.dta", replace

* HES diagnosis epi
import delimited using "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\linked data delivery\22_001969_Type2_delivery\Results\Aurum_linked\Final\hes_diagnosis_epi_22_001969.txt", clear stringcols(_all)
save "$Datadir\raw\linked\hes_diagnosis_epi_22_001969.dta", replace

* HES primary diagnosis
import delimited using "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\linked data delivery\22_001969_Type2_delivery\Results\Aurum_linked\Final\hes_primary_diag_hosp_22_001969.txt", clear stringcols(_all)
save "$Datadir\raw\linked\hes_primary_diag_hosp_22_001969.dta", replace

* ONS death data
import delimited using "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\linked data delivery\22_001969_Type2_delivery\Results\Aurum_linked\Final\death_patient_22_001969.txt", clear stringcols(_all)
save "$Datadir\raw\linked\death_patient_22_001969.dta", replace

* Patient-level IMD
import delimited using "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\linked data delivery\22_001969_Type2_delivery\Results\Aurum_linked\Final\patient_2019_imd_22_001969.txt", clear stringcols(1 2)
save "$Datadir\raw\linked\patient_2019_imd_22_001969.dta", replace

* Practice-level IMD
import delimited using "Z:\GPRD_GOLD\Mia\ethnicity_comparative_effectiveness\linked data delivery\22_001969_Type2_delivery\Results\Aurum_linked\Final\practice_imd_22_001969.txt", clear stringcols(1 2)
save "$Datadir\raw\linked\practice_imd_22_001969.dta", replace
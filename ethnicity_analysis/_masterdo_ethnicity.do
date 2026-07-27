/*==============================================================================
DO FILE NAME:			_masterdo_ethnicity.do

AUTHOR:					Mia Harley

VERSION:				v1

LAST UPDATED: 			09/2024								
					
DESCRIPTION OF FILE:	This do file runs all create do files
*=============================================================================*/

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\ethnicity\dofiles\_globals_ethnicity.do"

* Program to get hazard ratios by ethnicity
* "$Dodir\_ethnicity hazard ratios program.do"

* Baseline characteristics
do "$Dodir\A1a - ethnicity baseline characteristics.do"
do "$Dodir\A1b - baseline characteristics missing vs no missing.do"

* Incidence rates
do "$Dodir\A2a - ethnicity crude incidence rates.do"
do "$Dodir\A2b - ethnicity cumulative incidence.do"

* Main analysis
do "$Dodir\A3a - ethnicity main analysis.do"
do "$Dodir\A3b - ethnicity forest plot.do"

* Sensitivity analyses
do "$Dodir\A4a - ethnicity sens analysis - cca.do"
do "$Dodir\A4b - ethnicity sens analysis - as treated.do"
do "$Dodir\A4c - ethnicity sens analysis - fu cap.do"
do "$Dodir\A4d - ethnicity sens analysis - ipw.do"

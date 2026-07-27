/*=========================================================================
DO FILE NAME:			_masterdo_sex.do

AUTHOR:					Mia Harley

VERSION:				v1

LAST UPDATED: 			09/2024								
					
DESCRIPTION OF FILE:	This do file runs all create do files
*=========================================================================*/

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\sex\dofiles\_globals_sex.do"

* Baseline characteristics
do "$Dodir\A1a - sex baseline characteristics.do"
do "$Dodir\A1b - baseline characteristics missing vs no missing.do"

* Incidence rates
do "$Dodir\A2a - sex crude incidence rates.do"
do "$Dodir\A2b - sex cumulative incidence.do"

* Main analysis
do "$Dodir\A3a - sex main analysis.do"
do "$Dodir\A3b - sex main analysis forest plot.do"

* Age subgroup analysis
do "$Dodir\A4a - sex subgroup analysis.do"
do "$Dodir\A4b - sex subgroup forest plot.do"

* Sensitivity analyses
do "$Dodir\A5a - sex sens analysis - cca.do"
do "$Dodir\A5b - sex sens analysis - per protocol.do"
do "$Dodir\A5c - sex sens analysis - fu cap.do"
do "$Dodir\A5d - sex sens analysis - ipw.do"
do "$Dodir\A5e - sex sens analysis - per protocol with ipcw.do"


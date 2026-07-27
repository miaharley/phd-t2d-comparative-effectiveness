# Ethnic differences in the comparative effectiveness of t2d medications analysis

This folder contains the Stata code used to estimate differences in treatment effects by ethnicity.

## Overview

The analysis uses the study cohort generated using the scripts in the `cohort_creation` folder.

The scripts perform:
1. Descriptive analyses
2. Incidence rates
3. Main analysis
4. Sensitivity analysis

## Workflow
`_globals_ethnicity.do`
Defines global macros specifying file paths, input files, output locations and other project settings.

`_masterdo_ethnicity.do`
Runs all the ethnicity analysis scripts in the correct order, starting with global do file.

`_ethnicity hazard ratios program.do`
Program that generate hazard ratios for each treatment comparison with different adjustment models and inputs into excel file



# Ethnic differences in the comparative effectiveness of t2d medications analysis

This folder contains the Stata code used to estimate differences in treatment effects by sex.

## Overview
The analysis uses the study cohort generated using the scripts in the `cohort_creation` folder.

The scripts perform:

Descriptive analyses
Incidence rates
Main analysis and forest plot
Age subgroup analysis and forest plot
Sensitivity analysis

## Workflow
`_globals_sex.do`
Defines global macros specifying file paths, input files, output locations and other project settings.

`_masterdo_sex.do`
Runs all the cohort creation scripts in the correct order, starting with global do file.

`_sex hazard ratios program.do`
Program that generate hazard ratios for each treatment comparison with different adjustment models and inputs into excel file

`_sex age hazard ratios program.do`
Program that generate hazard ratios for each treatment comparison with age subgroups with different adjustment models and inputs into excel file

# Heterogenous treatment effects in the comparative effectiveness of t2d medications analysis

This folder contains a mixture of Stata and R code used to estimate heteorgenous treatment effects

## Overview
The analysis uses the study cohort generated using the scripts in the `cohort_creation` folder.

The scripts perform:
1. Create study dataset for this project from the overall T2D cohort in Stata
2. Descriptive analyses of the study population in Stata
3. Run the causal machine learning functions in R

## Workflow 
`_globals_hte.do`
Defines global macros specifying file paths, input files, output locations and other project settings.

`T2D_HTE_masterfile.R`
The master R script for running the causal machine learning

# Cohort creation

This folder contains the Stata code used to create the Type 2 diabetes study cohort.

## Overview

The cohort creation files consist of:
0. Importing the data extract
1. Extract clinical codes and prescriptions
2. Applying inclusion criteria to create the base cohort
3. Creating variables for the base cohort
4. Creating exposure periods for the base cohort
5. Identifying outcomes for the base cohort
6. Applying exclusion criteria to create study cohort
7. Create a dataset with all study variables
8. Run multiple imputation for missing covariate data

## Workflow

The cohort creation workflow is run using the following files:
`_globals_create.do`
Defines global macros specifying file paths, input files, output locations and other project settings.

`_masterdo_create.do`
Runs all the cohort creation scripts in the correct order, starting with global do file.

The remaining Stata do-files contain the individual data processing steps described in the overview above and are called by the master do-file.

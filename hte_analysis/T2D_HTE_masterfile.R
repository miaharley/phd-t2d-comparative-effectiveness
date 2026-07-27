######################################################################
# Script: Data example script for models with cross-fitting
# Author: Matt Pryce
# Date: 11/03/25
# Notes:
######################################################################

#MAKE SURE ALL PACKAGES INSTALLED 

#--- Loading libraries needed ---# 
library(base)
library(dplyr)
library(MASS)
library(tidyverse)
library(stringr)
library(lava)
library(reshape2)
library(data.table)
library(caTools)
library(ggplot2)
library(DAAG)
library(glmnet)
library(randomForest)
library(caret)
library(grf)
library(xgboost)
library(SuperLearner)
library(ranger)
library(KernelKnn)
library(nnet)
library(e1071)
library(haven)
library(writexl)

########################
###   Loading data   ###
########################

#WILL NEED TO UPDATE THE PATHWAY WHEN LOADING EACH OF THE FOLLOWING FUNCTIONS
setwd("J:/EHR-Working/Mia/PhD/T2D_comparative_effectiveness/hte/Matt")

# Output directory
output_dir <- "C:/Users/lsh1703855/OneDrive - London School of Hygiene and Tropical Medicine/PhD/6. Heterogenous treatment effects/Output"

#############################
###   Loading functions   ###
#############################

#Functions which tidy up the data and run nuisance models 
source("Data_management_1tp.R")
source("nuisance_models.R")

#Dr-learner script
source("DR_learner.R")

#T-learner script 
source("T_learner.R")

##########################
###   Running models   ###
##########################

#Notes:
#  -  Each model within each learner will be run using the superlearner.


##################################################################################################

#---------------------------#
#---   Data management   ---#
#---------------------------#

#--- Formatting variables ---#

#Here I make everything numeric as the EP-learner needs this, but needed for the DR-learner

#In terms of what you need in the data, you need
#    - Patient identifier
#    - An outcome variable
#    - An indicator as to whether the outcome is non-missing (C=1 if not missing)  #Important this is coded correctly
#    - Treatment variable 
#    - Covariates 

#T2D data   
study_cohort_hba1c <- read_dta("Z:/GPRD_GOLD/Mia/ethnicity_comparative_effectiveness/derived/study_cohort_hte_cca.dta")

# Convert patid to character
study_cohort_hba1c$patid <- as.character(study_cohort_hba1c$patid)

# Convert categorical variables to factor
study_cohort_hba1c$gender <- factor(study_cohort_hba1c$gender)
study_cohort_hba1c$ethnicity <- factor(study_cohort_hba1c$ethnicity)
study_cohort_hba1c$region <- factor(study_cohort_hba1c$region)
study_cohort_hba1c$smoking <- factor(study_cohort_hba1c$smoking)
study_cohort_hba1c$year_index <- factor(study_cohort_hba1c$year_index)

# Create dummy variables for ethnicity (for lasso)
eth_dummies <- model.matrix(~ ethnicity, data = study_cohort_hba1c)[, -1]
colnames(eth_dummies) <- sub("^ethnicity", "eth_", colnames(eth_dummies))
study_cohort_hba1c <- cbind(study_cohort_hba1c, eth_dummies)

# Create dummy variables for smoking (for lasso)
smok_dummies <- model.matrix(~ smoking, data = study_cohort_hba1c)[, -1]
colnames(smok_dummies) <- sub("^smoking", "smok_", colnames(smok_dummies))
study_cohort_hba1c <- cbind(study_cohort_hba1c, smok_dummies)

# Convert continuous, order and binary variables to numeric
study_cohort_hba1c$treatmentgroup <- as.numeric(study_cohort_hba1c$treatmentgroup)
study_cohort_hba1c$imd <- as.numeric(study_cohort_hba1c$imd)
study_cohort_hba1c$age_index <- as.numeric(study_cohort_hba1c$age_index)
study_cohort_hba1c$year_index <- as.numeric(study_cohort_hba1c$year_index)
study_cohort_hba1c$hba1c <- as.numeric(study_cohort_hba1c$hba1c)
study_cohort_hba1c$hba1c_change <- as.numeric(study_cohort_hba1c$hba1c_change)
study_cohort_hba1c$years_t2d<- as.numeric(study_cohort_hba1c$firstissue - study_cohort_hba1c$years_t2d)
study_cohort_hba1c$bmi <- as.numeric(study_cohort_hba1c$bmi)
study_cohort_hba1c$egfr <- as.numeric(study_cohort_hba1c$egfr)
study_cohort_hba1c$alcoholabuse <- as.numeric(study_cohort_hba1c$alcoholabuse)

#--- Defining covariates to be input into each model ---#
#Outcome models
out_cov_list <- c("gender","ethnicity","region","imd","age_index","year_index",
                  "years_t2d","bmi","egfr","alcoholabuse","smoking","healthcare_util","hba1c",
                  "af","pad","hypertension","neuropathy","retinopathy","cancer","liverdisease","crd","ra","dementia","smi","cmd",
                  "acei","arb","ccb","diuretics","statins","antiplat", "anticoag", "antipsych")
                  

#Missingness model
G_cov_list <- c("gender","ethnicity","region","imd","age_index","year_index", # sociodemographics
                "years_t2d","bmi","egfr","alcoholabuse","smoking","healthcare_util","hba1c", # clinical factors
                "af","pad","hypertension","neuropathy","retinopathy","cancer","liverdisease","crd","ra","dementia","smi","cmd", # comorbidities
                "acei","arb","ccb","diuretics","statins","antiplat", "anticoag", "antipsych") # medications

#Propensity score model (treatment)
ps_cov_list <- c("gender","ethnicity","region","imd","age_index","year_index", # sociodemographics
                 "years_t2d","bmi","egfr","alcoholabuse","smoking","healthcare_util","hba1c", # clinical factors
                 "af","pad","hypertension","neuropathy","retinopathy","cancer","liverdisease","crd","ra","dementia","smi","cmd", # comorbidities
                 "acei","arb","ccb","diuretics","statins","antiplat", "anticoag", "antipsych") # medications


pse_cov_list <- c("gender","ethnicity","age_index", # sociodemographics
                      "bmi","egfr","alcoholabuse","smoking","hba1c", # clinical factors
                      "af","pad","hypertension","neuropathy","retinopathy","cancer","liverdisease","crd","ra","dementia","smi","cmd", # comorbidities
                      "acei","arb","ccb","diuretics","statins","antiplat", "anticoag", "antipsych") # medications

##############################################################################################################################

#---------------------------------#
#---   Defining SL libraries   ---#
#---------------------------------#

#Note: Most of this is commented out, but this code allows you to use other ML 
#      algorithms and tune them, can discuss later, but for now stick with simple options
#      i.e., mean, LM/GLM, Lasso


#--- Creating learners for SL library's ---#
#LASSO & elastic net
nlambda_seq = c(50,100,250)# how many models to run with different penalty values to select which is best->higher number=less efficient
alpha_seq <- c(0.5,1)# balance between ridge vs lasso penalty regularisation->0=ridge (shrinks covariates but still includes them), 1=Lasso (excludes covariates). Elastic net is between ridge and lasso.
usemin_seq <- c(FALSE,TRUE) # tells SL-glmnet whether to use lambda.min (=TRUE) (more complicated but more accurate) or lambda.1se (=FALSE) (more simple and reproducible but less accurate)
para_learners = create.Learner("SL.glmnet", tune = list(nlambda = nlambda_seq,alpha = alpha_seq,useMin = usemin_seq))
para_learners

#Random forest
mtry_seq6 <-  floor(sqrt(6) * c(0.5, 1)) # number of covariates randomly samples as candidates at each split in the tree. Balances bias an variance. Small mtry->more variance and more bias, larger mtry->less variance and less bias
min_node_seq <- c(10,20,50) # minimum number of observations in terminal node (leaf). Smaller nodes->more detailed, less bias, more complex. Larger nodes ->more simple but more bias
rf_learners6 = create.Learner("SL.ranger", tune = list(mtry = mtry_seq6, min.node.size = min_node_seq))
rf_learners6

#Nnet (single layer neural nets)
size_seq <- c(1,2,5)
nnet_learners <- create.Learner("SL.nnet",tune = list(size = size_seq))

#SVM (Support vector machine)
nu_seq <- c(1)
type_seq <- c("C-classification") # "eps-regression" for continuous outcome, "C-classification for binary outcome)
svm_learners = create.Learner("SL.svm",tune = list(type.class = type_seq))

#KernelKnn - takes average outcome across K nearest neighbour patients
K_seq <- c(5,10,20) # number of nearest neighbours, the lower the number, the lower the bias and higher the variance
h_seq <- c(0.01,0.05,0.1,0.25) # the extent to which nearer neighbours are more highly weighted. Smaller h_seq->only nearest neighbours matter, larger h_seq-> further out neighbours matter more
KernelKnn_learners <- create.Learner("SL.kernelKnn",tune = list(k = K_seq, h = h_seq))

#Boosting - boosted tree model where trees trained sequentially, each tree with an incrementally better fit
depth_seq <- c(2,4,8) # controls the maximum number of splits of each tree
shrink_seq <- c(0.05,0.1,0.3) # controls how much 'learning' is done from each tree
minobs_seq <- c(10,20) # minimum number of observations for leaf node
boost_learners = create.Learner("SL.xgboost", tune = list(minobspernode=minobs_seq, max_depth = depth_seq, shrinkage = shrink_seq))
boost_learners

#GAM learners
k_vals <- c(2,3,4)
gam_learners = create.Learner("SL.gam", tune = list(k=k_vals))

#--- Creating SL libraries ---#
#Outcome models - Reduced
out_lib <- c("SL.glm",
             "SL.glmnet_8","SL.glmnet_11",
             "SL.ranger_2","SL.ranger_4")

#Imputation models - Reduced
G_lib <- c("SL.glm",
           "SL.glmnet_8","SL.glmnet_11",
           "SL.ranger_2")


#Propensity score models reduced
e_lib <- c("SL.glm",
           "SL.glmnet_8","SL.glmnet_11",
           "SL.ranger_2")


#Pseudo outcome model - Single covariate - Reduced   (be careful using LASSO in this model)
pse_lib <- c("SL.mean",
             "SL.lm",
             "SL.ranger_1",
             "SL.gam_2")


##################################################################################################################


#--------------#
#--- Set up ---#
#--------------#

# Storage for all CATE results
CATE_results <- list()

#------------------------------------------------------------------#
#--- Running T learner (SL imputation) - All pseudo outcome set ---#
#------------------------------------------------------------------#

#Setting seed for consistency
set.seed(1101)

start_time <- Sys.time()

tryCatch(
  {
    #--- Running model ---#
    TL_result <- T_learner(analysis = "SL imputation",
                      data = study_cohort_hba1c,
                      id = "patid",
                      outcome =  "hba1c_change",
                      exposure = "treatmentgroup",
                      outcome_observed_indicator = "c",
                      out_method = "Super learner",
                      out_covariates = out_cov_list,
                      out_SL_lib = out_lib,
                      imp_covariates = G_cov_list,
                      imp_SL_lib = G_lib,
                      newdata = study_cohort_hba1c)
    
    message("T-learner model fitting completed successfully")
  },
  error = function(e) { 
    message("ERROR: T-learner model fitting failed")
    print(e)
    stop("Cannot proceed without fitted model")
  }
)    

# Print the time it took to run
end_time <- Sys.time()
print(end_time - start_time)

# Store CATE results
CATE_results$TL_CATE <- TL_result

# Add CATE estimate to main dataset
study_cohort_hba1c$TL_CATE <- as.vector(TL_result$CATE_est)

# Save CATE results
saveRDS(TL_result, file = "TL_CATE.rds")

rm(TL_result)

#-----------------------------------------#
#--- mDR learner regressed on all covariates ---#
#-----------------------------------------#

#Setting seed for consistency
set.seed(2202)

start_time <- Sys.time()

#This is the missing outcome version of the DR-learner
tryCatch(
  {
    #--- Running model ---#
    mDR_CATE_allcovs <- DR_learner(analysis = "mDR-learner",       
                                 data = study_cohort_hba1c,
                                 id = "patid",
                                 outcome = "hba1c_change",
                                 exposure = "treatmentgroup",
                                 outcome_observed_indicator = "c",
                                 splits = 10,                      #When running for real set this to 10
                                 e_method = "Super learner",
                                 e_covariates = ps_cov_list,
                                 e_SL_lib = e_lib,
                                 out_method = "Super learner",
                                 out_covariates = out_cov_list,
                                 out_SL_lib = out_lib,
                                 g_method = "Super learner",
                                 g_covariates = G_cov_list,
                                 g_SL_lib = G_lib,
                                 pse_method = "Super learner - Discrete",
                                 pse_covariates = pse_cov_list,
                                 pse_SL_lib = pse_lib,
                                 newdata = study_cohort_hba1c,
                                 return_nuisance_models = TRUE)
    
    message("DR-learner model fitting completed successfully")
  },
  error = function(e) { 
    message("ERROR: DR-learner model fitting failed")
    print(e)
    stop("Cannot proceed without fitted model")
  }
)

# Print the time it took to run
end_time <- Sys.time()
print(end_time - start_time)

# Store CATE results
CATE_results$mDR_CATE_allcovs <- mDR_CATE_allcovs

# Add CATE estimate to main dataset
study_cohort_hba1c$mDR_CATE_allcovs <- as.vector(mDR_CATE_allcovs$CATE_est)

# Save CATE results
saveRDS(mDR_CATE_allcovs, file = "mDR_CATE_allcovs.rds")

rm(mDR_CATE_allcovs)

# See what learners the SL used
print(CATE_results$mDR_CATE_allcovs$nuis_mods$cen_mod$g_mod$coef)
print(CATE_results$mDR_CATE_allcovs$nuis_mods$prop_mod$e_mod$coef)
print(CATE_results$mDR_CATE_allcovs$nuis_mods$outcome_models$o_mod_0$coef)
print(CATE_results$mDR_CATE_allcovs$nuis_mods$outcome_models$o_mod_1$coef)

#-----------------------------------------#
#--- mDR learner regressed on one covariate at a time ---#
#-----------------------------------------#

#Setting seed for consistency
set.seed(12345)

# Just edit this list - add or remove variables as needed
covariates_to_run <- c("gender", "ethnicity")

for (covariate in covariates_to_run) {

# Start timer
start_time <- Sys.time()

# Run mDR-learner
tryCatch(
  {
    mDR_result <- DR_learner(analysis = "mDR-learner",       
                            data = study_cohort_hba1c,
                            id = "patid",
                            outcome = "hba1c_change",
                            exposure = "treatmentgroup",
                            outcome_observed_indicator = "c",
                            splits = 10,
                            e_method = "Super learner",
                            e_covariates = ps_cov_list,
                            e_SL_lib = e_lib,
                            out_method = "Super learner",
                            out_covariates = out_cov_list,
                            out_SL_lib = out_lib,
                            g_method = "Super learner",
                            g_covariates = G_cov_list,
                            g_SL_lib = G_lib,
                            pse_method = "Super learner - Discrete",
                            pse_covariates = covariate, 
                            pse_SL_lib = pse_lib,
                            newdata = study_cohort_hba1c,
                            return_nuisance_models = TRUE
    )
    
    message("DR-learner model fitting completed successfully for: ", covariate)
  },
  error = function(e) { 
    message("ERROR: DR-learner model fitting failed for: ", covariate)
    print(e)
    stop("Cannot proceed without fitted model")
  }
)

# Print the time it took to run
end_time <- Sys.time()
print(end_time - start_time)

# Store CATE results
CATE_results[[paste0("mDR_CATE_", covariate)]] <- mDR_result

# Add CATE estimate to main dataset
study_cohort_hba1c[[paste0("mDR_CATE_", covariate)]] <- as.vector(mDR_result$CATE_est)

# Save CATE results
saveRDS(mDR_result, file = paste0("mDR_CATE_", covariate, ".rds"))

rm(mDR_result)
}

#-----------------------------------------#
#--- mDR learner - adaptive Lasso ---#
#-----------------------------------------#

study_cohort_hba1c$pse_Y <- CATE_results$mDR_CATE_allcovs$data$pse_Y

x_cont <- model.matrix(~ . - 1, data = study_cohort_hba1c[, pse_cov_list])
y_cont <- study_cohort_hba1c$pse_Y

foldid <- sample(rep(1:10, length.out = nrow(x_cont)))

# ## Perform initial ridge regression with 10-fold CV
# ridge1_cv <- cv.glmnet(
#   x = x_cont, y = y_cont,
#   type.measure = "mse",
#   foldid = foldid,
#   alpha = 0,
#   standardize = TRUE)
# 
# ## Extract ridge coeff at lambda.min (drop intercept)
# best_ridge_coef <- as.numeric(coef(ridge1_cv, s = ridge1_cv$lambda.min))[-1]
# 
# ## Perform adaptive LASSO with 10-fold CV
# alasso1_cv <- cv.glmnet(
#   x = x_cont, y = y_cont,
#   type.measure = "mse",
#   foldid = foldid,
#   alpha = 1,
#   penalty.factor = 1 / abs(best_ridge_coef),
#   standardize = TRUE)
# 
# ## Penalty vs CV MSE plot
# plot(alasso1_cv)

## Perform LASSO with 10-fold CV
lasso1_cv <- cv.glmnet(
  x = x_cont, 
  y = y_cont,
  alpha = 1,
  penalty.factor = rep(1, ncol(x_cont))  # Or omit - equal penalties
)

## Get a list of covariates with non-zero coefficients
coef_min <- as.vector(coef(lasso1_cv, s = "lambda.min"))[-1]
names(coef_min) <- colnames(x_cont)
selected_covs <- coef_min[coef_min != 0]
selected_covs <- selected_covs[order(abs(selected_covs), decreasing = TRUE)]
print(selected_covs) 

## Create data frame of coefficients
coef_table <- data.frame(
  covariate = names(selected_covs),
  coef      = as.numeric(selected_covs),
  abs_coef  = abs(as.numeric(selected_covs)),
  row.names = NULL
)

write_xlsx(
  coef_table,
  path = file.path(output_dir, "adaptive_lasso_coefficients.xlsx")
)


#-----------------------------------------#
#--- mDR learner regressed on all covariates using lasso ---#
#-----------------------------------------#

pse_lasso_list <- c("gender","eth_2","eth_3","eth_4","eth_5","eth_6","age_index",
                      "bmi","egfr","alcoholabuse","smok_1","smok_2","hba1c",
                      "af","pad","hypertension","neuropathy","retinopathy","cancer","liverdisease","crd","ra","dementia","smi","cmd",
                      "acei","arb","ccb","diuretics","statins","antiplat", "anticoag", "antipsych")

pse_lib_lasso <- c("SL.glmnet_5")

#Setting seed for consistency
set.seed(12345)

start_time <- Sys.time()

#This is the missing outcome version of the DR-learner
tryCatch(
  {
    #--- Running model ---#
    mDR_CATE_lasso <- DR_learner(analysis = "mDR-learner",       
                                 data = study_cohort_hba1c,
                                 id = "patid",
                                 outcome = "hba1c_change",
                                 exposure = "treatmentgroup",
                                 outcome_observed_indicator = "c",
                                 splits = 1,                      #When running for real set this to 10
                                 e_method = "Super learner",
                                 e_covariates = ps_cov_list,
                                 e_SL_lib = e_lib,
                                 out_method = "Super learner",
                                 out_covariates = out_cov_list,
                                 out_SL_lib = out_lib,
                                 g_method = "Super learner",
                                 g_covariates = G_cov_list,
                                 g_SL_lib = G_lib,
                                 pse_method = "Super learner - Discrete",
                                 pse_covariates = pse_lasso_list,
                                 pse_SL_lib = pse_lib_lasso,
                                 newdata = study_cohort_hba1c,
                                 return_nuisance_models = TRUE)
    
    message("DR-learner model fitting completed successfully")
  },
  error = function(e) { 
    message("ERROR: DR-learner model fitting failed")
    print(e)
    stop("Cannot proceed without fitted model")
  }
)

# Print the time it took to run
end_time <- Sys.time()
print(end_time - start_time)

# Store CATE results
CATE_results$mDR_CATE_lasso <- mDR_CATE_lasso

# Add CATE estimate to main dataset
study_cohort_hba1c$mDR_CATE_lasso <- as.vector(mDR_CATE_lasso$CATE_est)

# Save CATE results
saveRDS(mDR_CATE_lasso, file = "mDR_CATE_lasso.rds")

rm(mDR_CATE_lasso)

# Extract coefficients using the lambda.min from glmnet
glmnet_fit <- CATE_results$mDR_CATE_lasso$pse_mod$po_mod$fitLibrary$SL.glmnet_All$object$glmnet.fit
coef_min <- coef(glmnet_fit, s = cv_glmnet$lambda.min)
coef_vector <- as.numeric(coef_min)[-1]

# Assign names - get variable names from the SuperLearner object
var_names <- CATE_results$mDR_CATE_lasso$pse_mod$po_mod$varNames
names(coef_vector) <- var_names

# Get non-zero coefficients
selected_covs <- coef_vector[coef_vector != 0]
selected_covs <- selected_covs[order(abs(selected_covs), decreasing = TRUE)]
print(selected_covs)

#-----------------------------------------#
#--- Tables and figures ---#
#-----------------------------------------#

source("histogram of cate estimates.R")
source("histogram censoring weights and propensity score.R")
source("correlation mDR-learner T-learner.R")
source("mdr_1cov_plots.R")
source("glm_1cov_plots.R")
source("adaptive lasso bar plot.R")


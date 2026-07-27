library(rms)

##########################################
### Linear regression - no interaction ###
##########################################

glm <- Glm(
  hba1c_change ~ treatmentgroup + rcs(hba1c, 3) +
    gender + ethnicity + region + imd + rcs(age_index, 3) + year_index +
    rcs(years_t2d, 3) + alcoholabuse + smoking + healthcare_util + rcs(egfr, 3) + rcs(bmi, 3) +
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +
    crd + ra + dementia + smi + cmd +
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c,
  x = TRUE, y = TRUE
)

summary(glm)

coef_est <- coef(glm)["treatmentgroup"]

se_est <- sqrt(vcov(glm)["treatmentgroup",
                         "treatmentgroup"])

lower_ci <- coef_est - 1.96 * se_est
upper_ci <- coef_est + 1.96 * se_est

c(Estimate = coef_est,
  Lower_95CI = lower_ci,
  Upper_95CI = upper_ci)

ate <- contrast(glm,
                list(treatmentgroup = 1),
                list(treatmentgroup = 0))

ate

##########################################
###   Figure - interaction analyses    ###
##########################################

png(file.path(output_dir, "glm_1cov_cont.png"),
    width = 700, height = 700)

par(
  mfrow = c(2, 2),  
  mar   = c(5, 5, 4, 2)
)

ylim_common <- c(-10, 0.5)

dd <- datadist(study_cohort_hba1c)
options(datadist = "dd")

## Panel 1: HbA1c
glm_hba1c <- Glm(
  hba1c_change ~ treatmentgroup * rcs(hba1c, 3) +
    gender + ethnicity + region + imd + rcs(age_index, 3) + year_index +
    rcs(years_t2d, 3) + alcoholabuse + smoking + healthcare_util + rcs(egfr, 3) + rcs(bmi, 3) +
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +
    crd + ra + dementia + smi + cmd +
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c,
  x = TRUE, y = TRUE
)

hba1c_seq <- seq(
  quantile(study_cohort_hba1c$hba1c, 0.01, na.rm = TRUE),
  quantile(study_cohort_hba1c$hba1c, 0.99, na.rm = TRUE),
  by = 1
)

glm_delta_hba1c <- intEST(
  var2values = hba1c_seq,
  model = glm_hba1c,
  data = study_cohort_hba1c,
  var1 = "treatmentgroup",
  var2 = "hba1c",
  ci.method = "delta"
)

plotINT(
  glm_delta_hba1c,
  xlab = "HbA1c",
  ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
  ylim = ylim_common,
  ref.zero = FALSE
)

abline(h = 0, lty = 2)

## Panel 2: eGFR
glm_egfr <- Glm(
  hba1c_change ~ treatmentgroup * rcs(egfr, 3) +
    gender + ethnicity + region + imd + rcs(age_index, 3) + year_index +
    rcs(years_t2d, 3) + alcoholabuse + smoking + healthcare_util + rcs(hba1c, 3) + rcs(bmi, 3) +
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +
    crd + ra + dementia + smi + cmd +
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c,
  x = TRUE, y = TRUE
)

egfr_seq <- seq(38.4, 128.2, by = 0.1)

glm_delta_egfr <- intEST(
  var2values = egfr_seq,
  model = glm_egfr,
  data = study_cohort_hba1c,
  var1 = "treatmentgroup",
  var2 = "egfr",
  ci.method = "delta"
)

plotINT(
  glm_delta_egfr,
  xlab = "eGFR",
  ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
  ylim = ylim_common,
  ref.zero = FALSE
)

abline(h = 0, lty = 2)

## Panel 3: BMI
glm_bmi <- Glm(
  hba1c_change ~ treatmentgroup * rcs(bmi, 3) +
    gender + ethnicity + region + imd + rcs(age_index, 3) + year_index +
    rcs(years_t2d, 3) + rcs(egfr, 3) + alcoholabuse + smoking + healthcare_util + rcs(hba1c, 3) +
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +
    crd + ra + dementia + smi + cmd +
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c, 
  x=TRUE , y=TRUE
)

glm_delta_bmi <- intEST(
  var2values = c(21:55),
  model = glm_bmi,
  data = study_cohort_hba1c,
  var1 = "treatmentgroup",
  var2 = "bmi",
  ci.method = "delta"
)

plotINT(
  glm_delta_bmi,
  xlab = "BMI",
  ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
  ylim = ylim_common,
  ref.zero = FALSE
)

abline(h = 0, lty = 2)

## Panel 4: Age
glm_age <- Glm(
  hba1c_change ~ treatmentgroup * rcs(age_index, 3) +
    gender + ethnicity + region + imd + rcs(hba1c, 3) + year_index +
    rcs(years_t2d, 3) + alcoholabuse + smoking + healthcare_util + rcs(egfr, 3) + rcs(bmi, 3) +
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +
    crd + ra + dementia + smi + cmd +
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c,
  x = TRUE, y = TRUE
)

glm_delta_age <- intEST(
  var2values = 18:98,
  model = glm_age,
  data = study_cohort_hba1c,
  var1 = "treatmentgroup",
  var2 = "age_index",
  ci.method = "delta"
)

plotINT(
  glm_delta_age,
  xlab = "Age",
  ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
  ylim = ylim_common,
  ref.zero = FALSE
)

abline(h = 0, lty = 2)

dev.off()

glm_sex <- Glm(
  hba1c_change ~ treatmentgroup * gender +
    ethnicity + region + imd + rcs(age_index, 3) + year_index +
    rcs(years_t2d, 3) + alcoholabuse + smoking + healthcare_util +
    rcs(hba1c, 3) + rcs(bmi, 3) +
    af + pad + hypertension + neuropathy + retinopathy + cancer +
    liverdisease + crd + ra + dementia + smi + cmd +
    acei + arb + ccb + diuretics + statins +
    antiplat + anticoag + antipsych,
  data = study_cohort_hba1c,
  x = TRUE, y = TRUE
)

glm_ethnicity <- Glm(
  hba1c_change ~ treatmentgroup * ethnicity +
    gender + region + imd + rcs(age_index, 3) + year_index +
    rcs(years_t2d, 3) + alcoholabuse + smoking + healthcare_util +
    rcs(hba1c, 3) + rcs(bmi, 3) +
    af + pad + hypertension + neuropathy + retinopathy + cancer +
    liverdisease + crd + ra + dementia + smi + cmd +
    acei + arb + ccb + diuretics + statins +
    antiplat + anticoag + antipsych,
  data = study_cohort_hba1c,
  x = TRUE, y = TRUE
)

## Sex

library(rms)

contrast(glm_sex,
         list(treatmentgroup = 1, gender = 0),
         list(treatmentgroup = 0, gender = 0))

contrast(glm_sex,
         list(treatmentgroup = 1, gender = 1),
         list(treatmentgroup = 0, gender = 1))

# Male (assuming 0 = Male)
sex_male <- contrast(glm_sex,
                     list(treatmentgroup = 1, gender = 0),
                     list(treatmentgroup = 0, gender = 0))

# Female (assuming 1 = Female)
sex_female <- contrast(glm_sex,
                       list(treatmentgroup = 1, gender = 1),
                       list(treatmentgroup = 0, gender = 1))

male_est   <- sex_male$Contrast
female_est <- sex_female$Contrast

## Ethnicity
levels(study_cohort_hba1c$ethnicity)

eth_levels <- levels(study_cohort_hba1c$ethnicity)

eth_estimates <- sapply(eth_levels, function(e) {
  contrast(glm_ethnicity,
           list(treatmentgroup = 1, ethnicity = e),
           list(treatmentgroup = 0, ethnicity = e))$Contrast
})

table_out <- data.frame(
  Covariate = c("Sex", "",
                "Ethnicity", rep("", length(eth_levels) - 1)),
  
  Category = c("Male", "Female",
               eth_levels),
  
  `Estimated change in HbA1c % with SGLT2i vs DPP4i` =
    c(male_est,
      female_est,
      eth_estimates)
)

library(writexl)

write_xlsx(
  table_out,
  path = file.path(output_dir, "glm_1cov_cat.xlsx")
)

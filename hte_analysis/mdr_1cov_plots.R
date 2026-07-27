#------------------------------------------------------------------#
#--- Graphs of mDR regressed on one covariate at a time (continuous) ---#
#------------------------------------------------------------------#

png(file.path(output_dir, "mDR_CATE_1cov_cont.png"),
    width = 700, height = 700)

par(
  mfrow = c(2, 2),  
  mar   = c(5, 5, 4, 2)
)

ylim_common <- c(-1, 0)

## Panel 1: HbA1c

hba1c_data <- subset(
  study_cohort_hba1c,
  hba1c >= quantile(hba1c, 0.01, na.rm = TRUE) &
    hba1c <= quantile(hba1c, 0.99, na.rm = TRUE)
)

with(hba1c_data, {
  plot(hba1c, mDR_CATE_hba1c,
       ylim = ylim_common,
       xlab = "HbA1c (mmol/mol)",
       ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
       main = "HbA1c",
       col  = "black")
})
abline(h = 0, col = "black", lty = 2)

## Panel 2: eGFR
egfr_data <- subset(study_cohort_hba1c, egfr >= 38.4 & egfr <= 128.2)

with(egfr_data, {
  plot(egfr, mDR_CATE_egfr,
       ylim = ylim_common,
       xlab = "eGFR (mL/min/1.73m²)",
       ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
       main = "eGFR",
       col  = "black")
})
abline(h = 0, col = "black", lty = 2)

## Panel 3: BMI
bmi_data <- subset(study_cohort_hba1c, bmi >= 21 & bmi <= 55)

with(bmi_data, {
  plot(bmi, mDR_CATE_bmi,
       ylim = ylim_common,
       xlab = "BMI (kg/m²)",
       ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
       main = "BMI",
       col  = "black")
})
abline(h = 0, col = "black", lty = 2)

## Panel 4: Age
with(study_cohort_hba1c, {
  plot(age_index, mDR_CATE_age_index,
       ylim = ylim_common,
       xlab = "Age, years",
       ylab = "Difference in HbA1c change (SGLT2i − DPP4i)",
       main = "Age",
       col  = "black")
})
abline(h = 0, col = "black", lty = 2)

dev.off()

#------------------------------------------------------------------#
#--- Tables of mDR regressed on one covariate at a time (categorical/binary) ---#
#------------------------------------------------------------------#

# Get CATE conditional on sex
male_cate   <- unique(study_cohort_hba1c$mDR_CATE_gender[study_cohort_hba1c$gender == 0])
female_cate <- unique(study_cohort_hba1c$mDR_CATE_gender[study_cohort_hba1c$gender == 1])

# Get CATE conditional on ethnicity
white_cate       <- unique(study_cohort_hba1c$mDR_CATE_ethnicity[study_cohort_hba1c$ethnicity == 1])
southasian_cate  <- unique(study_cohort_hba1c$mDR_CATE_ethnicity[study_cohort_hba1c$ethnicity == 2])
black_cate       <- unique(study_cohort_hba1c$mDR_CATE_ethnicity[study_cohort_hba1c$ethnicity == 3])
other_cate       <- unique(study_cohort_hba1c$mDR_CATE_ethnicity[study_cohort_hba1c$ethnicity == 4])
mixed_cate       <- unique(study_cohort_hba1c$mDR_CATE_ethnicity[study_cohort_hba1c$ethnicity == 5])
notstated_cate   <- unique(study_cohort_hba1c$mDR_CATE_ethnicity[study_cohort_hba1c$ethnicity == 6])

# Create dataframe for table
table_out <- data.frame(
  Covariate = c("Sex", rep("", 1), "Ethnicity", rep("", 5)),
  Category  = c("Male", "Female", "White", "South Asian", "Black", "Other", "Mixed", "Not stated"),
  `Estimated change in HbA1c\n% with SGLT2i vs DPP4i` =
    sprintf("%.3f", c(male_cate, female_cate, white_cate, southasian_cate,
                      black_cate, other_cate, mixed_cate, notstated_cate)),
  check.names = FALSE
)

library(writexl)

write_xlsx(
  table_out,
  path = file.path(output_dir, "mDR_CATE_1cov_cat.xlsx")
)

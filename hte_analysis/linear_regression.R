library(splines)
library(rms)


lr_nointeraction <- lm(
  hba1c_change ~ treatmentgroup + 
    gender + ethnicity + region + imd + ns(age_index, df = 3) + year_index + 
    ns(years_t2d, df = 3) + ns(bmi, df = 3) + ns(egfr, df = 3) + alcoholabuse + smoking + healthcare_util + ns(hba1c, df = 3) + 
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +  
    crd + ra + dementia + smi + cmd + 
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c
)

summary(lr_nointeraction)

#===========================================
# Treatment × Sex
#===========================================
lr_sex <- lm(
  hba1c_change ~ treatmentgroup * gender + 
    ethnicity + region + imd + ns(age_index, df = 3) + year_index + 
    ns(years_t2d, df = 3) + ns(bmi, df = 3) + ns(egfr, df = 3) + alcoholabuse + smoking + healthcare_util + ns(hba1c, df = 3) + 
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +  
    crd + ra + dementia + smi + cmd + 
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c
)

anova(lr_nointeraction, lr_sex)

#===========================================
# Treatment x Ethnicity
#===========================================
lr_ethnicity <- lm(
  hba1c_change ~ treatmentgroup * ethnicity + 
    gender + region + imd + ns(age_index, df = 3) + year_index + 
    ns(years_t2d, df = 3) + ns(bmi, df = 3) + ns(egfr, df = 3) + alcoholabuse + smoking + healthcare_util + ns(hba1c, df = 3) + 
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +  
    crd + ra + dementia + smi + cmd + 
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c
)

summary(lr_ethnicity)

anova(lr_nointeraction, lr_ethnicity)

#===========================================
# Treatment x BMI
#===========================================

lr_bmi <- lm(
  hba1c_change ~ treatmentgroup * ns(bmi, df = 3) + 
    gender + ethnicity + region + imd + ns(age_index, df = 3) + year_index + 
    ns(years_t2d, df = 3) + ns(egfr, df = 3) + alcoholabuse + smoking + healthcare_util + ns(hba1c, df = 3) + 
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +  
    crd + ra + dementia + smi + cmd + 
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c
)

summary(lr_bmi)

anova(lr_nointeraction, lr_bmi)

#===========================================
# Treatment x eGFR
#===========================================

lr_egfr <- lm(
  hba1c_change ~ treatmentgroup * ns(egfr, df = 3) + 
    gender + ethnicity + region + imd + ns(age_index, df = 3) + year_index + 
    ns(years_t2d, df = 3) + ns(bmi, df = 3) + alcoholabuse + smoking + healthcare_util + ns(hba1c, df = 3) + 
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +  
    crd + ra + dementia + smi + cmd + 
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c
)

summary(lr_egfr)

anova(lr_nointeraction, lr_egfr)

#===========================================
# Treatment x Age
#===========================================

lr_age <- lm(
  hba1c_change ~ treatmentgroup * ns(age_index, df = 3) + 
    gender + ethnicity + region + imd + year_index + 
    ns(years_t2d, df = 3) + ns(bmi, df = 3) + ns(egfr, df = 3) + alcoholabuse + smoking + healthcare_util + ns(hba1c, df = 3) + 
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +  
    crd + ra + dementia + smi + cmd + 
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c
)

summary(lr_age)

anova(lr_nointeraction, lr_age)

#===========================================
# Treatment x HbA1c
#===========================================

lr_hba1c <- lm(
  hba1c_change ~ treatmentgroup * ns(hba1c, df = 3) + 
    gender + ethnicity + region + imd + year_index + ns(age_index, df = 3) +
    ns(years_t2d, df = 3) + ns(bmi, df = 3) + ns(egfr, df = 3) + alcoholabuse + smoking + healthcare_util +  
    af + pad + hypertension + neuropathy + retinopathy + cancer + liverdisease +  
    crd + ra + dementia + smi + cmd + 
    acei + arb + ccb + diuretics + statins + antiplat + anticoag + antipsych,
  data = study_cohort_hba1c
)

summary(lr_hba1c)

anova(lr_nointeraction, lr_hba1c)

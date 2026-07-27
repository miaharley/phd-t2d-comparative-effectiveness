#------------------------------------------------------------------#
#--- Histogram of CATE estimates from mDR-learner and T-learner---#
#------------------------------------------------------------------#
# Common x limits
x_limits <- range(
  c(study_cohort_hba1c$TL_CATE,
    study_cohort_hba1c$mDR_CATE_allcovs),
  na.rm = TRUE
)

# x-axis ticks
x_ticks <- seq(
  from = floor(x_limits[1]),
  to   = ceiling(x_limits[2]),
  by   = 1
)

h1 <- hist(study_cohort_hba1c$TL_CATE, plot = FALSE, breaks = 30) 
h2 <- hist(study_cohort_hba1c$mDR_CATE_allcovs, plot = FALSE, breaks = 30)

png(file.path(output_dir, "CATE_hist_TL_mDR.png"),
    width = 1600, height = 900)

par(
  mfrow = c(1, 2),
  mar   = c(5, 5, 4, 2),
  xaxs  = "i",
  yaxs  = "i",
  cex.main = 1.4,  # titles
  cex.lab  = 1.3,  # axis labels
  cex.axis = 1.2   # tick labels
)

## T-learner
cols1 <- ifelse(h1$mids < 0, "lightblue", "lightcoral")

plot(h1,
     col = cols1,
     border = "black",
     xlim = c(-15, 5),
     ylim = c(0, 12000),
     xaxt = "n",
     main = "T-learner CATE estimates",
     xlab = "CATE (HbA1c reduction, mmol/mol)",
     ylab = "Frequency")

axis(1, at = x_ticks)
abline(v = 0, lty = 2)

## mDR-learner
cols2 <- ifelse(h2$mids < 0, "lightblue", "lightcoral")

plot(h2,
     col = cols2,
     border = "black",
     xlim = c(-15, 5),
     ylim = c(0, 12000),
     xaxt = "n",
     yaxt = "n",   # remove y-axis
     main = "mDR-learner CATE estimates",
     xlab = "CATE (HbA1c reduction, mmol/mol)",
     ylab = "")

axis(1, at = x_ticks)
abline(v = 0, lty = 2)

dev.off()

#------------------------------------------------------------------#
#--- Median and IQR of CATE from T-learner and mDR-learner---#
#------------------------------------------------------------------#

x_TL <- study_cohort_hba1c$TL_CATE

q_TL <- quantile(x_TL, c(0.25, 0.5, 0.75), na.rm = TRUE)

mean_TL <- mean(x_TL, na.rm = TRUE)
sd_TL   <- sd(x_TL, na.rm = TRUE)

pos_TL  <- mean(x_TL > 0,  na.rm = TRUE) * 100
neg_TL  <- mean(x_TL < 0,  na.rm = TRUE) * 100
zero_TL <- mean(x_TL == 0, na.rm = TRUE) * 100

x_mDR <- study_cohort_hba1c$mDR_CATE_allcovs

q_mDR <- quantile(x_mDR, c(0.25, 0.5, 0.75), na.rm = TRUE)

mean_mDR <- mean(x_mDR, na.rm = TRUE)
sd_mDR   <- sd(x_mDR, na.rm = TRUE)

pos_mDR  <- mean(x_mDR > 0,  na.rm = TRUE) * 100
neg_mDR  <- mean(x_mDR < 0,  na.rm = TRUE) * 100
zero_mDR <- mean(x_mDR == 0, na.rm = TRUE) * 100

results_table <- data.frame(
  Metric = c(
    "Mean (SD)",
    "Median (IQR)",
    "% positive CATE",
    "% negative CATE",
    "% zero CATE"
  ),
  
  T_learner = c(
    sprintf("%.3f (%.3f)", mean_TL, sd_TL),
    sprintf("%.3f (%.3f,%.3f)", q_TL[2],  q_TL[1],  q_TL[3]),
    sprintf("%.1f", pos_TL),
    sprintf("%.1f", neg_TL),
    sprintf("%.1f", zero_TL)
  ),
  
  mDR_learner = c(
    sprintf("%.3f (%.3f)", mean_mDR, sd_mDR),
    sprintf("%.3f (%.3f,%.3f)", q_mDR[2], q_mDR[1], q_mDR[3]),
    sprintf("%.1f", pos_mDR),
    sprintf("%.1f", neg_mDR),
    sprintf("%.1f", zero_mDR)
  ),
  
  row.names = NULL
)

library(writexl)

write_xlsx(
  results_table,
  path = file.path(output_dir, "CATE_summary_TL_mDR.xlsx")
)
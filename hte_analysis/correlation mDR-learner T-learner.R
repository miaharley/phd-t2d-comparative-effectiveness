
#------------------------------------------------------------------#
#--- Correlation of mDR-learner and T-learner CATE estimates ---#
#------------------------------------------------------------------#

png(file.path(output_dir, "CATE_corr_TL_mDR.png"),
    width = 8, height = 7, units = "in",
    res = 300, type = "cairo-png")

par(
  mar      = c(7, 5, 4, 2) + 0.1,
  cex.axis = 0.75,
  cex.lab  = 0.75
)

with(study_cohort_hba1c, {
  plot(TL_CATE, mDR_CATE_allcovs,
       xlab = "T-learner CATE estimation (change in HbA1c, %)",
       ylab = "mDR-learner CATE estimation (change in HbA1c, %)",
       pch  = 15,
       cex  = 0.25)
})

r <- with(study_cohort_hba1c,
          cor(TL_CATE, mDR_CATE_allcovs, use = "complete.obs"))

mtext(paste0("Correlation coefficient = ", round(r, 3)),
      side = 1,
      line = 5,
      cex  = par("cex.axis"))

dev.off()

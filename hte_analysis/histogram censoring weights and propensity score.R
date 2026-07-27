#------------------------------------------------------------------#
#--- Histogram of mDR-learner censoring weights and propensity scores---#
#------------------------------------------------------------------#

## Propensity scores
png(file.path(output_dir, "prop_hist_mDR.png"),
    width = 800, height = 600)

par(
  yaxs = "i",       # axes start exactly at 0 (no gap)
  xaxs = "i",
  mar = c(5, 6, 4, 2),  # bottom, left, top, right margins
  cex.lab  = 1.7,   # axis label size
  cex.axis = 1.5    # tick label size
)

# Extract propensity scores by treatment group
ps_dpp4i <- CATE_results$mDR_CATE_allcovs$nuis_mods$prop_mod$e_pred[
  study_cohort_hba1c$treatmentgroup == 0
]

ps_sglt2i <- CATE_results$mDR_CATE_allcovs$nuis_mods$prop_mod$e_pred[
  study_cohort_hba1c$treatmentgroup == 1
]

# Common breaks so histograms align
breaks <- seq(0, 1, length.out = 26)

#histogram for dpp4i in red
hist(ps_dpp4i,
     breaks = breaks,
     main = "",
     xlab = "Propensity scores",
     ylab = "Distribution",
     col  = rgb(0.9, 0.3, 0.3, 0.5),
     border = "black",
     ylim = c(0, 10),
     freq=FALSE 
)

# Overlay histogram for sglt2i in blue
hist(ps_sglt2i,
     breaks = breaks,
     col  = rgb(0.2, 0.4, 0.8, 0.5),
     border = "black",
     add = TRUE,
     freq=FALSE
)

# Legend
legend("topright",
       legend = c("DPP4i", "SGLT2i"),
       fill = c(
         rgb(0.9, 0.3, 0.3, 0.5),
         rgb(0.2, 0.4, 0.8, 0.5)
       ),
       border = "black",
       bty = "n",
       cex = 1.3)


dev.off()

## Censoring weights
png(file.path(output_dir, "cens_hist_mDR.png"),
    width = 800, height = 600)

par(
  yaxs = "i",       # axes start exactly at 0 (no gap)
  xaxs = "i",
  mar = c(5, 6, 4, 2),  # bottom, left, top, right margins
  cex.lab  = 1.7,   # axis label size
  cex.axis = 1.5    # tick label size
)

hist(CATE_results$mDR_CATE_allcovs$nuis_mods$cen_mod$g_pred,
     breaks = 30,
     main = "",
     xlab = "Censoring weights",
     ylab = "Frequency",
     col  = "grey80",
     border = "black",
     ylim = c(0, 500)  # 
)

dev.off()

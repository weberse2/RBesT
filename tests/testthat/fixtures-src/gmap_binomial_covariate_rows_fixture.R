data_covs <- data.frame(
  n = 10,
  r = 3,
  study = c(1, 2, 2),
  stratum = factor(c("A", "A", "B"))
)
data_covs$group <- paste(data_covs$study, data_covs$stratum, sep = "/")
data_covs$id <- as.integer(factor(data_covs$group))

fixture <- withr::with_options(
  list(RBesT.MC.save_warmup = FALSE),
  suppressMessages(suppressWarnings(
    gMAP(
      cbind(r, n - r) ~ 1 + stratum | study,
      family = binomial,
      data = data_covs,
      tau.dist = "Fixed",
      tau.prior = 0.25,
      beta.prior = 2,
      warmup = 100,
      iter = 200,
      chains = 1,
      thin = 1
    )
  ))
)

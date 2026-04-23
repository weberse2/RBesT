fixture <- suppressWarnings(
  suppressMessages(
    gMAP(
      cbind(r, n - r) ~ 1 | study,
      data = AS[-1, ],
      family = binomial,
      tau.dist = "HalfNormal",
      tau.prior = 0.5,
      iter = 100,
      warmup = 50,
      chains = 1,
      thin = 1
    )
  )
)

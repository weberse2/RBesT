data_extreme <- data.frame(
  n = c(5, 5, 5, 5),
  r = c(5, 5, 5, 5),
  study = c(1, 1, 2, 2)
)

fixture <- suppressWarnings(
  gMAP(
    cbind(r, n - r) ~ 1 | study,
    family = binomial,
    data = data_extreme,
    tau.dist = "HalfNormal",
    tau.prior = 2.0,
    beta.prior = 2,
    warmup = 100,
    iter = 200,
    chains = 1,
    thin = 1
  )
)

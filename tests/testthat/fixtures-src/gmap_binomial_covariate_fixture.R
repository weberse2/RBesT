trans_cov <- transform(
  transplant,
  country = cut(1:11, c(0, 5, 8, Inf), c("CH", "US", "DE"))
)

fixture <- withr::with_seed(
  34246,
  withr::with_options(
    list(RBesT.MC.save_warmup = FALSE),
    gMAP(
      cbind(r, n - r) ~ 1 + country | study,
      data = trans_cov,
      tau.dist = "HalfNormal",
      tau.prior = 1,
      beta.prior = rbind(c(0, 2), c(0, 1), c(0, 1)),
      family = binomial,
      # The fixture supports downstream behavior tests, not inference-quality
      # checks, so keep the local cache cheap to rebuild.
      warmup = 100,
      iter = 200,
      thin = 1,
      chains = 2
    )
  )
)

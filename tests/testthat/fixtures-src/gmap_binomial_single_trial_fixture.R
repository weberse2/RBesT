fixture <- withr::with_options(
  list(
    RBesT.MC.warmup = 250,
    RBesT.MC.iter = 500,
    RBesT.MC.chains = 2,
    RBesT.MC.save_warmup = FALSE
  ),
  suppressMessages(suppressWarnings(
    gMAP(
      cbind(r, n - r) ~ 1,
      data = colitis[1, ],
      family = binomial,
      tau.dist = "HalfNormal",
      tau.prior = c(0.5),
      beta.prior = cbind(0, 1)
    )
  ))
)

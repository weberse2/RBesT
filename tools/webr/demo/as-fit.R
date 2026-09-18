# End-to-end demonstration fit for the wasm/webR build of RBesT: a
# meta-analytic-predictive (MAP) analysis of the AS data set.
#
# Run it with tools/webr/demo/run-webr-demo.sh, which executes this exact file
# either inside webR (against the built VFS library image) or under native R,
# so the two can be compared. Nothing here is webR-specific -- that is the
# point: it is ordinary RBesT code, and the test is that it behaves the same in
# both engines.
#
# Unlike tools/webr/verify-rbest.R -- which is the CI assertion script and
# checks patch markers, library provenance and finiteness -- this one is meant
# to be read: it prints a full analysis, and the numbers it reports are the
# ones the runner compares across engines.

set.seed(34563)

say <- function(...) cat("\n== ", ..., " ==\n", sep = "")

engine <- if (identical(R.version$arch, "wasm32")) "webr" else "native"
say("engine: ", engine, " (", R.version.string, " on ", R.version$platform, ")")

library(RBesT)
cat("RBesT     ", format(packageVersion("RBesT")), "\n")
cat("rstan     ", format(packageVersion("rstan")), "\n")
cat("library   ", dirname(system.file(package = "RBesT")), "\n")

## ---------------------------------------------------------------------------
## The data: eight historical ankylosing-spondylitis trials, ASAS20
## responders out of patients randomised to the control arm.
## ---------------------------------------------------------------------------
say("AS: historical control data")
print(AS)

## ---------------------------------------------------------------------------
## 1. MAP analysis. This is the Stan half of the package -- a precompiled
##    model sampled by rstan, which under webR is the wasm rstan built by
##    tools/webr/docker/.
## ---------------------------------------------------------------------------
say("1. gMAP: random-effects meta-analysis of the historical controls")
elapsed <- system.time(
  map_mc <- gMAP(cbind(r, n - r) ~ 1 | study,
    data = AS,
    family = binomial,
    tau.dist = "HalfNormal",
    tau.prior = 0.5,
    beta.prior = 2,
    chains = 4,
    iter = 6000,
    warmup = 2000,
    thin = 4,
    cores = 1
  )
)
cat("sampling took", sprintf("%.1f s", elapsed[["elapsed"]]), "\n\n")
print(map_mc)

say("1b. convergence")
rhat_max <- map_mc$Rhat.max
cat("maximal Rhat:", format(rhat_max, digits = 4), "\n")
if (!is.finite(rhat_max) || rhat_max > 1.05) {
  stop("gMAP did not converge (maximal Rhat ", rhat_max, ")")
}

## ---------------------------------------------------------------------------
## 2. The non-Stan half: approximate the MAP predictive distribution -- draws
##    for a *new* study's control response rate -- by a beta mixture.
## ---------------------------------------------------------------------------
say("2. automixfit: parametric approximation of the MAP prior")
map <- automixfit(map_mc)
print(map)

say("3. effective sample size of the MAP prior")
ess_elir <- ess(map, method = "elir")
ess_morita <- ess(map, method = "morita")
cat("ESS (ELIR)  ", format(ess_elir, digits = 4), "\n")
cat("ESS (Morita)", format(ess_morita, digits = 4), "\n")

## ---------------------------------------------------------------------------
## 4. Robustification and use: add a weakly informative component, then update
##    with data from a new trial's control arm.
## ---------------------------------------------------------------------------
say("4. robustify (20% weight on a unit-information component)")
rmap <- robustify(map, weight = 0.2, mean = 0.5)
print(rmap)
cat(
  "ESS (ELIR) after robustification",
  format(ess(rmap, method = "elir"), digits = 4), "\n"
)

say("5. posterior after a new control arm with 14/50 responders")
post <- postmix(rmap, r = 14, n = 50)
print(post)
cat("P(response rate < 0.3) =", format(pmix(post, 0.3), digits = 4), "\n")

## ---------------------------------------------------------------------------
## The quantities the runner compares between webR and native R. Posterior
## summaries, not bit patterns: the two engines run the same sampler with the
## same seed but on different architectures, so they agree to Monte Carlo
## error, not exactly.
## ---------------------------------------------------------------------------
pred <- summary(map_mc)$theta.pred
map_summary <- summary(map)
post_summary <- summary(post)
results <- c(
  pred_mean = unname(pred[, "mean"]),
  pred_sd = unname(pred[, "sd"]),
  pred_q2.5 = unname(pred[, "q2.5"]),
  pred_q97.5 = unname(pred[, "q97.5"]),
  tau_mean = unname(summary(map_mc)$tau[, "mean"]),
  map_mean = unname(map_summary[["mean"]]),
  map_sd = unname(map_summary[["sd"]]),
  ess_elir = ess_elir,
  post_mean = unname(post_summary[["mean"]]),
  post_sd = unname(post_summary[["sd"]]),
  post_p_lt_0.3 = pmix(post, 0.3)
)

say("summary")
print(round(results, 5))

## Emitted on stdout in a form the runner can grep out of a captured log --
## webR runs in its own wasm filesystem and does not inherit the caller's
## environment, so a shared temporary file is not an option and stdout is the
## one channel both engines have in common.
cat("\n")
cat(
  sprintf("#RESULT\t%s\t%.10g\n", names(results), as.numeric(results)),
  sep = ""
)

cat("\n[demo] OK --", engine, "\n")

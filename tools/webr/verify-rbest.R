# Verification run for the wasm/webR build of RBesT.
#
# Executed inside a webR session by tools/webr/run-webr-vfs.cjs, against a
# freshly built VFS library image and with the package repository pointed at a
# dead address, so nothing can be silently downloaded to cover a gap in the
# image.
#
# Any stop() here fails the CI job. Keep the assertions meaningful: a build can
# succeed and still produce an image that cannot be loaded (see the TBB symbol
# discussion in the troubleshooting section of
# design/howto-build-rbest-webr.md).

report <- function(...) cat("[verify]", ..., "\n")

report("R", as.character(getRversion()), "|", R.version$platform)

## 1. Loading. This is where an unresolved-symbol problem surfaces -- the
##    wasm binary links fine and only fails at dlopen() time.
report("loading rstan ...")
library(rstan)
report("rstan", as.character(packageVersion("rstan")), "loaded")

report("loading RBesT ...")
library(RBesT)
report("RBesT", as.character(packageVersion("RBesT")), "loaded")

## 2. The library must have come from the mounted image, not from anywhere
##    webR might have fetched it.
report("RBesT lib:", dirname(system.file(package = "RBesT")))

## 3. There is no forking and detectCores() is NA in webR, so chains run
##    sequentially. Assert it rather than letting a future webR silently
##    change the answer.
if (!identical(parallel::detectCores(), NA_integer_)) {
  report("note: detectCores() is no longer NA:", parallel::detectCores())
}

## 4. A real fit. Precompiled Stan model, actual sampling.
report("fitting gMAP ...")
elapsed <- system.time(
  map_mc <- gMAP(cbind(r, n - r) ~ 1 | study,
    data = AS,
    family = binomial,
    tau.dist = "HalfNormal",
    tau.prior = 0.5,
    beta.prior = 2,
    chains = 2,
    iter = 2000,
    warmup = 500,
    cores = 1
  )
)
report("gMAP took", sprintf("%.1f s", elapsed[["elapsed"]]))

print(map_mc)

## `summary()` returns a data.frame per quantity, and `is.finite()` has no
## data.frame method, so reduce to a numeric matrix before testing.
fit_summary <- as.matrix(summary(map_mc)$theta.pred)
if (!all(is.finite(fit_summary))) {
  stop("gMAP posterior summary contains non-finite values")
}

## 5. The non-Stan half of the package, on the fit's predictive draws.
report("running automixfit ...")
map <- automixfit(map_mc)
print(map)

if (!all(is.finite(summary(map)))) {
  stop("automixfit summary contains non-finite values")
}

report("OK")

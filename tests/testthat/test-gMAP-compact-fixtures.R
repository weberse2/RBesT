test_that("gMAP can return a draw-free chains=0 skeleton", {
  map <- withr::with_options(
    list(RBesT.MC.save_warmup = FALSE),
    suppressMessages(gMAP(
      cbind(r, n - r) ~ 1 | study,
      family = binomial,
      data = AS,
      tau.dist = "Fixed",
      tau.prior = 0.5,
      beta.prior = 2,
      warmup = 100,
      iter = 200,
      chains = 0,
      thin = 1
    ))
  )

  expect_s3_class(map, "gMAP")
  expect_identical(map$backend, "none")
  expect_s3_class(map$draws, "draws_array")
  expect_s3_class(map$draws_diag, "draws_array")
  expect_identical(posterior::ndraws(map$draws), 0L)
  expect_identical(posterior::ndraws(map$draws_diag), 0L)
  expect_identical(
    posterior::variables(map$draws),
    c(
      "theta[1]",
      "theta[2]",
      "theta[3]",
      "theta[4]",
      "theta[5]",
      "theta[6]",
      "theta[7]",
      "theta[8]",
      "beta[1]",
      "tau[1]",
      "theta_pred",
      "theta_resp_pred",
      "lp__"
    )
  )
  expect_identical(map$metadata_mcmc$chains, 0L)
  expect_identical(map$metadata_mcmc$n_save_per_chain, 0L)
  expect_true(all(is.na(map$beta)))
  expect_true(all(is.na(map$tau)))
  expect_equal(map$Rhat.max, NA_real_)
  expect_equal(nrow(map$X), nrow(AS))
  expect_equal(map$family$family, "binomial")
  expect_warning(
    expect_identical(nrow(posterior::as_draws_matrix(map)), 0L),
    "gMAP object \"map\" does not contain any samples"
  )
  expect_warning(
    capture.output(print(map)),
    "gMAP object \"map\" does not contain any samples"
  )
  expect_warning(
    summary(map),
    "gMAP object \"map\" does not contain any samples"
  )
  expect_warning(
    coef(map),
    "gMAP object \"map\" does not contain any samples"
  )
  expect_warning(
    fitted(map),
    "gMAP object \"map\" does not contain any samples"
  )
  withr::local_options(lifecycle_verbosity = "quiet")
  expect_warning(
    as.matrix(map),
    "gMAP object \"map\" does not contain any samples"
  )
  expect_warning(
    pred <- predict(map),
    "gMAP object \"map\" does not contain any samples"
  )
  expect_s3_class(pred, "gMAPpred")
  expect_identical(nrow(as.matrix(pred)), 0L)
  expect_true(all(is.na(summary(pred))))
})

test_that("compact gMAP rejects intercept-mismatched skeletons", {
  intercept_skeleton <- suppressMessages(gMAP(
    cbind(r, n - r) ~ 1 | study,
    family = binomial,
    data = AS,
    tau.dist = "Fixed",
    tau.prior = 0.5,
    beta.prior = 2,
    warmup = 100,
    iter = 200,
    chains = 0,
    thin = 1
  ))

  spec <- list(
    name = "intercept_mismatch",
    seed = 1L,
    nc = 1L,
    has_intercept = intercept_skeleton$has_intercept,
    tau_fixed = TRUE,
    tau_values = c(`tau[1]` = 0.5),
    builder = function() {
      suppressWarnings(suppressMessages(gMAP(
        cbind(r, n - r) ~ 0 + study | study,
        family = binomial,
        data = AS,
        tau.dist = "Fixed",
        tau.prior = 0.5,
        beta.prior = 2,
        warmup = 100,
        iter = 200,
        chains = 0,
        thin = 1
      )))
    }
  )

  expect_error(
    inject_compact_gmap_draws(spec),
    "intercept setting does not match"
  )
})

test_that("compact gMAP rehydration requires an explicit skeleton", {
  expect_error(
    rehydrate_compact_gmap_draws(list()),
    "argument \"skeleton\" is missing"
  )
})

test_that("compact gMAP rejects non-null tau values for non-fixed tau", {
  spec <- list(
    builder = function() {
      suppressMessages(gMAP(
        cbind(r, n - r) ~ 1 | study,
        family = binomial,
        data = AS,
        tau.dist = "HalfNormal",
        tau.prior = 1,
        beta.prior = 2,
        chains = 0
      ))
    },
    has_intercept = TRUE,
    tau_fixed = FALSE,
    tau_values = numeric(0)
  )

  expect_error(
    inject_compact_gmap_draws(spec),
    "must use `tau_values = NULL`"
  )
})

test_that("compact gMAP fixture rehydrates fixed-tau draws", {
  map <- suppressMessages(
    load_compact_gmap_fixture("gmap_binomial_fixed_tau")
  )

  expect_s3_class(map, "gMAP")
  expect_identical(map$backend, "compact-fixture")
  expect_identical(attr(map, "compact_fixture")$name, "gmap_binomial_fixed_tau")
  expect_identical(
    posterior::variables(as_draws(map)),
    c(
      "theta[1]",
      "theta[2]",
      "theta[3]",
      "theta[4]",
      "theta[5]",
      "theta[6]",
      "theta[7]",
      "theta[8]",
      "beta[1]",
      "tau[1]",
      "theta_pred",
      "theta_resp_pred",
      "lp__"
    )
  )
  expect_identical(dim(as_draws_array(map)), c(100L, 2L, 13L))
  expect_identical(nsamples(map), 200L)
  expect_s3_class(posterior::as_draws_matrix(map), "draws_matrix")
  expect_s3_class(posterior::as_draws_df(map), "draws_df")
  expect_warning(
    as.matrix(map),
    class = "lifecycle_warning_deprecated"
  )
  expect_identical(
    posterior::variables(map$draws_diag),
    c(
      "accept_stat__",
      "stepsize__",
      "treedepth__",
      "n_leapfrog__",
      "divergent__",
      "energy__"
    )
  )
  expect_equal(
    sum(as.array(posterior::subset_draws(
      map$draws_diag,
      variable = "divergent__"
    ))),
    0
  )
})

test_that("compact gMAP stores fixed tau outside the MVN", {
  map <- suppressMessages(
    load_compact_gmap_fixture("gmap_binomial_fixed_tau")
  )
  compact_metadata <- attr(map, "compact_fixture")

  expect_true(compact_metadata$tau_fixed)
  expect_identical(compact_metadata$tau_values, c(`tau[1]` = 0.5))
  expect_false(any(startsWith(compact_metadata$variables_model, "tau[")))
  tau_draws <- posterior::as_draws_matrix(map, variable = "tau")
  expect_equal(unique(as.numeric(tau_draws[, "tau[1]"])), 0.5)
})

test_that("compact gMAP fixture supports downstream summaries", {
  map <- suppressMessages(
    load_compact_gmap_fixture("gmap_binomial_fixed_tau")
  )

  expect_no_error(summary(map))
  expect_no_error(coef(map))
  expect_no_error(fitted(map))
  expect_no_error(predict(map))
  expect_no_error(mixfit(map, Nc = 1))
})

test_that("compact gMAP supports no-intercept cell-means models", {
  testthat::skip_on_cran()

  sampled <- withr::with_seed(
    81723,
    suppressWarnings(
      suppressMessages(gMAP(
        cbind(r, n - r) ~ 0 + study | study,
        family = binomial,
        data = AS,
        tau.dist = "Fixed",
        tau.prior = 0.5,
        beta.prior = 2,
        warmup = 50,
        iter = 100,
        chains = 1,
        thin = 1
      ))
    )
  )
  expect_false(sampled$has_intercept)
  expect_false("theta_resp_pred" %in% posterior::variables(as_draws(sampled)))
  expect_false("theta_pred" %in% posterior::variables(as_draws(sampled)))

  spec <- create_compact_gmap_draw_spec(sampled, seed = 81724L)
  spec$name <- "gmap_binomial_no_intercept"
  spec$builder <- function() {
    suppressWarnings(
      suppressMessages(gMAP(
        cbind(r, n - r) ~ 0 + study | study,
        family = binomial,
        data = AS,
        tau.dist = "Fixed",
        tau.prior = 0.5,
        beta.prior = 2,
        warmup = 50,
        iter = 100,
        chains = 0,
        thin = 1
      ))
    )
  }

  compact <- suppressWarnings(inject_compact_gmap_draws(spec))
  expect_false(compact$has_intercept)
  expect_false(attr(compact, "compact_fixture")$has_intercept)
  expect_false("theta_resp_pred" %in% posterior::variables(as_draws(compact)))
  expect_false("theta_pred" %in% posterior::variables(as_draws(compact)))
  expect_identical(
    dim(posterior::as_draws_array(compact)),
    c(50L, 1L, length(spec$variables))
  )
  expect_no_error(summary(compact))
  expect_no_error(coef(compact))
  expect_no_error(fitted(compact))
})

test_that("compact gMAP rehydrates stratified fixed tau constants", {
  testthat::skip_on_cran()

  dat <- AS
  dat$stratum <- rep(c("adult", "pediatric"), length.out = nrow(dat))
  sampled <- withr::with_seed(
    56192,
    suppressWarnings(
      suppressMessages(gMAP(
        cbind(r, n - r) ~ 1 | study,
        family = binomial,
        data = dat,
        tau.strata = stratum,
        tau.dist = "Fixed",
        tau.prior = c(0.25, 0.5),
        beta.prior = 2,
        warmup = 50,
        iter = 100,
        chains = 1,
        thin = 1
      ))
    )
  )

  spec <- create_compact_gmap_draw_spec(sampled, seed = 56193L)
  spec$name <- "gmap_binomial_stratified_fixed_tau"
  spec$builder <- function() {
    suppressWarnings(
      suppressMessages(gMAP(
        cbind(r, n - r) ~ 1 | study,
        family = binomial,
        data = dat,
        tau.strata = stratum,
        tau.dist = "Fixed",
        tau.prior = c(0.25, 0.5),
        beta.prior = 2,
        warmup = 50,
        iter = 100,
        chains = 0,
        thin = 1
      ))
    )
  }

  compact <- suppressWarnings(inject_compact_gmap_draws(spec))
  expect_true(spec$tau_fixed)
  expect_identical(spec$tau_values, c(`tau[1]` = 0.25, `tau[2]` = 0.5))
  expect_false(any(startsWith(spec$variables_model, "tau[")))

  tau_draws <- posterior::as_draws_matrix(compact, variable = "tau")
  expect_equal(unique(as.numeric(tau_draws[, "tau[1]"])), 0.25)
  expect_equal(unique(as.numeric(tau_draws[, "tau[2]"])), 0.5)
})

test_that("compact gMAP fixture stays close to the fixed-tau fixture", {
  real <- load_gmap_fixture("gmap_binomial_fixed_tau")
  compact <- suppressMessages(
    load_compact_gmap_fixture("gmap_binomial_fixed_tau")
  )

  variables <- c("beta[1]", "tau[1]", "theta_resp_pred")
  real_summary <- posterior::summarise_draws(
    posterior::subset_draws(as_draws(real), variable = variables),
    mean,
    sd,
    q5 = function(x) stats::quantile(x, 0.05),
    q95 = function(x) stats::quantile(x, 0.95)
  )
  compact_summary <- posterior::summarise_draws(
    posterior::subset_draws(as_draws(compact), variable = variables),
    mean,
    sd,
    q5 = function(x) stats::quantile(x, 0.05),
    q95 = function(x) stats::quantile(x, 0.95)
  )

  expect_equal(compact_summary$variable, real_summary$variable)
  expect_equal(compact_summary$mean, real_summary$mean, tolerance = 0.05)
  expect_equal(compact_summary$sd, real_summary$sd, tolerance = 0.05)
  expect_equal(compact_summary[["5%"]], real_summary[["5%"]], tolerance = 0.10)
  expect_equal(
    compact_summary[["95%"]],
    real_summary[["95%"]],
    tolerance = 0.10
  )
})

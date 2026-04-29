args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 2) {
  stop(
    paste(
      "Usage: R --file=tools/report-compact-gmap-fixtures.R --args",
      "[recipe-dir | recipe.R output.report]"
    ),
    call. = FALSE
  )
}

recipe_input <- if (length(args) >= 1) {
  args[[1]]
} else {
  file.path("tests", "testthat", "fixtures-compact-src")
}
report_path <- if (length(args) == 2) args[[2]] else NULL

required_packages <- c(
  "checkmate",
  "devtools",
  "posterior",
  "testthat",
  "withr"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    "Missing packages required to report compact gMAP fixture quality: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(posterior)
  library(testthat)
  library(withr)
})

devtools::load_all(".", quiet = TRUE)
source("tests/testthat/helper-compressed-fixtures.R")
source("tools/compact-gmap-fixture-utils.R")

fixture_name_from_recipe <- function(path) {
  sub("_fixture[.]R$", "", basename(path))
}

summarise_theta_pred <- function(x) {
  variables <- posterior::variables(posterior::as_draws_array(x))
  if (!"theta_pred" %in% variables) {
    return(NULL)
  }
  posterior::summarise_draws(
    posterior::as_draws_array(x, variable = "theta_pred"),
    mean,
    sd,
    q10 = function(z) unname(stats::quantile(z, 0.10)),
    q80 = function(z) unname(stats::quantile(z, 0.80))
  )
}

quality_deltas <- function(sampled, compact) {
  sampled_summary <- summarise_theta_pred(sampled)
  compact_summary <- summarise_theta_pred(compact)
  if (is.null(sampled_summary) || is.null(compact_summary)) {
    return(NULL)
  }

  out <- merge(
    sampled_summary[, c("variable", "mean", "sd", "q10", "q80")],
    compact_summary[, c("variable", "mean", "sd", "q10", "q80")],
    by = "variable",
    suffixes = c("_sampled", "_compact")
  )
  out$mean_delta <- out$mean_compact - out$mean_sampled
  out$sd_delta <- out$sd_compact - out$sd_sampled
  out$q10_delta <- out$q10_compact - out$q10_sampled
  out$q80_delta <- out$q80_compact - out$q80_sampled
  out$mean_ok <- abs(out$mean_delta) <= 0.05
  out$sd_ok <- abs(out$sd_delta) <= 0.05
  out$q10_ok <- abs(out$q10_delta) <= 0.10
  out$q80_ok <- abs(out$q80_delta) <= 0.10
  out$within_tolerance <- out$mean_ok & out$sd_ok & out$q10_ok & out$q80_ok
  out
}

format_report <- function(report) {
  c(
    "Compact gMAP fixture approximation report",
    "Tolerance for delta: mean <= 0.05, sd <= 0.05, q10 <= 0.10, q80 <= 0.10",
    "",
    capture.output(print(report, row.names = FALSE))
  )
}

report_one <- function(recipe) {
  name <- fixture_name_from_recipe(recipe)
  env <- new.env(parent = globalenv())
  sys.source(recipe, envir = env)

  if (!exists("fixture", envir = env, inherits = FALSE)) {
    stop(
      "Compact fixture recipe must create `fixture`: ",
      recipe,
      call. = FALSE
    )
  }

  sampled <- get("fixture", envir = env, inherits = FALSE)
  compact <- suppressMessages(load_compact_gmap_fixture(name))
  deltas <- quality_deltas(sampled, compact)
  if (is.null(deltas)) {
    return(data.frame(
      fixture = name,
      variable = "theta_pred",
      mean_delta = NA_real_,
      sd_delta = NA_real_,
      q10_delta = NA_real_,
      q80_delta = NA_real_,
      within_tolerance = NA,
      note = "theta_pred unavailable"
    ))
  }

  data.frame(
    fixture = name,
    variable = deltas$variable,
    mean_delta = deltas$mean_delta,
    sd_delta = deltas$sd_delta,
    q10_delta = deltas$q10_delta,
    q80_delta = deltas$q80_delta,
    within_tolerance = deltas$within_tolerance,
    note = ifelse(deltas$within_tolerance, "", "outside tolerance")
  )
}

if (dir.exists(recipe_input)) {
  recipes <- list.files(
    recipe_input,
    pattern = "_fixture[.]R$",
    full.names = TRUE
  )
} else {
  recipes <- normalizePath(recipe_input, mustWork = TRUE)
}
if (!length(recipes)) {
  stop("No compact fixture recipes found in: ", recipe_input, call. = FALSE)
}

message("Compact gMAP fixture approximation report")
if (dir.exists(recipe_input)) {
  message("Recipe directory: ", normalizePath(recipe_input, winslash = "/"))
} else {
  message("Recipe: ", normalizePath(recipe_input, winslash = "/"))
}
message("Tolerance: mean <= 0.05, sd <= 0.05, q10/q80 <= 0.10")

report <- do.call(rbind, lapply(recipes, report_one))
report_lines <- format_report(report)
cat(paste(report_lines, collapse = "\n"), "\n", sep = "")

if (!is.null(report_path)) {
  dir.create(dirname(report_path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(
    pattern = basename(report_path),
    tmpdir = dirname(report_path)
  )
  on.exit(unlink(tmp), add = TRUE)
  writeLines(report_lines, tmp, useBytes = TRUE)
  if (!file.rename(tmp, report_path)) {
    stop(
      "Could not move temporary report into place: ",
      report_path,
      call. = FALSE
    )
  }
  message("Wrote compact fixture approximation report: ", report_path)
}

outside <- !is.na(report$within_tolerance) & !report$within_tolerance
if (any(outside)) {
  message(
    "Compact fixture approximation warnings: ",
    sum(outside),
    " fixture comparison(s) outside tolerance."
  )
}

invisible(report)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2 || length(args) > 3) {
  stop(
    paste(
      "Usage: R --file=tools/build-compact-gmap-fixture.R --args",
      "<recipe.R> <fixtures-compact-dir> [fixture-name]"
    ),
    call. = FALSE
  )
}

recipe <- normalizePath(args[[1]], mustWork = TRUE)
fixture_dir <- args[[2]]
fixture_name <- if (length(args) >= 3) {
  args[[3]]
} else {
  sub("_fixture[.]R$", "", basename(recipe))
}
project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
recipe_path <- normalizePath(recipe, winslash = "/", mustWork = TRUE)
recipe_config_path <- if (startsWith(recipe_path, paste0(project_root, "/"))) {
  substring(recipe_path, nchar(project_root) + 2L)
} else {
  recipe_path
}

required_packages <- c(
  "checkmate",
  "devtools",
  "posterior",
  "testthat",
  "withr"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    "Missing packages required to build compact gMAP fixtures: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(checkmate)
  library(posterior)
  library(testthat)
  library(withr)
})

devtools::load_all(".", quiet = TRUE)
source("tests/testthat/helper-compressed-fixtures.R")
source("tools/compact-gmap-fixture-utils.R")

env <- new.env(parent = globalenv())
sys.source(recipe, envir = env)

if (!exists("fixture", envir = env, inherits = FALSE)) {
  stop("Compact fixture recipe must create an object named `fixture`.", call. = FALSE)
}
if (!exists("fixture_call", envir = env, inherits = FALSE)) {
  stop(
    "Compact fixture recipe must create a gMAP call named `fixture_call`.",
    call. = FALSE
  )
}

fixture <- get("fixture", envir = env, inherits = FALSE)
fixture_call <- get("fixture_call", envir = env, inherits = FALSE)
if (!inherits(fixture, "gMAP")) {
  stop("Compact fixture recipe did not create a gMAP object.", call. = FALSE)
}
if (!is.call(fixture_call) || !identical(fixture_call[[1]], as.name("gMAP"))) {
  stop("`fixture_call` must be a direct gMAP(...) call.", call. = FALSE)
}

recipe_value <- function(name, default) {
  env_name <- paste0("COMPACT_FIXTURE_", toupper(sub("^compact_", "", name)))
  from_env <- Sys.getenv(env_name, unset = NA_character_)
  if (!is.na(from_env) && nzchar(from_env)) {
    return(from_env)
  }
  if (exists(name, envir = env, inherits = FALSE)) {
    return(get(name, envir = env, inherits = FALSE))
  }
  default
}

compact_seed <- as.integer(recipe_value("compact_seed", 873461L))
compact_nc <- as.integer(recipe_value("compact_nc", 1L))
compact_digits <- as.integer(recipe_value("compact_digits", 4L))
compact_data_objects <- recipe_value("compact_data_objects", character())
if (is.na(compact_seed) || compact_seed < 1L) {
  stop("compact_seed must be a positive integer.", call. = FALSE)
}
if (is.na(compact_nc) || compact_nc < 1L || compact_nc > 3L) {
  stop("compact_nc must be an integer between 1 and 3.", call. = FALSE)
}
if (is.na(compact_digits) || compact_digits < 1L) {
  stop("compact_digits must be a positive integer.", call. = FALSE)
}
checkmate::assert_character(
  compact_data_objects,
  any.missing = FALSE,
  unique = TRUE
)
missing_data_objects <- compact_data_objects[
  !vapply(compact_data_objects, exists, logical(1), envir = env, inherits = FALSE)
]
if (length(missing_data_objects)) {
  stop(
    "compact_data_objects not found in recipe environment: ",
    paste(missing_data_objects, collapse = ", "),
    call. = FALSE
  )
}

skeleton_call <- fixture_call
skeleton_call$chains <- 0L

compact_builder <- function() {
  withr::with_options(
    list(RBesT.MC.save_warmup = FALSE),
    suppressWarnings(suppressMessages(eval(skeleton_call, envir = env)))
  )
}

compact_spec <- create_compact_gmap_draw_spec(
  fixture,
  seed = compact_seed,
  nc = compact_nc
)
compact_spec$name <- fixture_name
compact_spec$builder <- compact_builder
compact_spec$generation_config <- list(
  recipe = recipe_config_path,
  nc = compact_nc,
  digits = compact_digits,
  seed = compact_seed,
  data_objects = compact_data_objects
)

quality_summary <- function(x) {
  draws <- posterior::as_draws_array(x, variable = "theta_pred")
  posterior::summarise_draws(
    draws,
    mean,
    sd,
    q10 = function(z) unname(stats::quantile(z, 0.10)),
    q80 = function(z) unname(stats::quantile(z, 0.80))
  )
}

check_quality <- function(sampled, compact) {
  if (!"theta_pred" %in% posterior::variables(posterior::as_draws_array(sampled))) {
    message(
      "Compact fixture approximation quality skipped for ",
      fixture_name,
      ": sampled fixture has no theta_pred."
    )
    return(invisible(NULL))
  }

  sampled_summary <- quality_summary(sampled)
  compact_summary <- quality_summary(compact)
  deltas <- merge(
    sampled_summary[, c("variable", "mean", "sd", "q10", "q80")],
    compact_summary[, c("variable", "mean", "sd", "q10", "q80")],
    by = "variable",
    suffixes = c("_sampled", "_compact")
  )
  deltas$mean_delta <- deltas$mean_compact - deltas$mean_sampled
  deltas$sd_delta <- deltas$sd_compact - deltas$sd_sampled
  deltas$q10_delta <- deltas$q10_compact - deltas$q10_sampled
  deltas$q80_delta <- deltas$q80_compact - deltas$q80_sampled

  outside <- abs(deltas$mean_delta) > 0.05 |
    abs(deltas$sd_delta) > 0.05 |
    abs(deltas$q10_delta) > 0.10 |
    abs(deltas$q80_delta) > 0.10

  if (any(outside)) {
    message(
      "Compact fixture approximation warning for ",
      fixture_name,
      ": theta_pred summary deltas exceed tolerance."
    )
    print(deltas[, c(
      "variable",
      "mean_delta",
      "sd_delta",
      "q10_delta",
      "q80_delta"
    )])
  } else {
    message("Compact fixture approximation within tolerance for ", fixture_name, ".")
  }

  invisible(deltas)
}

generated_compact <- suppressWarnings(inject_compact_gmap_draws(compact_spec))
check_quality(fixture, generated_compact)

dir.create(fixture_dir, recursive = TRUE, showWarnings = FALSE)
fixture_dir <- normalizePath(fixture_dir, winslash = "/", mustWork = TRUE)

model_json <- file.path(fixture_dir, paste0(fixture_name, "_mvn_model.json"))
theta_json <- file.path(fixture_dir, paste0(fixture_name, "_mvn_theta.json"))
spec_path <- file.path(fixture_dir, paste0(fixture_name, "_spec.R"))

write_mix_json(compact_spec$mvn_model, model_json, pretty = TRUE, digits = compact_digits)
write_mix_json(compact_spec$mvn_theta, theta_json, pretty = TRUE, digits = compact_digits)

compact_spec$mvn_model <- NULL
compact_spec$mvn_theta <- NULL
compact_spec$builder <- NULL

json_model_basename <- basename(model_json)
json_theta_basename <- basename(theta_json)
object_name <- paste0(fixture_name, "_compact_spec")
data_object_lines <- unlist(lapply(compact_data_objects, function(obj_name) {
  c(
    paste0(obj_name, " <- "),
    paste(capture.output(dput(get(obj_name, envir = env, inherits = FALSE))), collapse = "\n"),
    ""
  )
}), use.names = FALSE)

spec_lines <- c(
  data_object_lines,
  paste0(object_name, " <- "),
  paste0(
    "structure(",
    paste(capture.output(dput(compact_spec)), collapse = "\n"),
    ", class = \"compact_gmap_fixture_spec\")"
  ),
  "",
  paste0(object_name, "$mvn_model <- read_mix_json("),
  paste0(
    "  testthat::test_path(\"fixtures-compact\", \"",
    json_model_basename,
    "\"),"
  ),
  "  rescale = TRUE",
  ")",
  paste0(object_name, "$mvn_theta <- read_mix_json("),
  paste0(
    "  testthat::test_path(\"fixtures-compact\", \"",
    json_theta_basename,
    "\"),"
  ),
  "  rescale = TRUE",
  ")",
  paste0(object_name, "$builder <- function() {"),
  "  withr::with_options(",
  "    list(RBesT.MC.save_warmup = FALSE),",
  "    suppressWarnings(suppressMessages(eval(",
  paste0("      ", paste(deparse(skeleton_call), collapse = "\n      ")),
  "    )))",
  "  )",
  "}",
  ""
)

tmp <- tempfile(pattern = basename(spec_path), tmpdir = dirname(spec_path))
on.exit(unlink(tmp), add = TRUE)
writeLines(spec_lines, tmp, useBytes = TRUE)
if (!file.rename(tmp, spec_path)) {
  stop("Could not move temporary compact spec into place: ", spec_path, call. = FALSE)
}

message("Wrote compact gMAP fixture spec: ", spec_path)
message("Wrote compact gMAP fixture MVN JSON: ", model_json)
message("Wrote compact gMAP fixture theta JSON: ", theta_json)

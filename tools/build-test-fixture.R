args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop(
    "Usage: R --file=tools/build-test-fixture.R --args <recipe.R> <fixture.rds>",
    call. = FALSE
  )
}

recipe <- normalizePath(args[[1]], mustWork = TRUE)
fixture_path <- args[[2]]

required_packages <- c(
  "assertthat",
  "checkmate",
  "devtools",
  "Formula",
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
    "Missing packages required to build test fixtures: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(assertthat)
  library(checkmate)
  library(Formula)
  library(posterior)
  library(testthat)
  library(withr)
})

devtools::load_all(".", quiet = TRUE)

env <- new.env(parent = globalenv())
sys.source(recipe, envir = env)

if (!exists("fixture", envir = env, inherits = FALSE)) {
  stop("Fixture recipe must create an object named `fixture`.", call. = FALSE)
}

fixture <- get("fixture", envir = env, inherits = FALSE)

dir.create(dirname(fixture_path), recursive = TRUE, showWarnings = FALSE)
tmp <- tempfile(pattern = basename(fixture_path), tmpdir = dirname(fixture_path))
on.exit(unlink(tmp), add = TRUE)

saveRDS(fixture, tmp)
if (!file.rename(tmp, fixture_path)) {
  stop("Could not move temporary fixture into place: ", fixture_path, call. = FALSE)
}

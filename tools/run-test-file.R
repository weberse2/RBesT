args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop(
    "Usage: R --file=tools/run-test-file.R --args <test-file.R>",
    call. = FALSE
  )
}

test_file <- args[[1]]

required_packages <- c("devtools", "testthat")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    "Missing packages required to run test files: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

devtools::load_all()

reporter <- testthat::MultiReporter$new(
  reporters = list(
    testthat::CompactProgressReporter$new(),
    testthat::FailReporter$new()
  )
)
testthat::test_file(test_file, reporter = reporter)

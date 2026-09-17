# Compare two runs of tools/webr/demo/as-fit.R -- typically one in webR and one
# in native R -- by the `#RESULT` lines each of them prints.
#
# Usage: Rscript compare-runs.R <log1> <log2>
#
# The two runs use the same seed but different architectures, so the samplers
# do not produce identical draws; posterior summaries agree to Monte Carlo
# error, not exactly. The tolerances are set well above the observed spread and
# well below anything that would indicate a broken build. Posterior summaries
# are tight (observed: under 1.5% between engines); the ESS of the fitted
# mixture is looser, because it inherits both the Monte Carlo error and the
# variability of the EM approximation on top of it (observed: 7%).

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("usage: compare-runs.R <log1> <log2>")

tol_default <- as.numeric(Sys.getenv("RBEST_DEMO_TOL", "0.05"))
tol_by_quantity <- c(ess_elir = 0.2)

read_results <- function(path) {
  lines <- readLines(path, warn = FALSE)
  if (!any(grepl("[demo] OK", lines, fixed = TRUE))) {
    stop(path, ": the run did not reach the end of the script")
  }
  hits <- grep("^#RESULT\t", lines, value = TRUE)
  if (!length(hits)) stop(path, ": no #RESULT lines found")
  parts <- strsplit(hits, "\t", fixed = TRUE)
  stats::setNames(
    as.numeric(vapply(parts, `[`, "", 3)),
    vapply(parts, `[`, "", 2)
  )
}

read_version <- function(path, pkg) {
  hit <- grep(paste0("^", pkg, " +[0-9]"), readLines(path, warn = FALSE),
    value = TRUE
  )
  if (!length(hit)) {
    return(NA_character_)
  }
  trimws(sub(paste0("^", pkg, " +"), "", hit[1]))
}

for (pkg in c("RBesT", "rstan")) {
  v <- vapply(args, read_version, "", pkg = pkg, USE.NAMES = FALSE)
  if (!anyNA(v) && v[1] != v[2]) {
    cat("warning: the two runs used different", pkg, "versions:",
      paste(v, collapse = " vs "),
      "\n  differences below may be real changes, not Monte Carlo error\n\n"
    )
  }
}

a <- read_results(args[1])
b <- read_results(args[2])

common <- intersect(names(a), names(b))
if (!length(common)) stop("the two runs have no quantities in common")
missing <- setdiff(union(names(a), names(b)), common)
if (length(missing)) {
  cat("note: reported by only one run:", paste(missing, collapse = ", "), "\n")
}

a <- a[common]
b <- b[common]
scale <- pmax(abs(a), abs(b))
rel <- ifelse(scale > 0, abs(a - b) / scale, 0)
tol <- ifelse(common %in% names(tol_by_quantity),
  tol_by_quantity[common], tol_default
)

cmp <- data.frame(
  quantity = common,
  run1 = signif(a, 6),
  run2 = signif(b, 6),
  rel.diff = signif(rel, 3),
  tolerance = tol,
  row.names = NULL
)
cat("run1:", args[1], "\nrun2:", args[2], "\n\n")
print(cmp, row.names = FALSE)

bad <- cmp[rel > tol, , drop = FALSE]
cat("\nlargest relative difference:", signif(max(rel), 3),
  "on", common[which.max(rel)], "\n"
)
if (nrow(bad)) {
  print(bad, row.names = FALSE)
  stop(
    "the two runs disagree beyond tolerance on ",
    nrow(bad), " quantity/quantities"
  )
}
cat("\n[compare] OK -- the two engines agree to within Monte Carlo error\n")

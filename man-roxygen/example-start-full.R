# Full-sampling variant of example-start.R.
#
# The shipped man-roxygen/example-start.R sets slim sampling so that examples
# run fast under CRAN checks. That slim sampling also degrades the plots and
# output rendered on the pkgdown reference website. The Makefile pkgdown target
# temporarily swaps this file in for example-start.R and regenerates the Rd so
# the website examples run with the package default (full) sampling.
#
# Only the `#'` lines below become part of the rendered @examples. We still
# capture the current options into .user_mc_options (a no-op override) so that
# the paired example-stop.R can restore options unchanged.
#' @examples
#' .user_mc_options <- options()
#'

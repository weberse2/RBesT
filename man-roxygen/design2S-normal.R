#' @describeIn <%= fun %> Applies for the normal model with known
#' standard deviation \eqn{\sigma} and normal mixture priors for the
#' means. As a consequence from the assumption of a known standard
#' deviation, the calculation discards sampling uncertainty of the
#' second moment. The function has two extra arguments (with
#' defaults): \code{eps} (\eqn{10^{-6}}) and \code{Ngrid} (10). The
#' decision boundary is searched in the region of probability mass
#' \code{1-eps}, respectively for \eqn{y_1} and \eqn{y_2}. The
#' continuous decision function is evaluated at a discrete grid, which
#' is determined by a spacing with \eqn{\delta_2 =
#' \sigma_2/\sqrt{N_{grid}}}. Once the decision boundary is evaluated
#' at the discrete steps, a spline is used to inter-polate the
#' decision boundary at intermediate points.
#' @param sigma1 The fixed reference scale of sample 1. If left
#' unspecified, the default reference scale of the prior 1 is assumed.
#' @param sigma2 The fixed reference scale of sample 2. If left
#' unspecified, the default reference scale of the prior 2 is assumed.
#' @param family Optional \code{\link{family}} object specifying a
#' GLM family and link function (e.g.\ \code{binomial()},
#' \code{MASS::negative.binomial(theta)}). When provided, the
#' sampling standard deviation of each sample varies with the
#' respective parameter value via the family's variance function and
#' link. For the Gaussian family \code{sigma1}/\code{sigma2} act as
#' the dispersion parameters and must be supplied; for all other
#' families they must \emph{not} be given (they are determined by the
#' family). Default is \code{NULL} (constant \code{sigma1} and
#' \code{sigma2}).
#' @param offset1 Numeric scalar added to the linear predictor of
#' sample 1 before evaluating the family's variance function.
#' Relevant for Poisson/negative-binomial models with log link where
#' \code{offset1 = log(exposure)}. Default is \code{0}.
#' @param offset2 Numeric scalar added to the linear predictor of
#' sample 2; see \code{offset1}. Defaults to \code{offset1}.

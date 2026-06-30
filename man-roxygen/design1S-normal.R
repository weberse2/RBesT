#' @describeIn <%= fun %> Applies for the normal model with known
#' standard deviation \eqn{\sigma} and a normal mixture prior for the
#' mean. As a consequence from the assumption of a known standard
#' deviation, the calculation discards sampling uncertainty of the
#' second moment. The function \code{<%= fun %>} has an extra
#' argument \code{eps} (defaults to \eqn{10^{-6}}). The critical value
#' \eqn{y_c} is searched in the region of probability mass
#' \code{1-eps} for \eqn{y}.
#'
#' When \code{family} is specified, the sampling standard deviation
#' becomes a function of the parameter value \eqn{\theta} via
#' \deqn{\sigma(\theta) = \sqrt{\phi \, V(\mu)} / |g'(\mu)|}
#' where \eqn{V} is the variance function, \eqn{g} the link function
#' of the family, and \eqn{\phi} the dispersion parameter. For the
#' Gaussian family \eqn{\phi = \sigma^2} (so \code{sigma} must be
#' supplied); for all other families \eqn{\phi = 1} and \code{sigma}
#' must \emph{not} be given. Specifying
#' \code{family = gaussian("identity")} with \code{sigma} is
#' equivalent to the standard fixed-\eqn{\sigma} path.
#' @param sigma The fixed reference scale. If left unspecified, the
#' default reference scale of the prior is assumed. When \code{family}
#' is a non-Gaussian family, \code{sigma} must not be specified (it is
#' determined by the family). When \code{family = gaussian()},
#' \code{sigma} is required and acts as the dispersion parameter.
#' @param family Optional \code{\link{family}} object specifying a
#' GLM family and link function (e.g.\ \code{binomial()},
#' \code{MASS::negative.binomial(theta)}). When provided, the
#' sampling standard deviation varies with the parameter value via the
#' family's variance function and link. Default is \code{NULL}
#' (constant \code{sigma}).
#' @param offset Numeric scalar added to the linear predictor before
#' evaluating the family's variance function. Relevant for
#' Poisson/negative-binomial models with log link where
#' \code{offset = log(exposure)}. Default is \code{0}.

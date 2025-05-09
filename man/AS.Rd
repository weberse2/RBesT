% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AS.R
\docType{data}
\name{AS}
\alias{AS}
\title{Ankylosing Spondylitis.}
\format{
A data frame with 8 rows and 3 variables:
\describe{
\item{study}{study}
\item{n}{study size}
\item{r}{number of events}
}
}
\usage{
AS
}
\description{
Data set containing historical information for placebo for a phase
II trial of ankylosing spondylitis patients. The primary efficacy
endpoint was the percentage of patients with a 20\% response
according to the Assessment of SpondyloArthritis international
Society criteria for improvement (ASAS20) at week 6.
}
\examples{
## Setting up dummy sampling for fast execution of example
## Please use 4 chains and 20x more warmup & iter in practice
.user_mc_options <- options(RBesT.MC.warmup=50, RBesT.MC.iter=100,
                            RBesT.MC.chains=2, RBesT.MC.thin=1)

set.seed(34563)
map_AS <- gMAP(cbind(r, n - r) ~ 1 | study,
  family = binomial,
  data = AS,
  tau.dist = "HalfNormal", tau.prior = 1,
  beta.prior = 2
)
## Recover user set sampling defaults
options(.user_mc_options)

}
\references{
Baeten D. et. al, \emph{The Lancet}, 2013, (382), 9906, p 1705
}
\keyword{datasets}

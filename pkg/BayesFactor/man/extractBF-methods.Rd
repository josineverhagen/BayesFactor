\docType{methods}
\name{extractBF}
\alias{extractBF}
\alias{extractBF,BFBayesFactor-method}
\title{Extract the Bayes factor from an object}
\usage{
extractBF(x, logbf = FALSE, onlybf = FALSE)

\S4method{extractBF}{BFBayesFactor}(x, logbf = FALSE, onlybf = FALSE)
}
\arguments{
  \item{x}{object from which to extract the Bayes factors}

  \item{logbf}{return the logarithm of the Bayes factors}

  \item{onlybf}{return a vector of only the Bayes factors}
}
\value{
Returns an object containing Bayes factors extracted from
the object
}
\description{
Extract the Bayes factor from an object
}
\examples{
## Sample from the posteriors for two models
data(puzzles)

bf = lmBF(RT ~ shape*color + ID, data = puzzles, whichRandom="ID", progress=FALSE)

extractBF(bf)
}


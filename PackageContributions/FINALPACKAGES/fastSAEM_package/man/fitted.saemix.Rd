% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SaemixRes.R, R/SaemixObject.R, R/SaemixRes_c.R,
%   R/SaemixRes_d.R
\docType{methods}
\name{fitted.saemix}
\alias{fitted.saemix}
\alias{fitted.SaemixRes}
\alias{fitted}
\alias{fitted.SaemixObject}
\alias{fitted.SaemixObject}
\alias{fitted.saemix}
\alias{fitted.SaemixRes}
\alias{fitted}
\alias{fitted.SaemixObject}
\alias{fitted.saemix}
\alias{fitted.SaemixRes}
\alias{fitted}
\alias{fitted.SaemixObject}
\title{Extract Model Predictions}
\usage{
\method{fitted}{SaemixRes}(object, type = c("ipred", "ypred", "ppred",
  "icpred"), ...)

\method{fitted}{SaemixObject}(object, type = c("ipred", "ypred", "ppred",
  "icpred"), ...)

\method{fitted}{SaemixRes}(object, type = c("ipred", "ypred", "ppred",
  "icpred"), ...)

\method{fitted}{SaemixRes}(object, type = c("ipred", "ypred", "ppred",
  "icpred"), ...)
}
\arguments{
\item{object}{an object of type SaemixRes or SaemixObject}

\item{type}{string determining which predictions are extracted. Possible values are: "ipred" (individual predictions obtained using the mode of the individual distribution for each subject, default), "ypred" (population predictions obtained using the population parameters f(E(theta))), "ppred" (mean of the population predictions (E(f(theta)))) and "icpred" (individual predictions obtained using the conditional mean of the individual distribution). See user guide for details.}

\item{...}{further arguments to be passed to or from other methods}

\item{object}{an object of type SaemixRes or SaemixObject}

\item{type}{string determining which predictions are extracted. Possible values are: "ipred" (individual predictions obtained using the mode of the individual distribution for each subject, default), "ypred" (population predictions obtained using the population parameters f(E(theta))), "ppred" (mean of the population predictions (E(f(theta)))) and "icpred" (individual predictions obtained using the conditional mean of the individual distribution). See user guide for details.}

\item{...}{further arguments to be passed to or from other methods}

\item{object}{an object of type SaemixRes or SaemixObject}

\item{type}{string determining which predictions are extracted. Possible values are: "ipred" (individual predictions obtained using the mode of the individual distribution for each subject, default), "ypred" (population predictions obtained using the population parameters f(E(theta))), "ppred" (mean of the population predictions (E(f(theta)))) and "icpred" (individual predictions obtained using the conditional mean of the individual distribution). See user guide for details.}

\item{...}{further arguments to be passed to or from other methods}
}
\value{
Model predictions

Model predictions

Model predictions
}
\description{
fitted is a generic function which extracts model predictions from objects returned by modelling functions

fitted is a generic function which extracts model predictions from objects returned by modelling functions

fitted is a generic function which extracts model predictions from objects returned by modelling functions
}
\keyword{methods}

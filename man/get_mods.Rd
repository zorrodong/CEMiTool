% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/modules.R
\docType{methods}
\name{get_mods}
\alias{get_mods}
\alias{get_mods,CEMiTool-method}
\title{Calculate co-expression modules}
\usage{
get_mods(cem, ...)

\S4method{get_mods}{CEMiTool}(cem, cor_function = "cor",
  cor_method = "pearson", tom_type = "signed", min_ngen = 20)
}
\arguments{
\item{cem}{Object of class \code{CEMiTool}.}

\item{...}{Optional parameters.}

\item{cor_function}{A character string indicating the correlation function
to be used. Default \code{'cor'}.}

\item{cor_method}{A character string indicating which correlation
coefficient is to be computed. Default \code{"pearson"}.}

\item{tom_type}{A character string indicating to use either "unsigned" or
"signed" (default) TOM similarity measure.}

\item{min_ngen}{Minimal number of genes per module (Default: 20).}
}
\value{
Numeric labels assigning genes to modules.
}
\description{
This function takes a \code{CEMiTool} object containing an adjacency matrix
together with the given network parameters, and returns the given
co-expression modules.
}
\examples{
# Get example expression data
data(expr0)
# Initialize new CEMiTool object with expression data
cem <- new_cem(expr0, filter=TRUE, apply_vst=FALSE)
# Calculate adjacency matrix with example beta value 8
cem <- get_adj(cem, beta=8)
# Get module labels
mods <- get_mods(cem)
}

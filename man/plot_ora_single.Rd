% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/visualization.R
\name{plot_ora_single}
\alias{plot_ora_single}
\title{ORA visualization for one module}
\usage{
plot_ora_single(es, ordr_by = "p.adjust", max_length = 50,
  pv_cut = 0.05, graph_color = "#4169E1",
  title = "Over Representation Analysis")
}
\arguments{
\item{es}{a data.frame from ora function containing only one module}

\item{ordr_by}{column to order the data.frame}

\item{max_length}{max length of a gene set name}

\item{pv_cut}{p-value cuttoff}

\item{graph_color}{color of bars}

\item{title}{title of the graph}
}
\value{
a list with ggplot2 object and the number of significant gene sets
}
\description{
ORA visualization for one module
}
\keyword{internal}

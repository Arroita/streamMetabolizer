% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/metab_bayes.R
\name{mcmc_bayes}
\alias{mcmc_bayes}
\title{Run an MCMC simulation on a formatted data ply}
\usage{
mcmc_bayes(data_list, engine = c("stan", "jags"), model_path, params_out,
  split_dates, keep_mcmc = FALSE, n_chains = 4, n_cores = 4,
  adapt_steps = 1000, burnin_steps = 4000, saved_steps = 40000,
  thin_steps = 1, verbose = FALSE)
}
\arguments{
\item{data_list}{a formatted list of inputs to the JAGS model}

\item{engine}{character string indicating which software to use}

\item{model_path}{the JAGS model file to use, as a full file path}

\item{params_out}{a character vector of parameters whose values in the MCMC 
runs should be recorded and summarized}

\item{keep_mcmc}{logical. If TRUE, the Jags or Stan output object will be 
saved. Be careful; these can be big, and a run with many models might 
overwhelm R's memory.}

\item{n_chains}{the number of chains to run}

\item{n_cores}{the number of cores to apply to this run}

\item{adapt_steps}{the number of steps per chain to use in adapting the model}

\item{burnin_steps}{the number of steps per chain to run and ignore before
starting to collect MCMC 'data'}

\item{saved_steps}{the number of MCMC steps per chain to save}

\item{thin_steps}{the number of steps to move before saving another step. 1
means save all steps.}

\item{verbose}{logical. give status messages?}
}
\value{
a data.frame of outputs
}
\description{
Run an MCMC simulation on a formatted data ply
}
\keyword{internal}


#' Helper to predict_DO.metab_model
#' 
#' Usually assigned to model_fun within mm_model_by_ply, called from there
#' 
#' @param data_ply a data.frame of predictor data for a single ply (~day)
#' @param calc_DO_fun the function to use to build DO estimates from GPP, ER, 
#'   etc. default is calc_DO_mod, but could also be calc_DO_mod_by_diff
#' @param metab_ests a data.frame of metabolism estimates for all days, from 
#'   which this function will choose the relevant estimates
#' @param ... additional args passed from mm_model_by_ply and ignored here
#' @return a data.frame of predictions
mm_predict_1ply <- function(data_ply, calc_DO_fun, metab_ests, ...) {
  
  # determine which date these data center on
  date <- names(which.max(table(as.Date(data_ply$local.time))))
  
  # get the daily metabolism estimates, and skip today (return DO.mod=NAs) if
  # they're missing
  metab_est <- metab_ests[metab_ests$date==date,]
  if(is.na(metab_est$GPP)) {
    return(data.frame(data_ply, DO.mod=NA))
  }
  
  # if we have metab estimates, use them to predict DO
  . <- local.time <- ".dplyr.var"
  data_ply %>%
    do(with(., {
      
      # prepare auxiliary data
      n <- length(local.time)
      timestep.days <- suppressWarnings(mean(as.numeric(diff(local.time), units="days"), na.rm=TRUE))
      frac.GPP <- light/sum(light[strftime(local.time,"%Y-%m-%d")==date])
      
      # produce DO.mod estimates for today's GPP and ER
      DO.mod <- calc_DO_fun(
        GPP.daily=metab_est$GPP, 
        ER.daily=metab_est$ER, 
        K600.daily=metab_est$K600, 
        DO.obs=DO.obs, DO.sat=DO.sat, depth=depth, temp.water=temp.water, 
        frac.GPP=frac.GPP, frac.ER=timestep.days, frac.D=timestep.days, DO.mod.1=DO.obs[1], n=n)
      
      data.frame(., DO.mod=DO.mod)
    }))
}
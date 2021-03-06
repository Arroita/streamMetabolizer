// b_Kb_pcpi_eu_ko.stan

data {
  // Parameters of priors on metabolism
  real GPP_daily_mu;
  real GPP_daily_sigma;
  real ER_daily_mu;
  real ER_daily_sigma;
  
  // Parameters of hierarchical priors on K600_daily (binned model)
  int <lower=1> b; # number of K600_daily_betas
  vector[b] K600_daily_beta_mu;
  vector[b] K600_daily_beta_sigma;
  real K600_daily_sigma_shape;
  real K600_daily_sigma_rate;
  
  // Error distributions
  real err_proc_acor_phi_shape;
  real err_proc_acor_phi_rate;
  real err_proc_acor_sigma_shape;
  real err_proc_acor_sigma_rate;
  real err_proc_iid_sigma_shape;
  real err_proc_iid_sigma_rate;
  
  // Data dimensions
  int<lower=1> d; # number of dates
  int<lower=1> n; # number of observations per date
  
  // Daily data
  vector[d] DO_obs_1;
  int<lower=1,upper=b> discharge_bin_daily[d];
  
  // Data
  vector[d] DO_obs[n];
  vector[d] DO_sat[n];
  vector[d] frac_GPP[n];
  vector[d] frac_ER[n];
  vector[d] frac_D[n];
  vector[d] depth[n];
  vector[d] KO2_conv[n];
}

transformed data {
  vector[d] coef_GPP[n-1];
  vector[d] coef_ER[n-1];
  vector[d] coef_K600_full[n-1];
  vector[d] dDO_obs[n-1];
  
  for(i in 1:(n-1)) {
    // Coefficients by lag (e.g., frac_GPP[i] applies to the DO step from i to i+1)
    coef_GPP[i]  <- frac_GPP[i] ./ depth[i];
    coef_ER[i]   <- frac_ER[i] ./ depth[i];
    coef_K600_full[i] <- KO2_conv[i] .* frac_D[i] .*
      (DO_sat[i] - DO_obs[i]);
    // dDO observations
    dDO_obs[i] <- DO_obs[i+1] - DO_obs[i];
  }
}

parameters {
  vector[d] GPP_daily;
  vector[d] ER_daily;
  vector[d] K600_daily;
  
  vector[b] K600_daily_beta;
  real K600_daily_sigma;
  
  vector[d] err_proc_acor_inc[n-1];
  
  real err_proc_acor_phi;
  real err_proc_acor_sigma;
  real err_proc_iid_sigma;
}

transformed parameters {
  vector[d] dDO_mod[n-1];
  vector[d] err_proc_acor[n-1];
  vector[d] K600_daily_pred;
  
  // Model DO time series
  // * Euler version
  // * no observation error
  // * IID and autocorrelated process error
  // * reaeration depends on DO_obs
  
  err_proc_acor[1] <- err_proc_acor_inc[1];
  for(i in 1:(n-2)) {
    err_proc_acor[i+1] <- err_proc_acor_phi * err_proc_acor[i] + err_proc_acor_inc[i+1];
  }
  
  // dDO model
  for(i in 1:(n-1)) {
    dDO_mod[i] <- 
      err_proc_acor[i] +
      GPP_daily  .* coef_GPP[i] +
      ER_daily   .* coef_ER[i] +
      K600_daily .* coef_K600_full[i];
  }
  
  // Hierarchical, binned model of K600_daily
  K600_daily_pred <- K600_daily_beta[discharge_bin_daily];
}

model {
  // Independent, identically distributed process error
  for(i in 1:(n-1)) {
    dDO_obs[i] ~ normal(dDO_mod[i], err_proc_iid_sigma);
  }
  // SD (sigma) of the IID process errors
  err_proc_iid_sigma ~ gamma(err_proc_iid_sigma_shape, err_proc_iid_sigma_rate);
  
  // Autocorrelated process error
  for(i in 1:(n-1)) {
    err_proc_acor_inc[i] ~ normal(0, err_proc_acor_sigma);
  }
  // Autocorrelation (phi) & SD (sigma) of the process errors
  err_proc_acor_phi ~ gamma(err_proc_acor_phi_shape, err_proc_acor_phi_rate);
  err_proc_acor_sigma ~ gamma(err_proc_acor_sigma_shape, err_proc_acor_sigma_rate);
  
  // Daily metabolism priors
  GPP_daily ~ normal(GPP_daily_mu, GPP_daily_sigma);
  ER_daily ~ normal(ER_daily_mu, ER_daily_sigma);
  K600_daily ~ normal(K600_daily_pred, K600_daily_sigma);

  // Hierarchical constraints on K600_daily (binned model)
  K600_daily_beta ~ normal(K600_daily_beta_mu, K600_daily_beta_sigma);
  K600_daily_sigma ~ gamma(K600_daily_sigma_shape, K600_daily_sigma_rate);
}

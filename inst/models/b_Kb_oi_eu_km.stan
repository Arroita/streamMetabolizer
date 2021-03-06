// b_Kb_oi_eu_km.stan

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
  real err_obs_iid_sigma_shape;
  real err_obs_iid_sigma_rate;
  
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
  vector[d] coef_K600_part[n-1];
  
  for(i in 1:(n-1)) {
    // Coefficients by lag (e.g., frac_GPP[i] applies to the DO step from i to i+1)
    coef_GPP[i]  <- frac_GPP[i] ./ depth[i];
    coef_ER[i]   <- frac_ER[i] ./ depth[i];
    coef_K600_part[i] <- KO2_conv[i] .* frac_D[i];
  }
}

parameters {
  vector[d] GPP_daily;
  vector[d] ER_daily;
  vector[d] K600_daily;
  
  vector[b] K600_daily_beta;
  real K600_daily_sigma;
  
  real err_obs_iid_sigma;
}

transformed parameters {
  vector[d] DO_mod[n];
  vector[d] K600_daily_pred;
  
  // Model DO time series
  // * Euler version
  // * observation error
  // * no process error
  // * reaeration depends on DO_mod
  
  // DO model
  DO_mod[1] <- DO_obs_1;
  for(i in 1:(n-1)) {
    DO_mod[i+1] <- (
      DO_mod[i] +
      GPP_daily .* coef_GPP[i] +
      ER_daily .* coef_ER[i] +
      K600_daily .* coef_K600_part[i] .* (DO_sat[i] - DO_mod[i])
    );
  }
  
  // Hierarchical, binned model of K600_daily
  K600_daily_pred <- K600_daily_beta[discharge_bin_daily];
}

model {
  // Independent, identically distributed observation error
  for(i in 1:n) {
    DO_obs[i] ~ normal(DO_mod[i], err_obs_iid_sigma);
  }
  // SD (sigma) of the observation errors
  err_obs_iid_sigma ~ gamma(err_obs_iid_sigma_shape, err_obs_iid_sigma_rate);
  
  // Daily metabolism priors
  GPP_daily ~ normal(GPP_daily_mu, GPP_daily_sigma);
  ER_daily ~ normal(ER_daily_mu, ER_daily_sigma);
  K600_daily ~ normal(K600_daily_pred, K600_daily_sigma);

  // Hierarchical constraints on K600_daily (binned model)
  K600_daily_beta ~ normal(K600_daily_beta_mu, K600_daily_beta_sigma);
  K600_daily_sigma ~ gamma(K600_daily_sigma_shape, K600_daily_sigma_rate);
}

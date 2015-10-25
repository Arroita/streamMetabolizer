data {
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
  int <lower=0> T;

  vector [T] y;
  vector [T] dodt;
  vector [T] oxysat; 
  vector [T] light;
  
  
  real z;
  vector [T] Kc;
  
}












parameters {
  
  real GPP; 
  real ER;
  real K;
  real <lower=0, upper=1> phi;
  real <lower=0> sigobs;
  real <lower=0> sigproc;
  vector[T] eta;
  
}

model {

  vector [T] mdodt;
  
  for (i in 1:T){
    mdodt[i] <- 
      eta[i] + 
      ((GPP/z)*(light[i]/sum(light))) +
      (ER*0.006944/z) +
      (Kc[i]*K * 0.006944*(oxysat[i]-y[i])); 
  }

  GPP ~ normal(0, 10);
  ER ~ normal(-10, 10);
  K ~ normal(10, 10);
   
  for (i in 1:T){
    dodt[i] ~ normal(mdodt[i], sigobs);
  }           

  for (i in 2:T){
    eta[i] ~ normal(phi*eta[i-1], sigproc);
  }
  
}
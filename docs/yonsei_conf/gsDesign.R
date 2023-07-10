library(gsDesign)

help(nSurv)

## Annual incidence
Pc <- 0.06
Pt <- 0.036

## Hazard rate: S(t) = exp(-lambda * t)
lambda_c <- -log(1 - Pc)
lambda_t <- -log(1 - Pt)

hr <- lambda_t/lambda_c

x <- nSurv(
  lambdaC = lambda_c,  # Hazard rate of control group
  hr = hr,             # Alternative hypothesis
  hr0 = 1,             # Null hypothesis
  T = 4,               # Total study period              
  R = 3,               # Accrural period 
  minfup = 1,          # 4- 3  
  beta = 0.1,       
  alpha = 0.025,       # 1-sided
  eta = 0,             # Annual drop out rate
  ratio = 2            # Randomization ratio, experimental/control
)

x






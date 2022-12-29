# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Create summary table of model estimates
# Author: Amanda Droghini (adroghini@alaska.edu)
# Last Updated: 2022-12-28
# Usage: Code chunks must be executed sequentially in RStudio/2022.12.0+353 or RStudio Server installation.

# def createTable([model_summary, model_ci, correct]):
# Description: Creates an in-memory data frame that summarizes model estimates, including beta coefficients, standard errors, and 95% CI, obtained from a conditional Poisson regression run with the glmmTMB package.
# Inputs: 'model_summary' -- Data frame of used & available paths with covariate values.
# ‘model_ci’ -- Number of bootstrapped samples you wish to create.
# ‘correct’ -- Correction to apply to p-value to account for multiple comparisons. Default method is Benjamini & Yekutieli (2001).
# 'explore' -- Is this an exploratory analysis? If yes, skips a mini-function that calculates how many CI estimates are in agreement with each other; function will break if one of the model returns an "Inf" estimate for the upper 95% CI. Default is "no".
# Returned Value: An in-memory data frame.
# ---------------------------------------------------------------------------

createTable <- function(model_summary, model_ci, correct = "BY", explore = "no") {
  
  # Create empty data frame
  num_rows <- length(dimnames(model_summary$coefficients$cond)[[1]])
  model_table <-
    data.frame(row.names = 1:num_rows)
  
  # Mini-function to calculate # of iterations with non-overlapping CIs
  conf_int_agree <- function(x,y) {
    if(x >= 1 && y >=1) return(1)
    else if(x<1 && y<1) return(1)
    else return(0)
  }
  
  # Populate data frame
  # The final column calculates whether unexponentiated coefficient is positive or negative
  model_table$covariate <- dimnames(model_summary$coefficients$cond)[[1]]
  model_table$SE <- model_summary$coefficients$cond[, 2]
  model_table$p_value <-
    p.adjust(model_summary$coefficients$cond[, 4], method = correct)
  
  # Add rows for variance of random effects
  diff_rows <- nrow(model_ci) - num_rows
  
  for (n in 1:diff_rows) {
  model_table[num_rows+n,1] <- row.names(model_ci)[num_rows+n]
  }
  
  # Add confidence intervals
  model_ci$covariate <- rownames(model_ci)
  
  # Rename CI columns
  # Exponentiate values
  model_ci <- model_ci %>% 
    rename(lower_95 = `2.5 %`,
           upper_95 = `97.5 %`,
           coef = Estimate) %>% 
    mutate(lower_95 = exp(lower_95),
           upper_95 = exp(upper_95),
           exp_coef = exp(coef),
           positive_coef = if_else(coef >= 0, 1,0))
  
  # Join tables together
  model_table <- left_join(model_table,model_ci,by="covariate")
  
  # Calculate whether CIs overlap
  # I'm sure there's a more elegant apply way to do this?
  
  if(explore == "yes") {
  }
  
  if(explore == "no") {
  for (n in 1:nrow(model_table)){
  model_table$ci_agree[n] <- conf_int_agree(model_table$lower_95[n],model_table$upper_95[n])}
  }
  
  return(model_table)
}

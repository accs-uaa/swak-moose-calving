# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Iterate model for exploratory analysis
# Author: Amanda Droghini (adroghini@alaska.edu)
# Last Updated: 2022-12-28
# Usage: Code chunks must be executed sequentially in RStudio/2022.12.0+353 or RStudio Server installation.

# def exploreModelFit([data, sample_ids, model_formula]):
# Description: Fit a conditional Poisson regression model to each user-specified sample.
# Inputs: 'data' -- Data frame of used and available paths with values for each covariate of interest.
# ‘sample_ids' -- Vector with unique id for each iteration to fit a model to. Each iteration contains a set of unique, randomly generated 'available' paths.
# 'model_formula' -- Mixed-effects formula for a glmmTMB model. Must contain at least 1 random slope.
# Returned Value: An in-memory nested list with 2 higher levels: 1) estimates of the fixed effects and variances of the random slopes; 2) estimates of random slopes and intercepts. Estimates for each bootstrapped sample are stored in their own list under these 2 levels.
# ---------------------------------------------------------------------------

exploreModelFit <- function(data, sample_ids, model_formula) {
  
  require(glmmTMB)
  
  # Create list for storing results
  model_list <- vector("list", 2)
  
  # Iterate over samples
  n_iterations <- length(sample_ids)
  for (n in 1:n_iterations) {
    
    cat("Iterating over unique set...", n, "of",n_iterations, "\n")
    
    # iteration ids coded from 0 to 49
    data_sample <- data %>% 
      filter(iteration_id %in% sample_ids[n] | iteration_id == 99)
    
    # Run mixed-effects model
    
    # Specify model structure
    model_structure = glmmTMB(model_formula,
      family = poisson,
      data = data_sample,
      doFit = FALSE
    )
    
    # Manually set the value of the last random effect i.e., stratum-specific random intercept (1|strata_id) to 10^6
    # As recommended by Muff et al. (2019)
    x <- as.numeric(length(model_structure$grpVar))
    model_structure$parameters$theta[x] = log(1e3)
    
    # Tell glmmTMB not to change the last standard deviation
    # All other values are freely estimated (and are different from each other)
    y <- x-1
    
    if(y > 1) {
      model_structure$mapArg = list(theta=factor(c(1:y, NA)))
    }
    
    # Need to add exception for when model only includes a random intercept (no random slopes) i.e., y = 1, otherwise specifying map argument throws an error
    if(y == 1) {
      model_structure$mapArg = list(theta=factor(c(1, NA)))
    }

    # Fit the model
    model_fit <- glmmTMB:::fitTMB(model_structure)
    
    # Produce summary 
    model_summary <- summary(model_fit)
    
    # Obtain 95% confidence intervals
    model_ci <- as.data.frame(confint(model_fit))
    
    # Create table
    # Apply B-Y correction to p-value
    model_table <- createTable(model_summary, model_ci, correct = "BY", explore = "yes")

     # Store random effect coefficients
    random_coef <- ranef(model_fit)$cond$animal_id

    # Add results to lists
    model_list[[1]][[n]] <- model_table
    
    # Only store to 2nd nested list (for random effect estimates) if model includes random slopes, otherwise no random effect table is produced and the function breaks.
    if(y > 1) {
      model_list[[2]][[n]] <- random_coef
    }
    
  rm(n)
  }
  return(model_list)
}
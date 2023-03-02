# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Iterate model over bootstrap samples
# Author: Amanda Droghini (adroghini@alaska.edu)
# Last Updated: 2022-12-28
# Usage: Code chunks must be executed sequentially in RStudio/2022.12.0+353 or RStudio Server installation.

# def iterateBootstrap([data, n_boot_sample, n_sample_size, strata, model_formula]):
# Description: Create bootstrapped samples, fit conditional Poisson regression model to each one, and extract estimates.
# Inputs: 'data' -- Data frame of used & available paths with covariate values.
          # ‘n_boot_sample’ -- Number of bootstrapped samples you wish to create.
          # ‘n_sample_size’ -- Number of unique items in each bootstrap sample.
          # 'strata' --- Character list with the names of each unique stratum.
          # 'model_formula' ---- Mixed-effects formula for a glmmTMB model. Must contain at least 1 random slope.
# Returned Value: An in-memory nested list with 2 higher levels: 1) estimates of the fixed effects and variances of the random slopes; 2) estimates of random slopes and intercepts. Estimates for each bootstrapped sample are stored in their own list under these 2 levels.
# ---------------------------------------------------------------------------

iterateBootstrap <- function(data, n_boot_sample, n_sample_size, strata, model_formula) {
  
  require(glmmTMB)
  require(infer)

  # Create lists for storing results
  boot_list <- vector("list", length(strata))
  model_list <- vector("list", 2)
  
  # Create bootstrap samples
  for (i in 1:length(strata)) {
    
    cat("Bootstrapping moose-year ID...", i, "out of",length(strata), "\n")
    
    stratum <- strata[i]
    
    subset_paths <- data %>% dplyr::filter(response == 0 & strata_id == stratum)
    boot_id <- infer::rep_sample_n(subset_paths, size = n_sample_size, replace = TRUE, reps = n_boot_sample)
    
    # Add results to list
    boot_list[[i]] <-
      boot_id
  }
  
  # Convert list to dataframe
  boot_df <- data.table::rbindlist(boot_list,use.names=FALSE,idcol=FALSE)
  
  # Add cases (response = 1)
  boot_df <- rbind(boot_df,filter(data,response==1),fill=TRUE)

  for (n in 1:n_boot_sample) {
    boot_paths <- boot_df %>% filter(replicate==n | response == 1)
    
    cat("Running model for bootstrap sample...", n, "out of",n_boot_sample, "\n")
    
    # Run conditional Poisson regression model
    
    # Specify model structure
    model_structure = glmmTMB(model_formula,
                              family = poisson,
                              data = boot_paths,
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
    model_table <- createTable(model_summary, model_ci, correct = "BY")
    
    # Store random effect coefficients
    random_coef <- ranef(model_fit)$cond$animal_id
    
    # Add results to lists
    model_list[[1]][[n]] <- model_table
    
    if(y > 1) {
    model_list[[2]][[n]] <- random_coef
    }
    
    rm(n)
  }
  return(model_list)
}
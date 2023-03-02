# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Explore candidate models for habitat selection of non-maternal moose
# Author: Amanda Droghini
# Last Updated: 2022-12-28
# Usage: Code chunks must be executed sequentially in RStudio/2022.12.0+353 or RStudio Server installation.
# Description: Run full model on a small number (n=10) of iterations in which every available path is unique. Evaluate model estimates and adjust formula as needed. Code follows recommendations in Muff et al. (2020) and Muff et al. (2021).
# Citations: 
# 1) Muff, S., J. Signer, and J. Fieberg. 2020. Accounting for individual‐specific variation in habitat‐selection studies: Efficient estimation of mixed‐effects models using Bayesian or frequentist computation. Journal of Animal Ecology 89(1):80–92.
# 2) Muff, S., J. Signer, and J. Fieberg. 2021. R Code and Output Supporting "Accounting for individual-specific variation in habitat-selection studies: Efficient estimation of mixed-effects models using Bayesian or frequentist computation". Retrieved from the Data Repository for the University of Minnesota, https://doi.org/10.13020/8bhv-dz98. 
# ---------------------------------------------------------------------------

rm(list=ls())

#### Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Statistics/"

#### Load packages & functions ----
source(paste0(git_dir,"init.R"))

#### Load data ----
non_maternal <- read_csv(file=paste(pipeline_dir,
                            "01-dataPrepForAnalyses",
                            "paths_nonmaternal_20221228.csv",
                            sep="/"))

# Exploratory model run ----
# Run through a few iterations to see if full model specification will converge
num_iterations <- 10
sample_iterations <- sample(0:49, size = num_iterations, replace = FALSE)

# Run mixed-effects model ----

# Model Attempt #1 - Full model
# Full model formula fails
full_formula <- formula(response ~ -1 + forest_edge_mean +
                          tundra_edge_mean +
                          alnus_mean +
                          salshr_mean +
                          roughness_mean +
                          wetsed_mean +
                          (0 + forest_edge_mean | animal_id) +
                          (0 + alnus_mean | animal_id) +
                          (0 + tundra_edge_mean | animal_id) +
                          (0 + salshr_mean | animal_id) +
                          (0 + roughness_mean | animal_id) +
                          (0 + wetsed_mean | animal_id) +
                          (1 | strata_id))

list_results <- exploreModelFit(data = non_maternal, 
                                sample_ids = sample_iterations, 
                                model_formula = full_formula)
# Model warnings:
#1) Model convergence problem; non-positive-definite Hessian matrix.
#2) Model convergence problem; singular convergence
#3) In sqrt(diag(object$cov.fixed)) : NaNs produced

# Model Attempt #2
# Try using fewer random effects
# Use same model as maternal females: drop random effects for tundra_edge_km, roughness_mean, and wetsed_mean
restricted_formula <- formula(response ~ -1 + 
                                forest_edge_mean +
                                tundra_edge_mean +
                                alnus_mean +
                                salshr_mean +
                                roughness_mean +
                                wetsed_mean +
                                (0 + forest_edge_mean | animal_id) +
                                (0 + alnus_mean | animal_id) +
                                (0 + salshr_mean | animal_id) +
                                (1 | strata_id))


# Re-run model
list_results <- exploreModelFit(data = non_maternal, 
                                sample_ids = sample_iterations, 
                                model_formula = restricted_formula)
# Some, but not all of the iterations, converged
# Still get "non-positive-definite Hessian matrix" error

# Convert lists to dataframe
coef_fixed <- data.table::rbindlist(list_results[[1]],use.names=FALSE,idcol=TRUE)

# All of the random slopes are estimated to be zero
coef_fixed %>% filter(log(lower_95) == 0) %>% 
  distinct(covariate)

# Model Attempt #3 - Drop forest_edge_mean as a random effect
restricted_formula <- formula(response ~ -1 + 
                                forest_edge_mean +
                                tundra_edge_mean +
                                alnus_mean +
                                salshr_mean +
                                roughness_mean +
                                wetsed_mean +
                                (0 + alnus_mean | animal_id) +
                                (0 + salshr_mean | animal_id) +
                                (1 | strata_id))

list_results <- exploreModelFit(data = non_maternal, 
                                sample_ids = sample_iterations, 
                                model_formula = restricted_formula)
coef_fixed <- data.table::rbindlist(list_results[[1]],use.names=FALSE,idcol=TRUE)

# Model Attempt #4 - Drop roughness as a fixed effect (based on unrealistic estimates)
restricted_formula <- formula(response ~ -1 + 
                                forest_edge_mean +
                                tundra_edge_mean +
                                alnus_mean +
                                salshr_mean +
                                wetsed_mean +
                                (0 + alnus_mean | animal_id) +
                                (0 + salshr_mean | animal_id) +
                                (1 | strata_id))

list_results <- exploreModelFit(data = non_maternal, 
                                sample_ids = sample_iterations, 
                                model_formula = restricted_formula)

coef_fixed <- data.table::rbindlist(list_results[[1]],use.names=FALSE,idcol=TRUE)

# That worked without warnings and estimates seem reasonable

# Model Attempt #5 - Reintroduce some of the random effects
restricted_formula <- formula(response ~ -1 + 
                                forest_edge_mean +
                                tundra_edge_mean +
                                alnus_mean +
                                salshr_mean +
                                wetsed_mean +
                                (0 + forest_edge_mean | animal_id) +
                                (0 + alnus_mean | animal_id) +
                                (0 + salshr_mean | animal_id) +
                                (1 | strata_id))

list_results <- exploreModelFit(data = non_maternal, 
                                sample_ids = sample_iterations, 
                                model_formula = restricted_formula)

coef_fixed <- data.table::rbindlist(list_results[[1]],use.names=FALSE,idcol=TRUE)

# forest_edge random effect has fairly extreme estimates (upper 95% is 1.6 x 10^14), so leave it out and stick with model #4 (no roughness, only alder and salix as random effects)
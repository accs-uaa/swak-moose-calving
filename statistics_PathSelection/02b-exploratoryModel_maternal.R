# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Explore candidate models for habitat selection of maternal moose
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
maternal <- read_csv(file=paste(pipeline_dir,
                            "01-dataPrepForAnalyses",
                            "paths_maternal_20221228.csv",
                            sep="/"))

# Exploratory model run ----
# Run through a few iterations to see if full model specification will converge
num_iterations <- 10
sample_iterations <- sample(0:49, size = num_iterations, replace = FALSE)

# Specify full model formula
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

# Run mixed-effects model
list_results <- exploreModelFit(data = maternal, 
                  sample_ids = sample_iterations, 
                  model_formula = full_formula)

# Convert list to dataframe
coef_fixed <- data.table::rbindlist(list_results[[1]],use.names=FALSE,idcol=TRUE)

# Trouble-shoot model formula ----
# https://cran.r-project.org/web/packages/glmmTMB/vignettes/troubleshooting.html

# There are a few random effects whose variance is estimated to be zero: tundra_edge_km, roughness_mean, and wetsed_mean that are possibly leading to convergence issues
# Apply natural log transform since covariates were exponentiated
coef_fixed %>% filter(log(lower_95) == 0) %>% 
  distinct(covariate)

# Try formula w/o these random effects
# Will also help with over-parameterization
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
list_results <- exploreModelFit(data = maternal, 
                               sample_ids = sample_iterations, 
                               model_formula = restricted_formula)

# Convert lists to dataframe
coef_fixed <- data.table::rbindlist(list_results[[1]],use.names=FALSE,idcol=TRUE)
coef_random <- data.table::rbindlist(list_results[[2]],use.names=FALSE,idcol=TRUE)

# Plot random effects ----

# Interpretation of random slope coefficients
# From glmmTMB::ranef vignette: "For coef.glmmTMB: a similar list, but containing the overall coefficient value for each level, i.e., the sum of the fixed effect estimate and the random effect value for that level. Conditional variances are not yet available as an option for coef.glmmTMB"

# Leave them un-exponentiated otherwise range is hard to plot
# Need to add population level B estimate
boxplot(coef_random[,2:4])
# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Run final habitat selection function for non-maternal moose
# Author: Amanda Droghini (adroghini@alaska.edu)
# Last Updated: 2022-12-28
# Usage: Code chunks must be executed sequentially in RStudio/2022.12.0+353 or RStudio Server installation.
# Description: Using the model formula chosen in the exploratory analysis, fit mixed-effects, conditional Poisson regression on 2,000 bootstrap samples. Sampled paths come from a larger set of 500 unique available paths, which are paired to 49 used paths in a ratio of 10 available:1 used. Code follows recommendations in Muff et al. (2020) and Muff et al. (2021).
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

#### Define output csv files ----
output_fixed <- file.path(paste0(output_dir,"/maternal_fixed_",format(Sys.Date(), "%Y%m%d"),
                                 ".csv"))

output_random <- file.path(paste0(output_dir,"/maternal_random_",format(Sys.Date(), "%Y%m%d"),
                          ".csv"))

# Define parameters for function ----
boot_sample <- 2000
sample_size <- 10
unique_strata <- unique(maternal$strata_id)

final_formula <- formula(response ~ -1 + 
                                forest_edge_mean +
                                tundra_edge_mean +
                                alnus_mean +
                                salshr_mean +
                                roughness_mean +
                                wetsed_mean +
                                (0 + alnus_mean | animal_id) +
                                (0 + salshr_mean | animal_id) +
                                (1 | strata_id))

# Run model ----
model_results <- iterateBootstrap(data = maternal, 
                              n_boot_sample = boot_sample,
                              n_sample_size = sample_size, 
                              strata = unique_strata, 
                              model_formula = final_formula)

#### Summarize results ----

# Convert list to dataframe
fixed_estimates <- data.table::rbindlist(model_results[[1]],use.names=FALSE,idcol=TRUE)
random_estimates <- data.table::rbindlist(model_results[[2]],use.names=FALSE,idcol=TRUE)

# Summarize fixed / population-level estimates
final_table <- fixed_estimates %>% 
  rename(Covariate = covariate) %>%
  group_by(Covariate) %>% 
  arrange(exp_coef, .by_group=TRUE) %>% 
  summarise("Mean Exp Coef" = mean(exp_coef, na.rm = TRUE), 
            lower_95 = quantile(exp_coef,0.025), 
            upper_95 = quantile(exp_coef,0.975), 
            "Within-Sample Agreement" = (sum(ci_agree)/length(ci_agree)*100)) %>% 
  mutate("Variable Type" = if_else(grepl("Std.Dev.",Covariate),"Random Effect","Fixed Effect")) %>% 
  rename("Variable Name" = "Covariate") %>% 
  select(`Variable Type`, everything()) %>% 
  arrange(`Variable Type`)

# Format table ----

# Round values
final_table <- as.data.frame(cbind(final_table[,1:2],
                                   sapply(final_table[,3:6], FUN = round, digits = 2)))

# Combine CI into single column
final_table <-
  final_table %>% mutate(
    "95% CI" = paste(lower_95, upper_95, sep = ", ")) %>%
  select("Variable Name","Mean Exp Coef","95% CI", "Within-Sample Agreement",-c(lower_95, upper_95))


#### Export tables ----
write_csv(final_table, file=output_fixed)
write_csv(random_estimates, file=output_random)

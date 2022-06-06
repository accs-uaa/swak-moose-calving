# Objectives: Run path selection function for females without calves using conditional logistic regression

# Hypothesis: We expect all female moose to maximize willow availability and protective cover. Female moose avoid terrain that imposes high energetic costs to movement as inferred from roughness (standard deviation of elevation). Cows with calves should select more strongly for willow and protective cover in response to increased energetic demand and predation risk.

# Sub-hypothesis 1: Female moose select for higher willow abundance than other shrub aggregates (alder and birch shrubs).
# Sub-hypothesis 2: Female moose select for higher tree abundance and lower distance from forest edge than Eriophorum abundance or distance from tussock tundra edge.

# Alternate 1: Cows with calves select more strongly for cover, but not for willow, relative to cows without calves. Increased predation risk is the driving force that cows with calves respond to, at the expense of meeting their nutritional needs.

# Alternate 2: Cows with calves have greater movement rates and select less strongly for willow availability and protective cover, resulting in more random movements, relative to non-parturient cows. Cows with calves move erratically and often to avoid predators at the expense of both meeting their nutritional needs and remaining close to cover.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

#### Define Git directory ----
git_dir <- "C:/Users/adroghini/Documents/Repositories/southwest-alaska-moose/package_Statistics/"

#### Load packages & functions ----
source(paste0(git_dir,"init.R"))

no_calf <- read_csv(file=paste(pipeline_dir,
                             "01-dataPrepForAnalyses",
                             "paths_no_calves.csv",
                             sep="/"))


#### Define output csv files ----
csv_name <- paste0("clogit_results_no_calf_",format(Sys.Date(), "%Y-%m-%d"),
                  ".csv")
output_no_calf <- file.path(output_dir,csv_name)

#### Define parameters ----
unique_ids <- (no_calf %>% distinct(mooseYear_id))$mooseYear_id
boot_size <- 2000
sample_size <- 10 # 10 controls per case
model_formula <- formula(response ~ forest_edge_km + 
                           tundra_edge_km + 
                           alnus_mean + 
                           salshr_mean + 
                           roughness_mean + 
                           wetsed_mean +
                           strata(mooseYear_id))

#### Run model ----

list_no_calf <- iterateRun(data = no_calf, 
                           ids = unique_ids, 
                           n_boot_sample = boot_size, 
                           n_sample_size = sample_size, 
                           model_formula = model_formula )

# Convert list to dataframe
df_no_calf <- data.table::rbindlist(list_no_calf,use.names=FALSE,idcol=TRUE)

#### Summarize results ----
final_no_calf <- df_no_calf %>% 
  rename(Covariate = covariate) %>% 
  group_by(Covariate) %>%
  arrange(exp_coef, .by_group=TRUE) %>%
  summarise("Mean Exp Coef" = mean(exp_coef), 
            lower_95 = quantile(exp_coef,0.025), 
            upper_95 = quantile(exp_coef,0.975), 
            "Within-Sample Agreement" = (sum(ci_agree)/length(ci_agree)*100))

#### Format table ----

# Round values
final_no_calf <- as.data.frame(cbind(final_no_calf[,1],sapply(final_no_calf[,2:5], FUN = round, digits = 2)))

# Combine CI into single column
final_no_calf <-
  final_no_calf %>% dplyr::mutate(
    "95% CI" = paste(lower_95, upper_95, sep = ", ")) %>%
  select(Covariate,"Mean Exp Coef","95% CI", "Within-Sample Agreement",-c(lower_95, upper_95))

#### Export table ----
write_csv(final_no_calf, file=output_no_calf)

#### Clear workspace ----
rm(list=ls())
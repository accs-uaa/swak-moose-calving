# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare datasets for statistical model
# Author: Amanda Droghini
# Last Updated: 2022-12-28
# Usage: Code chunks must be executed sequentially in RStudio/2022.12.0+353 or RStudio Server installation.
# Description: Create and transform variables for use in a conditional Poisson regression model: scale and center all continuous variables, convert grouping (strata) variable to sequential numbers, and add unique numeric identifier with which to differentiate between individual animals. This script also splits the data into two separate datasets based on the maternal status of each moose within a given year: 1) maternal moose ('calf at heel'), 2) non-maternal moose. The outputs are 2 CSVs file(1 for each dataset) that can be used in conditional regression models. 
# ---------------------------------------------------------------------------

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Statistics/"

#### Load packages and data ----
source(paste0(git_dir,"init.R"))

paths <- read_csv(file=paste(pipeline_dir,
                             "07-summarizeByPath",
                             "paths_meanCovariates.csv",
                             sep="/"))

##### Define output CSV files ----
output_fpath <- file.path(pipeline_dir,"01-dataPrepForAnalyses")

output_maternal <- file.path(output_fpath,
                     paste0("paths_maternal_",
                     format(Sys.Date(), "%Y%m%d"),
                     ".csv"))

output_nonmaternal <- file.path(output_fpath,
                         paste0("paths_nonmaternal_",
                                format(Sys.Date(), "%Y%m%d"),
                                ".csv"))

# Add individual animal identifier ----
id <- str_split(paths$mooseYear_id,pattern="_",n=3)
id_df <- do.call(rbind.data.frame, id)[1]
colnames(id_df) <- "id"
paths$animal_id <- as.numeric(as.factor(id_df$id))
rm(id, id_df)

### Split data, create strata, and scale ----
# Create numeric strata identifiers by converting grouping (strata) variable 'mooseYear_id' to sequential numbers
# Recommended by Muff et al. (2020)

# List variables to be scaled
var_names <- names(paths)[c(5:22)]

maternal <- paths %>% 
  filter(calfStatus==1) %>% 
  mutate(strata_id = as.numeric(as.factor(mooseYear_id)),
         across(starts_with(var_names), scale),
         across(starts_with(var_names), as.numeric))
  
nonmaternal <- paths %>% 
  filter(calfStatus==0) %>% 
  mutate(strata_id = as.numeric(as.factor(mooseYear_id)),
         across(starts_with(var_names), scale),
         across(starts_with(var_names), as.numeric))

# QA/QC
# Each strata should have 501 observations (500 used paths + 1 available)
table(maternal$strata_id)
table(nonmaternal$strata_id)

# Export CSVs ----
write_csv(maternal, file = output_maternal)
write_csv(nonmaternal, file = output_nonmaternal)

# Clear workspace
rm(list=ls())
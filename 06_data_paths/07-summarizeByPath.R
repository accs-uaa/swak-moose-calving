# Objective: Summarize point-level variables as the mean for each path. Exclude random paths that are outside the study area boundary or that have more than 7 points in a lake. Exclude points in a lake from the remaining paths. Randomly select 500 paths from the subset of the "lake-free" random paths for use in statistical modeling.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

#### Specify user ---
user <- "AD"

#### Load data ----
# File paths depend on which user is specified

if(user=="AD") {
  
# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Paths/"

# Load packages and data ----
source(paste0(git_dir,"init.R"))

paths <- read_csv(paste(pipeline_dir, "06-extractCovariates",
                         "allPoints_extractedCovariates.csv",
                         sep="/"))

# Define output csv file ----
output_csv = paste(pipeline_dir,
                       "07-summarizeByPath",
                       "paths_meanCovariates.csv", sep="/") 

} else {

##### Load data from TWN's computer ----
library(tidyverse)
paths <- read_csv("N:/ACCS_Work/Projects/WildlifeEcology/Moose_SouthwestAlaska/Data/Data_Input/paths/allPoints_extractedCovariates.csv")
output_csv = "N:/ACCS_Work/Projects/WildlifeEcology/Moose_SouthwestAlaska/Data/Data_Input/paths/paths_meanCovariates.csv"

}

#### Exclude paths with points outside of study area ----
# Points for these paths have lake values = 128
# Value represents points that are outside of lake raster/study area boundary
drop_lake_rows <- paths %>% 
  filter(lake == 128) %>% 
  dplyr::select(fullPath_id) %>% 
  dplyr::distinct()

drop_na_rows <- paths %>%
  filter_all(any_vars(is.na(.))) %>%
  dplyr::select(fullPath_id) %>% 
  dplyr::distinct()

drop_rows = as.matrix(rbind(drop_lake_rows, drop_na_rows) %>%
  dplyr::select(fullPath_id) %>% 
  dplyr::distinct())

paths <- paths %>% 
  filter(!(fullPath_id %in% drop_rows))

# Check
# Value for lake should only be 1 or 0
unique(paths$lake)

rm(drop_rows)
rm(drop_lake_rows)
rm(drop_na_rows)

##### Exclude paths with lots of points in lakes ----

# 1) Define threshold for how many lake points/paths are acceptable based on observed paths
# 2) Include only random paths with sum of lake points below this threshold
# 3) Once major lake paths have been excluded, exclude points that fall in a lake from remaining random paths and from all observed paths
# Final set of paths will have a small number of points dropped that is equivalent either to a) max number of points in a lake (for observed path) or b) threshold number (for random paths). There won't be any remaining points that fall in a lake.

## 1) Define threshold
# For observed paths, max number of lake points per path is 9, 6, 2.
paths %>% 
  group_by(fullPath_id) %>%
  filter(response == 1) %>% 
  dplyr::summarise(lake_sum = sum(lake)) %>% 
  arrange(desc(lake_sum))

# Exclude random paths with more than 7 points in a lake
# Number chosen based on data from observed paths and to ensure that every observed path can be paired with 500 random paths
lakePaths <- paths %>% 
  group_by(fullPath_id) %>% 
  filter(response == 0) %>% 
  dplyr::summarise(lake_sum = sum(lake))%>% filter(lake_sum > 7)

## 2) Include only paths with total number of lake points below this threshold
paths <- paths %>% 
  filter(!(fullPath_id %in% lakePaths$fullPath_id))

rm(lakePaths)

# 3) Drop all points in a lake
# Lake points won't have any veg values associated with them, therefore underestimating mean willow cover, etc.
paths <- paths %>% 
  filter(lake == 0)

# Check - value for lake should be all zeroes
unique(paths$lake)

#### Summarize covariates for every path ----
# Calculate mean for every variable of interest
meanPaths <- paths %>% 
  dplyr::select(mooseYear_id,fullPath_id,calfStatus,response,
                elevation:wetsed) %>% 
  dplyr::group_by(mooseYear_id,fullPath_id) %>%
  dplyr::summarise(across(calfStatus:wetsed, 
                          mean, .names = "{.col}_mean"),.groups="keep") %>%
  dplyr::rename(calfStatus = calfStatus_mean, response = response_mean) %>% 
  ungroup()

#### Select 500 random paths ----
randomPaths <- meanPaths %>% 
  filter(response == 0) %>% 
  group_by(mooseYear_id) %>% 
  dplyr::sample_n(500)

# Check that there are 500 random paths for each ID
randomPaths %>% 
  dplyr::count(mooseYear_id) %>% 
  filter (n!=500)

# Assign iteration number
# For each mooseYear_id, group random paths into 50 groups of 10
randomPaths <- randomPaths %>% group_by(mooseYear_id) %>% mutate(iteration_id = as.integer(((row_number()-1)/10)))

# Create final dataset ----
# Should have 40,080 rows (80 observed + 80*500 random)
allPaths <- meanPaths %>% 
  dplyr::filter(response==1) %>%
  mutate(iteration_id = as.integer(99)) %>% 
  rbind(randomPaths)

#### Export data ----
write_csv(allPaths, file=output_csv)

rm(list=ls())
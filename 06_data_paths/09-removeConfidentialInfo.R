# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Remove identifying information from telemetry dataset
# Author: Amanda Droghini (adroghini@alaska.edu)
# Last Updated: 2022-05-21
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: Scrub paths_meanCovariates file of any identifying information so that we can legally share the dataset with the public. Information to remove includes individual ID, collar frequencies, date.
# ---------------------------------------------------------------------------

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Paths/"

# Load packages and data ----
source(paste0(git_dir,"init.R"))
paths <- read_csv(paste(pipeline_dir,
                   "07-summarizeByPath",
                   "paths_meanCovariates.csv", sep="/"))

# Define output csv file ----
output_csv = paste(pipeline_dir,
                   "07-summarizeByPath",
                   "paths_meanCovariates_forSharing.csv", sep="/") 

# Split fullPath_id into separate components ----
# The first 2 columns contain sensitive information (moose ID and year)
ids_split <- as.data.frame(stringr::str_split(string = paths$fullPath_id, pattern = "_",simplify=TRUE))

# Extract unique number of IDs and years
original_ids <- unique(ids_split$V1)
number_of_ids <- length(original_ids)
original_years <- unique(ids_split$V2)
number_of_years <- length(original_years)

# Generate random numbers for moose IDs & years ----
# Append "M" and "Y" to the start of the animal id & year sequence, respectively
# Ensures R will interpret the column as a character
# Hopefully makes it more reader-friendly, too
# Sequential order for years doesn't matter for this analysis
random_ids <- sample(1000:9999, number_of_ids , replace=FALSE)
random_ids <- paste0("M",random_ids)

random_years <- sample(100:999, number_of_years , replace=FALSE)
random_years <- paste0("Y",random_years)

# Create new string by replacing sensitive values ----
new_ids <- data.frame(matrix(nrow=nrow(ids_split), ncol=0))
new_ids$animal_id <- mapvalues(ids_split$V1, 
               from=original_ids, to=random_ids)
new_ids$year_id <- mapvalues(ids_split$V2, 
                                     from=original_years, to=random_years)

# Replace original columns mooseYear_id and fullPath_id with new data ----
paths_new_ids <- paths
paths_new_ids$fullPath_id <- paste(new_ids$animal_id,
                              new_ids$year,
                              ids_split$V3, sep="_")
paths_new_ids$mooseYear_id <- str_split(paths_new_ids$fullPath_id, 
                                        "-", simplify=TRUE)[,1]

#### Export data ----
write_csv(paths_new_ids, file=output_csv)
rm(list=ls())

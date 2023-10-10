# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Format GPS data
# Author: Amanda Droghini, Alaska Center for Conservation Science
# Last Updated: 2023-10-10
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: "Format GPS data" projects location coordinates, re-codes collar ID to account for redeployments, and renames column.
# ---------------------------------------------------------------------------

rm(list=ls())

# Load packages ----
library(dplyr)
library(readr)
library(tidyr)

# Define directories ----
drive <- "C:"
root_folder <- "ACCS_Work/Projects/Moose_SouthwestAlaska"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")

# Define inputs ----
gps_file <- file.path(pipeline_dir,"01_importData/raw_gps_data.csv")
deploy_file <- file.path(pipeline_dir,"01_createDeployMetadata/deployMetadata.Rdata")

# Define output ----
output_path <- file.path(pipeline_dir,"02_formatData","gps_data.csv")

# Load data ----
gpsData <- read_csv(gps_file)
load(deploy_file)

# Format GPS data ----
# 1. Filter out records for which Date Time, Lat, or Lon is NA
# 2. Filter out records with longitude values that are beyond the easternmost extent of our study area boundary. Some fixes had values of 13.xx, which is in Germany where collars are manufactured. 
# 3. Format Date/Time: Format UTC_Date column as Date. Combine date and time in a single column ("datetime"). Use UTC rather than local time to conform with Movebank requirements.
# 4. Rename columns
gpsData <- gpsData %>%
  dplyr::mutate(datetime = as.POSIXlt(paste(gpsData$UTC_Date, gpsData$UTC_Time),
                               format="%m/%d/%Y %H:%M:%S",tz="GMT"),
                UTC_Date = as.Date(as.POSIXct(strptime(UTC_Date,format="%m/%d/%Y",tz="GMT")))) %>%
  dplyr::rename(longX = "Longitude....", latY = "Latitude....", tag_id = CollarID,
                mortalityStatus = "Mort..Status") %>%
  filter(!(is.na(longX) | is.na(latY) | is.na(UTC_Date))) %>%
  filter(longX < -153)

# QA/QC to make sure the datetime was coded properly
gpsData %>% filter(is.na(gpsData$datetime))

# Format deployment file ----
# Identify which collars have been redeployed. Redeployed collars are differentiated from non-redeploys because they end in a letter
redeployList <- deploy %>%
  filter(sensor_type == "GPS" & grepl(paste(letters, collapse="|"), deployment_id)) %>%
  dplyr::select(deployment_id,tag_id,deploy_on_timestamp,deploy_off_timestamp)

# Convert to wide format
# Format date columns as UTC dates
redeployList <- redeployList %>% 
  mutate(sequence = rep(c("a","b"),times=2)) %>% 
  select(-deployment_id) %>% 
  pivot_wider(names_from = sequence,
                             values_from=c(deploy_on_timestamp,deploy_off_timestamp)) %>% 
  mutate(deploy_off_timestamp_b = Sys.Date()) %>% 
  mutate(across(deploy_on_timestamp_a:deploy_off_timestamp_b,
                ~ as.POSIXct(.x, format="%m/%d/%Y",
                             tz="GMT")),
         across(deploy_on_timestamp_a:deploy_off_timestamp_b, ~ as.Date(.x)))
         
# Code redeploys ----
gpsData$tag_id <- as.character(gpsData$tag_id)
gpsData$deployment_id <- as.character(NA)

# Run for loop
# Iterate over the number of unique redeployment tags
for (a in 1:length(unique(redeployList$tag_id))) {
  tag <- redeployList$tag_id[a]
  cat("working on tag...", tag, "\n")
  
  redeploy_df <- gpsData %>% 
    filter(tag_id == tag)
  
  redeploy_time <- redeployList %>% 
    filter(tag_id == tag)
  
  # Define start and end times of deployment
  start1 <- redeploy_time$deploy_on_timestamp_a[1]
  end1 <- redeploy_time$deploy_off_timestamp_a[1]
  start2 <- redeploy_time$deploy_on_timestamp_b[1]
  
  # Code deployment_id as "a", "b", or "error" depending on start/end times of deployment
  # Where "a" is the first instance the collar was deployed and "b" is the second
  # "error" is for fixes in between deployment stints (when collar was on a dead moose or at the ADF&G offices)
  redeploy_df <- redeploy_df %>% 
    mutate(deployment_id = case_when(UTC_Date >= start1 & UTC_Date <= end1 ~ 
                                       paste0("M",tag,"a"),
                                     UTC_Date >= start2 ~ paste0("M",tag,"b"),
                                     .default = "error")) %>% 
    filter(deployment_id!="error")
  
  if (a == 1) {
    gpsRedeploy <- redeploy_df
  } else {
    gpsRedeploy <- bind_rows(gpsRedeploy,redeploy_df)
  }
}

# Combine redeploy with non-redeploys
gpsData <- gpsData %>% 
  filter(!(tag_id %in% unique(redeployList$tag_id))) %>% 
  mutate(deployment_id = paste0("M",tag_id)) %>% 
  bind_rows(gpsRedeploy)

# QA/QC
# Check for correct number of collars (should be 24)
length(unique(gpsData$deployment_id))

# Format corrected dataset ----
# Create unique row number, RowID, for each device in ascending order according to date/time. Note that RowID will be unique within but not across individuals. This will replace the "No" column that exists in the original GPS data.
# Drop unnecessary columns
# Create unique mooseYear ID
gpsData <- gpsData %>%
  mutate(mooseYear = paste(deployment_id,
                           as.numeric(format(gpsData$UTC_Date[1], "%Y")),
                           sep=".")) %>% 
group_by(deployment_id) %>%
  arrange(datetime) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>%
  arrange(deployment_id,RowID) %>%
  ungroup() %>%
  dplyr::select(-c(No,LMT_Date,LMT_Time,tag_id)) %>%
  dplyr::select(RowID,everything())

# Join with deployment metadata to get individual animal ID
# Useful when uploading into Movebank.
deploy <- deploy %>% dplyr::select(animal_id,deployment_id)

gpsData <- left_join(gpsData,deploy,by="deployment_id")

# Export data ----
write_csv(gpsData, file=output_path)

# Clean workspace ----
rm(list = ls())
# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Format GPS data
# Author: Amanda Droghini, Alaska Center for Conservation Science
# Last Updated: 2023-10-31
# Usage: Code chunks must be executed sequentially in R version 4.3.1+.
# Description: "Format GPS data" projects location coordinates, re-codes collar ID to account for re-deployments, removes post-mortality locations, and renames column.
# ---------------------------------------------------------------------------

rm(list=ls())

# Load packages ----
library(dplyr)
library(lubridate)
library(move2)
library(readr)
library(sf)
library(tidyr)

# Define directories ----
drive = "D:"
project_folder = file.path(drive,"ACCS_Work/Projects/Moose_SouthwestAlaska")
input_dir = file.path(project_folder, "Data_01_Input")
pipeline_dir = file.path(project_folder, "Data_02_Pipeline")

# Define inputs ----
gps_file = file.path(pipeline_dir,"01_importData/raw_gps_data.csv")
deploy_file = file.path(pipeline_dir,"01_createDeployMetadata/deployMetadata.Rdata")

# Define output ----
output_path = file.path(pipeline_dir,"02_formatData","gps_data.csv")

# Load data ----
gpsData = read_csv(gps_file)
load(deploy_file)

# Format GPS data ----
# 1. Filter out records for which Date Time, Lat, or Lon is NA
# 2. Filter out records with longitude values that are beyond the easternmost extent of our study area boundary. Some fixes had values of 13.xx, which is in Germany where collars are manufactured. 
# 3. Format Date/Time: Format UTC_Date column as Date. Combine date and time in a single column ("datetime"). Use UTC rather than local time to conform with Movebank requirements.
# 4. Rename columns
gpsData = gpsData %>%
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
redeployList = deploy %>%
  filter(sensor_type == "GPS" & grepl(paste(letters, collapse="|"), deployment_id)) %>%
  dplyr::select(deployment_id,tag_id,deploy_on_timestamp,deploy_off_timestamp)

# Convert to wide format
# Format date columns as UTC dates
redeployList = redeployList %>% 
  mutate(sequence = rep(c("a","b"),times=2)) %>% 
  select(-deployment_id) %>% 
  tidyr::pivot_wider(names_from = sequence,
                             values_from=c(deploy_on_timestamp,deploy_off_timestamp)) %>% 
  mutate(deploy_off_timestamp_b = Sys.Date()) %>% 
  mutate(across(deploy_on_timestamp_a:deploy_off_timestamp_b,
                ~ as.POSIXct(.x, format="%m/%d/%Y",
                             tz="GMT")),
         across(deploy_on_timestamp_a:deploy_off_timestamp_b, ~ as.Date(.x)))
         
# Code redeploys ----
gpsData$tag_id = as.character(gpsData$tag_id)
gpsData$deployment_id = as.character(NA)

# Run for loop
# Iterate over the number of unique redeployment tags
for (a in 1:length(unique(redeployList$tag_id))) {
  tag = redeployList$tag_id[a]
  cat("working on tag...", tag, "\n")
  
  redeploy_df = gpsData %>% 
    filter(tag_id == tag)
  
  redeploy_time = redeployList %>% 
    filter(tag_id == tag)
  
  # Define start and end times of deployment
  start1 = redeploy_time$deploy_on_timestamp_a[1]
  end1 = redeploy_time$deploy_off_timestamp_a[1]
  start2 = redeploy_time$deploy_on_timestamp_b[1]
  
  # Code deployment_id as "a", "b", or "error" depending on start/end times of deployment
  # Where "a" is the first instance the collar was deployed and "b" is the second
  # "error" is for fixes in between deployment stints (when collar was on a dead moose or at the ADF&G offices)
  redeploy_df = redeploy_df %>% 
    mutate(deployment_id = case_when(UTC_Date >= start1 & UTC_Date <= end1 ~ 
                                       paste0("M",tag,"a"),
                                     UTC_Date >= start2 ~ paste0("M",tag,"b"),
                                     .default = "error")) %>% 
    filter(deployment_id!="error")
  
  if (a == 1) {
    gpsRedeploy = redeploy_df
  } else {
    gpsRedeploy = bind_rows(gpsRedeploy,redeploy_df)
  }
}

# Combine redeploy with non-redeploys
gpsData = gpsData %>% 
  filter(!(tag_id %in% unique(redeployList$tag_id))) %>% 
  mutate(deployment_id = paste0("M",tag_id)) %>% 
  bind_rows(gpsRedeploy)

# QA/QC
# Check for correct number of collars (should be 24)
length(unique(gpsData$deployment_id))

rm(a,tag,start1,start2,end1, redeploy_df,redeploy_time,gpsRedeploy,redeployList)

# Format corrected dataset ----
# Create unique row number, RowID, for each device in ascending order according to date/time. Note that RowID will be unique within but not across individuals. This will replace the "No" column that exists in the original GPS data.
# Drop unnecessary columns
# Create unique mooseYear ID based on local datetime
gpsData = gpsData %>%
  mutate(LMT_Date = as.Date(LMT_Date, format = "%m/%d/%Y"),
    mooseYear = paste(deployment_id,
                           as.numeric(year(LMT_Date)),
                           sep=".")) %>% 
group_by(deployment_id) %>%
  arrange(datetime) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>%
  arrange(deployment_id,RowID) %>%
  ungroup() %>%
  dplyr::select(-c(No,tag_id)) %>%
  dplyr::select(RowID,everything())

# Join with deployment metadata to get individual animal ID
# Useful when uploading into Movebank.
deploy = deploy %>% dplyr::select(animal_id,deployment_id)
gpsData = left_join(gpsData,deploy,by="deployment_id")

# Remove mortality data ----
# Collars performed well and only had minor problems
# Largely outside of calving season and linked with mortality or start of deployment

# In previous iteration of the code, I looked at each ID manually to pinpoint issues related to missed fixes. On top of being time-consuming, the exercise revealed 2 primary issues that explained almost all of the missed fixes:
# 1) Individual had died (oftentimes the individual died several hours/days before the first mortality signal was received)
# 2) Collar had just been deployed (some collars took ~5-7 fixes before starting to send consistent fix rates; one collar sent out a "Mortality" signal a few hours after being placed)

# Automated version: Run through each id. Delete the first 10 data points. Detect the first instance when the collar recorded a "Mortality no radius" signal (if signal was detected). Delete every instance after that (print out a warning if number of points > 100) and the 84 points preceding that (equivalent to 1 week of data).

ids = unique(gpsData$deployment_id)

for (i in 1:length(ids)){
  
  cat("working on individual...", ids[i], "\n")
  
  gps_subset = gpsData %>% 
    filter(deployment_id == ids[i]) %>% 
    filter(RowID > 10)
  
  mort_idx = gps_subset %>% 
    filter(mortalityStatus=="Mortality no radius")
  
  if(nrow(mort_idx) > 0){ 
    mort_idx = min(mort_idx$RowID-84)
    difference = nrow(gps_subset)-mort_idx
    
    if (difference > 200) {
      cat("Discarding...", difference, "rows out of...", nrow(gps_subset), "\n")
    }
    
    gps_subset = gps_subset %>% 
      filter(RowID < mort_idx)
  } else {
  }
  
  if (i == 1) {
    gpsClean = gps_subset
  } else {
    gpsClean = bind_rows(gpsClean,gps_subset)
  }
}

# Total number of rows deleted (n=6769, or 2.75% of the dataset) is only slightly higher than in the previous, manual iteration (n= 5976 / 2.4% of the data)
rm(gpsData,gps_subset,mort_idx,i)

# Recode RowID
gpsClean = gpsClean %>%
  group_by(deployment_id) %>%
  arrange(datetime) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>%
  arrange(deployment_id,RowID)

# Calculate time between fixes ----

# Project coordinates
# Convert to sf object; this works well with the move2 package
# Use EPSG:3338 (NAD83 / Alaska Albers)
gpsClean = st_as_sf(gpsClean, 
                     coords = c("longX", "latY"), 
                     crs = 4326, remove = FALSE)
gpsClean = st_transform(gpsClean, crs = 3338)

# Convert to move object
gpsMove = mt_as_move2(gpsClean, 
                       time_column="datetime", 
                       sf_column_name = c("geometry"),
                       track_id_column="deployment_id",
                       crs = 3338)

mt_n_tracks(gpsMove) # no of individuals
table(mt_track_id(gpsMove)) # no of locations per individuals

# Ensure dataframe is ordered properly
gpsMove = gpsMove %>%
  arrange(deployment_id,RowID)

# Calculate time between locations ----
# Express as hours to match programmed fix rate (2 hours)
gpsMove$timeLags = mt_time_lags(gpsMove)
gpsMove$timeLags = units::set_units(gpsMove$timeLags, h)
gpsMove$timeLags = as.numeric(gpsMove$timeLags)

# Filter entries for which time lags are below a certain threshold
# In this dataset, most entries with time lags < 2 hours are either very close to zero (i.e., duplicated fixes) or >1.5 hours. I picked 0.6, but the difference in the number of rows between 0.1, 0.2, 0.3, ... 1.5 are minimal
gpsMove = gpsMove %>% filter(!(timeLags<0.6))

# Calculate new time lags
gpsMove$timeLags = mt_time_lags(gpsMove)
gpsMove$timeLags = units::set_units(gpsMove$timeLags, h)
gpsMove$timeLags = as.numeric(gpsMove$timeLags)

# Calculate descriptive statistics
# To provide a sense of how well the collars performed for each individual
for (i in 1:length(ids)){
  
  cat("working on individual...", ids[i], "\n")
  
  gps_subset = gpsMove %>% 
    filter(deployment_id == ids[i] & !is.na(timeLags))
  
  summary = data.frame(row.names = ids[i])
  summary$id = ids[i]
  summary$min = min(gps_subset$timeLags)
  summary$mean = mean(gps_subset$timeLags)
  summary$sd = sd(gps_subset$timeLags)
  summary$max = max(gps_subset$timeLags)
  
  if (i == 1) {
    time_summary = summary
  } else {
    time_summary = bind_rows(time_summary,summary)
  }
}

# Clearly some missed fixes in the dataset, but we can deal with those on a case-by-case basis as we progress in our analyses

# Export data ----
gpsClean = as.data.frame(gpsMove)

# Remove extraneous columns
gpsClean = gpsClean %>% 
  select(-c(geometry,timeLags))

write_csv(gpsClean, file=output_path)

# Clean workspace ----
rm(list = ls())
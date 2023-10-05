# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Format GPS data
# Author: Amanda Droghini, Alaska Center for Conservation Science
# Last Updated: 2023-10-05
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: "Format GPS data" projects location coordinates, re-codes collar ID to account for redeployments, and renames column.
# ---------------------------------------------------------------------------

rm(list=ls())

# Load packages ----
library(dplyr)
library(readr)
library(sf)
library(tidyr)

# Define directories ----
drive <- "D:"
root_folder <- "ACCS_Work/Projects/Moose_SouthwestAlaska"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")

# Define code repository ----
git_dir <- file.path(drive, "ACCS_Work/GitHub/swak-moose-calving/package_TelemetryFormatting")

# Load functions ----
source(file.path(git_dir,"function-collarRedeploys.R"))

# Define inputs ----
gps_file <- file.path(pipeline_dir,"01_importData/raw_gps_data.csv")
deploy_file <- file.path(pipeline_dir,"01_createDeployMetadata/deployMetadata.Rdata")

# Load data ----
gpsData <- read_csv(gps_file)
load(deploy_file)

# Format GPS data ----
# 1. Filter out records for which Date Time, Lat, or Lon is NA
# 2. Filter out records with longitude values that are beyond the easternmost extent of our study area boundary. Some fixes had values of 13.xx, which is in Germany where collars are manufactured. 
# 3. Combine date and time in a single column ("datetime"). Use UTC rather than local time to conform with Movebank requirements.
# 4. Rename columns
gpsData <- gpsData %>%
  dplyr::mutate(datetime = as.POSIXlt(paste(gpsData$UTC_Date, gpsData$UTC_Time),
                               format="%m/%d/%Y %H:%M:%S",tz="GMT")) %>%
  dplyr::rename(longX = "Longitude....", latY = "Latitude....", tag_id = CollarID,
                mortalityStatus = "Mort..Status") %>%
  filter(!(is.na(longX) | is.na(latY) | is.na(UTC_Date))) %>%
  filter(longX < -153)

# QA/QC to make sure the datetime was coded properly
gpsData %>% filter(is.na(gpsData$datetime))

# Project coordinates ----
# Convert coordinates to sf object
# Use EPSG:3338 (NAD83 / Alaska Albers)
gpsData <- st_as_sf(gpsData, coords = c("longX", "latY"), crs = 4326, remove = FALSE)
gpsData <- st_transform(gpsData, crs = 3338)

# st_coordinates(gpsData[,1]) # to extract geometry

# Correct redeploys ----
# Identify which collars have been redeployed. Redeployed collars are differentiated from non-redeploys because they end in a letter
redeployList <- deploy %>%
  filter(sensor_type == "GPS" & (grepl(paste(letters, collapse="|"), deployment_id))) %>%
  dplyr::select(deployment_id,tag_id,deploy_on_timestamp,deploy_off_timestamp)

gpsData <- gpsData %>% 
  mutate(tagStatus = case_when(tag_id %in% redeployList$tag_id ~ "redeploy",
                               .default = "unique"))


# Format LMT Date column as POSIX data type for easier filtering
gpsData$LMT_Date = as.POSIXct(strptime(gpsData$LMT_Date,
                                       format="%m/%d/%Y",tz="America/Anchorage"))

# Split dataset into two and apply function to redeploys
gpsRedeployOnly <- subset(gpsData,tagStatus=="redeploy")
gpsUniqueOnly <- subset(gpsData,tagStatus!="redeploy")

gpsRedeployOnly$deployment_id <- apply(X=gpsRedeployOnly,MARGIN=1,FUN=makeRedeploysUnique,redeployData=redeployList) # Throws an error as of 2023-10-05

# Filter out errors
# Combine redeploy with non-redeploys
gpsRedeployOnly <- subset(gpsRedeployOnly,deployment_id!="error")
gpsUniqueOnly$deployment_id <- paste0("M",gpsUniqueOnly$tag_id,sep="")

gpsData <- rbind(gpsUniqueOnly,gpsRedeployOnly)

# Check
unique(gpsData$deployment_id)
length(unique(gpsData$deployment_id)) # Should be 24

# Clean workspace
rm(gpsRedeployOnly,gpsUniqueOnly,redeployList,makeRedeploysUnique,tagRedeploy)

#### Additional formatting----

# Create unique row number
# For each device, according to date/time
# Note that RowID will be unique within but not across individuals

# Drop unnecessary columns

# Create unique mooseYear ID

gpsData <- gpsData %>%
  mutate(mooseYear = paste(deployment_id,year(gpsData$LMT_Date),sep=".")) %>% 
group_by(deployment_id) %>%
  arrange(datetime) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>%
  arrange(deployment_id,RowID) %>%
  ungroup() %>%
  dplyr::select(-c(No,tagStatus,LMT_Date,LMT_Time,tag_id)) %>%
  dplyr::select(RowID,everything())

# Join with deployment metadata to get individual animal ID
# Useful when uploading into Movebank.
deploy <- deploy %>% dplyr::select(animal_id,deployment_id)

gpsData <- left_join(gpsData,deploy,by="deployment_id")

# Coerce back to dataframe (needed for move package)
gpsData <- as.data.frame(gpsData)

##### Export data ----
# Save as .Rdata file
save(gpsData, file=paste0(pipeline_dir,"02_formatData/gpsData_formatted.Rdata"))

#### Clean workspace ----
rm(list = ls())
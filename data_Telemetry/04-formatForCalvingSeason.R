# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Restrict to Calving Season
# Author: Amanda Droghini, Alaska Center for Conservation Science
# Last Updated: 2023-10-31
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: "Restrict to Calving Season" subsets GPS collar data to include only calving season (from May 10th to first week of June), adds Boolean calf status variable, and creates a unique ID for each moose-year-calf status combination. The script also explores sample size to ensure sufficient relocations for each moose-year.
# ---------------------------------------------------------------------------

# Notes: 
# 1) Calving period dates defined based on Kassie's work on the Watana moose population and the end dates of aerial surveys for this project (dictates when we stop having information on calf survival status). End dates of daily aerial surveys: June 4 for 2018, June 6 for 2019, 31 May for 2020.
# 2) VHF individuals had very few relocations during the calving season (57% of moose-year-calves had fewer than 5 relocs). In addition, generating random paths will be complicated by the inconsistent time intervals between relocations (not daily). We think it will be more worthwhile to keep the VHF data for model validation and do not include VHF individuals in this script.

rm(list = ls())

# Load packages ----
library(dplyr)
library(ggplot2)
library(lubridate)
library(move2)
library(sf)
library(tidyr)

# Define directories ----
drive <- "D:"
root_folder <- file.path(drive,"ACCS_Work")
project_folder <- file.path(root_folder, "Projects/Moose_SouthwestAlaska")
input_dir <- file.path(project_folder, "Data_01_Input")
pipeline_dir <- file.path(project_folder, "Data_02_Pipeline")
output_dir <- file.path(project_folder,"Data_03_Output")

# Define inputs ----
gps_file <- file.path(pipeline_dir,"03b_cleanLocations/cleanLocations.Rdata")
parturience_file <- file.path(pipeline_dir,"01-formatParturienceVariable/parturienceData.Rdata")

# Define output ----
output_path <- file.path(output_dir,"animalData","cleanedGPSCalvingSeason.csv")

# Read in data -----
load(gps_file)
load(parturience_file)

# Create calf status variable ----
# Merge information about calf survival from daily flights (calfData) with GPS collar data based on local data
calvingSeason = gpsClean %>%
  mutate(AKDT_Date = as.Date(datetime)) %>%  # Create local date column to merge with deployment metadata file
  left_join(calfData,by = c("deployment_id", "AKDT_Date")) %>% # Merge collar data with deployment metadata 
  select(-sensor_type) %>% 
  dplyr::filter(!is.na(calfStatus)) # Drop observations that do not have a calf status associated with it, effectively restricting the dataset to the calving season

# Graph calf status for one year to see if that worked
calvingSeason %>% 
  dplyr::filter(year(AKDT_Date) == 2018) %>% 
  ggplot(aes(AKDT_Date,calfStatus)) + 
  geom_point() +
  scale_x_date(date_breaks = ("4 days")) +
  theme_bw()

# Ensure there are no mortality signals in the dataset
unique(calvingSeason$mortalityStatus)

# Create unique moose-year-calf ID ----
# Recode deployment_id to include year and calf status
# We are treating paths from different calving seasons as independent
calvingSeason = calvingSeason %>%
  mutate(mooseYear_id = paste(deployment_id,year(AKDT_Date),
                              paste0("calf",calfStatus),sep="_")) %>% 
  select(-mortalityStatus) %>%
  group_by(mooseYear_id) %>%
  arrange(datetime,.by_group=TRUE) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>% # Create RowID variable for sorting
  ungroup()

# Explore sample size ----

# 24 unique female individuals
length(unique(calvingSeason$deployment_id)) 

# Sampling unit is the path = moose x year x calf 
# Total of 80 paths
# 49 paths with calves, 31 without
length(unique(calvingSeason$mooseYear_id)) 
nrow(calvingSeason %>% filter(calfStatus=="1") %>% 
       distinct(mooseYear_id))

# Number of locations per path ranges from 12 to 324
# 12 paths have fewer than 30 relocations
frequency_table = calvingSeason %>% 
  group_by(mooseYear_id) %>% 
  summarize(count = n())

summary(frequency_table$count)
nrow(frequency_table %>% dplyr::filter(count < 30)) 

# How many unique paths per female?
calvingSeason %>% 
  group_by(deployment_id) %>% 
  distinct(mooseYear_id) %>% 
  mutate(count = 1) %>% 
  summarize(unique_paths = sum(count)) %>% 
  ungroup() %>%  
  summarize(mean_paths = mean(unique_paths), 
            stdev = sd(unique_paths), 
            minim = min(unique_paths), 
            maxim = max(unique_paths))

# How many years per female?
calvingSeason %>% 
  mutate(year = lubridate::year(AKDT_Date)) %>% 
  group_by(deployment_id) %>% 
  distinct(year) %>% 
  mutate(count = 1) %>% 
  summarize(unique_years = sum(count)) %>% 
  ungroup() %>%  
  summarize(mean_years = mean(unique_years), 
            stdev = sd(unique_years), 
            minim = min(unique_years), 
            maxim = max(unique_years))

# How many females present in all 3 years?
calvingSeason %>% 
  mutate(year = lubridate::year(AKDT_Date)) %>% 
  group_by(deployment_id) %>% 
  distinct(year) %>% 
  mutate(count = 1) %>% 
  summarize(unique_years = sum(count)) %>% 
  filter(unique_years==max(unique_years)) %>% 
  nrow()

# Explore time between locations ----

# Convert to spatial object (sf then move)
gpsMove = st_as_sf(calvingSeason, 
                   coords = c("longX", "latY"), 
                   crs = 4326, remove = FALSE)
gpsMove = st_transform(gpsMove, crs = 3338)
gpsMove = mt_as_move2(gpsMove, 
                      time_column="datetime", 
                      sf_column_name = c("geometry"),
                      track_id_column="mooseYear_id",
                      crs = 3338)

# Ensure dataframe is ordered properly
gpsMove = gpsMove %>%
  arrange(mooseYear_id,RowID)

# Ensure move recognizes proper sampling unit
mt_n_tracks(gpsMove)

# Calculate time lags
# Express as hours to match programmed fix rate (2 hours)
# Median & mean time interval: 2 hours
# Minimum: 1.96 h
# Maximum: 4 h
gpsMove$timeLags = mt_time_lags(gpsMove)
gpsMove$timeLags = units::set_units(gpsMove$timeLags, h)
gpsMove$timeLags = as.numeric(gpsMove$timeLags)

summary(gpsMove$timeLags)

# Export data ----
# Save as .Rdata file
save(calvingSeason, file=file.path(pipeline_dir,
                                "04-formatForCalvingSeason",
                                "gpsCalvingSeason.Rdata"))
write_csv(calvingSeason, file=output_file)

# Clean workspace ----
rm(list = ls())
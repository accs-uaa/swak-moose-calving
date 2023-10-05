# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Import GPS data from Separate CSVs
# Author: Amanda Droghini, Alaska Center for Conservation Science
# Last Updated: 2023-10-05
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: "Import GPS data from Separate CSVs" reads all data containing GPS locations from moose collars, excludes mortality files, and combines files into a single dataframe that can be used for analyses. GPS data were last downloaded on 2021-03-14.
# ---------------------------------------------------------------------------

rm(list=ls())

# Load packages ----
library(plyr)
library(readr)
library(tidyr)
library(dplyr)

# Define directories ----
drive <- "D:"
root_folder <- "ACCS_Work/Projects/Moose_SouthwestAlaska"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")

# Define inputs ----
# Use pattern="GPS" to drop Mortality files
# Should have 22 files
filePath <- paste0(input_dir,"/telemetry")
dataFiles <- list.files(file.path(filePath),full.names = TRUE,pattern="GPS")

# Define outputs ----
output_path <- file.path(pipeline_dir,"01_importData","raw_gps_data.csv")

# Load data ----

# Decipher encoding since column names have non-ASCII characters
guess_encoding(dataFiles[1])

# Read each file and combine into single dataframe
# Select only relevant columns
# See https://www.vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-X_v1.2.1.pdf) page 125 for meaning of column names

for (i in 1:length(dataFiles)) {
  f <- dataFiles[i]

  temp <- read_csv(f, locale = locale(encoding = "ISO-8859-1"),
                   col_select=c(1:6,13,14,16,17,44),
                   name_repair = make.names)

  if (i == 1) {
    gpsData <- temp

  } else {
    gpsData <- plyr::rbind.fill(gpsData, temp)
  }
}

# Verify that all individuals have been imported (should include the number of files)
length(unique(gpsData$CollarID)) == length(dataFiles)

# Clear virtual memory
rm(temp,dataFiles,f,i)
gc()

# Export as CSV ----
write_csv(gpsData, file=output_path)

# Clean workspace ----
rm(list=ls())
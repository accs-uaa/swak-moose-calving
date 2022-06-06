# Define directories
drive <- "C:"
root_folder <- "ACCS_Work/GMU_17_Moose"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")
output_dir <- file.path(drive, root_folder, "Data_03_Output")
geoDB <- file.path(drive, root_folder, "GIS/Moose_SouthwestAlaska.gdb")

# Data management packages
library(plyr)
library(tidyverse)
library(lubridate)
library(readxl)

# Spatial packages
library(sp)
library(rgdal)

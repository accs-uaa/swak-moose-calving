# Define directories
drive <- "C:"
root_folder <- "ACCS_Work/Projects/Moose_SouthwestAlaska"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")
output_dir <- file.path(drive, root_folder, "Data_03_Output","pathSelectionFunction")

# Data management packages
library(tidyverse)

# Statistics packages
library(infer)
library(glmmTMB)

# Functions to fit model & extract estimates
source(paste0(git_dir,"modelRunExploratory.R"))
source(paste0(git_dir,"modelRunBootstrap.R"))
source(paste0(git_dir,"summarizeModelEstimates.R"))
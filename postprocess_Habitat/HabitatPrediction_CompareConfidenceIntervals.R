# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Plot prediction distributions
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2021-08-29
# Usage: Script should be executed in R 4.0.0+.
# Description: "Plot prediction distributions" creates a plot of the distribution of standardized predictions by calf status.
# ---------------------------------------------------------------------------

# Set root directory
drive = 'N:'
root_folder = 'ACCS_Work'

# Define input data
data_folder = paste(drive,
                    root_folder,
                    'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data',
                    sep = '/')
nocalf_file = paste(data_folder,
                    'Data_Output/data_package/version_1.2_20210820',
                    'allPoints_Observed_Predicted_0.csv',
                    sep = '/')

# Import libraries
library(boot)
library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(simpleboot)
library(tidyr)

# Import data to data frame and pivot to long form
nocalf_data = read.csv(nocalf_file)
nocalf_data = nocalf_data %>%
  select(-mooseyear_id, -pointID, -calf_status, -deployment_id, -fullPath_id,
         -calf_select, - calf_ci95, -nocalf_select, -nocalf_ci95, -x, -y) %>%
  pivot_longer(!fullPoint_id, names_to = 'iteration', values_to = 'selection')

# Generate list of CID
nocalf_ids = nocalf_data %>%
  select(fullPoint_id) %>%
  unique()
nocalf_ids = nocalf_ids[['fullPoint_id']]

# Subset the data to a point of choice for comparison
subset = nocalf_data %>%
  filter(fullPoint_id == nocalf_ids[10])

# Convert subset data to vector
d = subset[['selection']]

# Calculate confidence intervals by bootstrap (compare these to the confidence interval width raster values)
boot.obj = one.boot(d, FUN = mean, R = 500)
boot.ci(boot.obj, conf = 0.95, type = 'all')
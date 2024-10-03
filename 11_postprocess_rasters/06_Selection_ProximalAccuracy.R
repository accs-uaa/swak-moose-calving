# ---------------------------------------------------------------------------
# Calculate proximal accuracy
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2021-10-06
# Usage: Script should be executed in R 4.1.0+.
# Description: "Calculate proximal accuracy" calculates the proximity accuracy of independent VHF validation data relative to landscape mean distance to habitat.
# ---------------------------------------------------------------------------

# Define version
round = 'round_20210820'

# Set root directory
drive = 'N:'
root_folder = 'ACCS_Work'

# Define input data
data_folder = paste(drive,
                    root_folder,
                    'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data/Data_Output/analysis_rasters',
                    round,
                    sep = '/')
togiak_file = paste(data_folder,
                    'cleanedVHFdata_Togiak_Extracted.csv',
                    sep = '/')
nushagak_file = paste(data_folder,
                      'cleanedVHFdata_Nushagak_Extracted.csv',
                      sep = '/')

# Import libraries
library(dplyr)
library(tidyr)

# Import data to data frame
togiak_data = read.csv(togiak_file)
nushagak_data = read.csv(nushagak_file)

# Parse data into maternal and non-maternal groups
togiak_summary = togiak_data %>%
  drop_na() %>%
  select(calfStatus, distance_calf, distance_nocalf, mean_calf, mean_nocalf) %>%
  group_by(calfStatus) %>%
  summarize(sample_n = n(),
            sample_calf = mean(distance_calf),
            sample_nocalf = mean(distance_nocalf),
            mean_calf = mean(mean_calf),
            mean_nocalf = mean(mean_nocalf)) %>%
  mutate(accuracy = case_when(calfStatus == 1 ~ (mean_calf - sample_calf) / mean_calf,
                              calfStatus == 0 ~ (mean_nocalf - sample_nocalf) / mean_nocalf,
                              TRUE ~ 0))
nushagak_summary = nushagak_data %>%
  drop_na() %>%
  select(calfStatus, distance_calf, distance_nocalf, mean_calf, mean_nocalf) %>%
  group_by(calfStatus) %>%
  summarize(sample_n = n(),
            sample_calf = mean(distance_calf),
            sample_nocalf = mean(distance_nocalf),
            mean_calf = mean(mean_calf),
            mean_nocalf = mean(mean_nocalf)) %>%
  mutate(accuracy = case_when(calfStatus == 1 ~ (mean_calf - sample_calf) / mean_calf,
                              calfStatus == 0 ~ (mean_nocalf - sample_nocalf) / mean_nocalf,
                              TRUE ~ 0))
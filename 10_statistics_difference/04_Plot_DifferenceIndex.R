# ---------------------------------------------------------------------------
# Plot Distribution of Locally Standardized Maternal Tradeoff
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2022-03-07
# Usage: Script should be executed in R 4.1.0+.
# Description: "Plot Distribution of Locally Standardized Maternal Tradeoff" creates a plot of the distribution of the locally standardized maternal tradeoff intensity predictions by calf status.
# ---------------------------------------------------------------------------

# Set root directory
drive = 'N:'
root_folder = 'ACCS_Work'

# Define input data
data_folder = paste(drive,
                    root_folder,
                    'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data',
                    sep = '/')
input_file = paste(data_folder,
                   'Data_Output/analysis_tables',
                   'allPoints_Observed_Tradeoff.csv',
                   sep = '/')

# Import libraries
library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(tidyr)

# Import data to data frame
tradeoff_results = read.csv(input_file)

# Plot the results
plot = ggplot(tradeoff_results, aes(x=tradeoff_dist)) +
  geom_histogram(aes(y = ..count..),
                 bins=30, alpha=0.4, position = 'identity') +
  theme_minimal()
plot
# ---------------------------------------------------------------------------
# Calculate tradeoff, distribution tradeoff, and standardized tradeoff for observed paths
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2021-08-29
# Usage: Script should be executed in R 4.0.0+.
# Description: "Calculate tradeoff, distribution tradeoff, and standardized tradeoff for observed paths" creates a data frame of tradeoff values from all combinations of calf and no calf selection predictions.
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
                    'Data_Output/analysis_tables',
                    'allPoints_Observed_Predicted_0.csv',
                    sep = '/')
calf_file = paste(data_folder,
                  'Data_Output/analysis_tables',
                  'allPoints_Observed_Predicted_1.csv',
                  sep = '/')
join_file = paste(data_folder,
                  'Data_Output/analysis_tables',
                  'allPoints_Observed_Selection.csv',
                  sep = '/')

# Define output file
output_file = paste(data_folder,
                    'Data_Output/analysis_tables',
                    'allPoints_Observed_Tradeoff.csv',
                    sep = '/')

# Import libraries
library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(tibble)
library(tidyr)

# Import data to data frame
nocalf_data = read.csv(nocalf_file)
calf_data = read.csv(calf_file)
join_data = read.csv(join_file)

# Pivot data to long form
nocalf_data = nocalf_data %>%
  select(-mooseyear_id, -pointID, -calf_status, -deployment_id, -fullPath_id,
         -calf_select, - calf_ci95, -nocalf_select, -nocalf_ci95, -x, -y) %>%
  pivot_longer(!fullPoint_id, names_to = 'iteration', values_to = 'selection')
calf_data = calf_data %>%
  select(-mooseyear_id, -pointID, -calf_status, -deployment_id, -fullPath_id,
         -calf_select, - calf_ci95, -nocalf_select, -nocalf_ci95, -x, -y) %>%
  pivot_longer(!fullPoint_id, names_to = 'iteration', values_to = 'selection')

# Generate list of CID
point_ids = nocalf_data %>%
  select(fullPoint_id) %>%
  unique()
point_ids = point_ids[['fullPoint_id']]

# Create empty vector to store results data frames
results_list = list()

# Loop through each set of values and subtract all other values
count = 1
for (id in point_ids) {
  print(paste('Calculating tradeoff for point ',
              toString(count),
              ' of ',
              toString(length(point_ids)),
              '...',
              sep = ''))
  
  # Subset the calf and no calf data
  calf_subset = calf_data %>%
    filter(fullPoint_id == id)
  nocalf_subset = nocalf_data %>%
    filter(fullPoint_id == id)
  
  # For each calf prediction, subtract all no calf predictions
  i = 1
  tradeoff_list = c()
  while (i <= 50) {
    calf_value = calf_subset$selection[i]
    n = 1
    while (n <= 50) {
      nocalf_value = nocalf_subset$selection[n]
      tradeoff = calf_value - nocalf_value
      tradeoff_list = append(tradeoff_list, tradeoff)
      # Increase counter
      n = n + 1
    }
    # Increase counter
    i = i + 1
  }
  
  # Calculate point specific minimum, maximum, and range
  min_local = min(tradeoff_list)
  max_local = max(tradeoff_list)
  range = max_local - min_local
  
  # Convert list into data frame and calculate tradeoff distribution
  results = as.data.frame(tradeoff_list) %>%
    rename(tradeoff = tradeoff_list) %>%
    mutate(tradeoff_dist = (tradeoff - min_local) / (range)) %>%
    mutate(fullPoint_id = id) %>%
    rowid_to_column('sample_id')
  
  # Append results data frame to results list
  results_list = c(list(results), results_list)
  
  # Increase counter
  count = count + 1
}

# Bind all rows into single data frame
all_results = bind_rows(results_list)

# Identify max and min values
min_tradeoff = min(all_results$tradeoff)
max_tradeoff = max(all_results$tradeoff)
range = max_tradeoff - min_tradeoff

# Adjust maternal tradeoff values to standardized scale between 0 and 1
adjusted_results = all_results %>%
  mutate(tradeoff_standard = (tradeoff - min_tradeoff) / range)

# Prepare join data
join_data = join_data %>%
  select(mooseyear_id, x, y, calf_status, fullPath_id, fullPoint_id)

# Join additional data to adjusted results
output_results = adjusted_results %>%
  inner_join(join_data, by = 'fullPoint_id') %>%
  select(mooseyear_id, sample_id, calf_status, fullPath_id, fullPoint_id, x, y,
         tradeoff, tradeoff_dist, tradeoff_standard)

# Export sample results to csv
write.csv(output_results, file = output_file, fileEncoding = 'UTF-8', row.names = FALSE)
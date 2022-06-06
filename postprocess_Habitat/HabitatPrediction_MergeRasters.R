# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Merge Predicted Rasters
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2021-08-20
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: "Merge Predicted Rasters" merges the predicted grid rasters into a single output raster for selection mean, 95% confidence interval width, and binary significance (p=0.05).
# ---------------------------------------------------------------------------

# Set root directory
root_folder = 'N://ACCS_Work/Projects/WildlifeEcology/Moose_SouthwestAlaska/Data/Data_Output/'

# Define round
round_date = 'round_20210820'

# Set map class folder
map_class = 'Calf'

# Define input folders
mean_folder = paste(root_folder,
                    'predicted_rasters',
                    round_date,
                    map_class,
                    'mean',
                    sep = '/'
                    )
ci_folder = paste(root_folder,
                  'predicted_rasters',
                  round_date,
                  map_class,
                  'ci',
                  sep = '/'
                  )
significance_folder = paste(root_folder,
                            'predicted_rasters',
                            round_date,
                            map_class,
                            'significance',
                            sep = '/'
                            )
# Define list of input folders
input_folders = c(mean_folder, ci_folder, significance_folder)

# Define output folder
merged_folder = paste(root_folder,
                      'rasters_merged',
                      round_date,
                      map_class,
                      sep = '/'
                      )

# Define output files
output_mean = paste(merged_folder, 
                    '/',
                    'SouthwestAlaska_Moose_Calving_',
                    map_class,
                    '_SelectionMean.tif',
                    sep = '')
output_ci = paste(merged_folder,
                  '/',
                  'SouthwestAlaska_Moose_Calving_',
                  map_class,
                  '_CI95Width.tif',
                  sep = '')
output_significance = paste(merged_folder,
                            '/',
                            'SouthwestAlaska_Moose_Calving_',
                            map_class,
                            '_Significance.tif',
                            sep = '')
# Define list of output files
output_files = c(output_mean, output_ci, output_significance)

# Import required libraries for geospatial processing: sp, raster, rgdal, and stringr.
library(sp)
library(raster)
library(rgdal)

# Loop through each raster type and merge rasters
i = 1
while(i <= 3) {
  # Select input folder
  input_folder = input_folders[i]
  
  # Select output file
  output_file = output_files[i]
  
  # Generate list of raster img files from input folder
  raster_files = list.files(path = input_folder, pattern = ".img$", full.names = TRUE)
  count = length(raster_files)
  
  # Convert list of files into list of raster objects
  start = proc.time()
  print(paste('Compiling ', toString(count), ' rasters...'))
  raster_objects = lapply(raster_files, raster)
  # Add function and filename attributes to list
  raster_objects$fun = max
  raster_objects$filename = output_file
  raster_objects$overwrite = TRUE
  raster_objects$options = c('TFW=YES')
  end = proc.time() - start
  print(paste('Completed in ', end[3], ' seconds.', sep = ''))
  
  # Merge rasters
  start = proc.time()
  print(paste('Merging ', toString(count), ' rasters...'))
  merged_raster = do.call(mosaic, raster_objects)
  end = proc.time() - start
  print(paste('Completed in ', end[3], ' seconds.', sep = ''))
  
  # Increase counter
  i = i + 1
}

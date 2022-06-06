# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Convert Habitat Predictions to Raster
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2021-08-20
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: "Convert Habitat Predictions to Raster" processes the selection predictions in csv tables into rasters in img format. Raster outputs are in the same coordinate system that grids were exported in but will not be associated with that projection. Three rasters are produced per grid: the selection mean, 95% confidence interval width, and binary significance (p = 0.05).
# ---------------------------------------------------------------------------

# Set root directory
root_folder = 'N://ACCS_Work/Projects/WildlifeEcology/Moose_SouthwestAlaska/Data/Data_Output/'

# Define round
round_date = 'round_20210820'

# Set map class folder
map_class = 'Calf'

# Define input folder
prediction_folder = paste(root_folder,
                          'predicted_tables',
                          round_date,
                          map_class,
                          sep = '/'
                          )
# Define output folders
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

# Import required libraries for geospatial processing: sp, raster, rgdal, and stringr.
library(sp)
library(raster)
library(rgdal)
library(stringr)

# Generate a list of all predictions in the predictions directory
prediction_list = list.files(prediction_folder, pattern='csv$', full.names=TRUE)
prediction_length = length(prediction_list)

# Define a function to convert the prediction csv to a raster and export an img raster file
convert_predictions = function(input_data, output_raster, z_column) {
  prediction_data = input_data[,c('x', 'y', z_column)]
  prediction_raster = rasterFromXYZ(prediction_data, res=c(10,10), crs='+init=EPSG:3338', digits=5)
  writeRaster(prediction_raster, output_raster, format='HFA', overwrite=TRUE)
}

# Create raster files for each prediction table in the predictions directory
count = 1
for (prediction in prediction_list) {
  # Define input and output data
  input_data = read.csv(prediction)
  mean_raster = paste(mean_folder, '/', sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(prediction)), '_mean.img', sep='')
  ci_raster = paste(ci_folder, '/', sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(prediction)), '_ci.img', sep='')
  significance_raster = paste(significance_folder, '/', sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(prediction)), '_sig.img', sep='')
  
  # Create output mean raster if it does not already exist
  if (!file.exists(mean_raster)) {
    # Convert table to raster
    convert_predictions(input_data, mean_raster, 'selection_mean')
    print(paste('Selection mean raster conversion iteration ', toString(count), ' out of ', toString(prediction_length), ' completed...', sep=''))
    print('----------')
  } else {
    print(paste('Raster ', toString(count), ' out of ', toString(prediction_length), ' already exists.', sep = ''))
    print('----------')
  }
  
  # Create output ci raster if it does not already exist
  if (!file.exists(ci_raster)) {
    # Convert table to raster
    convert_predictions(input_data, ci_raster, 'ci_width')
    print(paste('Selection 95% confidence interval width raster conversion iteration ', toString(count), ' out of ', toString(prediction_length), ' completed...', sep=''))
    print('----------')
  } else {
    print(paste('Raster ', toString(count), ' out of ', toString(prediction_length), ' already exists.', sep = ''))
    print('----------')
  }
  
  # Create output significance raster if it does not already exist
  if (!file.exists(significance_raster)) {
    # Convert table to raster
    convert_predictions(input_data, significance_raster, 'significance')
    print(paste('Selection significance raster conversion iteration ', toString(count), ' out of ', toString(prediction_length), ' completed...', sep=''))
    print('----------')
  } else {
    print(paste('Raster ', toString(count), ' out of ', toString(prediction_length), ' already exists.', sep = ''))
    print('----------')
  }
  
  count = count + 1
}
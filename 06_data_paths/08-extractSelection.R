# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Extract selection and confidence interval to paths
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2021-08-29
# Usage: Script should be executed in R 4.0.0+.
# Description: "Extract selection and confidence interval to paths" extracts the predicted mean selection and confidence interval widths for females with and without calves to all observed moose path-points.
# ---------------------------------------------------------------------------

# Set root directory
drive = 'N:'
root_folder = 'ACCS_Work'

# Define input data
data_folder = paste(drive,
                    root_folder,
                    'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data',
                    sep = '/')
geodatabase = paste(data_folder,
                    'Moose_SouthwestAlaska.gdb',
                    sep = '/')
calf_selection = paste(data_folder,
                       'Data_Output/data_package/version_1.2_20210820/Calf/rasters',
                       'SouthwestAlaska_Moose_Calving_Calf_Selection.tif',
                       sep = '/')
calf_ci95 = paste(data_folder,
                  'Data_Output/data_package/version_1.2_20210820/Calf/rasters',
                  'SouthwestAlaska_Moose_Calving_Calf_CI95Width.tif',
                  sep = '/')
nocalf_selection = paste(data_folder,
                         'Data_Output/data_package/version_1.2_20210820/NoCalf/rasters',
                         'SouthwestAlaska_Moose_Calving_NoCalf_Selection.tif',
                         sep = '/')
nocalf_ci95 = paste(data_folder,
                    'Data_Output/data_package/version_1.2_20210820/NoCalf/rasters',
                    'SouthwestAlaska_Moose_Calving_NoCalf_CI95Width.tif',
                    sep = '/')

# Define output csv file
output_csv = paste(data_folder,
                   'Data_Output/analysis_tables',
                   'allPoints_Observed_Selection.csv',
                   sep = '/')

# Import required libraries
library(dplyr)
library(raster)
library(rgdal)
library(sp)
library(tidyr)

# Create a list of all rasters
extract_rasters = c(calf_selection,
                    calf_ci95,
                    nocalf_selection,
                    nocalf_ci95)
print(paste('Number of extraction rasters: ', length(extract_rasters), sep = ''))

# Generate a stack of all covariate rasters
print('Creating raster stack...')
start = proc.time()
extract_stack = stack(extract_rasters)
end = proc.time() - start
print(end[3])

# Read path data and extract covariates
print('Extracting covariates...')
start = proc.time()
path_data = readOGR(dsn=geodatabase,layer="allPoints_Observed")
path_extracted = data.frame(path_data@data, raster::extract(extract_stack, path_data))
end = proc.time() - start
print(end[3])

# Convert field names to standard
path_extracted = path_extracted %>%
  dplyr::rename(calf_select = SouthwestAlaska_Moose_Calving_Calf_Selection) %>%
  dplyr::rename(calf_ci95 = SouthwestAlaska_Moose_Calving_Calf_CI95Width) %>%
  dplyr::rename(nocalf_select = SouthwestAlaska_Moose_Calving_NoCalf_Selection) %>%
  dplyr::rename(nocalf_ci95 = SouthwestAlaska_Moose_Calving_NoCalf_CI95Width) %>%
  dplyr::rename(calf_status = calfStatus) %>%
  dplyr::rename(mooseyear_id = mooseYear_id) %>%
  tidyr::drop_na()

# Export data as a csv
write.csv(path_extracted, file = output_csv, fileEncoding = 'UTF-8')
print('Finished extracting to paths.')
print('----------')
# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Apply mask to habitat prediction
# Author: Timm Nawrocki
# Last Updated: 2021-08-20
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Apply mask to habitat prediction" extracts the habitat prediction to a mask raster of the study area excluding areas mapped as water in the NLCD 2016.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import extract_to_boundary

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define round
round_date = 'round_20210820'
version = 'version_1.2_20210820'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')
input_folder = os.path.join(data_folder, 'Data_Output/rasters_merged', round_date)

# Define input rasters
raster_mask = os.path.join(data_folder, 'Data_Input/waterice_mask.tif')
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
calf_mean = os.path.join(input_folder,
                         'Calf/SouthwestAlaska_Moose_Calving_Calf_SelectionMean.tif')
calf_ci = os.path.join(input_folder,
                       'Calf/SouthwestAlaska_Moose_Calving_Calf_CI95Width.tif')
calf_significance = os.path.join(input_folder,
                                 'Calf/SouthwestAlaska_Moose_Calving_Calf_Significance.tif')
nocalf_mean = os.path.join(input_folder,
                           'NoCalf/SouthwestAlaska_Moose_Calving_NoCalf_SelectionMean.tif')
nocalf_ci = os.path.join(input_folder,
                         'NoCalf/SouthwestAlaska_Moose_Calving_NoCalf_CI95Width.tif')
nocalf_significance = os.path.join(input_folder,
                                   'NoCalf/SouthwestAlaska_Moose_Calving_NoCalf_Significance.tif')

# Define input raster list
input_rasters = [calf_mean, calf_ci, calf_significance, nocalf_mean, nocalf_ci, nocalf_significance]

# Loop through each raster in input rasters and extract to boundary
count = 1
for raster in input_rasters:
    # Define base name
    base_name = os.path.split(raster)[1]

    # Define output raster
    if raster == calf_mean or raster == calf_ci or raster == calf_significance:
        raster_output = os.path.join(data_folder,
                                     f'Data_Output/data_package/{version}/Calf/rasters/{base_name}')
    else:
        raster_output = os.path.join(data_folder,
                                     f'Data_Output/data_package/{version}/NoCalf/rasters/{base_name}')

    # If output raster does not already exist, create output raster
    if arcpy.Exists(raster_output) == 0:
        # Define input and output arrays
        extract_inputs = [raster, raster_mask, study_area]
        extract_outputs = [raster_output]

        # Create key word arguments
        extract_kwargs = {'no_data_replace': '',
                          'work_geodatabase': work_geodatabase,
                          'input_array': extract_inputs,
                          'output_array': extract_outputs
                          }

        # Combine raster tiles
        print(f'Extracting raster {count} of {len(input_rasters)} to mask...')
        arcpy_geoprocessing(extract_to_boundary, **extract_kwargs)
        print('----------')
        count += 1
    else:
        print(f'Output raster {count} of {len(input_rasters)} already exists.')
        print('----------')
        count += 1

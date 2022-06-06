# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare VHF Validation Data
# Author: Timm Nawrocki
# Last Updated: 2021-10-06
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare VHF Validation Data" extracts distance to calving habitat to VHF validation points and calculates a zonal mean distance from calving habitat within the bounds of the VHF points to provide a reference frame.
# ---------------------------------------------------------------------------

# Import packages
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import prepare_validation_points

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define round
round_date = 'round_20210820'
version = 'version_1.2_20210820'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')
input_folder = os.path.join(data_folder, 'Data_Input/validation_points')
output_folder = os.path.join(data_folder, 'Data_Output/analysis_rasters', round_date)

# Define input VHF data
togiak_points = os.path.join(work_geodatabase, 'cleanedVHFdata_Togiak')
nushagak_points = os.path.join(work_geodatabase, 'cleanedVHFdata_Nushagak')

# Define input spatial datasets
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
calf_distance = os.path.join(output_folder, 'SouthwestAlaska_Moose_Calving_Calf_Distance.tif')
nocalf_distance = os.path.join(output_folder, 'SouthwestAlaska_Moose_Calving_NoCalf_Distance.tif')

# Define output zonal mean datasets
togiak_calf = os.path.join(output_folder, 'SouthwestAlaska_Moose_Togiak_Calf_MeanDistance.tif')
togiak_nocalf = os.path.join(output_folder, 'SouthwestAlaska_Moose_Togiak_NoCalf_MeanDistance.tif')
nushagak_calf = os.path.join(output_folder, 'SouthwestAlaska_Moose_Nushagak_Calf_MeanDistance.tif')
nushagak_nocalf = os.path.join(output_folder, 'SouthwestAlaska_Moose_Nushagak_NoCalf_MeanDistance.tif')

# Define output csv files
togiak_export = os.path.join(output_folder, 'cleanedVHFdata_Togiak_Extracted.csv')
nushagak_export = os.path.join(output_folder, 'cleanedVHFdata_Nushagak_Extracted.csv')

# Define input and output datasets
input_lists = [[study_area, calf_distance, nocalf_distance, togiak_points],
               [study_area, calf_distance, nocalf_distance, nushagak_points]]
output_lists = [[togiak_calf, togiak_nocalf, togiak_export], [nushagak_calf, nushagak_nocalf, nushagak_export]]

# Loop through each raster in input rasters and extract to boundary
count = 1
for input_list in input_lists:
    # Define output list
    output_list = output_lists[count-1]

    # Create key word arguments
    validation_kwargs = {'work_geodatabase': work_geodatabase,
                         'input_array': input_list,
                         'output_array': output_list
                         }

    # Prepare validation data
    print(f'Preparing validation data and reference frame for dataset {count} of {len(output_lists)}...')
    arcpy_geoprocessing(prepare_validation_points, **validation_kwargs)
    print('----------')

    # Increase count
    count += 1

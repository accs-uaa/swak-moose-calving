# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Calculate Euclidean distance to habitat
# Author: Timm Nawrocki
# Last Updated: 2021-10-04
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Calculate Euclidean distance to habitat" converts continuous habitat to discrete habitat with non-habitat represented by -1, neutral habitat (or non-significant) represented by 0, and habitat represented by 1 and then calculates the Euclidean distance raster to values of 1.
# ---------------------------------------------------------------------------

# Import packages
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import convert_to_discrete
from package_GeospatialProcessing import calculate_raw_distance

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define round
round_date = 'round_20210820'
version = 'version_1.2_20210820'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')
input_folder = os.path.join(data_folder, 'Data_Output/data_package', version)
output_folder = os.path.join(data_folder, 'Data_Output/analysis_rasters', round_date)

# Define input rasters
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
calf_selection = os.path.join(input_folder,
                              'Calf/rasters/SouthwestAlaska_Moose_Calving_Calf_Selection.tif')
calf_significance = os.path.join(input_folder,
                                 'Calf/rasters/SouthwestAlaska_Moose_Calving_Calf_Significance.tif')
nocalf_selection = os.path.join(input_folder,
                                'NoCalf/rasters/SouthwestAlaska_Moose_Calving_NoCalf_Selection.tif')
nocalf_significance = os.path.join(input_folder,
                                   'NoCalf/rasters/SouthwestAlaska_Moose_Calving_NoCalf_Significance.tif')

# Define output rasters
calf_discrete = os.path.join(output_folder, 'SouthwestAlaska_Moose_Calving_Calf_Discrete.tif')
nocalf_discrete = os.path.join(output_folder, 'SouthwestAlaska_Moose_Calving_NoCalf_Discrete.tif')
calf_distance = os.path.join(output_folder, 'SouthwestAlaska_Moose_Calving_Calf_Distance.tif')
nocalf_distance = os.path.join(output_folder, 'SouthwestAlaska_Moose_Calving_NoCalf_Distance.tif')

# Define input and output datasets
input_lists = [[study_area, calf_selection, calf_significance],
               [study_area, nocalf_selection, nocalf_significance]]
discrete_list = [calf_discrete, nocalf_discrete]
distance_list = [calf_distance, nocalf_distance]

# Loop through each raster in input rasters and extract to boundary
count = 1
for input_list in input_lists:
    # Create key word arguments
    discrete_kwargs = {'threshold': 0,
                       'work_geodatabase': work_geodatabase,
                       'input_array': input_list,
                       'output_array': [discrete_list[count - 1]]
                       }
    distance_kwargs = {'value': 1,
                       'work_geodatabase': work_geodatabase,
                       'input_array': [study_area, discrete_list[count-1]],
                       'output_array': [distance_list[count-1]]}

    # Convert continuous selection to discrete habitat
    print(f'Converting continuous selection to discrete habitat for set {count} of {len(discrete_list)}...')
    arcpy_geoprocessing(convert_to_discrete, **discrete_kwargs)
    print('----------')

    # Calculate distance to discrete habitat
    print(f'Calculating distance to discrete habitat for for set {count} of {len(distance_list)}...')
    arcpy_geoprocessing(calculate_raw_distance, **distance_kwargs)
    print('----------')
    count += 1

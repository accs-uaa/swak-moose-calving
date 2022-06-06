# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare validation points
# Author: Timm Nawrocki
# Last Updated: 2021-10-06
# Usage: Must be executed in an ArcGIS Pro Python 3.6+ installation.
# Description: "Prepare validation points" is a function that extracts distances from point data and calculates a zonal mean distance within the bounds of the point data.
# ---------------------------------------------------------------------------

# Define a function to extract distance to points and calculate zonal mean
def prepare_validation_points(**kwargs):
    """
    Description: extracts distance for a set of input points and calculates zonal mean for the bounds of the points
    Inputs: 'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the study area raster (must be first), a continuous distance raster for maternal females, a continuous distance raster for non-maternal females, and a feature class of validation points
            'output_array' -- an array containing the output zonal mean raster for maternal females, the output zonal mean raster for non-maternal females, and the output csv file
    Returned Value: Returns a raster dataset on disk containing the combined raster
    Preconditions: requires continuous and significance rasters
    """

    # Import packages
    import arcpy
    from arcpy.sa import ExtractMultiValuesToPoints
    from arcpy.sa import Raster
    from arcpy.sa import ZonalStatistics
    import datetime
    import os
    import pandas as pd
    import time

    # Parse key word argument inputs
    work_geodatabase = kwargs['work_geodatabase']
    study_area = kwargs['input_array'][0]
    calf_distance = kwargs['input_array'][1]
    nocalf_distance = kwargs['input_array'][2]
    validation_points = kwargs['input_array'][3]
    calf_zonal = kwargs['output_array'][0]
    nocalf_zonal = kwargs['output_array'][1]
    output_file = kwargs['output_array'][2]

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Use two thirds of cores on processes that can be split.
    arcpy.env.parallelProcessingFactor = "66%"

    # Set snap raster, extent, and cell size
    arcpy.env.snapRaster = study_area
    arcpy.env.extent = Raster(study_area).extent
    arcpy.env.cellSize = "MINOF"

    # Define intermediate datasets
    extracted_points = os.path.join(work_geodatabase, 'validation_points_extracted')
    minimum_bound = os.path.join(work_geodatabase, 'minimum_bound')
    buffered_bound = os.path.join(work_geodatabase, 'buffered_bound')

    # Calculate bounding geometry
    print(f'\tCalculate bounding geometry from points...')
    iteration_start = time.time()
    arcpy.management.MinimumBoundingGeometry(validation_points,
                                             minimum_bound,
                                             'CONVEX_HULL',
                                             'ALL',
                                             '',
                                             'NO_MBG_FIELDS')
    arcpy.analysis.Buffer(minimum_bound,
                          buffered_bound,
                          '1000 Meters',
                          'FULL',
                          'ROUND',
                          'NONE',
                          '',
                          'PLANAR')
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Calculate zonal mean distances
    distance_rasters = [calf_distance, nocalf_distance]
    output_rasters = [calf_zonal, nocalf_zonal]
    count = 1
    for distance_raster in distance_rasters:
        # Define output raster
        output_raster = output_rasters[count - 1]
        print(f'\tCalculate zonal mean {count} of {len(output_rasters)}...')
        iteration_start = time.time()
        # Calculate zonal mean
        zonal_raster = ZonalStatistics(buffered_bound,
                                       'OBJECTID',
                                       distance_raster,
                                       'MEAN',
                                       'DATA',
                                       'CURRENT_SLICE')
        # Save zonal raster to disk
        arcpy.management.CopyRaster(zonal_raster,
                                    output_raster,
                                    '',
                                    '',
                                    '-32768',
                                    'NONE',
                                    'NONE',
                                    '32_BIT_FLOAT',
                                    'NONE',
                                    'NONE',
                                    'TIFF',
                                    'NONE',
                                    'CURRENT_SLICE',
                                    'NO_TRANSPOSE')
        # End timing
        iteration_end = time.time()
        iteration_elapsed = int(iteration_end - iteration_start)
        iteration_success_time = datetime.datetime.now()
        # Report success
        print(
            f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
        print('\t----------')
        count += 1

    # Extract values to points
    print(f'\tExtract values to points...')
    iteration_start = time.time()
    # Copy validation points
    arcpy.management.CopyFeatures(validation_points, extracted_points)
    # Extract values
    ExtractMultiValuesToPoints(extracted_points,
                               [[calf_distance, 'distance_calf'],
                                [nocalf_distance, 'distance_nocalf'],
                                [calf_zonal, 'mean_calf'],
                                [nocalf_zonal, 'mean_nocalf']],
                               'NONE')
    # Export table
    final_fields = [field.name for field in arcpy.ListFields(extracted_points)
                    if field.name != arcpy.Describe(extracted_points).shapeFieldName]
    output_data = pd.DataFrame(arcpy.da.TableToNumPyArray(extracted_points,
                                                          final_fields,
                                                          '',
                                                          False,
                                                          -99999))
    output_data.to_csv(output_file, header=True, index=False, sep=',', encoding='utf-8')
    # Delete intermediate files
    if arcpy.Exists(minimum_bound):
        arcpy.management.Delete(minimum_bound)
    if arcpy.Exists(buffered_bound):
        arcpy.management.Delete(buffered_bound)
    if arcpy.Exists(extracted_points):
        arcpy.management.Delete(extracted_points)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')
    out_process = 'Exported extracted values to table.'
    return out_process

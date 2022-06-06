# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Calculate raw distance
# Author: Timm Nawrocki
# Last Updated: 2021-10-05
# Usage: Must be executed in an ArcGIS Pro Python 3.6+ installation.
# Description: "Calculate raw distance" is a function that calculates Euclidean distance to a single value
# ---------------------------------------------------------------------------

# Define a function to calculate distance to target value
def calculate_raw_distance(**kwargs):
    """
    Description: calculates an accumulated distance to a target value in a raster
    Inputs: 'value' -- the target value to calculate distance
            'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the study area raster (must be first) and a target raster
            'output_array' -- an array containing the output raster
    Returned Value: Returns a raster dataset on disk containing the combined raster
    Preconditions: requires a target raster and a value that exists in that raster
    """

    # Import packages
    import arcpy
    from arcpy.sa import EucDistance
    from arcpy.sa import ExtractByMask
    from arcpy.sa import Raster
    from arcpy.sa import SetNull
    import datetime
    import time

    # Parse key word argument inputs
    value = kwargs['value']
    work_geodatabase = kwargs['work_geodatabase']
    study_area = kwargs['input_array'][0]
    input_raster = kwargs['input_array'][1]
    output_raster = kwargs['output_array'][0]

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

    # Convert continuous raster to discrete raster
    print(f'\tConverting raster to target...')
    iteration_start = time.time()
    target_raster = SetNull(input_raster, 1, f"value <> {value}")
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Convert continuous raster to discrete raster
    print(f'\tCalculating distances...')
    iteration_start = time.time()
    distance_raster = EucDistance(target_raster, '', '', '', 'PLANAR', '', '')
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Convert continuous raster to discrete raster
    print(f'\tExtracting distances to study area...')
    iteration_start = time.time()
    extract_raster = ExtractByMask(distance_raster, study_area)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Save the summed raster to disk
    print(f'\tSaving discrete raster to disk...')
    iteration_start = time.time()
    arcpy.management.CopyRaster(extract_raster,
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
    out_process = 'Converted continuous raster to discrete representation.'
    return out_process

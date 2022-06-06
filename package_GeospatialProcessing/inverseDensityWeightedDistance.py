# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Calculate inverse density-weighted distance
# Author: Timm Nawrocki
# Last Updated: 2021-10-05
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Calculate inverse density-weighted distance" is a function that calculates euclidean distance from raster values and divides distance by density (e.g., foliar cover).
# ---------------------------------------------------------------------------

# Define a function to calculate the inverse density-weighted distance
def calculate_idw_distance(**kwargs):
    """
    Description: calculates the distance/density of an input raster
    Inputs: 'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'target_value' -- an integer value of the target foliar cover value
            'input_array' -- an array containing the study area raster (must be first) and the input raster (must be second)
            'output_array' -- an array containing the output raster
    Returned Value: Returns a raster dataset on disk containing the IDW Distance values
    Preconditions: requires an input foliar cover raster
    """

    # Import packages
    import arcpy
    from arcpy.sa import EucDistance
    from arcpy.sa import Raster
    from arcpy.sa import SetNull
    import datetime
    import time

    # Parse key word argument inputs
    work_geodatabase = kwargs['work_geodatabase']
    target_value = kwargs['target_value']
    study_area = kwargs['input_array'][0]
    input_raster = kwargs['input_array'][1]
    output_raster = kwargs['output_array'][0]

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Use two thirds of cores on processes that can be split.
    arcpy.env.parallelProcessingFactor = "50%"

    # Set snap raster, extent, and cell size
    arcpy.env.snapRaster = study_area
    arcpy.env.extent = Raster(study_area).extent
    arcpy.env.cellSize = "MINOF"

    # Set all values except for the target value to NODATA
    iteration_start = time.time()
    print(f'\tNullifying raster values other than {target_value}...')
    nulled_raster = SetNull(input_raster, 1, f'VALUE <> {target_value}')
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Set all values except for the target value to NODATA
    print(f'\tCalculating euclidean distance to target value...')
    iteration_start = time.time()
    distance_raster = EucDistance(nulled_raster)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Set all values except for the target value to NODATA
    print(f'\tWeighting distances by inverse density...')
    iteration_start = time.time()
    edge_raster = distance_raster / (target_value / 100)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Save the summed raster to disk
    print(f'\tSaving edge raster to disk...')
    iteration_start = time.time()
    arcpy.management.CopyRaster(edge_raster,
                                output_raster,
                                '',
                                '',
                                '-32768',
                                'NONE',
                                'NONE',
                                '32_BIT_SIGNED',
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
    out_process = f'Successfully calculated inverse density-weighted distance where foliar cover = {target_value}%.'
    return out_process

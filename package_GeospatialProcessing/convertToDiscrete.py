# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Convert to discrete
# Author: Timm Nawrocki
# Last Updated: 2021-10-05
# Usage: Must be executed in an ArcGIS Pro Python 3.6+ installation.
# Description: "Convert to discrete" is a function that converts a continuous distribution to a discrete distribution including a negative state (-1), a non-significant state (0), and a positive state (1).
# ---------------------------------------------------------------------------

# Define a function to convert a continuous binary raster and a significance raster to a three state discrete raster
def convert_to_discrete(**kwargs):
    """
    Description: converts a continuous raster and a significance raster to a three state discrete raster
    Inputs: 'threshold' -- the continuous raster threshold
            'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the study area raster (must be first), a continuous raster, and a binary significance raster where significant = 1 and non-significant = 0
            'output_array' -- an array containing the output raster
    Returned Value: Returns a raster dataset on disk containing the combined raster
    Preconditions: requires continuous and significance rasters
    """

    # Import packages
    import arcpy
    from arcpy.sa import Con
    from arcpy.sa import Raster
    import datetime
    import time

    # Parse key word argument inputs
    threshold = kwargs['threshold']
    work_geodatabase = kwargs['work_geodatabase']
    study_area = kwargs['input_array'][0]
    continuous_raster = kwargs['input_array'][1]
    significance_raster = kwargs['input_array'][2]
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
    print(f'\tConverting raster to discrete representation...')
    iteration_start = time.time()
    conditional_raster = Con(Raster(significance_raster),
                             0,
                             Con(Raster(continuous_raster), 1, -1, f'value > {threshold}'),
                             f'value = {threshold}')
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
    arcpy.management.CopyRaster(conditional_raster,
                                output_raster,
                                '',
                                '',
                                '-128',
                                'NONE',
                                'NONE',
                                '8_BIT_SIGNED',
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

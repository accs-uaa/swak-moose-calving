# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Predict Habitat Selection Function for Points in Observed Paths
# Author: Timm Nawrocki
# Last Updated: 2021-08-29
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Predict Habitat Selection Function for Points in Observed Paths" predicts a random forest model (i.e., path selection function) to a set of grid csv files containing extracted covariate values to produce a set of output predictions with mean and standard deviation. The script must be run on a machine that can support 4 cores.
# ---------------------------------------------------------------------------

# Import packages
import copy
import joblib
import os
import pandas as pd
import time
import datetime

# Import functions from repository statistics package
from package_Statistics import predict_habitat_selection
from package_Statistics import read_text_value

# Define round date
round_date = 'round_20210820'

#### SET UP DIRECTORIES, FILES, AND FIELDS

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folders
data_folder = os.path.join(drive,
                           root_folder,
                           'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
model_folder = os.path.join(data_folder, 'Data_Output/model_results', round_date)

# Define input data file
input_file = os.path.join(data_folder,
                          'Data_Output/analysis_tables',
                          'allPoints_Observed_Selection.csv')

# Define variable sets
predictor_all = ['elevation', 'roughness', 'forest_edge', 'tundra_edge', 'alnus', 'betshr', 'dectre',
                 'empnig', 'erivag', 'picea', 'rhoshr', 'salshr', 'sphagn', 'vaculi', 'vacvit', 'wetsed']
retain_columns = ['mooseyear_id', 'pointID', 'calf_status', 'deployment_id', 'fullPath_id', 'fullPoint_id',
                  'calf_select', 'calf_ci95', 'nocalf_select', 'nocalf_ci95']
coordinates = ['x', 'y']
absence = ['absence']
presence = ['presence']
output_columns = retain_columns + coordinates

# Define random state
rstate = 21

# For each calf status, predict model results
calf_status = [0, 1]
for status in calf_status:
    # Define output file
    output_file = os.path.join(data_folder,
                               'Data_Output/analysis_tables',
                               f'allPoints_Observed_Predicted_{status}.csv')

    # Define response names
    if status == 0:
        input_folder = os.path.join(model_folder, 'NoCalf')
    else:
        input_folder = os.path.join(model_folder, 'Calf')

    # Load model and threshold sets into memory
    print(f'Loading 50 classifiers and thresholds into memory...')
    segment_start = time.time()
    # Define empty lists to store classifiers and thresholds
    model_set = []
    threshold_set = []
    # Iterate through folders to add classifiers and thresholds to list
    i = 1
    while i <= 50:
        # Define paths for classifier and threshold
        if i < 10:
            classifier_path = os.path.join(input_folder, f'0{str(i)}', 'classifier.joblib')
            threshold_path = os.path.join(input_folder, f'0{str(i)}', 'threshold.txt')
        else:
            classifier_path = os.path.join(input_folder, str(i), 'classifier.joblib')
            threshold_path = os.path.join(input_folder, str(i), 'threshold.txt')
        # Load and append classifier
        classifier = joblib.load(classifier_path)
        model_set.append(classifier)
        # Read and append threshold
        threshold = read_text_value(threshold_path)
        threshold_set.append(threshold)
        # Increase the counter
        i += 1
    # Report success
    segment_end = time.time()
    segment_elapsed = int(segment_end - segment_start)
    segment_success_time = datetime.datetime.now()
    print(f'Completed at {segment_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=segment_elapsed)})')
    print('----------')

    # Predict the output table if it does not already exist
    if os.path.exists(output_file) == 0:
        print(f'Predicting selection for calf status {status}...')
        total_start = time.time()

        # Identify file path to input csv file
        print(f'\tLoading grid data into memory...')
        segment_start = time.time()
        # Load the input data
        input_data = pd.read_csv(input_file)
        input_data = input_data.dropna(axis=0, how='any')
        # Create a Picea column
        input_data['picea'] = input_data['picgla'] + input_data['picmar']
        # Define the X data
        X_data = input_data[predictor_all].astype(float)
        # Prepare output data
        output_data = copy.deepcopy(input_data)
        output_data = output_data[output_columns]
        # Report success
        segment_end = time.time()
        segment_elapsed = int(segment_end - segment_start)
        segment_success_time = datetime.datetime.now()
        print(f'\tCompleted at {segment_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=segment_elapsed)})')
        print('\t----------')

        # Loop through model sets and run prediction routine
        print(f'\tPredicting model results for all sets...')
        iteration = 1
        while iteration <= 50:
            print(f'\t\tPredicting model {str(iteration)} of 50...')
            segment_start = time.time()
            # Select classifier and threshold for iteration
            classifier = model_set[iteration-1]
            threshold = threshold_set[iteration-1]
            # Predict data for the iteration
            output_data = predict_habitat_selection(classifier, threshold, X_data, iteration, output_data)
            # Report success
            segment_end = time.time()
            segment_elapsed = int(segment_end - segment_start)
            segment_success_time = datetime.datetime.now()
            print(f'\t\tCompleted at {segment_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=segment_elapsed)})')
            print('\t\t----------')

            # Increase iteration count
            iteration += 1

        # Export output data to csv
        print('\tExporting model predictions to csv...')
        segment_start = time.time()
        output_data.to_csv(output_file, header=True, index=False, sep=',', encoding='utf-8')
        # Report success
        segment_end = time.time()
        segment_elapsed = int(segment_end - segment_start)
        segment_success_time = datetime.datetime.now()
        print(f'\tCompleted at {segment_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=segment_elapsed)})')
        print('\t----------')

        # Report success for iteration
        total_end = time.time()
        total_elapsed = int(total_end - total_start)
        total_success_time = datetime.datetime.now()
        print(f'Iteration completed at {total_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=total_elapsed)})')
        print('----------')

    else:
        print(f'Model predictions already exist for calf status {status}.')
        print('----------')

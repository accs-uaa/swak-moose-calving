# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Train and Test Habitat Selection Function
# Author: Timm Nawrocki
# Last Updated: 2021-08-20
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Train and Test Habitat Selection Function" trains a random forest model (i.e., path selection function) to predict habitat from path covariate means. A threshold for avoidance/selection conversion is selected empirically. All model performance metrics are calculated on independent test partitions where independence of groups is maintained. This script runs the model train and test steps to output a model performance and variable importance report, trained classifier file, and threshold file that can be transferred to the prediction script. The train-test classifier is set to use 4 cores. The script must be run on a machine that can support 4 cores.
# ---------------------------------------------------------------------------

# Import packages
import os
import pandas as pd
from sklearn.model_selection import LeaveOneGroupOut
from sklearn.model_selection import GroupKFold
import time
import datetime

# Import functions from repository statistics package
from package_Statistics import model_train_test
from package_Statistics import plot_importances_mdi
from package_Statistics import write_model_report

# Define calf status
calf_status = 1

# Define round
round_date = 'round_20210820'

#### SET UP DIRECTORIES, FILES, AND FIELDS

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folders
data_folder = os.path.join(drive,
                           root_folder,
                           'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
data_input = os.path.join(data_folder,
                          'Data_Input/paths')
data_output = os.path.join(data_folder, 'Data_Output/model_results', round_date)

# Define input file
input_file = os.path.join(data_input, 'paths_meanCovariates.csv')

# Define variable sets
predictor_all = ['elevation', 'roughness', 'forest_edge', 'tundra_edge', 'alnus', 'betshr', 'dectre',
                 'empnig', 'erivag', 'picea', 'rhoshr', 'salshr', 'sphagn', 'vaculi', 'vacvit', 'wetsed']
response = ['response']
retain_variables = ['mooseYear_id', 'fullPath_id', 'calfStatus']
iteration = ['iteration_id']
all_variables = retain_variables + iteration + predictor_all + response
outer_cv_split_n = ['outer_cv_split_n']
absence = ['absence']
presence = ['presence']
prediction = ['prediction']
selection = ['selection']
output_variables = all_variables + outer_cv_split_n + absence + presence + prediction + selection

# Define random state
rstate = 21

# Define response names
if calf_status == 0:
    output_folder = os.path.join(data_output, 'NoCalf')
    output_html = os.path.join(output_folder, 'report-moose-nocalf.html')
    taxon_name = 'Moose without Calves'
else:
    output_folder = os.path.join(data_output, 'Calf')
    output_html = os.path.join(output_folder, 'report-moose-calf.html')
    taxon_name = 'Moose with Calves'

# Define output test data
output_csv = os.path.join(output_folder, 'prediction.csv')

# Define output meta model
output_metamodel = os.path.join(output_folder, 'meta_classifier.joblib')

# Create a plots folder if it does not exist
plots_folder = os.path.join(output_folder, 'plots')
if not os.path.exists(plots_folder):
    os.makedirs(plots_folder)

# Define output correlation plot
correlation_plot = os.path.join(plots_folder, 'variable_correlation.png')
# Define output variable importance plot
importance_mdi_plot = os.path.join(plots_folder, 'importance_classifier_mdi.png')
# Define output variable importance tables
importance_mdi_csv = os.path.join(output_folder, 'importance_classifier_mdi.csv')

#### CONDUCT MODEL TRAIN AND TEST ITERATIONS

# Create a standardized parameter set for a random forest classifier
classifier_params = {'n_estimators': 1000,
                     'criterion': 'gini',
                     'max_depth': None,
                     'min_samples_split': 2,
                     'min_samples_leaf': 1,
                     'min_weight_fraction_leaf': 0,
                     'max_features': 'sqrt',
                     'bootstrap': False,
                     'oob_score': False,
                     'warm_start': False,
                     'class_weight': 'balanced',
                     'n_jobs': 4,
                     'random_state': rstate}

# Create data frame of input data
data_all = pd.read_csv(input_file)
input_data = data_all[data_all['calfStatus'] == calf_status].copy()

# Rename covariates to match prediction grids
input_data = input_data.rename(columns={'elevation_mean': 'elevation',
                                        'roughness_mean': 'roughness',
                                        'forest_edge_mean': 'forest_edge',
                                        'tundra_edge_mean': 'tundra_edge',
                                        'alnus_mean': 'alnus',
                                        'betshr_mean': 'betshr',
                                        'dectre_mean': 'dectre',
                                        'dryas_mean': 'dryas',
                                        'empnig_mean': 'empnig',
                                        'erivag_mean': 'erivag',
                                        'picgla_mean': 'picgla',
                                        'picmar_mean': 'picmar',
                                        'rhoshr_mean': 'rhoshr',
                                        'salshr_mean': 'salshr',
                                        'sphagn_mean': 'sphagn',
                                        'vaculi_mean': 'vaculi',
                                        'vacvit_mean': 'vacvit',
                                        'wetsed_mean': 'wetsed'})

# Create a Picea column
input_data['picea'] = input_data['picgla'] + input_data['picmar']

# Add one to iteration_id
input_data['iteration_id'] = input_data['iteration_id'] + 1

# Define 5-fold cross validation split methods
outer_cv_splits = LeaveOneGroupOut()
inner_cv_splits = GroupKFold(n_splits=5)

# Create empty data frames to store the results across all iterations
output_results = pd.DataFrame(columns=output_variables)
importances_all = pd.DataFrame(columns=['iteration', 'covariate', 'importance'])

# Create empty lists to store threshold and performance metrics
auc_list = []
accuracy_list = []
classifier_list = []

# Loop through each iteration and train and test a classification model
iteration = 1
while iteration <= 50:
    print(f'Conducting model train and test for iteration {iteration} of 50...')

    # Define iteration folder
    if iteration < 10:
        iteration_folder = os.path.join(output_folder, "0" + str(iteration))
    else:
        iteration_folder = os.path.join(output_folder, str(iteration))
    if not os.path.exists(iteration_folder):
        os.mkdir(iteration_folder)

    # Define output model file
    output_classifier = os.path.join(iteration_folder, 'classifier.joblib')
    # Define output threshold file
    threshold_file = os.path.join(iteration_folder, 'threshold.txt')

    # Update iteration_id for observed paths
    input_data.loc[(input_data.response == 1), 'iteration_id'] = iteration

    # Select all data for iteration into iteration dataset
    iteration_data = input_data[input_data.iteration_id == iteration].copy()

    # Conduct model train and test for iteration
    outer_results, auc, accuracy, iteration_classifier, importance_table = model_train_test(classifier_params,
                                                                                            iteration_data,
                                                                                            outer_cv_splits,
                                                                                            inner_cv_splits,
                                                                                            rstate,
                                                                                            threshold_file,
                                                                                            output_classifier)

    # Print results of model train and test
    print(f'Outer results for iteration {iteration} contain {len(outer_results)} rows.')
    print(f'AUC for iteration {iteration} = {auc}.')
    print(f'Accuracy for iteration {iteration} = {accuracy}.')
    print('----------')

    # Add the outer results for the iteration to the output data frame
    output_results = output_results.append(outer_results, ignore_index=True, sort=True)

    # Append the AUC and Accuracy to the lists
    auc_list.append(auc)
    accuracy_list.append(accuracy)

    # Add model to the list
    classifier_list.append(iteration_classifier)

    # Add the importances to the importance table
    importance_table['iteration'] = iteration
    importances_all = importances_all.append(importance_table, ignore_index=True, sort=True)

    # Increase the iteration
    iteration += 1

#### CALCULATE PERFORMANCE AND STORE RESULTS

# Store output results in csv file
print('Saving combined results to csv file...')
iteration_start = time.time()
output_results.to_csv(output_csv, header=True, index=False, sep=',', encoding='utf-8')
iteration_end = time.time()
iteration_elapsed = int(iteration_end - iteration_start)
iteration_success_time = datetime.datetime.now()
print(
    f'Completed at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
print('----------')

# Export a variable importance plot for the meta model based on MDI
print('Creating a plot of MDI importances from all models...')
iteration_start = time.time()
plot_importances_mdi(importances_all, 6, 3, importance_mdi_plot, importance_mdi_csv)
iteration_end = time.time()
iteration_elapsed = int(iteration_end - iteration_start)
iteration_success_time = datetime.datetime.now()
print(
    f'Completed at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
print('----------')

# Write output report
print('Writing report for model accuracy and results...')
iteration_start = time.time()
write_model_report(taxon_name, auc_list, accuracy_list, output_html)
iteration_end = time.time()
iteration_elapsed = int(iteration_end - iteration_start)
iteration_success_time = datetime.datetime.now()
print(
    f'Completed at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
print('----------')

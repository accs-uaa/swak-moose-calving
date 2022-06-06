# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Train and Export Classifier
# Author: Timm Nawrocki
# Last Updated: 2021-08-18
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Train and Export Classifier" is a function that trains and exports a classifier.
# ---------------------------------------------------------------------------

# Create a function to train and export a classification model
def train_export_classifier(classifier_params, iteration_data, inner_cv_splits, threshold_file, output_classifier):
    """
    Description: trains and exports a classification model and threshold value
    Inputs: 'classifier_params' -- a set of parameters for a random forest classifier specified according to the sklearn API
            'iteration_data' -- a data frame of the data for a specified single iteration
            'inner_cv_splits' -- a splitting method for the inner cross validation specified according to the sklearn API
            'threshold_file' -- a text file to store the threshold value
            'output_classifier' -- a joblib file to store the trained classifier
    Returned Value: Returns a threshold value on disk and a trained classifier on disk
    Preconditions: requires a classifier specification, a data frame of covariates and responses for a single iteration, and an inner cross validation specification
    """

    # Import packages
    import joblib
    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier
    import time
    import datetime

    # Import functions from repository statistics package
    from package_Statistics import inner_cross_validation
    from package_Statistics import determine_optimal_threshold

    # Define variable sets
    predictor_all = ['elevation', 'roughness', 'forest_edge', 'tundra_edge', 'alnus', 'betshr', 'dectre',
                     'empnig', 'erivag', 'picea', 'rhoshr', 'salshr', 'sphagn', 'vaculi', 'vacvit', 'wetsed']
    response = ['response']

    # Conduct inner cross validation routine
    print(f'\t\tConducting inner cross validation...')
    iteration_start = time.time()
    inner_results = inner_cross_validation(classifier_params, iteration_data, inner_cv_splits)
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    print(
        f'\t\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t\t----------')

    # Calculate the optimal threshold and performance of the presence-absence classification
    print('\t\tOptimizing classification threshold...')
    iteration_start = time.time()
    iteration_threshold, sensitivity, specificity, auc, accuracy = determine_optimal_threshold(
        inner_results['presence'],
        inner_results['response'])
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    print(
        f'\t\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t\t----------')

    # Write a text file to store the presence-absence conversion threshold
    file = open(threshold_file, 'w')
    file.write(str(round(iteration_threshold, 5)))
    file.close()

    # Split the X and y data for classification
    X_classify = iteration_data[predictor_all].astype(float)
    y_classify = iteration_data[response[0]].astype('int32')

    # Train classifier
    export_classifier = RandomForestClassifier(**classifier_params)
    export_classifier.fit(X_classify, y_classify)

    # Save classifier to an external file
    joblib.dump(export_classifier, output_classifier)

    # Get feature importances calculated as MDI
    importances = export_classifier.feature_importances_
    feature_names = list(X_classify.columns)
    importance_table = pd.DataFrame({'covariate': feature_names,
                                     'importance': importances})

    # Return trained classifier
    return export_classifier, importance_table

# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Classification Outer Cross Validation
# Author: Timm Nawrocki
# Last Updated: 2021-08-18
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Classification Outer Cross Validation" is a function that conducts the outer cross validation routine for all partitions of a pre-defined outer cross validation set.
# ---------------------------------------------------------------------------

def outer_cross_validation(classifier_params, iteration_data, outer_cv_splits, inner_cv_splits):
    """
    Description: conducts outer cross validation iterations for a classification model
    Inputs: 'classifier_params' -- a set of parameters for a random forest classifier specified according to the sklearn API
            'train_iteration' -- a data frame of the inner cross validation partition
            'outer_cv_splits' -- a splitting method for the outer cross validation specified according to the sklearn API
            'inner_cv_splits' -- a splitting method for the inner cross validation specified according to the sklearn API
    Returned Value: Returns a plot on disk
    Preconditions: requires a classifier specification, a data frame of covariates and responses for a single iteration, an inner cross validation specification, and an outer cross validation specification
    """

    # Import packages
    import numpy as np
    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier
    import time
    import datetime

    # Import functions from repository statistics package
    from package_Statistics import inner_cross_validation
    from package_Statistics import determine_optimal_threshold
    from package_Statistics import convert_to_selection

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

    # Create an empty data frame to store the outer cross validation splits
    outer_train = pd.DataFrame(columns=all_variables)
    outer_test = pd.DataFrame(columns=all_variables)

    # Create an empty data frame to store the outer test results
    outer_results = pd.DataFrame(columns=output_variables)

    # Create outer cross validation splits
    count = 1
    for train_index, test_index in outer_cv_splits.split(iteration_data,
                                                         iteration_data['response'],
                                                         iteration_data['mooseYear_id']):
        # Split the data into train and test partitions
        train = iteration_data.iloc[train_index]
        test = iteration_data.iloc[test_index]
        # Insert outer_cv_split_n to train
        train = train.assign(outer_cv_split_n=count)
        # Insert iteration to test
        test = test.assign(outer_cv_split_n=count)
        # Append to data frames
        outer_train = outer_train.append(train, ignore_index=True, sort=True)
        outer_test = outer_test.append(test, ignore_index=True, sort=True)
        # Increase counter
        count += 1
    cv_length = count - 1
    print(f'\tCreated {cv_length} outer cross-validation group splits.')

    # Reset indices
    outer_train = outer_train.reset_index()
    outer_test = outer_test.reset_index()

    # Iterate through outer cross validation splits
    outer_cv_i = 1
    while outer_cv_i <= cv_length:

        #### CONDUCT MODEL TRAIN
        ####____________________________________________________

        # Partition the outer train split by iteration number
        print(f'\tConducting outer cross-validation iteration {outer_cv_i} of {cv_length}...')
        train_iteration = outer_train[outer_train['outer_cv_split_n'] == outer_cv_i].copy()

        # Conduct inner cross validation routine
        print(f'\t\tConducting inner cross validation...')
        inner_results = inner_cross_validation(classifier_params, train_iteration, inner_cv_splits)

        # Calculate the optimal threshold and performance of the presence-absence classification
        print('\t\tOptimizing classification threshold...')
        iteration_start = time.time()
        threshold, sensitivity, specificity, auc, accuracy = determine_optimal_threshold(inner_results['presence'],
                                                                                         inner_results['response'])
        iteration_end = time.time()
        iteration_elapsed = int(iteration_end - iteration_start)
        iteration_success_time = datetime.datetime.now()
        print(f'\t\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
        print('\t\t----------')

        # Identify X and y train splits for the classifier
        X_train_classify = train_iteration[predictor_all].astype(float).copy()
        y_train_classify = train_iteration[response[0]].astype('int32').copy()

        # Train classifier
        print('\t\tTraining classifier...')
        iteration_start = time.time()
        outer_classifier = RandomForestClassifier(**classifier_params)
        outer_classifier.fit(X_train_classify, y_train_classify)
        iteration_end = time.time()
        iteration_elapsed = int(iteration_end - iteration_start)
        iteration_success_time = datetime.datetime.now()
        print(f'\t\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
        print('\t\t----------')

        #### CONDUCT MODEL TEST
        ####____________________________________________________

        # Partition the outer test split by iteration number
        print('\t\tPredicting outer cross-validation test data...')
        iteration_start = time.time()
        test_iteration = outer_test[outer_test['outer_cv_split_n'] == outer_cv_i].copy()

        # Identify X test split
        X_test = test_iteration[predictor_all]

        # Use the classifier to predict class probabilities
        probability_prediction = outer_classifier.predict_proba(X_test)

        # Concatenate predicted values to test data frame
        test_iteration = test_iteration.assign(absence=probability_prediction[:, 0])
        test_iteration = test_iteration.assign(presence=probability_prediction[:, 1])

        # Convert probability to presence-absence
        presence_zeros = np.zeros(test_iteration[presence[0]].shape)
        presence_zeros[test_iteration[presence[0]] >= threshold] = 1

        # Concatenate distribution values to test data frame
        test_iteration = test_iteration.assign(prediction=presence_zeros)

        # Convert probability to selection
        test_iteration = convert_to_selection(test_iteration, presence, threshold, selection)

        # Add the test results to output data frame
        outer_results = outer_results.append(test_iteration, ignore_index=True, sort=True)
        iteration_end = time.time()
        iteration_elapsed = int(iteration_end - iteration_start)
        iteration_success_time = datetime.datetime.now()
        print(f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
        print('\t----------')

        # Increase iteration number
        outer_cv_i += 1

    return outer_results

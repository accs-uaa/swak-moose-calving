# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Classification Inner Cross Validation
# Author: Timm Nawrocki
# Last Updated: 2021-08-18
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Classification Inner Cross Validation" is a function that conducts the inner cross validation routine for all partitions of a pre-defined inner cross validation set.
# ---------------------------------------------------------------------------

def inner_cross_validation(classifier_params, train_iteration, inner_cv_splits):
    """
    Description: conducts inner cross validation iterations for a classification model
    Inputs: 'classifier_params' -- a set of parameters for a random forest classifier specified according to the sklearn API
            'train_iteration' -- a data frame of the inner cross validation partition
            'inner_cv_splits' -- a splitting method for the inner cross validation specified according to the sklearn API
    Returned Value: Returns a plot on disk
    Preconditions: requires a classifier specification, a data frame of covariates and responses for a train iteration, and an inner cross validation specification
    """

    # Import packages
    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier
    import time
    import datetime

    # Define variable sets
    predictor_all = ['elevation', 'roughness', 'forest_edge', 'tundra_edge', 'alnus', 'betshr', 'dectre',
                     'empnig', 'erivag', 'picea', 'rhoshr', 'salshr', 'sphagn', 'vaculi', 'vacvit', 'wetsed']
    response = ['response']
    retain_variables = ['mooseYear_id', 'fullPath_id', 'calfStatus']
    iteration = ['iteration_id']
    all_variables = retain_variables + iteration + predictor_all + response
    absence = ['absence']
    presence = ['presence']

    # Create an empty data frame to store the inner cross validation splits
    inner_train = pd.DataFrame(columns=all_variables)
    inner_test = pd.DataFrame(columns=all_variables)

    # Create an empty data frame to store the inner test results
    inner_results = pd.DataFrame(
        columns=all_variables + absence + presence + ['inner_cv_split_n'])

    # Create inner cross validation splits
    count = 1
    for train_index, test_index in inner_cv_splits.split(train_iteration,
                                                         train_iteration['response'],
                                                         train_iteration['mooseYear_id']):
        # Split the data into train and test partitions
        train = train_iteration.iloc[train_index]
        test = train_iteration.iloc[test_index]
        # Insert iteration to train
        train = train.assign(inner_cv_split_n=count)
        # Insert iteration to test
        test = test.assign(inner_cv_split_n=count)
        # Append to data frames
        inner_train = inner_train.append(train, ignore_index=True, sort=True)
        inner_test = inner_test.append(test, ignore_index=True, sort=True)
        # Increase counter
        count += 1

    # Iterate through inner cross validation splits
    inner_cv_i = 1
    while inner_cv_i <= 5:
        iteration_start = time.time()
        print(f'\t\t\tConducting inner cross validation iteration {inner_cv_i} of {5}...')
        inner_train_iteration = inner_train[inner_train['inner_cv_split_n'] == inner_cv_i]
        inner_test_iteration = inner_test[inner_test['inner_cv_split_n'] == inner_cv_i]

        # Identify X and y inner train and test splits
        X_train_inner = inner_train_iteration[predictor_all].astype(float)
        y_train_inner = inner_train_iteration[response[0]].astype('int32')
        X_test_inner = inner_test_iteration[predictor_all].astype(float)

        # Train classifier on the inner train data
        inner_classifier = RandomForestClassifier(**classifier_params)
        inner_classifier.fit(X_train_inner, y_train_inner)

        # Predict probabilities for inner test data
        probability_inner = inner_classifier.predict_proba(X_test_inner)
        # Concatenate predicted values to test data frame
        inner_test_iteration = inner_test_iteration.assign(absence=probability_inner[:, 0])
        inner_test_iteration = inner_test_iteration.assign(presence=probability_inner[:, 1])

        # Add the test results to output data frame
        inner_results = inner_results.append(inner_test_iteration, ignore_index=True, sort=True)
        iteration_end = time.time()
        iteration_elapsed = int(iteration_end - iteration_start)
        iteration_success_time = datetime.datetime.now()
        print(
            f'\t\t\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
        print('\t\t\t----------')

        # Increase n value
        inner_cv_i += 1

    return inner_results

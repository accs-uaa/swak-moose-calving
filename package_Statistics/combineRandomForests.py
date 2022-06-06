# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Combine Random Forests
# Author: Timm Nawrocki
# Last Updated: 2021-08-18
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Combine Random Forests" is a function that combines multiple independently trained random forest models with the same response and covariates into a single meta model.
# ---------------------------------------------------------------------------

# Create a function to combine random forest models
def combine_random_forests(classifier_list):
    """
    Description: combines estimators from a list of random forest models
    Inputs: 'classifier_list' -- a list of trained random forest models
    Returned Value: Returns a meta random forest model
    Preconditions: requires a set of trained random forest models
    """

    # Import packages
    import copy

    # Create a meta model
    meta_classifier = copy.deepcopy(classifier_list[0])
    count = 1
    print(f'\t\tRandom forest model {str(count)} contains {str(classifier_list[count - 1].n_estimators)}.')
    count += 1

    # Loop through classifiers and add them to initial classifier
    length = len(classifier_list)
    while count <= length:
        print(f'\t\tRandom forest model {str(count)} contains {str(classifier_list[count-1].n_estimators)}.')
        meta_classifier.estimators_ += classifier_list[count-1].estimators_
        meta_classifier.n_estimators = len(meta_classifier.estimators_)
        count += 1

    # Print number of estimators
    print(f'\t\tRandom forest meta model contains {str(meta_classifier.n_estimators)} estimators.')

    # Return combined estimators
    return meta_classifier

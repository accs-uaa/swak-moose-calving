# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Determine Optimal Threshold
# Author: Timm Nawrocki
# Last Updated: 2021-08-18
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Determine Optimal Threshold" is a set of functions that test presence thresholds for converting probabilistic predictions to binary predictions to determine a threshold value that minimizes the absolute value difference between sensitivity and specificity.
# ---------------------------------------------------------------------------

# Define a function to test presence threshold values
def test_presence_threshold(predict_probability, threshold, y_test):
    """
    Description: tests the performance of a threshold value by calculating sensitivity, specificity, auc, and accuracy on a test data set of response values
    Inputs: 'predict_probability' -- the predicted probability values
            'threshold' -- the probability value to use as the conversion threshold to binary
            'y_test' -- the observed binary values
    Returned Value: Returns the sensitivity, specificity, auc, and accuracy for the specified threshold value
    Preconditions: requires existing probability predictions and binary responses of the same shape
    """

    # Import packages
    import numpy as np
    from sklearn.metrics import confusion_matrix
    from sklearn.metrics import roc_auc_score

    # Create an empty array of zeroes that matches the length of the probability predictions
    predict_thresholded = np.zeros(predict_probability.shape)

    # Set values for all probabilities greater than or equal to the threshold equal to 1
    predict_thresholded[predict_probability >= threshold] = 1

    # Determine error rates
    confusion_test = confusion_matrix(y_test.astype('int32'), predict_thresholded.astype('int32'))
    true_negative = confusion_test[0, 0]
    false_negative = confusion_test[1, 0]
    true_positive = confusion_test[1, 1]
    false_positive = confusion_test[0, 1]

    # Calculate sensitivity and specificity
    sensitivity = true_positive / (true_positive + false_negative)
    specificity = true_negative / (true_negative + false_positive)

    # Calculate AUC score
    auc = roc_auc_score(y_test.astype('int32'), predict_probability.astype(float))

    # Calculate overall accuracy
    accuracy = (true_negative + true_positive) / (true_negative + false_positive + false_negative + true_positive)

    # Return the thresholded probabilities and the performance metrics
    return sensitivity, specificity, auc, accuracy

# Define a function to test presence threshold values
def determine_optimal_threshold(predict_probability, y_test):
    """
    Description: determines the threshold value that minimizes the absolute value difference between sensitivity and specificity to one decimal percentage.
    Inputs: 'predict_probability' -- the predicted probability values
            'y_test' -- the observed binary values
    Returned Value: Returns the optimal threshold value and the sensitivity, specificity, auc, and accuracy of the optimal threshold value
    Preconditions: requires existing probability predictions and binary responses of the same shape
    """

    # Import packages
    import numpy as np

    # Iterate through numbers between 0 and 1000 to output a list of sensitivity and specificity values per threshold number
    i = 1
    sensitivity_list = []
    specificity_list = []
    while i <= 1000:
        threshold = i / 1000
        sensitivity, specificity, auc, accuracy = test_presence_threshold(predict_probability, threshold, y_test)
        sensitivity_list.append(sensitivity)
        specificity_list.append(specificity)
        i = i + 1

    # Calculate a list of absolute value difference between sensitivity and specificity and find the optimal threshold
    difference_list = [np.absolute(a - b) for a, b in zip(sensitivity_list, specificity_list)]
    value, threshold = min((value, threshold) for (threshold, value) in enumerate(difference_list))
    threshold = threshold / 1000

    # Calculate the performance of the optimal threshold
    sensitivity, specificity, auc, accuracy = test_presence_threshold(predict_probability, threshold, y_test)

    # Return the optimal threshold and the performance metrics of the optimal threshold
    return threshold, sensitivity, specificity, auc, accuracy

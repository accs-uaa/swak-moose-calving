# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Predict Habitat Selection
# Author: Timm Nawrocki
# Last Updated: 2021-08-19
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Predict Habitat Selection" is a function that predicts a path selection function and converts the probabilistic values to selection values.
# ---------------------------------------------------------------------------

# Create a function to predict and convert a stored path selection model
def predict_habitat_selection(classifier, threshold, X_data, iteration, output_data):
    """
    Description: predicts a stored model, applies a conversion threshold, and sets a column name for storage of results
    Inputs: 'classifier' -- a classification model loaded in memory
            'threshold' -- a numerical threshold value loaded in memory
            'X_data' -- a set of data to predict with all necessary covariates for the model
            'iteration' -- a number of the iteration
            'output_data' -- a data frame to store the prediction results
    Returned Value: Returns the output data frame of selection predictions and coordinates
    Preconditions: requires a classifier, threshold, and covariates
    """

    # Import functions from repository statistics package
    from package_Statistics import convert_to_selection

    # Predict the classification probabilities for the X data
    classification = classifier.predict_proba(X_data)

    # Concatenate predicted values to output data frame
    output_data = output_data.assign(absence=classification[:, 0])
    output_data = output_data.assign(presence=classification[:, 1])

    # Define selection column
    if iteration < 10:
        selection_column = [f'selection_0{str(iteration)}']
    else:
        selection_column = [f'selection_{str(iteration)}']

    # Define presence column
    presence = ['presence']

    # Convert to selection
    output_data = convert_to_selection(output_data, presence, threshold, selection_column)

    # Remove absence and presence columns
    output_data = output_data.drop(columns=['absence', 'presence'])

    return output_data

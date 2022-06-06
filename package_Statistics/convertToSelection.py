# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Composite Selection
# Author: Timm Nawrocki
# Last Updated: 2021-08-18
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Composite Selection" is a set of functions that convert the probabilistic predictions to a selection range from -1 to 1 where avoidance is represented by decimals from -1 to 0 and selection is represented by decimals from 0 to 1.
# ---------------------------------------------------------------------------

# Create a function to convert probability values to selection range values
def convert_to_selection(input_data, presence, threshold, output):
    """
    Description: converts a probabilistic range from 0 to 1 to a binary range from -1 to 1 using a threshold value.
    Inputs: 'input_data' -- an input data frame containing a column of probabilistic presence predictions
            'presence' -- the name of a column containing probabilistic presence predictions
            'threshold' -- the probability value to use as the conversion threshold to binary
            'output' -- the name of a column in which to store the calculated composite predictions
    Returned Value: Returns the binary range predictions in a specified column
    Preconditions: requires a data frame of predicted presence probabilities
    """

    # Determine positive and negative ranges
    positive_range = input_data[presence[0]].max() - threshold
    negative_range = threshold - input_data[presence[0]].min()

    # Create a function to convert probability to binary range
    def probability_to_range(row):
        """
        Description: converts a probabilistic range from 0 to 1 to a binary range from -1 to 1 using a threshold value.
        Inputs: 'row' -- a row in a data frame containing a column of probabilistic presence predictions
                'presence' -- the name of a column containing probabilistic presence predictions
                'threshold' -- the probability value to use as the conversion threshold to binary
                'positive_range' -- the absolute value difference in maximum and minimum values for selection
                'negative_range' -- the absolute value difference in maximum and minimum values for avoidance
        Returned Value: Returns the adjusted value for the binary range
        Preconditions: requires a single row from a data frame containing a probabilistic presence prediction
        """
        if row[presence[0]] == threshold:
            return 0
        elif row[presence[0]] > threshold:
            adjusted_value = (row[presence[0]] - threshold) / positive_range
            return adjusted_value
        elif row[presence[0]] < threshold:
            adjusted_value = (row[presence[0]] - threshold) / negative_range
            return adjusted_value

    # Apply function to all rows in data
    input_data[output[0]] = input_data.apply(lambda row: probability_to_range(row), axis=1)

    # Return the data frame with composited results
    return input_data

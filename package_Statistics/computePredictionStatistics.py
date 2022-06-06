# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Compute Prediction Statistics
# Author: Timm Nawrocki
# Last Updated: 2021-08-19
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Compute Prediction Statistics" is a function that computes the mean, standard deviation, 95% confidence interval, and binary significance on a data frame containing model predictions.
# ---------------------------------------------------------------------------

# Create a function to compute statistics on rows in a data frame
def compute_prediction_statistics(output_data):
    """
    Description: computes statistics on a set of predictions per cell
    Inputs: 'output_data' -- a data frame containing a set of predictions for a grid
    Returned Value: Returns a data frame of computed statistics per cell in a grid
    Preconditions: requires a data frame of x and y values and 50 model predictions converted to selection values.
    """

    # Import packages
    import math
    import pandas as pd

    # Define variable sets
    coordinates = ['x', 'y']
    output_columns = coordinates + ['selection_mean', 'selection_std']

    # Summarize mean and standard deviation of predictions
    output_data['selection_mean'] = output_data.iloc[:, 2:52].mean(axis=1)
    output_data['selection_std'] = output_data.iloc[:, 2:52].std(axis=1)

    # Collapse output data to coordinates plus summary statistics
    output_stats = output_data[output_columns]

    # Drop statistics columns from output_data
    output_data = output_data.drop(columns=['selection_mean', 'selection_std'])

    # Calculate 95% confidence intervals and significance
    ci95_upper = []
    ci95_lower = []
    ci95_width = []
    significance = []
    denominator = math.sqrt(50)
    for i in output_stats.index:
        x, y, cell_mean, cell_std = output_stats.loc[i]
        upper_value = cell_mean + ((1.95 * cell_std) / denominator)
        lower_value = cell_mean - ((1.95 * cell_std) / denominator)
        width_value = upper_value - lower_value
        if upper_value > 0 and lower_value > 0 or upper_value < 0 and lower_value < 0:
            sig_value = 1
        elif upper_value > 0 > lower_value:
            sig_value = 0
        else:
            sig_value = 999
        ci95_upper.append(upper_value)
        ci95_lower.append(lower_value)
        ci95_width.append(width_value)
        significance.append(sig_value)

    # Append confidence intervals to output stats
    output_stats = output_stats.assign(upper_95=ci95_upper)
    output_stats = output_stats.assign(lower_95=ci95_lower)
    output_stats = output_stats.assign(ci_width=ci95_width)
    output_stats = output_stats.assign(significance=significance)

    return output_stats

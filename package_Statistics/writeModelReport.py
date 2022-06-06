# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Write Model Report
# Author: Timm Nawrocki
# Last Updated: 2021-08-17
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Write Model Report" is a function that produces a standardized report of model performance metrics and results.
# ---------------------------------------------------------------------------

# Create a function to plot Pearson correlation of predictor variables
def write_model_report(taxon_name, auc_list, accuracy_list, output_html):
    """
    Description: creates an output html report of model performance metrics and results
    Inputs: 'auc_list' -- a list of auc values from each model train and test iteration
            'accuracy_list' -- a list of accuracy values from each model train and test iteration
            'output_html' -- an html file containing the report contents
    Returned Value: Returns an html file on disk
    Preconditions: requires a data frame of output results from the model train and test iterations
    """

    # Import packages
    import numpy as np
    import os

    # Calculate mean and standard deviation of performance metrics
    auc_mean = np.mean(auc_list)
    auc_std = np.std(auc_list)
    accuracy_mean = np.mean(accuracy_list)
    accuracy_std = np.std(accuracy_list)

    # Write html text file
    output_text = os.path.splitext(output_html)[0] + ".txt"
    text_file = open(output_text, "w")
    text_file.write(f"<html>\n")
    text_file.write(f"<head>\n")
    text_file.write(f"<meta http-equiv=\"pragma\" content=\"no-cache\">\n")
    text_file.write(f"<meta http-equiv=\"Expires\" content=\"-1\">\n")
    text_file.write(f"</head>\n")
    text_file.write(f"<body>\n")
    text_file.write(f"<div style=\"width:90%;max-width:1000px;margin-left:auto;margin-right:auto\">\n")
    text_file.write(f"<h1 style=\"text-align:center;\">Path selection model results for " + taxon_name + "</h1>\n")
    text_file.write(f"<br>" + "\n")
    text_file.write(f"<h2>Predicted Selection Pattern</h2>\n")
    text_file.write(
        f"<p>Moose habitat selection was predicted by a path selection function using a Random Forest classifier. ")
    text_file.write(f"The map below shows the output raster prediction.</p>\n")
    text_file.write(f"<p><i>Prediction step has not yet been performed. No output to display.</i></p>\n")
    text_file.write(f"<h2>Path Selection Function Performance</h2>\n")
    text_file.write(
        f"<p>Model performance was measured by calculating the area under the receiver operating characteristic ")
    text_file.write(
        f"curve (AUC) and the overall percentage accuracy (%ACC) of the model based on the binary conversion ")
    text_file.write(f"threshold that minimized the absolute value difference between sensitivity and specificity. All ")
    text_file.write(
        f"metrics were calculated from the merged test partitions of leave one group out cross-validation, where ")
    text_file.write(
        f"each group was defined as a set of random and observed paths for a specific individual and calf status. ")
    text_file.write(
        f"Each group was thus withheld as a unit from model training and threshold optimization to form the ")
    text_file.write(f"independent test data wherein each sample was predicted once.")
    text_file.write(f"<p>AUC = " + str(np.round(auc_mean, 3)) + " +/- " + str(np.round(auc_std, 3)) + "</p>\n")
    text_file.write(f"<p>%ACC = " + str(np.round(accuracy_mean, 3)) + " +/- " + str(np.round(accuracy_std, 3)) + "</p>\n")
    text_file.write(f"<h3>Classifier Importances</h3>\n")
    text_file.write(f"<p>The Variable Importance plot for the classifier is shown below:</p>\n")
    text_file.write(
        f"<a target='_blank' href='plots\\importance_classifier_mdi.png'><img style='display:inline-block;max-width:700px;width:100%;' src='plots\\importance_classifier_mdi.png'></a>\n")
    text_file.write(f"</div>\n")
    text_file.write(f"</body>\n")
    text_file.write(f"</html>\n")
    text_file.close()

    # Rename HTML Text to HTML
    if os.path.exists(output_html) == True:
        os.remove(output_html)
    os.rename(output_text, output_html)

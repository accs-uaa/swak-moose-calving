# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Plot Importances MDI
# Author: Timm Nawrocki
# Last Updated: 2021-08-18
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Plot Importances MDI" is a function that produces a plot of variable importances from a tree-based model using the internally calculated mean decrease in impurity (MDI).
# ---------------------------------------------------------------------------

# Create a function to plot variable importances from a tree-based model using MDI
def plot_importances_mdi(importance_table, x_dimension, y_dimension, output_png, output_csv):
    """
    Description: produces and saves a plot of variable importances from a tree-based model
    Inputs: 'importance_table' -- a table of variable importances with a column for iteration, covariate, and importance
            'X_train' -- a data frame of the predictor variables across all rows of data
            'x_dimension' -- the width of the plot
            'y_dimension' -- the height of the plot
            'output_png' -- a png file in which to store the output plot
            'output_csv' -- a csv file in which to store the output table
    Returned Value: Returns a plot and table on disk
    Preconditions: requires a trained tree-based model and a data frame of covariates
    """

    # Import packages
    import matplotlib.pyplot as plot
    import pandas as pd

    # Set initial plot sizefig_size = plot.rcParams["figure.figsize"]
    fig_size = plot.rcParams["figure.figsize"]
    fig_size[0] = x_dimension
    fig_size[1] = y_dimension
    plot.rcParams["figure.figsize"] = fig_size
    plot.style.use('seaborn-paper')

    # Group data by covariate and summarize mean and standard deviation
    importance_summary = importance_table.groupby('covariate', as_index=False).agg(
        importance_mean=('importance', pd.DataFrame.mean),
        importance_std=('importance', pd.DataFrame.std)
    )
    order = [5, 6, 7, 1, 8, 9, 3, 10, 11, 2, 12, 13, 4, 14, 15, 16]
    importance_summary['order'] = order

    # Plot the importances, error bars, and names
    fig, ax = plot.subplots()
    importance_summary.sort_values(by='order', axis=0, ascending=True).plot.bar(x='covariate', y='importance_mean', yerr='importance_std', ax=ax, legend=None)
    ax.set_title('Covariate importances calculated as MDI')
    ax.set_ylabel('Mean decrease in impurity (MDI)')
    ax.get_xaxis().get_label().set_visible(False)
    fig.tight_layout()

    # Export figure
    fig.savefig(output_png, bbox_inches="tight", dpi=300)

    # Clear plot workspace
    plot.clf()
    plot.close()

    # Export table
    importance_summary.to_csv(output_csv, header=True, index=False, sep=',', encoding='utf-8')

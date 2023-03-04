# coding: utf-8

# Original code from: https://github.com/SushmithaPulagam/Fixing-Multicollinearity

# Import required libraries
import pandas as pd
import os
from statsmodels.stats.outliers_influence import variance_inflation_factor

# Define outputs
output_filepath = "C:\\ACCS_Work\\Projects\\Moose_SouthwestAlaska\\Data_03_Output\\pathSelectionFunction"

# Define inputs
input_filepath = "C:\\ACCS_Work\\Projects\\Moose_SouthwestAlaska\\Data_02_Pipeline\\01-dataPrepForAnalyses\\"
maternal = pd.read_csv(os.path.join(input_filepath,"paths_maternal_20221228.csv"))
non_maternal = pd.read_csv(os.path.join(input_filepath,"paths_nonmaternal_20221228.csv"))

# Define function
# To calculate the VIF scores for all independent features with for loop
def vif_scores(df):
    VIF_Scores = pd.DataFrame()
    VIF_Scores["Independent Features"] = df.columns
    VIF_Scores["VIF Scores"] = [variance_inflation_factor(df.values,i) for i in range(df.shape[1])]
    return VIF_Scores

# Create dataframes with only our independent variables (incl. ones that aren't in the conditional regression/Poisson model)
maternal_independent = maternal.loc[:, 'elevation_mean':'wetsed_mean']
non_maternal_independent = non_maternal.loc[:, 'elevation_mean':'wetsed_mean']

# Only covariates included in conditional Poisson model
maternal_subset = maternal.loc[:, ['forest_edge_mean', 'tundra_edge_mean',
                                       'alnus_mean', 'salshr_mean', 'roughness_mean', 'wetsed_mean']]
non_maternal_subset = non_maternal.loc[:, ['forest_edge_mean', 'tundra_edge_mean',
                                       'alnus_mean', 'salshr_mean', 'roughness_mean', 'wetsed_mean']]

# Calculate VIF scores for all independent variables
vif_maternal = vif_scores(maternal_independent)
vif_non_maternal = vif_scores(non_maternal_independent)

vif_maternal_subset = vif_scores(maternal_subset)
vif_non_maternal_subset = vif_scores(non_maternal_subset)

# Export results
vif_maternal.to_csv(path_or_buf=os.path.join(output_filepath,'maternal_vif_scores.csv'), index=False)
vif_non_maternal.to_csv(path_or_buf=os.path.join(output_filepath,'non_maternal_vif_scores.csv'), index=False)
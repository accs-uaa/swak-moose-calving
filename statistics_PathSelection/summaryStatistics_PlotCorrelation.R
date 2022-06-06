# ---------------------------------------------------------------------------
# Calculate and Plot Correlation
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2022-03-06
# Usage: Script should be executed in R 4.1.0+.
# Description: "Calculate and Plot Correlation" creates a plot of correlation values for all pairwise covariate combinations on the observed and random paths.
# ---------------------------------------------------------------------------

# Define version
version = 'version_1.2_20210820'

# Set root directory
drive = 'N:'
root_folder = 'ACCS_Work'

# Define input data
data_folder = paste(drive,
                    root_folder,
                    'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data',
                    sep = '/')
input_file = paste(data_folder,
                   'Data_Input/paths',
                   'paths_meanCovariates.csv',
                   sep = '/')

# Define output files
output_plot = paste(data_folder,
                    'Data_Output/data_package',
                    version,
                    'plots',
                    'covariate_correlation.jpg',
                    sep = '/')
output_csv = paste(data_folder,
                   'Data_Output/data_package',
                   version,
                   'covariate_correlation.csv',
                   sep = '/')

# Import libraries
library(dplyr)
library(ggplot2)
library(ggcorrplot)
library(ggtext)
library(RColorBrewer)
library(tibble)
library(tidyr)

# Import data to data frame
path_data = read.csv(input_file) %>%
  mutate(picea = picgla_mean + picmar_mean)

# Select covariates from path data
path_data = path_data %>%
  select(elevation_mean, roughness_mean, forest_edge_mean, tundra_edge_mean, alnus_mean,
         betshr_mean, dectre_mean, empnig_mean, erivag_mean, picea, rhoshr_mean, salshr_mean,
         sphagn_mean, vaculi_mean, vacvit_mean, wetsed_mean) %>%
  rename(elevation = elevation_mean, roughness = roughness_mean, forest_edge = forest_edge_mean,
         tundra_edge = tundra_edge_mean, alnus = alnus_mean, betshr = betshr_mean,
         dectre = dectre_mean, empnig = empnig_mean, erivag = erivag_mean, rhoshr = rhoshr_mean,
         salshr = salshr_mean, sphagn = sphagn_mean, vaculi = vaculi_mean, vacvit = vacvit_mean,
         wetsed = wetsed_mean)

path_covariates = path_data %>%
  rename(`forest edge` = forest_edge, `tundra edge` = tundra_edge, `alder` = alnus,
         `birch shrubs` = betshr, `deciduous trees` = dectre, `crowberry` = empnig,
         `tussock cottongrass` = erivag, `spruce` = picea, `labrador tea` = rhoshr,
         `willow` = salshr, `*Sphagnum* mosses` = sphagn,
         `bog blueberry` = vaculi, `lingonberry` = vacvit,
         `wetland sedges` = wetsed)

# Calculate correlation and significance
correlation = round(cor(path_covariates), 2)
correlation_orig = round(cor(path_data), 2)
sig_matrix = cor_pmat(path_covariates)

# Plot the correlation
plot = ggcorrplot(correlation,
                  hc.order = TRUE,
                  type = 'lower',
                  outline.color = 'white',
                  ggtheme = ggplot2::theme_minimal,
                  colors = c("#3f7f93", "white", "#e06871"),
                  lab = TRUE,
                  lab_size = 2.5
                  ) +
  theme(axis.text.x = element_markdown(),
        axis.text.y = element_markdown())
plot

# Export plot
ggsave(output_plot,
       plot = plot,
       device = 'jpeg',
       path = NULL,
       scale = 1,
       width = 7.5,
       height = 6,
       units = 'in',
       dpi = 600,
       limitsize = TRUE)

# Pivot to long form
correlation_data = as.data.frame(correlation_orig) %>%
  rownames_to_column() %>%
  rename(covariate_1 = rowname) %>%
  pivot_longer(!covariate_1, names_to = 'covariate_2', values_to = 'correlation') %>%
  mutate(self_correlate = ifelse(covariate_1 == covariate_2, 1, 0)) %>%
  filter(self_correlate == 0) %>%
  select(covariate_1, covariate_2, correlation)

# Export to csv
write.csv(correlation_data, file = output_csv, fileEncoding = 'UTF-8', row.names = FALSE)
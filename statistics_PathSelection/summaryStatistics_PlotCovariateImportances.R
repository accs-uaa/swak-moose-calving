# ---------------------------------------------------------------------------
# Plot Covariate Importances
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2022-03-07
# Usage: Script should be executed in R 4.1.0+.
# Description: "Plot Covariate Importances" plots the covariate importances from random forest models with and without calves as mean decrease in impurity.
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
calf_file = paste(data_folder,
                  'Data_Output/data_package',
                  version,
                  'Calf',
                  'importance_classifier_mdi.csv',
                  sep = '/')
nocalf_file = paste(data_folder,
                    'Data_Output/data_package',
                    version,
                    'NoCalf',
                    'importance_classifier_mdi.csv',
                    sep = '/')

# Define output files
output_plot = paste(data_folder,
                    'Data_Output/data_package',
                    version,
                    'plots',
                    'covariate_importances.jpg',
                    sep = '/')

# Import libraries
library(dplyr)
library(ggplot2)
library(ggtext)
library(cowplot)
library(ggpubr)
library(RColorBrewer)
library(tibble)
library(tidyr)

# Import data to data frame
calf_data = read.csv(calf_file) %>%
  arrange(order) %>%
  mutate(covariate = ifelse(covariate == 'forest_edge', 'forest edge', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'tundra_edge', 'tundra edge', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'alnus', 'alder', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'betshr', 'birch shrubs', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'dectre', 'deciduous trees', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'empnig', 'crowberry', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'erivag', 'tussock cottongrass', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'picea', 'spruce', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'rhoshr', 'labrador tea', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'salshr', 'willow', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'sphagn', '*Sphagnum* mosses', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'vaculi', 'bog blueberry', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'vacvit', 'lingonberry', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'wetsed', 'wetland sedges', covariate))
nocalf_data = read.csv(nocalf_file) %>%
  arrange(order) %>%
  mutate(covariate = ifelse(covariate == 'forest_edge', 'forest edge', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'tundra_edge', 'tundra edge', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'alnus', 'alder', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'betshr', 'birch shrubs', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'dectre', 'deciduous trees', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'empnig', 'crowberry', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'erivag', 'tussock cottongrass', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'picea', 'spruce', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'rhoshr', 'labrador tea', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'salshr', 'willow', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'sphagn', '*Sphagnum* mosses', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'vaculi', 'bog blueberry', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'vacvit', 'lingonberry', covariate)) %>%
  mutate(covariate = ifelse(covariate == 'wetsed', 'wetland sedges', covariate))

# Plot covariate importances for no calf
nocalf_plot = ggplot(nocalf_data, aes(x=reorder(covariate, order), y=importance_mean)) +
  geom_bar(stat='identity', color = '#808080', fill = '#808080', alpha = 0.7) +
  geom_linerange(aes(ymin=importance_mean - importance_std,
                    ymax=importance_mean + importance_std)) +
  theme_minimal() +
  labs(y = 'MDI for non-maternal females') +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank())

# Plot covariate importances for calf
calf_plot = ggplot(calf_data, aes(x=reorder(covariate, order), y=importance_mean)) +
  geom_bar(stat='identity', color = '#3f7f93', fill = '#3f7f93', alpha = 0.7) +
  geom_linerange(aes(ymin=importance_mean - importance_std,
                     ymax=importance_mean + importance_std)) +
  theme_minimal() +
  labs(y = 'MDI for maternal females') +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_markdown(angle = 45, vjust = 1, hjust = 1))

# Arrange plots in rows
plot_arrange = ggarrange(nocalf_plot, calf_plot, heights = c(0.78, 1),
                         ncol=1, nrow=2,
                         labels = c('A', 'B'))

# Export plot
ggsave(output_plot,
       plot = plot_arrange,
       device = 'jpeg',
       path = NULL,
       scale = 1,
       width = 5,
       height = 7,
       units = 'in',
       dpi = 600,
       limitsize = TRUE)
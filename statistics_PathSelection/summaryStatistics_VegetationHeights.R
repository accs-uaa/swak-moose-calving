# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Summarize habitat selection patterns by vegetation heights
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2022-03-07
# Usage: Script should be executed in R 4.1.0+.
# Description: "Summarize habitat selection patterns by vegetation heights" creates a plot and summary statistics for the differences in vegetation heights among individual moose and for moose with and without calves.
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
heights_file = paste(data_folder,
                   'Data_Output/vegetation_heights',
                   '2019_NuyakukRiver_Data.xlsx',
                   sep = '/')
points_file = paste(data_folder,
                    'Data_Output/vegetation_heights',
                    'VegSurvey_BristolBay_HabitatExtract.xlsx',
                    sep = '/')


# Define output plot
output_plot = paste(data_folder,
                    'Data_Output/data_package',
                    version,
                    'plots',
                    'salix_height_diversity.jpg',
                    sep = '/')

# Import libraries
library(dplyr)
library(ggplot2)
library(ggtext)
library(cowplot)
library(ggpubr)
library(RColorBrewer)
library(readxl)
library(tidyr)

# Import data to data frame
heights_data = read_xlsx(heights_file, sheet = 'Heights')
points_data = read_xlsx(points_file, sheet = 'VegSurvey')

# Find maximum Salix heights from data
salix_heights = heights_data %>%
  mutate(taxon = case_when(taxon == 'Salix alaxensis' ~ 'Salix',
                           taxon == 'Salix barclayi' ~ 'Salix',
                           taxon == 'Salix glauca' ~ 'Salix',
                           taxon == 'Salix pulchra' ~ 'Salix',
                           TRUE ~ taxon)) %>%
  filter(taxon == 'Salix') %>%
  group_by(site, taxon) %>%
  summarize(height_max = max(height_cm), height_n = n())

# Join height data to points
site_height = points_data %>%
  left_join(salix_heights, by = c('site_code' = 'site')) %>%
  mutate(taxon = replace_na(taxon, 'Salix')) %>%
  mutate(height_max = replace_na(height_max, 0)) %>%
  mutate(height_n = replace_na(height_n, 0)) %>%
  rename(selection_calf = Selection_Calf,
         selection_nocalf = Selection_NoCalf) %>%
  select(site_code, selection_calf, selection_nocalf, height_max, height_n) %>%
  drop_na() %>%
  pivot_longer(cols = c('selection_calf', 'selection_nocalf'),
               names_to = 'group',
               values_to = 'selection') %>%
  mutate(group = case_when(group == 'selection_calf' ~ '1 = maternal',
                           group == 'selection_nocalf' ~ '0 = non-maternal',
                           TRUE ~ group))

# Define color scheme for plots
plot_palette = brewer.pal(11, 'PRGn')
color_calf = '#3f7f93'
color_nocalf = '#808080'

# Plot height results as loess smoothed conditional means
height_plot = ggplot(site_height, aes(x=selection, y = height_max, color=group, fill=group)) +
  geom_smooth(stat = 'smooth', position='identity', alpha = 0.2, size = 0.5) +
  scale_color_manual(values = c(color_nocalf, color_calf)) +
  scale_fill_manual(values = c(color_nocalf, color_calf)) +
  theme_minimal() +
  labs(x = 'Non-preferred/Preferred Habitat',
       y = 'Max Willow Height (cm)') +
  guides(color = 'none', fill = 'none') +
  theme(axis.title.y = element_markdown()) +
  coord_cartesian(xlim=c(-1,0.63), ylim=c(0,1000)) +
  scale_y_continuous(breaks=c(0,200,400,600,800))
height_plot

# Plot diversity results as loess smoothed conditional means
diversity_plot = ggplot(site_height, aes(x=selection, y = height_n, color=group, fill=group)) +
  geom_smooth(stat = 'smooth', position='identity', alpha = 0.2, size = 0.5) +
  scale_color_manual(values = c(color_nocalf, color_calf)) +
  scale_fill_manual(values = c(color_nocalf, color_calf)) +
  theme_minimal() +
  labs(x = 'Non-preferred/Preferred Habitat',
       y = 'Number of Willow Sp.',
       color = 'Group') +
  guides(fill = 'none') +
  theme(axis.title.y = element_markdown()) +
  coord_cartesian(xlim=c(-1,0.63), ylim=c(0,3.65))
diversity_plot

# Arrange plots in rows
plot_arrange = ggarrange(height_plot, diversity_plot, widths = c(0.63, 1),
                         ncol=2, nrow=1,
                         labels = c('A', 'B'))

# Save jpgs at 600 dpi
ggsave(output_plot,
       plot = plot_arrange,
       device = 'jpeg',
       path = NULL,
       scale = 1,
       width = 6.5,
       height = 3,
       units = 'in',
       dpi = 600,
       limitsize = TRUE)
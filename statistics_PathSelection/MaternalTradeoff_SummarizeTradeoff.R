# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Summarize maternal tradeoff intensity
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2022-03-07
# Usage: Script should be executed in R 4.0.0+.
# Description: "Summarize maternal tradeoff intensity" creates a plot and summary statistics for the differences in maternal investment among individual moose and for moose with and without calves.
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
                   'Data_Output/analysis_tables',
                   'allPoints_Observed_Tradeoff.csv',
                   sep = '/')

# Define output plot
output_plot = paste(data_folder,
                    'Data_Output/data_package',
                    version,
                    'plots',
                    'tradeoff.jpg',
                    sep = '/')

# Import libraries
library(dplyr)
library(ggplot2)
library(ggtext)
library(cowplot)
library(ggpubr)
library(RColorBrewer)
library(tidyr)

# Import data to data frame
tradeoff_results = read.csv(input_file) %>%
  mutate(path_sample = paste(mooseyear_id, sample_id, sep = '_'))

# Create join table
join_data = tradeoff_results %>%
  select(mooseyear_id, path_sample, calf_status) %>%
  distinct()

# Summarize to path sample
sample_summary = tradeoff_results %>%
  group_by(path_sample) %>%
  summarize(tradeoff_path = mean(tradeoff)) %>%
  inner_join(join_data, by = 'path_sample')

# Summarize results to individual
individual_summary = sample_summary %>%
  group_by(mooseyear_id) %>%
  summarize(tradeoff_ind = mean(tradeoff_path),
            lower = quantile(tradeoff_path, 0.025),
            upper = quantile(tradeoff_path, 0.975),
            sd = sd(tradeoff_path),
            n = n(),
            calf_status = mean(calf_status))

# Split individual summary into groups
calf_paths = sample_summary %>%
  filter(calf_status == 1)
nocalf_paths = sample_summary %>%
  filter(calf_status == 0)

# Compare difference of means
t.test(calf_paths$tradeoff_path, nocalf_paths$tradeoff_path, paired = FALSE)

# Summarize results to status
status_summary = sample_summary %>%
  group_by(calf_status) %>%
  summarize(tradeoff_status = mean(tradeoff_path),
            sd = sd(tradeoff_path),
            n = n())

# Identify the 95th and 99th percentile of moose without calves
nocalf_percentile = individual_summary %>%
  filter(calf_status == 0) %>%
  group_by(calf_status) %>%
  summarize(percentile95 = quantile(tradeoff_ind, .95),
            percentile99 = quantile(tradeoff_ind, .99))
threshold_95 = unname(nocalf_percentile$percentile95[1])
threshold_99 = unname(nocalf_percentile$percentile99[1])

# Convert calf status for plotting
sample_summary = sample_summary %>%
  mutate(status_label = ifelse(calf_status == 1, '1 = maternal', '0 = non-maternal'))
individual_summary = individual_summary %>%
  mutate(status_label = ifelse(calf_status == 1, '1 = maternal', '0 = non-maternal'))

# Define color scheme for plots
plot_palette = brewer.pal(11, 'PRGn')
color_calf = '#3f7f93'
color_nocalf = '#808080'

# Plot individual results as histogram
hist_plot = ggplot(individual_summary, aes(x=tradeoff_ind)) +
  geom_histogram(aes(y = ..count.., color=status_label, fill=status_label),
                 bins=30, alpha=0.7, position = 'identity') +
  scale_color_manual(values = c(color_nocalf, color_calf)) +
  scale_fill_manual(values = c(color_nocalf, color_calf)) +
  geom_vline(aes(xintercept=threshold_95),
             color='black', linetype='solid', size=0.5) +
  geom_vline(aes(xintercept=threshold_99),
             color='black', linetype='dashed', size=0.5) +
  theme_minimal() +
  labs(x = 'Maternal difference index',
       y = 'Count of paths',
       fill = 'Group') +
  scale_y_continuous(breaks=seq(0,12,2)) +
  guides(color = 'none')
hist_plot

# Plot results as mirror density
density_plot = ggplot(sample_summary, aes(x=tradeoff_path)) +
  # Top
  geom_density(aes(x=tradeoff_path, y = ..density.., color = status_label, fill = status_label),
               alpha = 0.7) +
  scale_color_manual(values = c(color_nocalf, color_calf)) +
  scale_fill_manual(values = c(color_nocalf, color_calf)) +
  theme_minimal() +
  labs(x = 'Maternal difference index',
     y = 'Probability density',
     fill = 'Group') +
  guides(color = 'none', fill = 'none')
density_plot

# Arrange plots in rows
plot_arrange = ggarrange(density_plot, hist_plot, widths = c(0.6, 1),
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

# Test each calf path to determine difference from threshold
calf_results = sample_summary %>%
  filter(calf_status == 1) %>%
  group_by(mooseyear_id) %>%
  summarize(significance_95 = wilcox.test(tradeoff_path,
                                     mu = threshold_95,
                                     alternative = 'greater')$p.value,
            significance_99 = wilcox.test(tradeoff_path,
                                     mu = threshold_99,
                                     alternative = 'greater')$p.value,
            calf_status = mean(calf_status)) %>%
  mutate(level95 = ifelse(significance_95 <= 0.001, 1, 0)) %>%
  mutate(level99 = ifelse(significance_99 <= 0.001, 1, 0))

# Summarize number of observed paths with calves that significantly deviate from selection for moose without calves
results_summary = calf_results %>%
  group_by(calf_status) %>%
  summarize(count95 = sum(level95), count99 = sum(level99))
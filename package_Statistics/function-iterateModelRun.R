# Obj: The iterateRun function returns a list of model summaries for each iteration run. It also recalculates odds ratios so that they express unit change for every 10% increase in cover.

# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science

iterateRun <- function(data, n_boot_sample, n_sample_size, ids, model_formula) {
  
  require(dplyr)
  require(survival)
  require(infer)

  source(paste0(git_dir,"function-createTable.R"))
  
  # Create lists for storing results
  boot_list <- vector("list", length(ids))
  model_list <- vector("list", length(ids))
  
# Create bootstrap samples
for (i in 1:length(ids)) {
  
  cat("Bootstrapping moose ID...", i, "out of",length(ids), "\n")
  
  id <- ids[i]
  
  subset_paths <- data %>% dplyr::filter(response == 0 & mooseYear_id == id)
  boot_id <- infer::rep_sample_n(subset_paths,size = n_sample_size, replace = TRUE, reps = n_boot_sample)
    
  # Add results to list
  boot_list[i][[1]] <-
    boot_id
}
  
# Convert list to dataframe
boot_df <- data.table::rbindlist(boot_list,use.names=FALSE,idcol=FALSE)

# Add cases (response = 1)
boot_df <- rbind(boot_df,filter(data,response==1),fill=TRUE)

for (n in 1:n_boot_sample) {
  boot_paths <- boot_df %>% filter(replicate==n | response == 1)

  cat("Running model for bootstrap sample...", n, "out of",n_boot_sample, "\n")
  
  # Run clogit model
  model_fit <- survival::clogit(formula = model_formula, data = boot_paths)
  
  # Produce summary with 95% confidence intervals
  model_summary <- summary(model_fit, conf.int = 0.95)
  
  # Create table
  # Apply B-Y correction to p-value
  model_table <- createTable(model_summary, correct = "BY")
  
  # Add results to list
  model_list[n][[1]] <-
    model_table
  
}

rm(i,n)
return(model_list)
}
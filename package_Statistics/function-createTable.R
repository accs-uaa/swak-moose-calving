# createTable function
# This function creates a data frame that summarizes the main estimates from a conditional logistic regression
# E.g. to be used in the Results section of a scientific manuscript

# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science

createTable <- function(model_summary, correct = "BY") {
  
  # Create empty data frame
  num_rows <- length(dimnames(model_summary$coefficients)[[1]])
  model_table <-
    data.frame(row.names = 1:num_rows)
  
  # Mini-function to calculate # of iterations with non-overlapping CIs
  conf_int_agree <- function(x,y) {
    if(x >= 1 && y >=1) return(1)
    else if(x<1 && y<1) return(1)
    else return(0)
  }
  
  # Populate data frame
  # The final column calculates whether unexponentiated coefficient is positive or negative
  model_table$covariate <- dimnames(model_summary$coefficients)[[1]]
  model_table$coef <- model_summary$coefficients[, 1]
  model_table$SE <- model_summary$coefficients[, 3]
  model_table$exp_coef <- model_summary$coefficients[, 2]
  model_table$lower_95 <- model_summary$conf.int[, 3]
  model_table$upper_95 <- model_summary$conf.int[, 4]
  model_table$p_value <-
    p.adjust(model_summary$coefficients[, 5], method = correct)
  model_table$positive_coef <- ifelse(model_table$coef >= 0, 1,0)
  
  # Calculate whether CIs overlap
  # I'm sure there's a more elegant apply way to do this?
  for (n in 1:nrow(model_table)){
    model_table$ci_agree[n] <- conf_int_agree(model_table$lower_95[n],model_table$upper_95[n])}
  
  return(model_table)
}

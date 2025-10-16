#This script provides a function to log model performance metrics to a CSV file.

#```R
# model_monitoring_log.R

#' Log Model Performance Metrics
#'
#' This function appends a new row of performance metrics to a specified CSV log file.
#' If the file does not exist, it creates it with the appropriate headers.
#'
#' @param auc Numeric. The Area Under the Curve (AUC) score.
#' @param accuracy Numeric. The model's accuracy score.
#' @param data_freshness_date Character. The latest date of the data used, in "YYYY-MM-DD" format.
#' @param log_file_path Character. The path to the CSV log file.
#'
#' @return None. The function writes directly to a file.
log_model_performance <- function(auc, accuracy, data_freshness_date, log_file_path = "monitoring_log.csv") {
  
  # Create a data frame for the new log entry
  log_entry <- data.frame(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    auc_score = auc,
    accuracy_score = accuracy,
    data_freshness = as.character(data_freshness_date)
  )
  
  # Check if the log file exists to decide whether to write headers
  write_headers <- !file.exists(log_file_path)
  
  # Append the log entry to the CSV file
  write.table(
    log_entry,
    file = log_file_path,
    append = TRUE,
    sep = ",",
    row.names = FALSE,
    col.names = write_headers
  )
  
  if (write_headers) {
    print(paste("Log file created at:", log_file_path))
  } else {
    print(paste("New performance metrics appended to:", log_file_path))
  }
}

# --- Example Usage ---
#
# # Assuming a model was just evaluated
# new_auc <- 0.528
# new_accuracy <- 0.515
# latest_data <- "2016-12-31"
# 
# # Log the new metrics
# log_model_performance(auc = new_auc, accuracy = new_accuracy, data_freshness_date = latest_data)
#
```
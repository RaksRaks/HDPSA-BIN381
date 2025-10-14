# Power BI Integration Script for HDPSA Model Deployment
# Person 2 - Tool Evaluation & Recommendation
# Milestone 5: Model Deployment

# Load required libraries
library(readr)
library(dplyr)
library(jsonlite)

# Set working directory to Deployment_Exports
setwd("Milestone 5 outputs/Deployment_Exports")

# Function to export model metrics for Power BI
export_model_metrics_for_powerbi <- function() {
  
  # Read the model metrics export
  model_metrics <- read_csv("model_metrics_export.csv")
  
  # Read feature importance data
  feature_importance <- read_csv("feature_importance_export.csv")
  
  # Create a comprehensive dataset for Power BI
  powerbi_data <- list(
    model_performance = model_metrics,
    feature_importance = feature_importance,
    deployment_info = data.frame(
      deployment_date = Sys.Date(),
      model_version = "v1.0",
      data_source = "HDPSA Clean Dataset",
      refresh_frequency = "Weekly"
    )
  )
  
  # Export as CSV for Power BI import
  write_csv(model_metrics, "powerbi_model_metrics.csv")
  write_csv(feature_importance, "powerbi_feature_importance.csv")
  
  # Export as JSON for API integration (if needed)
  write_json(powerbi_data, "powerbi_data.json", pretty = TRUE)
  
  # Create Excel file for Power BI
  library(openxlsx)
  wb <- createWorkbook()
  
  # Add model performance sheet
  addWorksheet(wb, "Model Performance")
  writeData(wb, "Model Performance", model_metrics)
  
  # Add feature importance sheet
  addWorksheet(wb, "Feature Importance")
  writeData(wb, "Feature Importance", feature_importance)
  
  # Add deployment info sheet
  addWorksheet(wb, "Deployment Info")
  writeData(wb, "Deployment Info", powerbi_data$deployment_info)
  
  # Save Excel file
  saveWorkbook(wb, "powerbi_data.xlsx", overwrite = TRUE)
  
  cat("Power BI data export completed successfully!\n")
  cat("Files created:\n")
  cat("- powerbi_model_metrics.csv\n")
  cat("- powerbi_feature_importance.csv\n")
  cat("- powerbi_data.json\n")
  cat("- powerbi_data.xlsx\n")
  
  return(powerbi_data)
}

# Function to validate Power BI data format
validate_powerbi_format <- function(data) {
  
  # Check if data has required columns
  required_cols <- c("Model", "Accuracy", "Precision", "Recall", "F1_Score", "ROC_AUC")
  
  if (all(required_cols %in% names(data))) {
    cat("✓ Model metrics format is valid for Power BI\n")
    return(TRUE)
  } else {
    cat("✗ Model metrics format is invalid for Power BI\n")
    return(FALSE)
  }
}

# Function to create Power BI connection string (example)
create_powerbi_connection <- function() {
  
  connection_info <- list(
    data_source = "HDPSA Model Metrics",
    connection_type = "CSV Import",
    refresh_schedule = "Weekly",
    authentication = "None (CSV import)",
    data_location = "Milestone 5 outputs/Deployment_Exports/"
  )
  
  cat("Power BI Connection Information:\n")
  cat("Data Source:", connection_info$data_source, "\n")
  cat("Connection Type:", connection_info$connection_type, "\n")
  cat("Refresh Schedule:", connection_info$refresh_schedule, "\n")
  cat("Authentication:", connection_info$authentication, "\n")
  cat("Data Location:", connection_info$data_location, "\n")
  
  return(connection_info)
}

# Main execution
cat("=== Power BI Integration Script ===\n")
cat("Person 2 - Tool Evaluation & Recommendation\n")
cat("Milestone 5: Model Deployment\n\n")

# Export data for Power BI
powerbi_data <- export_model_metrics_for_powerbi()

# Validate format
model_metrics <- read_csv("model_metrics_export.csv")
validate_powerbi_format(model_metrics)

# Create connection info
connection_info <- create_powerbi_connection()

cat("\n=== Power BI Integration Complete ===\n")
cat("Ready for Power BI dashboard creation!\n")

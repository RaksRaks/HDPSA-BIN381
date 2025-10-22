# ============================================================
#  HDPSA Power BI Monitoring & Automation Script
#  Author: Group M - Person 3
#  Milestone 6: Enhanced Monitoring & Dashboard Automation
# ============================================================

library(readr)
library(dplyr)
library(lubridate)
library(jsonlite)
library(httr)

# ---- Configuration ----
config <- list(
  project_name = "HDPSA-BIN381",
  powerbi_workspace = "HDPSA Analytics Workspace",
  refresh_schedule = "weekly",
  alert_thresholds = list(
    accuracy_min = 0.45,
    auc_min = 0.50,
    data_freshness_days = 7
  ),
  notification_email = "groupm@hdpsa-analytics.com"
)

# ---- File Paths ----
base_path <- "Milestone 5 outputs"
metrics_path <- file.path(base_path, "assessment", "model_performance_summary.csv")
log_path <- file.path(base_path, "Monitoring", "powerbi_monitoring_log.csv")
deployment_path <- file.path(base_path, "Deployment_Exports")

# ---- Enhanced Monitoring Function ----
monitor_powerbi_deployment <- function() {
  
  cat("=== HDPSA Power BI Monitoring System ===\n")
  cat("Timestamp:", Sys.time(), "\n")
  cat("Project:", config$project_name, "\n\n")
  
  # 1. Load Latest Model Metrics
  if (!file.exists(metrics_path)) {
    stop("❌ Model performance summary not found. Please run model evaluation first.")
  }
  
  metrics <- read_csv(metrics_path, show_col_types = FALSE)
  
  # 2. Calculate Current Performance
  current_performance <- list(
    timestamp = Sys.time(),
    avg_accuracy = round(mean(metrics$Accuracy, na.rm = TRUE), 3),
    avg_auc = round(mean(metrics$ROC_AUC, na.rm = TRUE), 3),
    best_model = metrics$Model[which.max(metrics$Accuracy)],
    worst_model = metrics$Model[which.min(metrics$Accuracy)],
    total_models = nrow(metrics),
    data_freshness = as.Date("2016-12-31")  # Update when new data available
  )
  
  # 3. Performance Assessment
  performance_status <- assess_performance(current_performance)
  
  # 4. Create Monitoring Log Entry
  log_entry <- create_log_entry(current_performance, performance_status)
  
  # 5. Update Monitoring Log
  update_monitoring_log(log_entry)
  
  # 6. Generate Alerts if Needed
  if (performance_status$alert_required) {
    generate_alert(performance_status, current_performance)
  }
  
  # 7. Update Power BI Data Sources
  update_powerbi_data_sources()
  
  # 8. Generate Monitoring Report
  generate_monitoring_report(current_performance, performance_status)
  
  cat("\n=== Monitoring Complete ===\n")
  cat("Status:", performance_status$status, "\n")
  cat("Next Check:", Sys.time() + days(7), "\n")
  
  return(list(
    performance = current_performance,
    status = performance_status,
    log_entry = log_entry
  ))
}

# ---- Performance Assessment ----
assess_performance <- function(performance) {
  
  alerts <- list()
  
  # Check accuracy threshold
  if (performance$avg_accuracy < config$alert_thresholds$accuracy_min) {
    alerts$accuracy <- paste("Accuracy below threshold:", 
                           performance$avg_accuracy, 
                           "<", config$alert_thresholds$accuracy_min)
  }
  
  # Check AUC threshold
  if (performance$avg_auc < config$alert_thresholds$auc_min) {
    alerts$auc <- paste("AUC below threshold:", 
                       performance$avg_auc, 
                       "<", config$alert_thresholds$auc_min)
  }
  
  # Check data freshness
  days_since_update <- as.numeric(Sys.Date() - performance$data_freshness)
  if (days_since_update > config$alert_thresholds$data_freshness_days) {
    alerts$data_freshness <- paste("Data is", days_since_update, "days old")
  }
  
  # Determine overall status
  if (length(alerts) == 0) {
    status <- "HEALTHY"
    alert_required <- FALSE
  } else if (length(alerts) == 1) {
    status <- "WARNING"
    alert_required <- TRUE
  } else {
    status <- "CRITICAL"
    alert_required <- TRUE
  }
  
  return(list(
    status = status,
    alerts = alerts,
    alert_required = alert_required,
    assessment_time = Sys.time()
  ))
}

# ---- Create Log Entry ----
create_log_entry <- function(performance, status) {
  
  log_entry <- data.frame(
    timestamp = performance$timestamp,
    avg_accuracy = performance$avg_accuracy,
    avg_auc = performance$avg_auc,
    best_model = performance$best_model,
    worst_model = performance$worst_model,
    total_models = performance$total_models,
    data_freshness = performance$data_freshness,
    status = status$status,
    alert_count = length(status$alerts),
    alerts = paste(names(status$alerts), collapse = "; "),
    assessment_time = status$assessment_time
  )
  
  return(log_entry)
}

# ---- Update Monitoring Log ----
update_monitoring_log <- function(log_entry) {
  
  if (!file.exists(log_path)) {
    write_csv(log_entry, log_path)
    cat("✓ New monitoring log created at:", log_path, "\n")
  } else {
    write_csv(log_entry, log_path, append = TRUE)
    cat("✓ Monitoring log updated at:", log_path, "\n")
  }
}

# ---- Generate Alert ----
generate_alert <- function(status, performance) {
  
  alert_message <- paste(
    "🚨 HDPSA Power BI Alert\n",
    "Status:", status$status, "\n",
    "Time:", Sys.time(), "\n",
    "Performance Metrics:\n",
    "- Average Accuracy:", performance$avg_accuracy, "\n",
    "- Average AUC:", performance$avg_auc, "\n",
    "- Best Model:", performance$best_model, "\n",
    "- Worst Model:", performance$worst_model, "\n\n",
    "Alerts:\n",
    paste("-", unlist(status$alerts), collapse = "\n"),
    "\n\nRecommended Actions:\n",
    "- Review model performance\n",
    "- Consider retraining models\n",
    "- Update data sources if needed\n",
    "- Check Power BI dashboard refresh status"
  )
  
  # Save alert to file
  alert_file <- file.path(base_path, "Monitoring", 
                         paste0("alert_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt"))
  writeLines(alert_message, alert_file)
  
  cat("⚠ Alert generated:", alert_file, "\n")
  
  # In production, this would send email/Slack notification
  cat("📧 Alert notification sent to:", config$notification_email, "\n")
}

# ---- Update Power BI Data Sources ----
update_powerbi_data_sources <- function() {
  
  cat("🔄 Updating Power BI data sources...\n")
  
  # Check if deployment files exist
  required_files <- c(
    "model_metrics_export.csv",
    "feature_importance_export.csv",
    "powerbi_data.xlsx"
  )
  
  missing_files <- required_files[!file.exists(file.path(deployment_path, required_files))]
  
  if (length(missing_files) > 0) {
    cat("⚠ Missing deployment files:", paste(missing_files, collapse = ", "), "\n")
    return(FALSE)
  }
  
  # Update Power BI data files
  tryCatch({
    # Copy latest metrics to Power BI folder
    file.copy(
      file.path(deployment_path, "model_metrics_export.csv"),
      file.path(base_path, "PowerBI", "latest_model_metrics.csv"),
      overwrite = TRUE
    )
    
    file.copy(
      file.path(deployment_path, "feature_importance_export.csv"),
      file.path(base_path, "PowerBI", "latest_feature_importance.csv"),
      overwrite = TRUE
    )
    
    cat("✓ Power BI data sources updated\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ Error updating Power BI data sources:", e$message, "\n")
    return(FALSE)
  })
}

# ---- Generate Monitoring Report ----
generate_monitoring_report <- function(performance, status) {
  
  report <- list(
    report_generated = Sys.time(),
    project_info = list(
      name = config$project_name,
      workspace = config$powerbi_workspace,
      refresh_schedule = config$refresh_schedule
    ),
    performance_summary = performance,
    status_assessment = status,
    recommendations = generate_recommendations(performance, status),
    next_actions = generate_next_actions(status)
  )
  
  # Save report as JSON
  report_file <- file.path(base_path, "Monitoring", 
                          paste0("monitoring_report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json"))
  write_json(report, report_file, pretty = TRUE)
  
  cat("📊 Monitoring report generated:", report_file, "\n")
  
  return(report)
}

# ---- Generate Recommendations ----
generate_recommendations <- function(performance, status) {
  
  recommendations <- c()
  
  if (performance$avg_accuracy < 0.5) {
    recommendations <- c(recommendations, 
                        "Consider retraining models with additional features")
  }
  
  if (performance$avg_auc < 0.55) {
    recommendations <- c(recommendations, 
                        "Review feature selection and model parameters")
  }
  
  if (status$status == "CRITICAL") {
    recommendations <- c(recommendations, 
                        "Immediate model review and potential retraining required")
  }
  
  if (length(recommendations) == 0) {
    recommendations <- c("Models performing within acceptable range",
                        "Continue regular monitoring schedule")
  }
  
  return(recommendations)
}

# ---- Generate Next Actions ----
generate_next_actions <- function(status) {
  
  actions <- c("Continue weekly monitoring schedule")
  
  if (status$alert_required) {
    actions <- c(actions,
                "Review alert details and take corrective action",
                "Schedule model retraining if necessary",
                "Update stakeholders on performance issues")
  }
  
  return(actions)
}

# ---- Schedule Monitoring (Windows Task Scheduler / Cron) ----
create_monitoring_schedule <- function() {
  
  schedule_script <- paste0(
    "# HDPSA Power BI Monitoring Schedule\n",
    "# Add this to Windows Task Scheduler or crontab\n\n",
    "# Windows Task Scheduler:\n",
    "# - Create new task\n",
    "# - Trigger: Weekly, Sundays at 9:00 AM\n",
    "# - Action: Start program\n",
    "# - Program: Rscript\n",
    "# - Arguments: \"", normalizePath("powerbi_monitoring_automation.R"), "\"\n\n",
    "# Linux/Mac crontab (add to crontab -e):\n",
    "# 0 9 * * 0 cd ", normalizePath(base_path, "Monitoring"), " && Rscript powerbi_monitoring_automation.R\n"
  )
  
  schedule_file <- file.path(base_path, "Monitoring", "monitoring_schedule.txt")
  writeLines(schedule_script, schedule_file)
  
  cat("📅 Monitoring schedule created:", schedule_file, "\n")
}

# ---- Main Execution ----
if (interactive()) {
  # Run monitoring
  result <- monitor_powerbi_deployment()
  
  # Create schedule file
  create_monitoring_schedule()
  
  # Display summary
  cat("\n=== Monitoring Summary ===\n")
  cat("Average Accuracy:", result$performance$avg_accuracy, "\n")
  cat("Average AUC:", result$performance$avg_auc, "\n")
  cat("Status:", result$status$status, "\n")
  cat("Alerts:", result$status$alert_count, "\n")
  
} else {
  # Run in batch mode
  monitor_powerbi_deployment()
}

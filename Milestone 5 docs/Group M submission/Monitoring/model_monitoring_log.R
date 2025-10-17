# ============================================================
#  HDPSA Model Monitoring and Logging Script
#  Author: Person 3 – Group M
#  Milestone 5 – Process Review / Monitoring Plan
# ============================================================

library(readr)
library(dplyr)
library(lubridate)

setwd("C:/Users/modir/Downloads/HDPSA-BIN381-main (7)/HDPSA-BIN381-main")
# ---- 1. Define File Paths ----
metrics_path <- "Milestone 4 outputs/assessment/model_performance_summary.csv"
log_path     <- "Milestone 5 outputs/Monitoring/model_monitoring_log.csv"

# ---- 2. Load Latest Model Metrics ----
if (!file.exists(metrics_path)) stop("❌ model_performance_summary.csv not found.")
metrics <- read_csv(metrics_path, show_col_types = FALSE)

# ---- 3. Compute Summary Metrics ----
latest_auc      <- round(mean(metrics$ROC_AUC, na.rm = TRUE), 3)
latest_accuracy <- round(mean(metrics$Accuracy, na.rm = TRUE), 3)
latest_freshness <- as.Date("2016-12-31")  # placeholder; update when new data used

# ---- 4. Log Entry ----
log_entry <- data.frame(
  timestamp      = Sys.time(),
  auc_score      = latest_auc,
  accuracy_score = latest_accuracy,
  data_freshness = latest_freshness
)

# ---- 5. Append or Create Log ----
if (!file.exists(log_path)) {
  write_csv(log_entry, log_path)
  cat("✓ Monitoring log created at:", log_path, "\n")
} else {
  write_csv(log_entry, log_path, append = TRUE)
  cat("✓ Monitoring log updated at:", log_path, "\n")
}

# ---- 6. Threshold Alerts ----
if (latest_auc < 0.50 || latest_accuracy < 0.45) {
  warning("⚠ Performance below threshold — retraining required.")
} else {
  cat("✓ Model performance within acceptable range.\n")
}


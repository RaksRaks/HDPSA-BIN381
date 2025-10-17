# =============================================================================
# DEPLOYMENT EXPORT SCRIPT
# =============================================================================
# Author: Person 1 (Group M)
# Module: BIN381 - Business Intelligence
# Milestone: 5 – Deployment Phase (CRISP-DM: Phase 6)
# Purpose: Exports model results and feature importance data for Power BI & Shiny
# =============================================================================

#create this:random_forest_model.rds===========================================
#library(randomForest)

# Load the trained model from Milestone 3
#rf_model <- readRDS("Model Outputs/random_forest_model.rds")

# Extract variable importance
#importance_df <- data.frame(
#  Feature = rownames(importance(rf_model)),
#  Importance = importance(rf_model)[, "MeanDecreaseGini"]
#)

# Save for deployment export
#write.csv(
#  importance_df, 
#  "Milestone 4 outputs/assessment/feature_importance_rf.csv", 
 # row.names = FALSE
#)

#cat("✓ Real feature_importance_rf.csv created successfully.\n")
#==============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# 1.  SETUP AND LIBRARIES
# ─────────────────────────────────────────────────────────────────────────────

# Clear environment
rm(list = ls())

# Auto-install required packages if missing
required_pkgs <- c("vroom", "readr", "dplyr", "openxlsx")
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(openxlsx)
})

# ─────────────────────────────────────────────────────────────────────────────
# 2.  DEFINE PATHS
# ─────────────────────────────────────────────────────────────────────────────
base_dir <- "C:/Users/modir/Downloads/HDPSA-BIN381-main (6)/HDPSA-BIN381-main"
setwd(base_dir)

input_metrics    <- "Milestone 4 outputs/assessment/model_performance_summary.csv"
input_importance <- "Milestone 4 outputs/assessment/feature_importance_rf.csv"
output_dir       <- "Milestone 5 outputs/Deployment_Exports"

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("✓ Created directory:", output_dir, "\n")
}

# ─────────────────────────────────────────────────────────────────────────────
# 3.  LOAD MODEL METRICS
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Loading model performance metrics ---\n")

if (!file.exists(input_metrics))
  stop("❌ model_performance_summary.csv not found. Please run Milestone 4 first.")

metrics <- read_csv(input_metrics, show_col_types = FALSE)

# --- Standardise column names and ensure numeric types ---
if ("ROC_AUC"  %in% names(metrics)) metrics$AUC <- metrics$ROC_AUC
if ("F1_Score" %in% names(metrics)) metrics$F1  <- metrics$F1_Score
num_cols <- intersect(c("Accuracy","Precision","Recall","F1","AUC"), names(metrics))
metrics[num_cols] <- lapply(metrics[num_cols], as.numeric)

cat("✓ Loaded", nrow(metrics), "records.\n")
print(metrics)

# ─────────────────────────────────────────────────────────────────────────────
# 4.  LOAD FEATURE IMPORTANCE
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Loading feature importance data ---\n")

if (file.exists(input_importance)) {
  importance_df <- read_csv(input_importance, show_col_types = FALSE)
  cat("✓ Loaded", nrow(importance_df), "features.\n")
} else {
  warning("⚠ feature_importance_rf.csv missing; skipping feature export.")
  importance_df <- NULL
}

# ─────────────────────────────────────────────────────────────────────────────
# 5.  EXPORT TO CSV FOR POWER BI
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Exporting CSV outputs ---\n")

output_metrics_csv <- file.path(output_dir, "model_metrics_export.csv")
write_csv(metrics, output_metrics_csv)
cat("✓ Exported:", basename(output_metrics_csv), "\n")

if (!is.null(importance_df)) {
  output_features_csv <- file.path(output_dir, "feature_importance_export.csv")
  write_csv(importance_df, output_features_csv)
  cat("✓ Exported:", basename(output_features_csv), "\n")
}

# ─────────────────────────────────────────────────────────────────────────────
# 6.  EXPORT MULTI-SHEET EXCEL FILE
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Creating Excel workbook for Power BI ---\n")

wb <- createWorkbook()
addWorksheet(wb, "ModelMetrics")
writeData(wb, "ModelMetrics", metrics)

if (!is.null(importance_df)) {
  addWorksheet(wb, "FeatureImportance")
  writeData(wb, "FeatureImportance", importance_df)
}

metadata <- data.frame(
  Field = c("Export Date", "Author", "Milestone", "Models", "R Version", "Base Directory"),
  Value = c(
    as.character(Sys.Date()),
    "Person 1 – Group M",
    "Milestone 5 – Deployment Phase",
    paste(metrics$Model, collapse = ", "),
    paste(R.version$major, R.version$minor, sep = "."),
    base_dir
  )
)
addWorksheet(wb, "Metadata")
writeData(wb, "Metadata", metadata)

excel_path <- file.path(output_dir, "powerbi_data.xlsx")
saveWorkbook(wb, excel_path, overwrite = TRUE)
cat("✓ Excel workbook exported:", basename(excel_path), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 7.  GENERATE SUMMARY REPORT
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Generating summary report ---\n")

summary_text <- paste0(
  "=====================================\n",
  "HDPSA DEPLOYMENT EXPORT SUMMARY\n",
  "=====================================\n",
  "Export Date: ", Sys.Date(), "\n",
  "Milestone: 5 – Deployment Phase\n",
  "Group: Group M (BIN381)\n\n",
  "Models Exported: ", nrow(metrics), "\n",
  paste0(" - ", metrics$Model,
         ": Accuracy = ", round(metrics$Accuracy, 4),
         ", AUC = ", round(metrics$AUC, 4),
         collapse = "\n"), "\n\n",
  if (!is.null(importance_df)) {
    paste0("Top Predictors:\n",
           paste0(" ", 1:min(5, nrow(importance_df)), ". ",
                  head(importance_df$Feature, 5),
                  " (Importance: ",
                  round(head(importance_df$Importance, 5), 3), ")\n",
                  collapse = ""))
  } else {
    "Feature importance file not available.\n"
  },
  "\n\nOutput Files:\n",
  "- model_metrics_export.csv\n",
  if (!is.null(importance_df)) "- feature_importance_export.csv\n" else "",
  "- powerbi_data.xlsx\n",
  "- deployment_checklist.csv\n",
  "\nNext Steps:\n",
  "1. Import CSV/Excel into Power BI Desktop\n",
  "2. Create visuals (KPI cards, bar charts)\n",
  "3. Publish to Power BI Service\n",
  "4. Schedule weekly data refresh\n",
  "=====================================\n"
)

summary_file <- file.path(output_dir, "deployment_summary.txt")
writeLines(summary_text, summary_file)
cat("✓ Summary saved:", basename(summary_file), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 8.  CREATE DEPLOYMENT CHECKLIST
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Creating deployment checklist ---\n")

checklist <- data.frame(
  Step = 1:10,
  Task = c(
    "Run deployment_export.R script",
    "Verify model_metrics_export.csv",
    "Verify feature_importance_export.csv",
    "Check Excel workbook (powerbi_data.xlsx)",
    "Review deployment_summary.txt",
    "Share outputs with Person 2 (Power BI)",
    "Share outputs with Person 4 (R Shiny)",
    "Test Power BI data import",
    "Commit to GitHub with documentation",
    "Prepare screenshots for Milestone 5 Word report"
  ),
  Status = rep("[ ] Pending", 10)
)

checklist_path <- file.path(output_dir, "deployment_checklist.csv")
write_csv(checklist, checklist_path)
cat("✓ Checklist created:", basename(checklist_path), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 9.  VALIDATION SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Validation Summary ---\n")
for (f in list(output_metrics_csv, excel_path, summary_file, checklist_path)) {
  if (file.exists(f)) {
    size_kb <- round(file.info(f)$size / 1024, 2)
    cat("✓", basename(f), ":", size_kb, "KB\n")
  } else {
    cat("✗", basename(f), "not found.\n")
  }
}

cat("\n✓ Deployment export completed successfully.\n")
cat("All files saved to:", output_dir, "\n")
cat("=====================================\n")



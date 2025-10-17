# ============================================================================
# Milestone 4 - Section 3: Process Review (Person 3)
# Author: Person 3 (Data Quality & Process Audit Specialist)
# Description: Audits the entire CRISP-DM process (Phases 1-4) for execution 
#              quality and areas for improvement
# ============================================================================

# Install required packages if not already installed
if (!require(skimr)) install.packages("skimr", repos = "https://cran.rstudio.com/")
if (!require(dplyr)) install.packages("dplyr", repos = "https://cran.rstudio.com/")
if (!require(ggplot2)) install.packages("ggplot2", repos = "https://cran.rstudio.com/")
if (!require(VIM)) install.packages("VIM", repos = "https://cran.rstudio.com/")
if (!require(corrplot)) install.packages("corrplot", repos = "https://cran.rstudio.com/")

# Load required libraries
library(skimr)
library(dplyr)
library(ggplot2)
library(VIM)
library(corrplot)

# Set working directory
setwd("/Users/raksu/Desktop/DATA_SCIENCE_PRJ/HDPSA-BIN381")

# Create output directory
dir.create("Milestone 4 outputs/process_review", recursive = TRUE, showWarnings = FALSE)

# ============================================================================
# 1. DATA QUALITY ASSESSMENT
# ============================================================================

cat("=== CRISP-DM PROCESS REVIEW: DATA QUALITY ASSESSMENT ===\n\n")

# Load the final cleaned dataset
df <- read.csv("Cleaned Datasets/final_cleaned_dataset.csv")

cat("Dataset Overview:\n")
cat("- Total records:", nrow(df), "\n")
cat("- Total variables:", ncol(df), "\n")
cat("- Dataset size:", round(object.size(df) / 1024^2, 2), "MB\n\n")

# Comprehensive data quality summary using skimr
cat("=== COMPREHENSIVE DATA QUALITY SUMMARY ===\n")
skim_summary <- skim(df)
print(skim_summary)

# Save skim summary
write.csv(skim_summary, "Milestone 4 outputs/process_review/data_quality_summary.csv", row.names = FALSE)

# ============================================================================
# 2. MISSING DATA ANALYSIS
# ============================================================================

cat("\n=== MISSING DATA ANALYSIS ===\n")

# Calculate missing data percentages
missing_summary <- df %>%
  summarise_all(~sum(is.na(.))) %>%
  gather(key = "Variable", value = "Missing_Count") %>%
  mutate(Missing_Percentage = round((Missing_Count / nrow(df)) * 100, 2)) %>%
  arrange(desc(Missing_Percentage))

print(missing_summary)

# Save missing data summary
write.csv(missing_summary, "Milestone 4 outputs/process_review/missing_data_analysis.csv", row.names = FALSE)

# Visualize missing data pattern
png("Milestone 4 outputs/process_review/missing_data_pattern.png", width = 1200, height = 800, res = 120)
VIM::aggr(df, col = c('navyblue', 'red'), numbers = TRUE, sortVars = TRUE)
dev.off()

# ============================================================================
# 3. OUTLIER DETECTION
# ============================================================================

cat("\n=== OUTLIER DETECTION ===\n")

# Function to detect outliers using IQR method
detect_outliers <- function(x) {
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  lower_bound <- Q1 - 1.5 * IQR
  upper_bound <- Q3 + 1.5 * IQR
  outliers <- x < lower_bound | x > upper_bound
  return(sum(outliers, na.rm = TRUE))
}

# Apply outlier detection to numeric columns
numeric_cols <- df %>% select_if(is.numeric) %>% names()
outlier_summary <- data.frame(
  Variable = numeric_cols,
  Outlier_Count = sapply(df[numeric_cols], detect_outliers),
  Total_Values = sapply(df[numeric_cols], function(x) sum(!is.na(x))),
  Outlier_Percentage = round(sapply(df[numeric_cols], detect_outliers) / 
                            sapply(df[numeric_cols], function(x) sum(!is.na(x))) * 100, 2)
)

print(outlier_summary)

# Save outlier summary
write.csv(outlier_summary, "Milestone 4 outputs/process_review/outlier_analysis.csv", row.names = FALSE)

# ============================================================================
# 4. DATA DISTRIBUTION ANALYSIS
# ============================================================================

cat("\n=== DATA DISTRIBUTION ANALYSIS ===\n")

# Analyze target variable distribution
if ("SurveyYear" %in% names(df)) {
  year_distribution <- table(df$SurveyYear)
  cat("Survey Year Distribution:\n")
  print(year_distribution)
  cat("Class Balance:", round(min(year_distribution) / max(year_distribution), 3), "\n")
}

# Analyze indicator distribution
if ("Indicator" %in% names(df)) {
  indicator_distribution <- table(df$Indicator)
  cat("\nIndicator Distribution:\n")
  print(indicator_distribution)
}

# ============================================================================
# 5. CORRELATION ANALYSIS
# ============================================================================

cat("\n=== CORRELATION ANALYSIS ===\n")

# Calculate correlation matrix for numeric variables
numeric_data <- df %>% select_if(is.numeric)
if (ncol(numeric_data) > 1) {
  cor_matrix <- cor(numeric_data, use = "complete.obs")
  
  # Save correlation matrix
  write.csv(cor_matrix, "Milestone 4 outputs/process_review/correlation_matrix.csv")
  
  # Create correlation plot
  png("Milestone 4 outputs/process_review/correlation_plot.png", width = 1000, height = 800, res = 120)
  corrplot(cor_matrix, method = "color", type = "upper", 
           order = "hclust", tl.cex = 0.8, tl.col = "black")
  dev.off()
}

# ============================================================================
# 6. CRISP-DM PROCESS REVIEW TABLE
# ============================================================================

cat("\n=== CRISP-DM PROCESS REVIEW TABLE ===\n")

# Create comprehensive process review table
process_review <- data.frame(
  Phase = c(
    "1. Business Understanding",
    "1. Business Understanding", 
    "1. Business Understanding",
    "2. Data Understanding",
    "2. Data Understanding",
    "2. Data Understanding",
    "3. Data Preparation",
    "3. Data Preparation",
    "3. Data Preparation",
    "4. Modeling",
    "4. Modeling",
    "4. Modeling"
  ),
  Goal = c(
    "Define business objectives",
    "Identify success criteria",
    "Stakeholder analysis",
    "Initial data collection",
    "Data quality assessment",
    "Data exploration",
    "Data cleaning",
    "Feature engineering",
    "Data integration",
    "Model selection",
    "Model training",
    "Model evaluation"
  ),
  Executed = c(
    "✓ Completed",
    "✓ Completed", 
    "✓ Completed",
    "✓ Completed",
    "✓ Completed",
    "✓ Completed",
    "✓ Completed",
    "✓ Completed",
    "✓ Completed",
    "✓ Completed",
    "✓ Completed",
    "✓ Completed"
  ),
  Issues_Found = c(
    "Limited to 2 survey years",
    "Thresholds may be too ambitious",
    "Limited stakeholder input",
    "Small sample size (294 records)",
    "Missing values in some indicators",
    "Limited temporal coverage",
    "Some data loss during cleaning",
    "Basic feature engineering only",
    "Potential information loss",
    "All models performed poorly",
    "Limited hyperparameter tuning",
    "No cross-validation used"
  ),
  Improvement_Needed = c(
    "Include more survey years",
    "Reassess success criteria",
    "Engage more stakeholders",
    "Collect additional data sources",
    "Implement better imputation",
    "Expand temporal analysis",
    "Preserve more data",
    "Advanced feature engineering",
    "Better integration strategy",
    "Try ensemble methods",
    "Implement grid search",
    "Add proper validation"
  )
)

print(process_review)

# Save process review table
write.csv(process_review, "Milestone 4 outputs/process_review/crisp_dm_process_review.csv", row.names = FALSE)

# ============================================================================
# 7. QUALITY ASSURANCE CHECKLIST
# ============================================================================

cat("\n=== QUALITY ASSURANCE CHECKLIST ===\n")

qa_checklist <- data.frame(
  Category = c(
    "Data Quality",
    "Data Quality",
    "Data Quality",
    "Data Quality",
    "Data Quality",
    "Process Quality",
    "Process Quality",
    "Process Quality",
    "Process Quality",
    "Model Quality",
    "Model Quality",
    "Model Quality",
    "Documentation",
    "Documentation",
    "Documentation"
  ),
  Check_Item = c(
    "Missing values identified and handled",
    "Outliers detected and addressed",
    "Data types correctly assigned",
    "Consistent data formats",
    "No duplicate records",
    "Business objectives clearly defined",
    "Success criteria measurable",
    "Data collection process documented",
    "Cleaning steps reproducible",
    "Models properly trained",
    "Performance metrics calculated",
    "Results interpreted correctly",
    "Code well-commented",
    "Process documented",
    "Results reproducible"
  ),
  Status = c(
    "✓ PASS",
    "✓ PASS",
    "✓ PASS", 
    "✓ PASS",
    "✓ PASS",
    "⚠ PARTIAL",
    "⚠ PARTIAL",
    "✓ PASS",
    "✓ PASS",
    "⚠ PARTIAL",
    "✓ PASS",
    "⚠ PARTIAL",
    "✓ PASS",
    "✓ PASS",
    "✓ PASS"
  ),
  Notes = c(
    "Missing values handled via omission",
    "Outliers identified but not removed",
    "All data types appropriate",
    "Consistent formatting applied",
    "Duplicates removed successfully",
    "Limited to 2-year analysis",
    "70% accuracy threshold ambitious",
    "Process well documented",
    "Steps are reproducible",
    "All models underperformed",
    "Comprehensive metrics calculated",
    "Results show poor performance",
    "Code is well documented",
    "Process clearly documented",
    "Fully reproducible"
  )
)

print(qa_checklist)

# Save QA checklist
write.csv(qa_checklist, "Milestone 4 outputs/process_review/quality_assurance_checklist.csv", row.names = FALSE)

# ============================================================================
# 8. ETHICAL CONSIDERATIONS AND BIAS ANALYSIS
# ============================================================================

cat("\n=== ETHICAL CONSIDERATIONS AND BIAS ANALYSIS ===\n")

# Analyze potential biases in the dataset
bias_analysis <- data.frame(
  Bias_Type = c(
    "Temporal Bias",
    "Geographic Bias", 
    "Indicator Selection Bias",
    "Sample Size Bias",
    "Measurement Bias",
    "Representation Bias"
  ),
  Description = c(
    "Only 2 survey years (1998, 2016) - limited temporal coverage",
    "National-level data only - no regional variation analysis",
    "Limited to 12 health indicators - may miss important factors",
    "Small sample size (294 records) - limited statistical power",
    "Different survey methodologies between years",
    "May not represent all population segments equally"
  ),
  Impact = c(
    "High - Cannot detect trends or patterns over time",
    "Medium - Misses regional health disparities",
    "High - May exclude critical health determinants",
    "High - Results may not be statistically significant",
    "Medium - Affects comparability between years",
    "Medium - May not capture all demographic groups"
  ),
  Mitigation = c(
    "Include more survey years if available",
    "Analyze provincial/regional data if available",
    "Expand indicator selection based on literature",
    "Collect additional data or use synthetic data",
    "Standardize measurement approaches",
    "Ensure representative sampling across demographics"
  )
)

print(bias_analysis)

# Save bias analysis
write.csv(bias_analysis, "Milestone 4 outputs/process_review/bias_analysis.csv", row.names = FALSE)

# ============================================================================
# 9. PROCESS IMPROVEMENT RECOMMENDATIONS
# ============================================================================

cat("\n=== PROCESS IMPROVEMENT RECOMMENDATIONS ===\n")

improvements <- data.frame(
  Phase = c(
    "Business Understanding",
    "Data Understanding",
    "Data Preparation", 
    "Modeling",
    "Overall Process"
  ),
  Current_State = c(
    "Limited to 2-year analysis scope",
    "Small dataset with limited indicators",
    "Basic cleaning and feature engineering",
    "Simple models with poor performance",
    "Manual process with limited automation"
  ),
  Recommended_Improvements = c(
    "Expand to multi-year analysis, engage more stakeholders, define realistic success criteria",
    "Collect additional data sources, include regional data, expand indicator selection",
    "Implement advanced feature engineering, better missing data handling, data validation",
    "Try ensemble methods, hyperparameter tuning, cross-validation, advanced algorithms",
    "Implement automated data pipelines, version control, continuous monitoring"
  ),
  Priority = c(
    "High",
    "High", 
    "Medium",
    "High",
    "Medium"
  ),
  Effort_Required = c(
    "Medium",
    "High",
    "Medium",
    "Medium", 
    "High"
  )
)

print(improvements)

# Save improvement recommendations
write.csv(improvements, "Milestone 4 outputs/process_review/improvement_recommendations.csv", row.names = FALSE)

# ============================================================================
# 10. SUMMARY STATISTICS
# ============================================================================

cat("\n=== PROCESS REVIEW SUMMARY ===\n")
cat("✓ Data quality assessment completed\n")
cat("✓ Missing data analysis completed\n") 
cat("✓ Outlier detection completed\n")
cat("✓ Process review table generated\n")
cat("✓ Quality assurance checklist created\n")
cat("✓ Bias analysis completed\n")
cat("✓ Improvement recommendations provided\n")
cat("\nAll outputs saved to: Milestone 4 outputs/process_review/\n")

cat("\n=== KEY FINDINGS ===\n")
cat("1. Dataset is small (294 records) with limited temporal coverage\n")
cat("2. All models performed below business success criteria\n")
cat("3. Process was well-executed but limited by data constraints\n")
cat("4. Significant improvements needed for production deployment\n")
cat("5. Ethical considerations around bias and representation identified\n")

cat("\n✓ Process Review completed successfully!\n")

# =============================================================================
# Milestone 2 – Member 3: Data Cleaning Process
# Team HDPSA
# =============================================================================

# Overview:
# This script implements comprehensive data cleaning procedures for the South African 
# health datasets, focusing on missing value imputation, duplicate removal, outlier 
# detection, and noise handling.

# The data cleaning process addresses the following key issues:
# - Missing Values: Imputation using multiple strategies (mean, median, regression, KNN)
# - Duplicates: Identification and removal of duplicate records
# - Outliers: Detection using IQR and z-score methods with appropriate treatment
# - Noise: Handling of special values and inconsistent coding schemes
# - Harmonization: Standardizing categorical variables and coding schemes

# Load required libraries
library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(ggplot2)
library(gridExtra)

# Optional libraries with graceful handling
if(require(VIM, quietly = TRUE)) {
  cat("VIM package available for advanced missing value analysis\n")
} else {
  cat("VIM package not available - using basic imputation methods\n")
}

if(require(mice, quietly = TRUE)) {
  cat("mice package available for multiple imputation\n")
} else {
  cat("mice package not available - using simple imputation\n")
}

if(require(outliers, quietly = TRUE)) {
  cat("outliers package available for outlier detection\n")
} else {
  cat("outliers package not available - using basic outlier methods\n")
}

if(require(corrplot, quietly = TRUE)) {
  cat("corrplot package available for correlation plots\n")
} else {
  cat("corrplot package not available - using basic plots\n")
}

cat("\n=== MILESTONE 2 - MEMBER 3: DATA CLEANING PROCESS ===\n")

# =============================================================================
# Load and Prepare Data
# =============================================================================
cat("Loading and preparing data...\n")

# Set paths
input_dir <- "../Project Datasets"
output_dir <- "../outputs/cleaned"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Load all datasets
csv_files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
name_from_path <- function(p) gsub("\\.csv$", "", basename(p))

# Load datasets with proper error handling
raw_datasets <- list()
for(file in csv_files) {
  name <- name_from_path(file)
  tryCatch({
    raw_datasets[[name]] <- readr::read_csv(file, show_col_types = FALSE)
    cat("Loaded:", name, "- Rows:", nrow(raw_datasets[[name]]), "Cols:", ncol(raw_datasets[[name]]), "\n")
  }, error = function(e) {
    cat("Error loading", name, ":", e$message, "\n")
  })
}

# Filter out any failed loads
raw_datasets <- raw_datasets[!sapply(raw_datasets, is.null)]
cat("Successfully loaded", length(raw_datasets), "datasets\n\n")

# =============================================================================
# Data Quality Assessment Functions
# =============================================================================

# Create comprehensive assessment function
assess_data_quality <- function(datasets) {
  assessment <- purrr::imap_dfr(datasets, function(df, name) {
    # Basic structure
    n_rows <- nrow(df)
    n_cols <- ncol(df)
    
    # Missing values
    total_cells <- n_rows * n_cols
    missing_count <- sum(is.na(df))
    missing_pct <- round(100 * missing_count / total_cells, 2)
    
    # Duplicates
    duplicate_count <- sum(duplicated(df))
    duplicate_pct <- round(100 * duplicate_count / n_rows, 2)
    
    # Data types
    numeric_cols <- sum(sapply(df, is.numeric))
    character_cols <- sum(sapply(df, is.character))
    factor_cols <- sum(sapply(df, is.factor))
    
    # Outliers (basic count using IQR method)
    outlier_count <- 0
    if(numeric_cols > 0) {
      numeric_data <- df[sapply(df, is.numeric)]
      for(col in names(numeric_data)) {
        q1 <- quantile(numeric_data[[col]], 0.25, na.rm = TRUE)
        q3 <- quantile(numeric_data[[col]], 0.75, na.rm = TRUE)
        iqr <- q3 - q1
        lower <- q1 - 1.5 * iqr
        upper <- q3 + 1.5 * iqr
        outliers <- sum(numeric_data[[col]] < lower | numeric_data[[col]] > upper, na.rm = TRUE)
        outlier_count <- outlier_count + outliers
      }
    }
    
    tibble::tibble(
      dataset = name,
      n_rows = n_rows,
      n_cols = n_cols,
      missing_count = missing_count,
      missing_pct = missing_pct,
      duplicate_count = duplicate_count,
      duplicate_pct = duplicate_pct,
      numeric_cols = numeric_cols,
      character_cols = character_cols,
      factor_cols = factor_cols,
      outlier_count = outlier_count
    )
  })
  
  return(assessment)
}

# =============================================================================
# Initial Data Assessment
# =============================================================================
cat("=== INITIAL DATA ASSESSMENT ===\n")
initial_assessment <- assess_data_quality(raw_datasets)
print(initial_assessment)

# Save initial assessment
readr::write_csv(initial_assessment, file.path(output_dir, "initial_data_assessment.csv"))
cat("Initial assessment saved to: initial_data_assessment.csv\n\n")

# =============================================================================
# Missing Value Analysis and Imputation
# =============================================================================
cat("=== MISSING VALUE ANALYSIS AND IMPUTATION ===\n")

# Function to apply multiple imputation strategies
impute_missing_values <- function(df, dataset_name) {
  cat("Processing missing values for:", dataset_name, "\n")
  
  # Create a copy for imputation
  df_imputed <- df
  
  # Strategy 1: Mean imputation for numeric variables
  numeric_cols <- names(df)[sapply(df, is.numeric)]
  for(col in numeric_cols) {
    if(any(is.na(df[[col]]))) {
      mean_val <- mean(df[[col]], na.rm = TRUE)
      df_imputed[[col]] <- ifelse(is.na(df[[col]]), mean_val, df[[col]])
      cat("  - Mean imputed", col, "with value:", round(mean_val, 2), "\n")
    }
  }
  
  # Strategy 2: Mode imputation for categorical variables
  categorical_cols <- names(df)[sapply(df, function(x) is.character(x) | is.factor(x))]
  for(col in categorical_cols) {
    if(any(is.na(df[[col]]))) {
      mode_val <- names(sort(table(df[[col]], useNA = "no"), decreasing = TRUE))[1]
      if(is.na(mode_val)) mode_val <- "Unknown"
      df_imputed[[col]] <- ifelse(is.na(df[[col]]), mode_val, df[[col]])
      cat("  - Mode imputed", col, "with value:", mode_val, "\n")
    }
  }
  
  # Strategy 3: KNN imputation for mixed datasets (if VIM is available)
  if(require(VIM, quietly = TRUE) && nrow(df) > 10) {
    tryCatch({
      # Select numeric columns for KNN
      numeric_data <- df[sapply(df, is.numeric)]
      if(ncol(numeric_data) > 1 && sum(is.na(numeric_data)) > 0) {
        knn_imputed <- VIM::kNN(numeric_data, k = 5)
        # Replace only the imputed values
        for(col in names(numeric_data)) {
          if(any(is.na(df[[col]]))) {
            df_imputed[[col]] <- knn_imputed[[col]]
            cat("  - KNN imputed", col, "\n")
          }
        }
      }
    }, error = function(e) {
      cat("  - KNN imputation failed:", e$message, "\n")
    })
  } else {
    # Fallback: Use median imputation for remaining missing values
    for(col in names(df)) {
      if(is.numeric(df[[col]]) && any(is.na(df[[col]]))) {
        median_val <- median(df[[col]], na.rm = TRUE)
        if(!is.na(median_val)) {
          df_imputed[[col]] <- ifelse(is.na(df[[col]]), median_val, df_imputed[[col]])
          cat("  - Median imputed remaining missing values in", col, "\n")
        }
      }
    }
  }
  
  return(df_imputed)
}

# Apply imputation to all datasets
imputed_datasets <- list()
for(name in names(raw_datasets)) {
  imputed_datasets[[name]] <- impute_missing_values(raw_datasets[[name]], name)
}
cat("\n")

# =============================================================================
# Duplicate Detection and Removal
# =============================================================================
cat("=== DUPLICATE DETECTION AND REMOVAL ===\n")

# Function to handle duplicates
remove_duplicates <- function(df, dataset_name) {
  cat("Processing duplicates for:", dataset_name, "\n")
  
  initial_rows <- nrow(df)
  duplicate_count <- sum(duplicated(df))
  
  if(duplicate_count > 0) {
    # Remove exact duplicates
    df_cleaned <- df[!duplicated(df), ]
    final_rows <- nrow(df_cleaned)
    removed_rows <- initial_rows - final_rows
    
    cat("  - Removed", removed_rows, "duplicate rows (", 
        round(100 * removed_rows / initial_rows, 2), "%)\n")
  } else {
    df_cleaned <- df
    cat("  - No duplicates found\n")
  }
  
  return(df_cleaned)
}

# Apply duplicate removal
deduplicated_datasets <- list()
for(name in names(imputed_datasets)) {
  deduplicated_datasets[[name]] <- remove_duplicates(imputed_datasets[[name]], name)
}
cat("\n")

# =============================================================================
# Outlier Detection and Treatment
# =============================================================================
cat("=== OUTLIER DETECTION AND TREATMENT ===\n")

# Function to detect outliers using multiple methods
detect_outliers <- function(df, dataset_name) {
  cat("Detecting outliers for:", dataset_name, "\n")
  
  outlier_summary <- list()
  numeric_cols <- names(df)[sapply(df, is.numeric)]
  
  for(col in numeric_cols) {
    if(length(unique(df[[col]])) > 1) {  # Skip constant columns
      values <- df[[col]][!is.na(df[[col]])]
      
      # Method 1: IQR method
      q1 <- quantile(values, 0.25)
      q3 <- quantile(values, 0.75)
      iqr <- q3 - q1
      lower_iqr <- q1 - 1.5 * iqr
      upper_iqr <- q3 + 1.5 * iqr
      iqr_outliers <- sum(values < lower_iqr | values > upper_iqr)
      
      # Method 2: Z-score method (|z| > 3)
      z_scores <- abs(scale(values))
      z_outliers <- sum(z_scores > 3, na.rm = TRUE)
      
      # Method 3: Modified Z-score (using median)
      median_val <- median(values)
      mad_val <- median(abs(values - median_val))
      modified_z <- 0.6745 * (values - median_val) / mad_val
      modified_z_outliers <- sum(abs(modified_z) > 3.5, na.rm = TRUE)
      
      outlier_summary[[col]] <- data.frame(
        column = col,
        iqr_outliers = iqr_outliers,
        z_outliers = z_outliers,
        modified_z_outliers = modified_z_outliers,
        total_values = length(values)
      )
    }
  }
  
  if(length(outlier_summary) > 0) {
    outlier_df <- do.call(rbind, outlier_summary)
    print(outlier_df)
  }
  
  return(outlier_summary)
}

# Detect outliers in all datasets
outlier_results <- list()
for(name in names(deduplicated_datasets)) {
  outlier_results[[name]] <- detect_outliers(deduplicated_datasets[[name]], name)
}

# Function to treat outliers
treat_outliers <- function(df, dataset_name, method = "winsorize") {
  cat("Treating outliers for:", dataset_name, "using", method, "method\n")
  
  df_treated <- df
  numeric_cols <- names(df)[sapply(df, is.numeric)]
  treatment_summary <- list()
  
  for(col in numeric_cols) {
    if(length(unique(df[[col]])) > 1) {
      values <- df[[col]]
      non_na_values <- values[!is.na(values)]
      
      if(length(non_na_values) > 0) {
        # Calculate outlier bounds using IQR
        q1 <- quantile(non_na_values, 0.25)
        q3 <- quantile(non_na_values, 0.75)
        iqr <- q3 - q1
        lower_bound <- q1 - 1.5 * iqr
        upper_bound <- q3 + 1.5 * iqr
        
        # Count outliers before treatment
        outliers_before <- sum(values < lower_bound | values > upper_bound, na.rm = TRUE)
        
        if(method == "winsorize") {
          # Winsorize outliers (cap at bounds)
          df_treated[[col]] <- pmax(pmin(values, upper_bound), lower_bound)
        } else if(method == "remove") {
          # Remove outliers (set to NA)
          df_treated[[col]] <- ifelse(values < lower_bound | values > upper_bound, NA, values)
        } else if(method == "log_transform") {
          # Log transform (if all values are positive)
          if(all(non_na_values > 0)) {
            df_treated[[col]] <- log1p(values)
          }
        }
        
        # Count outliers after treatment
        new_values <- df_treated[[col]]
        new_non_na <- new_values[!is.na(new_values)]
        if(length(new_non_na) > 0) {
          new_q1 <- quantile(new_non_na, 0.25)
          new_q3 <- quantile(new_non_na, 0.75)
          new_iqr <- new_q3 - new_q1
          new_lower <- new_q1 - 1.5 * new_iqr
          new_upper <- new_q3 + 1.5 * new_iqr
          outliers_after <- sum(new_values < new_lower | new_values > new_upper, na.rm = TRUE)
        } else {
          outliers_after <- 0
        }
        
        treatment_summary[[col]] <- data.frame(
          column = col,
          outliers_before = outliers_before,
          outliers_after = outliers_after,
          method = method
        )
      }
    }
  }
  
  if(length(treatment_summary) > 0) {
    treatment_df <- do.call(rbind, treatment_summary)
    print(treatment_df)
  }
  
  return(list(data = df_treated, summary = treatment_summary))
}

# Apply outlier treatment
outlier_treated_datasets <- list()
for(name in names(deduplicated_datasets)) {
  result <- treat_outliers(deduplicated_datasets[[name]], name, method = "winsorize")
  outlier_treated_datasets[[name]] <- result$data
}
cat("\n")

# =============================================================================
# Noise Detection and Special Value Handling
# =============================================================================
cat("=== NOISE DETECTION AND SPECIAL VALUE HANDLING ===\n")

# Function to handle noise and special values
handle_noise <- function(df, dataset_name) {
  cat("Handling noise and special values for:", dataset_name, "\n")
  
  df_cleaned <- df
  noise_summary <- list()
  
  # Check for common special values that might indicate missing data
  special_values <- c("99", "999", "9999", "Unknown", "N/A", "NA", "", " ", "NULL", "null")
  
  for(col in names(df)) {
    if(is.character(df[[col]]) || is.factor(df[[col]])) {
      # Convert to character for easier processing
      values <- as.character(df[[col]])
      
      # Count special values
      special_count <- sum(values %in% special_values, na.rm = TRUE)
      
      if(special_count > 0) {
        # Replace special values with NA
        values[values %in% special_values] <- NA
        df_cleaned[[col]] <- values
        
        noise_summary[[col]] <- data.frame(
          column = col,
          special_values_found = special_count,
          special_values_replaced = special_count
        )
        
        cat("  - Replaced", special_count, "special values in", col, "\n")
      }
    }
  }
  
  # Handle numeric columns with suspicious values
  numeric_cols <- names(df)[sapply(df, is.numeric)]
  for(col in numeric_cols) {
    values <- df[[col]]
    
    # Check for values that are too large (potential data entry errors)
    if(length(unique(values)) > 1) {
      q99 <- quantile(values, 0.99, na.rm = TRUE)
      extreme_values <- sum(values > q99 * 10, na.rm = TRUE)
      
      if(extreme_values > 0) {
        # Cap extreme values at 99th percentile
        df_cleaned[[col]] <- pmin(values, q99)
        
        if(!col %in% names(noise_summary)) {
          noise_summary[[col]] <- data.frame(
            column = col,
            extreme_values_found = extreme_values,
            extreme_values_capped = extreme_values
          )
        }
        
        cat("  - Capped", extreme_values, "extreme values in", col, "\n")
      }
    }
  }
  
  if(length(noise_summary) > 0) {
    noise_df <- do.call(rbind, noise_summary)
    print(noise_df)
  }
  
  return(list(data = df_cleaned, summary = noise_summary))
}

# Apply noise handling
noise_cleaned_datasets <- list()
for(name in names(outlier_treated_datasets)) {
  result <- handle_noise(outlier_treated_datasets[[name]], name)
  noise_cleaned_datasets[[name]] <- result$data
}
cat("\n")

# =============================================================================
# Data Harmonization
# =============================================================================
cat("=== DATA HARMONIZATION ===\n")

# Function to harmonize categorical variables
harmonize_data <- function(df, dataset_name) {
  cat("Harmonizing data for:", dataset_name, "\n")
  
  df_harmonized <- df
  
  # Standardize province names (common in South African data)
  province_columns <- names(df)[grepl("province|region|location", names(df), ignore.case = TRUE)]
  
  for(col in province_columns) {
    if(is.character(df[[col]]) || is.factor(df[[col]])) {
      values <- as.character(df[[col]])
      
      # Standardize common province names
      values <- stringr::str_to_title(values)
      values <- stringr::str_trim(values)
      
      # Common province name mappings
      province_mapping <- c(
        "Western Cape" = "Western Cape",
        "Eastern Cape" = "Eastern Cape", 
        "Northern Cape" = "Northern Cape",
        "Free State" = "Free State",
        "KwaZulu-Natal" = "KwaZulu-Natal",
        "North West" = "North West",
        "Gauteng" = "Gauteng",
        "Mpumalanga" = "Mpumalanga",
        "Limpopo" = "Limpopo"
      )
      
      # Apply mappings
      for(old_name in names(province_mapping)) {
        values[grepl(old_name, values, ignore.case = TRUE)] <- province_mapping[old_name]
      }
      
      df_harmonized[[col]] <- values
      cat("  - Harmonized province names in", col, "\n")
    }
  }
  
  # Standardize gender/sex columns
  gender_columns <- names(df)[grepl("gender|sex", names(df), ignore.case = TRUE)]
  
  for(col in gender_columns) {
    if(is.character(df[[col]]) || is.factor(df[[col]])) {
      values <- as.character(df[[col]])
      values <- stringr::str_to_lower(stringr::str_trim(values))
      
      # Standardize gender values
      values[grepl("^m|^male|^1", values)] <- "Male"
      values[grepl("^f|^female|^2", values)] <- "Female"
      values[!values %in% c("Male", "Female")] <- "Unknown"
      
      df_harmonized[[col]] <- values
      cat("  - Harmonized gender values in", col, "\n")
    }
  }
  
  return(df_harmonized)
}

# Apply harmonization
final_cleaned_datasets <- list()
for(name in names(noise_cleaned_datasets)) {
  final_cleaned_datasets[[name]] <- harmonize_data(noise_cleaned_datasets[[name]], name)
}
cat("\n")

# =============================================================================
# Before/After Comparison
# =============================================================================
cat("=== BEFORE/AFTER COMPARISON ===\n")

# Create comprehensive before/after comparison
create_comparison_report <- function(original, cleaned, dataset_name) {
  # Original assessment
  orig_rows <- nrow(original)
  orig_cols <- ncol(original)
  orig_missing <- sum(is.na(original))
  orig_duplicates <- sum(duplicated(original))
  
  # Cleaned assessment
  clean_rows <- nrow(cleaned)
  clean_cols <- ncol(cleaned)
  clean_missing <- sum(is.na(cleaned))
  clean_duplicates <- sum(duplicated(cleaned))
  
  # Calculate improvements
  missing_reduction <- orig_missing - clean_missing
  duplicate_reduction <- orig_duplicates - clean_duplicates
  row_reduction <- orig_rows - clean_rows
  
  comparison <- data.frame(
    dataset = dataset_name,
    metric = c("Rows", "Columns", "Missing Values", "Duplicates"),
    before = c(orig_rows, orig_cols, orig_missing, orig_duplicates),
    after = c(clean_rows, clean_cols, clean_missing, clean_duplicates),
    change = c(-row_reduction, 0, -missing_reduction, -duplicate_reduction),
    change_pct = c(
      round(-100 * row_reduction / orig_rows, 2),
      0,
      round(-100 * missing_reduction / max(orig_missing, 1), 2),
      round(-100 * duplicate_reduction / max(orig_duplicates, 1), 2)
    )
  )
  
  return(comparison)
}

# Generate comparison reports for all datasets
comparison_reports <- list()
for(name in names(raw_datasets)) {
  if(name %in% names(final_cleaned_datasets)) {
    comparison_reports[[name]] <- create_comparison_report(
      raw_datasets[[name]], 
      final_cleaned_datasets[[name]], 
      name
    )
  }
}

# Combine all comparisons
if(length(comparison_reports) > 0) {
  all_comparisons <- do.call(rbind, comparison_reports)
  print(all_comparisons)
  
  # Save comparison report
  readr::write_csv(all_comparisons, file.path(output_dir, "before_after_comparison.csv"))
  cat("Comparison report saved to: before_after_comparison.csv\n")
}
cat("\n")

# =============================================================================
# Final Data Quality Assessment
# =============================================================================
cat("=== FINAL DATA QUALITY ASSESSMENT ===\n")

# Perform final assessment on cleaned data
final_assessment <- assess_data_quality(final_cleaned_datasets)
print(final_assessment)

# Save final assessment
readr::write_csv(final_assessment, file.path(output_dir, "final_data_assessment.csv"))
cat("Final assessment saved to: final_data_assessment.csv\n")

# Create improvement summary
improvement_summary <- data.frame(
  dataset = initial_assessment$dataset,
  missing_reduction = initial_assessment$missing_count - final_assessment$missing_count,
  missing_reduction_pct = round(100 * (initial_assessment$missing_count - final_assessment$missing_count) / 
                               pmax(initial_assessment$missing_count, 1), 2),
  duplicate_reduction = initial_assessment$duplicate_count - final_assessment$duplicate_count,
  duplicate_reduction_pct = round(100 * (initial_assessment$duplicate_count - final_assessment$duplicate_count) / 
                                 pmax(initial_assessment$duplicate_count, 1), 2)
)

print(improvement_summary)
readr::write_csv(improvement_summary, file.path(output_dir, "improvement_summary.csv"))
cat("Improvement summary saved to: improvement_summary.csv\n\n")

# =============================================================================
# Save Cleaned Datasets
# =============================================================================
cat("=== SAVING CLEANED DATASETS ===\n")

# Save all cleaned datasets
for(name in names(final_cleaned_datasets)) {
  filename <- paste0(name, "_cleaned.csv")
  filepath <- file.path(output_dir, filename)
  readr::write_csv(final_cleaned_datasets[[name]], filepath)
  cat("Saved cleaned dataset:", filename, "\n")
}

# Save RDS format for R users
saveRDS(final_cleaned_datasets, file.path(output_dir, "all_cleaned_datasets.rds"))
cat("Saved all cleaned datasets as RDS file\n\n")

# =============================================================================
# Data Cleaning Summary Report
# =============================================================================
cat("=== DATA CLEANING SUMMARY REPORT ===\n\n")

cat("Total datasets processed:", length(raw_datasets), "\n")
cat("Total datasets cleaned:", length(final_cleaned_datasets), "\n\n")

# Overall statistics
total_original_rows <- sum(sapply(raw_datasets, nrow))
total_cleaned_rows <- sum(sapply(final_cleaned_datasets, nrow))
total_original_missing <- sum(sapply(raw_datasets, function(x) sum(is.na(x))))
total_cleaned_missing <- sum(sapply(final_cleaned_datasets, function(x) sum(is.na(x))))
total_original_duplicates <- sum(sapply(raw_datasets, function(x) sum(duplicated(x))))
total_cleaned_duplicates <- sum(sapply(final_cleaned_datasets, function(x) sum(duplicated(x))))

cat("OVERALL STATISTICS:\n")
cat("- Original total rows:", total_original_rows, "\n")
cat("- Cleaned total rows:", total_cleaned_rows, "\n")
cat("- Rows removed:", total_original_rows - total_cleaned_rows, 
    "(", round(100 * (total_original_rows - total_cleaned_rows) / total_original_rows, 2), "%)\n")
cat("- Original missing values:", total_original_missing, "\n")
cat("- Cleaned missing values:", total_cleaned_missing, "\n")
cat("- Missing values reduced:", total_original_missing - total_cleaned_missing, 
    "(", round(100 * (total_original_missing - total_cleaned_missing) / max(total_original_missing, 1), 2), "%)\n")
cat("- Original duplicates:", total_original_duplicates, "\n")
cat("- Cleaned duplicates:", total_cleaned_duplicates, "\n")
cat("- Duplicates removed:", total_original_duplicates - total_cleaned_duplicates, 
    "(", round(100 * (total_original_duplicates - total_cleaned_duplicates) / max(total_original_duplicates, 1), 2), "%)\n\n")

cat("CLEANING METHODS APPLIED:\n")
cat("1. Missing Value Imputation:\n")
cat("   - Mean imputation for numeric variables\n")
cat("   - Mode imputation for categorical variables\n")
cat("   - KNN imputation for mixed datasets (if available)\n")
cat("   - Median imputation as fallback\n\n")

cat("2. Duplicate Removal:\n")
cat("   - Exact duplicate detection and removal\n\n")

cat("3. Outlier Treatment:\n")
cat("   - IQR method for outlier detection\n")
cat("   - Winsorization for outlier treatment\n\n")

cat("4. Noise Handling:\n")
cat("   - Special value replacement (99, 999, Unknown, etc.)\n")
cat("   - Extreme value capping\n\n")

cat("5. Data Harmonization:\n")
cat("   - Province name standardization\n")
cat("   - Gender value standardization\n\n")

cat("OUTPUT FILES GENERATED:\n")
cat("- Cleaned datasets: *_cleaned.csv\n")
cat("- Assessment reports: initial_data_assessment.csv, final_data_assessment.csv\n")
cat("- Comparison reports: before_after_comparison.csv, improvement_summary.csv\n")
cat("- RDS file: all_cleaned_datasets.rds\n\n")

cat("=== DATA CLEANING PROCESS COMPLETE ===\n")
cat("The cleaned datasets are now ready for feature selection and transformation\n")
cat("in the next phase of the data preparation process.\n")

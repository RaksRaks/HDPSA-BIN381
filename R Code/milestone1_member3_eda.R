# =============================================================================
# Milestone 1 – Member 3: Data Understanding (EDA & Quality)
# Team HDPSA
# =============================================================================

# Overview:
# This script loads all provided datasets, reports dimensions, variable types, 
# missing values, duplicate rows, outliers (basic), and summary statistics. 
# It saves CSV summaries into `outputs/`.

# Load required libraries
library(readr)
library(dplyr)
library(purrr)
library(stringr)

# Set up paths
input_dir <- "../Project Datasets"
output_dir <- "../outputs"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== MILESTONE 1 - MEMBER 3: DATA UNDERSTANDING (EDA & QUALITY) ===\n")
cat("Loading datasets from:", input_dir, "\n")
cat("Output directory:", output_dir, "\n\n")

# =============================================================================
# Load datasets
# =============================================================================
cat("Loading datasets...\n")
csv_files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
stopifnot(length(csv_files) > 0)

# Named list of tibbles
name_from_path <- function(p) gsub("\\.csv$", "", basename(p))
raw_datasets <- csv_files |> setNames(nm = vapply(csv_files, name_from_path, character(1))) |> 
  lapply(readr::read_csv, show_col_types = FALSE)

cat("Successfully loaded", length(raw_datasets), "datasets\n")
cat("Dataset names:", paste(names(raw_datasets), collapse = ", "), "\n\n")

# =============================================================================
# Structure and dimensions
# =============================================================================
cat("=== STRUCTURE AND DIMENSIONS ===\n")
structure_tbl <- purrr::imap_dfr(raw_datasets, function(df, nm){
  tibble::tibble(
    dataset = nm,
    n_rows = nrow(df),
    n_cols = ncol(df)
  )
})

readr::write_csv(structure_tbl, file.path(output_dir, "structure_summary.csv"))
print(structure_tbl)
cat("\n")

# =============================================================================
# Variable types
# =============================================================================
cat("=== VARIABLE TYPES ===\n")
coltypes_tbl <- purrr::imap_dfr(raw_datasets, function(df, nm){
  tibble::tibble(
    dataset = nm,
    column = names(df),
    type = vapply(df, function(x) class(x)[1], character(1))
  )
})

readr::write_csv(coltypes_tbl, file.path(output_dir, "column_types.csv"))

# Summary of data types
type_summary <- coltypes_tbl |> dplyr::count(type, sort = TRUE)
print(type_summary)
cat("\n")

# =============================================================================
# Missing values and duplicates
# =============================================================================
cat("=== MISSING VALUES AND DUPLICATES ===\n")

# Missing values analysis
missing_tbl <- purrr::imap_dfr(raw_datasets, function(df, nm){
  tibble::tibble(
    dataset = nm,
    total_cells = nrow(df) * ncol(df),
    total_missing = sum(is.na(df)),
    pct_missing = round(100 * total_missing / pmax(1, total_cells), 2)
  )
})

readr::write_csv(missing_tbl, file.path(output_dir, "missingness_summary.csv"))
print(missing_tbl)
cat("\n")

# Duplicates analysis
duplicates_tbl <- purrr::imap_dfr(raw_datasets, function(df, nm){
  dup_count <- sum(duplicated(df))
  tibble::tibble(dataset = nm, duplicate_rows = dup_count)
})

readr::write_csv(duplicates_tbl, file.path(output_dir, "duplicates_summary.csv"))
print(duplicates_tbl)
cat("\n")

# =============================================================================
# Summary statistics (numerical columns)
# =============================================================================
cat("=== SUMMARY STATISTICS (NUMERICAL COLUMNS) ===\n")
num_summary_tbl <- purrr::imap_dfr(raw_datasets, function(df, nm){
  num_df <- dplyr::select(df, where(is.numeric))
  if(ncol(num_df) == 0) return(tibble::tibble())
  num_df |>
    summarize(across(everything(), list(
      n = ~sum(!is.na(.x)),
      mean = ~mean(.x, na.rm = TRUE),
      sd = ~sd(.x, na.rm = TRUE),
      min = ~min(.x, na.rm = TRUE),
      q25 = ~quantile(.x, 0.25, na.rm = TRUE),
      median = ~median(.x, na.rm = TRUE),
      q75 = ~quantile(.x, 0.75, na.rm = TRUE),
      max = ~max(.x, na.rm = TRUE)
    ), .names = "{.col}.{.fn}")) |>
    mutate(dataset = nm, .before = 1)
})

readr::write_csv(num_summary_tbl, file.path(output_dir, "numeric_summary.csv"))
print(num_summary_tbl |> dplyr::slice_head(n = 10))
cat("\n")

# =============================================================================
# Basic outlier detection (IQR rule, counts per numeric column)
# =============================================================================
cat("=== BASIC OUTLIER DETECTION (IQR RULE) ===\n")
outliers_tbl <- purrr::imap_dfr(raw_datasets, function(df, nm){
  num_df <- dplyr::select(df, where(is.numeric))
  if(ncol(num_df) == 0) return(tibble::tibble())
  purrr::imap_dfr(num_df, function(col, cname){
    q1 <- quantile(col, 0.25, na.rm = TRUE)
    q3 <- quantile(col, 0.75, na.rm = TRUE)
    iqr <- q3 - q1
    lower <- q1 - 1.5*iqr
    upper <- q3 + 1.5*iqr
    tibble::tibble(dataset = nm, column = cname,
                   outlier_count = sum(col < lower | col > upper, na.rm = TRUE))
  })
})

readr::write_csv(outliers_tbl, file.path(output_dir, "outliers_summary.csv"))
print(outliers_tbl |> dplyr::arrange(desc(outlier_count)) |> dplyr::slice_head(n = 10))
cat("\n")

# =============================================================================
# Summary Report
# =============================================================================
cat("=== SUMMARY REPORT ===\n")
cat("Total datasets processed:", length(raw_datasets), "\n")
cat("Total rows across all datasets:", sum(sapply(raw_datasets, nrow)), "\n")
cat("Total columns across all datasets:", sum(sapply(raw_datasets, ncol)), "\n")
cat("Total missing values:", sum(sapply(raw_datasets, function(x) sum(is.na(x)))), "\n")
cat("Total duplicate rows:", sum(sapply(raw_datasets, function(x) sum(duplicated(x)))), "\n")

cat("\nOutput files created:\n")
cat("- structure_summary.csv\n")
cat("- column_types.csv\n")
cat("- missingness_summary.csv\n")
cat("- duplicates_summary.csv\n")
cat("- numeric_summary.csv\n")
cat("- outliers_summary.csv\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Use these summaries to inform cleaning and transformations in Milestone 2.\n")
cat("Member 4 can build visuals from outputs/ or reuse this script.\n")

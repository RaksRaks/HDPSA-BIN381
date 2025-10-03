#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(purrr); library(stringr); library(tibble)
})
input_dir <- "Project Datasets"
output_dir <- "outputs"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

csv_files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
if(length(csv_files) == 0) stop("No CSV files found in 'Project Datasets'")

name_from_path <- function(p) gsub("\\.csv$", "", basename(p))
raw_datasets <- csv_files |> setNames(nm = vapply(csv_files, name_from_path, character(1))) |> 
  lapply(readr::read_csv, show_col_types = FALSE)

structure_tbl <- imap_dfr(raw_datasets, function(df, nm){
  tibble(dataset = nm, n_rows = nrow(df), n_cols = ncol(df))
})
write_csv(structure_tbl, file.path(output_dir, "structure_summary.csv"))

coltypes_tbl <- imap_dfr(raw_datasets, function(df, nm){
  tibble(dataset = nm, column = names(df), type = vapply(df, function(x) class(x)[1], character(1)))
})
write_csv(coltypes_tbl, file.path(output_dir, "column_types.csv"))

missing_tbl <- imap_dfr(raw_datasets, function(df, nm){
  total_cells <- nrow(df) * ncol(df)
  total_missing <- sum(is.na(df))
  tibble(dataset = nm, total_cells = total_cells, total_missing = total_missing,
         pct_missing = round(100 * total_missing / pmax(1, total_cells), 2))
})
write_csv(missing_tbl, file.path(output_dir, "missingness_summary.csv"))

duplicates_tbl <- imap_dfr(raw_datasets, function(df, nm){
  tibble(dataset = nm, duplicate_rows = sum(duplicated(df)))
})
write_csv(duplicates_tbl, file.path(output_dir, "duplicates_summary.csv"))

num_summary_tbl <- imap_dfr(raw_datasets, function(df, nm){
  num_df <- dplyr::select(df, where(is.numeric))
  if(ncol(num_df) == 0) return(tibble())
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
write_csv(num_summary_tbl, file.path(output_dir, "numeric_summary.csv"))

outliers_tbl <- imap_dfr(raw_datasets, function(df, nm){
  num_df <- dplyr::select(df, where(is.numeric))
  if(ncol(num_df) == 0) return(tibble())
  imap_dfr(num_df, function(col, cname){
    q1 <- quantile(col, 0.25, na.rm = TRUE)
    q3 <- quantile(col, 0.75, na.rm = TRUE)
    iqr <- q3 - q1
    lower <- q1 - 1.5*iqr
    upper <- q3 + 1.5*iqr
    tibble(dataset = nm, column = cname, outlier_count = sum(col < lower | col > upper, na.rm = TRUE))
  })
})
write_csv(outliers_tbl, file.path(output_dir, "outliers_summary.csv"))

message("EDA complete. Outputs saved to 'outputs/'.")

## 01_person1_data_description_BASE.R  (no tidyverse)
## -------------------------------------------------
## What it does:
## - Reads ALL CSV files in input/
## - Creates overview & dictionary CSVs
## - Infers time span (year/survey_year) and basic geo coverage
## - Saves simple base-R plots (hist, boxplot, barplot) as PNGs

## -------- PROJECT PATHS --------
# Use Project Datasets folder directly
input_dir <- "Project Datasets"
output_dir <- "outputs/person1"

# Create output directory if it doesn't exist
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Verify input directory exists
if (!dir.exists(input_dir)) {
  stop("Project Datasets folder not found. Make sure you're running from the project root directory.")
}

## Optional: try to load janitor::clean_names(); else use a tiny fallback
clean_names <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}
if (requireNamespace("janitor", quietly = TRUE)) {
  clean_names <- janitor::clean_names
}

## Helpers
missing_pct <- function(x) mean(is.na(x))
sample_vals <- function(x, n = 5) {
  u <- unique(x[!is.na(x)])
  paste(head(u, n), collapse = ", ")
}

csv_files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(csv_files) == 0) stop(paste0("No CSV files found in ", input_dir, ". Place CSVs there or adjust input_dir."))

overview_list   <- list()
dictionary_list <- list()
timespan_list   <- list()
geo_list        <- list()

geo_cols   <- c("country","province","district","municipality","ward","region")
year_names <- c("year","survey_year")

for (f in csv_files) {
  message("Reading: ", f)
  df <- tryCatch(read.csv(f, stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
  if (is.null(df)) next
  names(df) <- clean_names(names(df))
  ds_name <- tools::file_path_sans_ext(basename(f))
  
  ## --- Overview ---
  overview_list[[ds_name]] <- data.frame(
    dataset = ds_name,
    file    = basename(f),
    rows    = nrow(df),
    cols    = ncol(df),
    stringsAsFactors = FALSE
  )
  
  ## --- Dictionary ---
  types <- sapply(df, function(col) class(col)[1])
  miss  <- sapply(df, missing_pct)
  uniq  <- sapply(df, function(col) length(unique(col)))
  smpl  <- sapply(df, sample_vals)
  
  dictionary_list[[ds_name]] <- data.frame(
    dataset       = ds_name,
    variable      = names(df),
    type          = unname(types),
    missing_pct   = round(as.numeric(miss), 4),
    unique_n      = as.integer(uniq),
    sample_values = unname(smpl),
    description   = "",     # <-- fill in later (meaning + units)
    stringsAsFactors = FALSE
  )
  
  ## --- Time span (numeric year) ---
  ycol <- intersect(year_names, names(df))
  if (length(ycol) > 0) {
    y <- suppressWarnings(as.integer(df[[ycol[1]]]))
    if (all(is.na(y))) {
      miny <- NA_integer_; maxy <- NA_integer_
    } else {
      miny <- suppressWarnings(min(y, na.rm = TRUE))
      maxy <- suppressWarnings(max(y, na.rm = TRUE))
    }
    timespan_list[[ds_name]] <- data.frame(
      dataset = ds_name, year_col = ycol[1],
      min_year = miny, max_year = maxy,
      stringsAsFactors = FALSE
    )
  } else {
    timespan_list[[ds_name]] <- data.frame(
      dataset = ds_name, year_col = NA_character_,
      min_year = NA_integer_, max_year = NA_integer_,
      stringsAsFactors = FALSE
    )
  }
  
  ## --- Geographic coverage ---
  present <- intersect(geo_cols, names(df))
  geo_list[[ds_name]] <- data.frame(
    dataset = ds_name,
    geo_columns = if (length(present) == 0) "none" else paste(present, collapse = ", "),
    stringsAsFactors = FALSE
  )
  
  ## --- Base R visuals ---
  # Numeric: up to 5 hist + 5 boxplots
  num_idx <- sapply(df, is.numeric)
  num_vars <- names(df)[num_idx]
  if (length(num_vars) > 0) {
    for (v in head(num_vars, 5)) {
      png(file.path(output_dir, paste0(ds_name, "_hist_", v, ".png")), width = 800, height = 550)
      hist(df[[v]], main = paste(ds_name, "-", v, "(hist)"), xlab = v, col = "grey")
      dev.off()
      
      png(file.path(output_dir, paste0(ds_name, "_box_", v, ".png")), width = 800, height = 550)
      boxplot(df[[v]], main = paste(ds_name, "-", v, "(box)"), ylab = v)
      dev.off()
    }
  }
  
  # Categorical: up to 5 barplots (top 10 categories)
  cat_vars <- names(df)[!num_idx]
  if (length(cat_vars) > 0) {
    for (v in head(cat_vars, 5)) {
      tt <- sort(table(df[[v]]), decreasing = TRUE)
      if (length(tt) > 0) {
        top <- head(tt, 10)
        png(file.path(output_dir, paste0(ds_name, "_bar_", v, ".png")), width = 900, height = 600)
        par(mar = c(8,4,4,1)+0.1)
        barplot(top, las = 2, main = paste(ds_name, "-", v, "(top 10)"), ylab = "count")
        dev.off()
      }
    }
  }
}

## --- Write combined outputs ---
overview   <- do.call(rbind, overview_list)
dictionary <- do.call(rbind, dictionary_list)
timespan   <- do.call(rbind, timespan_list)
geo_cover  <- do.call(rbind, geo_list)

write.csv(overview,   file.path(output_dir, "datasets_overview.csv"), row.names = FALSE)
write.csv(dictionary, file.path(output_dir, "data_dictionary.csv"),   row.names = FALSE)
write.csv(timespan,   file.path(output_dir, "time_span.csv"),         row.names = FALSE)
write.csv(geo_cover,  file.path(output_dir, "geo_coverage.csv"),      row.names = FALSE)

message("Done. Check outputs in: ", output_dir)

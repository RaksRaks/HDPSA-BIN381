# This script cleans and preprocesses the combined dataset.

# Load necessary libraries
# install.packages("dplyr") # Uncomment and run if dplyr is not installed
# install.packages("DescTools") # Uncomment and run if DescTools is not installed
library(dplyr)
library(DescTools) # For Mode function

# Set the path to the combined dataset
input_file_path <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\combined_dataset.csv"
output_file_path <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\cleaned_combined_dataset.csv"

# Read the combined dataset
data <- read.csv(input_file_path, stringsAsFactors = FALSE)

# --- 1. Remove duplicate rows ---
initial_rows <- nrow(data)
data_cleaned <- distinct(data)
removed_duplicates <- initial_rows - nrow(data_cleaned)
print(paste("Removed", removed_duplicates, "duplicate rows."))

# --- 2. Impute missing values (group-wise by Indicator and SurveyYear) ---
# Ensure Indicator and SurveyYear columns exist
if (!("Indicator" %in% colnames(data_cleaned) && "SurveyYear" %in% colnames(data_cleaned))) {
  stop("Error: 'Indicator' or 'SurveyYear' column not found for group-wise cleaning.")
}

data_cleaned <- data_cleaned %>%
  group_by(Indicator, SurveyYear) %>%
  mutate(
    across(where(is.numeric), ~ {
      if (any(is.na(.))) {
        mean_val <- mean(., na.rm = TRUE)
        if (is.nan(mean_val)) . else replace_na(., mean_val) # Handle cases where group is all NA
      } else {
        .
      }
    }),
    across(where(is.character) | where(is.factor), ~ {
      if (any(is.na(.))) {
        # Convert to character for mode calculation if it's a factor
        col_data_char <- as.character(.)
        mode_val <- DescTools::Mode(col_data_char[!is.na(col_data_char)])[1]
        if (is.na(mode_val)) . else replace_na(., mode_val) # Handle cases where group is all NA
      } else {
        .
      }
    })
  ) %>%
  ungroup()

print("Imputed missing values group-wise by Indicator and SurveyYear.")


# --- 3. Handle outliers (group-wise capping using IQR method for numerical columns) ---
data_cleaned <- data_cleaned %>%
  group_by(Indicator, SurveyYear) %>%
  mutate(
    across(where(is.numeric), ~ {
      Q1 <- quantile(., 0.25, na.rm = TRUE)
      Q3 <- quantile(., 0.75, na.rm = TRUE)
      IQR_val <- Q3 - Q1
      upper_bound <- Q3 + 1.5 * IQR_val
      lower_bound <- Q1 - 1.5 * IQR_val

      # Cap outliers
      .x[ .x > upper_bound ] <- upper_bound
      .x[ .x < lower_bound ] <- lower_bound
      .x
    })
  ) %>%
  ungroup()

print("Capped outliers group-wise by Indicator and SurveyYear.")


# Save the cleaned data to a new CSV file
write.csv(data_cleaned, output_file_path, row.names = FALSE)

print(paste0("Cleaned and preprocessed data saved to ", output_file_path))
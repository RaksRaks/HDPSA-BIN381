# This script performs feature selection by filtering the combined dataset.

# Load necessary libraries
library(dplyr) # Ensure dplyr is loaded for select()

# Set the path to the combined dataset
input_file_path <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\cleaned_combined_dataset.csv"
output_file_path <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\feature_selected_cleaned_combined_dataset.csv"

# Read the combined dataset
data <- read.csv(input_file_path, stringsAsFactors = FALSE)

# Filter the data to keep only rows where IsPreferred is 1
if ("IsPreferred" %in% colnames(data)) {
  data_filtered <- data[data$IsPreferred == 1, ]

  # Select only the specified columns
  required_columns <- c("Indicator", "Value", "SurveyYear")
  # Check if all required columns exist
  if (all(required_columns %in% colnames(data_filtered))) {
    data_selected <- data_filtered %>%
      select(all_of(required_columns)) # Use all_of to handle cases where columns might not exist (though checked above)

    # Save the filtered and selected data to a NEW file
    write.csv(data_selected, output_file_path, row.names = FALSE)
    print(paste0("Data filtered by IsPreferred = 1 and selected columns (Indicator, Value, SurveyYear), saved to ", output_file_path))
  } else {
    missing_cols <- setdiff(required_columns, colnames(data_filtered))
    print(paste0("Error: Missing required columns for selection: ", paste(missing_cols, collapse = ", ")))
  }
} else {
  print("Error: 'IsPreferred' column not found in the dataset.")
}
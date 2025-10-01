# This script filters, resolves duplicates, and ensures indicators exist in both years.

# Load necessary libraries
library(dplyr)
library(stringr)

# Define file paths
input_file <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\feature_selected_cleaned_combined_dataset.csv"
output_clean_file <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\final_cleaned_dataset.csv"
output_conflicts_file <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\conflicting_duplicates.csv"

# Read the input data
data <- read.csv(input_file, stringsAsFactors = FALSE)

# First, filter out any rows where the Indicator contains 'Total'
data_filtered <- data %>%
  filter(!grepl("Total", Indicator, ignore.case = TRUE))

# Create a 'base_indicator' to group weighted and unweighted versions of the same indicator
data_prepared <- data_filtered %>%
  mutate(
    base_indicator = str_trim(str_replace(Indicator, fixed("(unweighted)"), "")),
    is_unweighted = str_detect(Indicator, fixed("(unweighted)"))
  )

# Identify and save conflicting groups for review
conflicting_groups <- data_prepared %>%
  group_by(SurveyYear, base_indicator) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  select(Indicator, Value, SurveyYear)

if (nrow(conflicting_groups) > 0) {
  write.csv(conflicting_groups, output_conflicts_file, row.names = FALSE)
  print(paste("Found", nrow(conflicting_groups), "rows in conflicting groups. Saved to", output_conflicts_file))
} else {
  print("No conflicting groups found.")
}

# Resolve duplicates
resolved_data <- data_prepared %>%
  group_by(SurveyYear, base_indicator) %>%
  arrange(is_unweighted, desc(Value)) %>%
  slice(1) %>%
  ungroup()

# Filter for indicators that are present in both survey years
final_data <- resolved_data %>%
  group_by(base_indicator) %>%
  filter(n_distinct(SurveyYear) == 2) %>%
  ungroup() %>%
  # Select the final columns
  select(Indicator, Value, SurveyYear)

# Write the final resolved and filtered data to the output file
write.csv(final_data, output_clean_file, row.names = FALSE)

print(paste("Processing complete. Final cleaned data saved to", output_clean_file))
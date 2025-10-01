# This script rotates the final cleaned dataset to a wide format.

# Load necessary libraries
library(dplyr)
library(tidyr)

# Define file paths
input_file <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\final_cleaned_dataset.csv"
output_file <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\rotated_final_dataset.csv"

# Read the input data
data <- read.csv(input_file, stringsAsFactors = FALSE)

# Rotate the data using pivot_wider
rotated_data <- data %>%
  pivot_wider(
    names_from = Indicator,
    values_from = Value
  )

# Write the rotated data to a new CSV file
write.csv(rotated_data, output_file, row.names = FALSE)

print(paste("Data has been rotated and saved to", output_file))

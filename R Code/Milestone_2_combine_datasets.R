# Set the path to the raw datasets folder
raw_data_path <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Raw Datasets"

# Get a list of all CSV files in the folder
csv_files <- list.files(raw_data_path, pattern = "\\.csv$", full.names = TRUE)

# --- Step 1: Extract header from the first file ---
# Read the first file to get the header (from the first line)
first_file_header <- colnames(read.csv(csv_files[1], nrows = 1, header = TRUE, stringsAsFactors = FALSE))

# --- Step 2: Read all files without headers and combine ---
# Read all CSV files into a list of data frames, skipping the first TWO rows (header + metadata)
data_list_no_header <- lapply(csv_files, function(file) {
  read.csv(file, header = FALSE, stringsAsFactors = FALSE, skip = 2) # Changed skip from 1 to 2
})

# Combine all data frames into a single data frame
combined_data_no_header <- do.call(rbind, data_list_no_header)

# --- Step 3: Assign the extracted header ---
# Assign the header from the first file to the combined data
colnames(combined_data_no_header) <- first_file_header

# The combined_data_no_header now has the correct single header and all data.
combined_data_cleaned <- combined_data_no_header


# Set the path for the cleaned dataset
cleaned_data_path <- "C:\\Users\\Frederik\\Documents\\GitHub\\HDPSA-BIN381\\Cleaned Datasets\\combined_dataset.csv"

# Ensure the old combined dataset is removed if it exists
if (file.exists(cleaned_data_path)) {
  file.remove(cleaned_data_path)
  print("Removed existing combined_dataset.csv")
}

# Write the combined and cleaned data to a new CSV file
write.csv(combined_data_cleaned, cleaned_data_path, row.names = FALSE)

# Print a message to confirm completion
print("All CSV files have been combined with a single header, and saved to Cleaned Datasets/combined_dataset.csv")
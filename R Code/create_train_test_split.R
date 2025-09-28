# Load the dataset
data <- read.csv("../Cleaned Datasets/rotated_final_dataset.csv")

# Create training set (Year 1998)
training_data <- data[data$SurveyYear == 1998, ]

# Create testing set (Year 2016)
testing_data <- data[data$SurveyYear != 1998, ]

# Save the datasets
write.csv(training_data, "../Cleaned Datasets/training_data.csv", row.names = FALSE)
write.csv(testing_data, "../Cleaned Datasets/testing_data.csv", row.names = FALSE)

# Print a message to confirm completion
print("Training and testing datasets have been created successfully.")

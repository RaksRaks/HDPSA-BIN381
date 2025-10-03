## Generate Model Predictions for Person 4 Assessment
## Based on Person 3's Models commit (79c6a80)

library(caret)
library(rpart)
library(randomForest)
library(e1071)

# Load data
project_root <- "/Users/raksu/Desktop/DATA_SCIENCE_PRJ/HDPSA-BIN381"
data <- read.csv(file.path(project_root, "Cleaned Datasets", "final_cleaned_dataset.csv"))

# Prepare data (same as Person 3's approach)
data$YearCategory <- ifelse(data$SurveyYear == 1998, 0, 1)
data$YearCategory <- as.factor(data$YearCategory)
data_clean <- na.omit(data[, !names(data) %in% c("SurveyYear", "Indicator")])

# Set seed for reproducibility (same as Person 3)
set.seed(123)

# 70/30 train/test split
train_index <- createDataPartition(data_clean$YearCategory, p = 0.7, list = FALSE)
train_data <- data_clean[train_index, ]
test_data <- data_clean[-train_index, ]

# Prepare output directory
output_dir <- file.path(project_root, "Model Outputs")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# 1. Logistic Regression
cat("Generating Logistic Regression predictions...\n")
logit_model <- glm(YearCategory ~ ., data = train_data, family = binomial(link = "logit"))
logit_prob <- predict(logit_model, newdata = test_data, type = "response")
logit_pred <- ifelse(logit_prob > 0.5, 1, 0)
logit_true <- as.numeric(test_data$YearCategory) - 1

logit_df <- data.frame(
  y_true = logit_true,
  y_pred = logit_pred,
  y_prob = logit_prob,
  model = "logistic"
)
write.csv(logit_df, file.path(output_dir, "logistic_predictions.csv"), row.names = FALSE)

# 2. Decision Tree
cat("Generating Decision Tree predictions...\n")
tree_model <- rpart(YearCategory ~ ., data = train_data, method = "class",
                    control = rpart.control(minsplit = 20, cp = 0.01))
tree_pred_prob <- predict(tree_model, newdata = test_data, type = "prob")
tree_pred <- predict(tree_model, newdata = test_data, type = "class")
tree_true <- test_data$YearCategory

tree_df <- data.frame(
  y_true = as.numeric(tree_true) - 1,
  y_pred = as.numeric(tree_pred) - 1,
  y_prob = tree_pred_prob[, 2],  # Probability of class 1
  model = "decision_tree"
)
write.csv(tree_df, file.path(output_dir, "decision_tree_predictions.csv"), row.names = FALSE)

# 3. Random Forest
cat("Generating Random Forest predictions...\n")
p <- ncol(train_data) - 1
mtry_value <- max(1, floor(sqrt(p)))
rf_model <- randomForest(YearCategory ~ ., data = train_data, ntree = 100, 
                         mtry = mtry_value, importance = TRUE)
rf_pred_prob <- predict(rf_model, newdata = test_data, type = "prob")
rf_pred <- predict(rf_model, newdata = test_data)
rf_true <- test_data$YearCategory

rf_df <- data.frame(
  y_true = as.numeric(rf_true) - 1,
  y_pred = as.numeric(rf_pred) - 1,
  y_prob = rf_pred_prob[, 2],  # Probability of class 1
  model = "random_forest"
)
write.csv(rf_df, file.path(output_dir, "random_forest_predictions.csv"), row.names = FALSE)

# 4. Naive Bayes
cat("Generating Naive Bayes predictions...\n")
nb_model <- naiveBayes(YearCategory ~ ., data = train_data, laplace = 1)
nb_pred_raw <- predict(nb_model, newdata = test_data, type = "raw")
nb_pred <- predict(nb_model, newdata = test_data)
nb_true <- test_data$YearCategory

nb_df <- data.frame(
  y_true = as.numeric(nb_true) - 1,
  y_pred = as.numeric(nb_pred) - 1,
  y_prob = nb_pred_raw[, 2],  # Probability of class 1
  model = "naive_bayes"
)
write.csv(nb_df, file.path(output_dir, "naive_bayes_predictions.csv"), row.names = FALSE)

cat("\n=== Prediction files generated successfully ===\n")
cat("Output directory:", output_dir, "\n")
cat("Files created:\n")
cat("  - logistic_predictions.csv\n")
cat("  - decision_tree_predictions.csv\n")
cat("  - random_forest_predictions.csv\n")
cat("  - naive_bayes_predictions.csv\n")


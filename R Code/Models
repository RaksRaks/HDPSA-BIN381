library(caret)
> library(rpart)
> library(rpart.plot)
> library(randomForest)
> library(e1071)
> 
> data <- read.csv("C:\\Users\\shait\\OneDrive\\Documents\\BINDatasets\\final_cleaned_dataset.csv")
> #surveyYear was set as target
> data$YearCategory <- ifelse(data$SurveyYear == 1998, 0, 1)
> data$YearCategory <- as.factor(data$YearCategory)
> data_clean <- na.omit(data[, !names(data) %in% c("SurveyYear", "Indicator")])
> if(nrow(data_clean) < 2) {
+     stop("Not enough data after cleaning. Check your dataset structure.")
+ }
> 
> #seed for reproducibility
> set.seed(123)
> 
> #70/30 train/test split
> train_index <- createDataPartition(data_clean$YearCategory, p = 0.7, list = FALSE)
> train_data <- data_clean[train_index, ]
> test_data <- data_clean[-train_index, ]

> if(length(unique(train_data$YearCategory)) < 2 | length(unique(test_data$YearCategory)) < 2) {
+     # If stratification failed, use simple random sampling
+     train_index <- sample(1:nrow(data_clean), size = 0.7 * nrow(data_clean))
+     train_data <- data_clean[train_index, ]
+     test_data <- data_clean[-train_index, ]
+ }
> 
> cat("Training set size:", nrow(train_data), "\n")
Training set size: 206 
> cat("Test set size:", nrow(test_data), "\n")
Test set size: 88 
> cat("Class distribution in training set:\n")
Class distribution in training set:
> print(table(train_data$YearCategory))

  0   1 
103 103 
> cat("Class distribution in test set:\n")
Class distribution in test set:
> print(table(test_data$YearCategory))

 0  1 
44 44 
> 
> #Logistic regression using logit
> cat("\n=== LOGISTIC REGRESSION ===\n")

=== LOGISTIC REGRESSION ===
> logit_model <- glm(YearCategory ~ ., 
+                    data = train_data, 
+                    family = binomial(link = "logit"))

> logit_pred <- predict(logit_model, newdata = test_data, type = "response")
> logit_pred_class <- ifelse(logit_pred > 0.5, 1, 0)

> logit_accuracy <- mean(logit_pred_class == as.numeric(test_data$YearCategory) - 1)
> cat("Logistic Regression Accuracy:", round(logit_accuracy * 100, 2), "%\n")
Logistic Regression Accuracy: 52.27 %
> 
> #Decison trees with a minsplit of 20
> cat("\n=== DECISION TREE ===\n")

=== DECISION TREE ===
> tree_model <- rpart(YearCategory ~ ., 
+                     data = train_data,
+                     method = "class",
+                     control = rpart.control(minsplit = 20, cp = 0.01))

> rpart.plot(tree_model, main = "Decision Tree for Year Classification")

> tree_pred <- predict(tree_model, newdata = test_data, type = "class")

> tree_accuracy <- mean(tree_pred == test_data$YearCategory)
> cat("Decision Tree Accuracy:", round(tree_accuracy * 100, 2), "%\n")
Decision Tree Accuracy: 50 %
> 
> #random forest with 100 trees(better accuracy than 10)
> cat("\n=== RANDOM FOREST ===\n")

=== RANDOM FOREST ===
> p <- ncol(train_data) - 1  # Number of predictors (excluding target)
> mtry_value <- max(1, floor(sqrt(p)))
> 
> rf_model <- randomForest(YearCategory ~ ., 
+                          data = train_data,
+                          ntree = 100,
+                          mtry = mtry_value,
+                          importance = TRUE)

> rf_pred <- predict(rf_model, newdata = test_data)

> rf_accuracy <- mean(rf_pred == test_data$YearCategory)
> cat("Random Forest Accuracy:", round(rf_accuracy * 100, 2), "%\n")
Random Forest Accuracy: 54.55 %
> 
> #naive bayes wuth laplace
> cat("\n=== NAIVE BAYES ===\n")

=== NAIVE BAYES ===
> nb_model <- naiveBayes(YearCategory ~ ., 
+                        data = train_data,
+                        laplace = 1)

> nb_pred <- predict(nb_model, newdata = test_data)

> nb_accuracy <- mean(nb_pred == test_data$YearCategory)
> cat("Naive Bayes Accuracy:", round(nb_accuracy * 100, 2), "%\n")
Naive Bayes Accuracy: 50 %
> 
> #model comparison
> cat("\n=== MODEL COMPARISON ===\n")

=== MODEL COMPARISON ===
> results <- data.frame(
+     Model = c("Logistic Regression", "Decision Tree", "Random Forest", "Naive Bayes"),
+     Accuracy = c(logit_accuracy, tree_accuracy, rf_accuracy, nb_accuracy)
+ )
> results$Accuracy_Percent <- round(results$Accuracy * 100, 2)
> 
> print(results)
                Model  Accuracy Accuracy_Percent
1 Logistic Regression 0.5227273            52.27
2       Decision Tree 0.5000000            50.00
3       Random Forest 0.5454545            54.55
4         Naive Bayes 0.5000000            50.00
> 
> # Confusion matrices
> cat("\n=== CONFUSION MATRICES ===\n")

=== CONFUSION MATRICES ===
> 
> cat("Logistic Regression:\n")
Logistic Regression:
> print(table(Predicted = logit_pred_class, Actual = as.numeric(test_data$YearCategory) - 1))
         Actual
Predicted  0  1
        0  3  1
        1 41 43
> 
> cat("\nDecision Tree:\n")

Decision Tree:
> print(table(Predicted = tree_pred, Actual = test_data$YearCategory))
         Actual
Predicted  0  1
        0 18 18
        1 26 26
> 
> cat("\nRandom Forest:\n")

Random Forest:
> print(table(Predicted = rf_pred, Actual = test_data$YearCategory))
         Actual
Predicted  0  1
        0 21 17
        1 23 27
> 
> cat("\nNaive Bayes:\n")

Naive Bayes:
> print(table(Predicted = nb_pred, Actual = test_data$YearCategory))
         Actual
Predicted  0  1
        0  0  0
        1 44 44

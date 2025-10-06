# ============================================================================
# Milestone 4 - Section 1: Model Performance Evaluation
# Author: Petrus Human (577842)
# Description: Computes classification metrics for all four models
# ============================================================================
#install packages
# Install caret (machine learning framework)
install.packages("caret", dependencies = TRUE)

# Install pROC (for ROC and AUC curves)
install.packages("pROC")

# (Optional but recommended: ensure dplyr, ggplot2, gridExtra are up-to-date)
install.packages(c("dplyr", "ggplot2", "gridExtra"))
install.packages("lava", dependencies = TRUE)
# Load required libraries
library(caret)
library(pROC)
library(dplyr)
library(ggplot2)
library(gridExtra)




# Set working directory
setwd("C:/Users/modir/Desktop/HDPSA-BIN381-main")

# Create outputs directory
dir.create("Milestone 4 outputs/assessment", recursive = TRUE, showWarnings = FALSE)

# Read model predictions from Milestone 3
logistic_pred <- read.csv("Model Outputs/logistic_predictions.csv")
tree_pred <- read.csv("Model Outputs/decision_tree_predictions.csv")
rf_pred <- read.csv("Model Outputs/random_forest_predictions.csv")
nb_pred <- read.csv("Model Outputs/naive_bayes_predictions.csv")

# Function to calculate comprehensive metrics
calculate_metrics <- function(predictions, model_name) {
  
  # Convert to factors for confusion matrix
  y_true_factor <- factor(predictions$y_true, levels = c(0, 1))
  y_pred_factor <- factor(predictions$y_pred, levels = c(0, 1))
  
  # Confusion matrix
  cm <- confusionMatrix(y_pred_factor, y_true_factor, positive = "1")
  
  # Extract metrics
  accuracy <- cm$overall['Accuracy']
  precision <- cm$byClass['Pos Pred Value']
  recall <- cm$byClass['Sensitivity']
  f1 <- cm$byClass['F1']
  
  # Calculate ROC-AUC if probabilities available
  roc_auc <- NA
  if (!all(is.na(predictions$y_prob))) {
    roc_obj <- roc(predictions$y_true, predictions$y_prob, quiet = TRUE)
    roc_auc <- auc(roc_obj)
  }
  
  # Return metrics data frame
  data.frame(
    Model = model_name,
    Accuracy = round(accuracy, 4),
    Precision = round(precision, 4),
    Recall = round(recall, 4),
    F1_Score = round(f1, 4),
    ROC_AUC = round(roc_auc, 4),
    Meets_Accuracy_Goal = ifelse(accuracy >= 0.70, "Yes", "No"),
    Meets_AUC_Goal = ifelse(roc_auc > 0.75, "Yes", "No")
  )
}

# Calculate metrics for all models
metrics_list <- list(
  calculate_metrics(logistic_pred, "Logistic Regression"),
  calculate_metrics(tree_pred, "Decision Tree"),
  calculate_metrics(rf_pred, "Random Forest"),
  calculate_metrics(nb_pred, "Naïve Bayes")
)

# Combine into single data frame
all_metrics <- bind_rows(metrics_list)

# Save metrics table
write.csv(all_metrics, "Milestone 4 outputs/assessment/model_performance_summary.csv", 
          row.names = FALSE)

# Print formatted table
print("===== MODEL PERFORMANCE SUMMARY =====")
print(all_metrics)

# Generate ROC curve comparison plot
plot_roc_curves <- function() {
  
  # Create ROC objects for models with probabilities
  roc_logistic <- roc(logistic_pred$y_true, logistic_pred$y_prob, quiet = TRUE)
  roc_tree <- roc(tree_pred$y_true, tree_pred$y_prob, quiet = TRUE)
  roc_rf <- roc(rf_pred$y_true, rf_pred$y_prob, quiet = TRUE)
  roc_nb <- roc(nb_pred$y_true, nb_pred$y_prob, quiet = TRUE)
  
  # Plot
  png("Milestone 4 outputs/assessment/roc_auc_comparison.png", width = 1000, height = 800, res = 120)
  
  plot(roc_rf, col = "#00BA38", lwd = 2, main = "ROC Curve Comparison - All Models")
  plot(roc_logistic, col = "#F8766D", lwd = 2, add = TRUE)
  plot(roc_tree, col = "#619CFF", lwd = 2, add = TRUE)
  plot(roc_nb, col = "#B79F00", lwd = 2, add = TRUE)
  
  legend("bottomright", 
         legend = c(
           sprintf("Random Forest (AUC = %.3f)", auc(roc_rf)),
           sprintf("Logistic Regression (AUC = %.3f)", auc(roc_logistic)),
           sprintf("Decision Tree (AUC = %.3f)", auc(roc_tree)),
           sprintf("Naïve Bayes (AUC = %.3f)", auc(roc_nb))
         ),
         col = c("#00BA38", "#F8766D", "#619CFF", "#B79F00"),
         lwd = 2,
         cex = 0.9)
  
  abline(a = 0, b = 1, lty = 2, col = "gray50")
  
  dev.off()
}

plot_roc_curves()

# Generate performance comparison bar chart
plot_performance_comparison <- function() {
  
  metrics_long <- all_metrics %>%
    select(Model, Accuracy, F1_Score, ROC_AUC) %>%
    tidyr::pivot_longer(cols = -Model, names_to = "Metric", values_to = "Value")
  
  p <- ggplot(metrics_long, aes(x = Model, y = Value, fill = Metric)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
    geom_hline(yintercept = 0.70, linetype = "dashed", color = "red", size = 0.8) +
    geom_hline(yintercept = 0.75, linetype = "dashed", color = "darkred", size = 0.8) +
    annotate("text", x = 0.5, y = 0.71, label = "70% Threshold", hjust = 0, color = "red", size = 3.5) +
    annotate("text", x = 0.5, y = 0.76, label = "75% Threshold", hjust = 0, color = "darkred", size = 3.5) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.1)) +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "Model Performance Comparison Against Business Success Criteria",
      subtitle = "Accuracy, F1-Score, and ROC-AUC for all candidate models",
      x = "Model",
      y = "Score (0-1)",
      fill = "Metric"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray40"),
      axis.text.x = element_text(angle = 15, hjust = 1),
      legend.position = "top"
    )
  
  ggsave("Milestone 4 outputs/assessment/model_performance_comparison.png", 
         plot = p, width = 10, height = 7, dpi = 300)
}

plot_performance_comparison()

cat("\n✓ Evaluation metrics computed and saved successfully.\n")
cat("✓ Visualizations generated in 'Milestone 4 outputs/assessment/'\n")

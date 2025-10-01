## Milestone 3: Model Assessment Script
## ------------------------------------------------
## Reads model prediction outputs (from Person 3), computes metrics,
## generates confusion matrices and ROC curves, and writes a performance
## summary table and figures.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(pROC)
  library(tidyr)
  library(stringr)
})

## ------------------------
## Configurable paths
## ------------------------
project_root <- "/Users/raksu/Desktop/DATA_SCIENCE_PRJ/HDPSA-BIN381"
model_outputs_dir <- file.path(project_root, "Model Outputs")
assessment_outputs_dir <- file.path(project_root, "Milestone 3 outputs", "assessment")
dir.create(assessment_outputs_dir, recursive = TRUE, showWarnings = FALSE)

## Expected file format for model outputs (per model):
## - CSV with columns: y_true (0/1), y_pred (0/1), y_prob (0..1 optional), model (name)
## - Alternatively, a single combined CSV with the same columns for multiple models
## Files can be named e.g.:
##   - logistic_predictions.csv
##   - decision_tree_predictions.csv
##   - random_forest_predictions.csv
##   - naive_bayes_predictions.csv

read_prediction_file <- function(path) {
  df <- read_csv(path, show_col_types = FALSE)
  # Normalize required columns
  required <- c("y_true", "y_pred")
  if (!all(required %in% names(df))) {
    stop("Missing required columns in ", basename(path), ": need y_true, y_pred")
  }
  if (!"model" %in% names(df)) {
    inferred <- tools::file_path_sans_ext(basename(path))
    df$model <- inferred
  }
  if (!"y_prob" %in% names(df)) {
    df$y_prob <- NA_real_
  }
  df
}

## Gather all prediction CSVs under model_outputs_dir
if (!dir.exists(model_outputs_dir)) {
  stop("Model outputs directory not found: ", model_outputs_dir,
       "\nAsk Person 3 to export prediction CSVs there.")
}

prediction_files <- list.files(model_outputs_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(prediction_files) == 0) {
  stop("No prediction CSVs found in ", model_outputs_dir,
       ". Expected at least one CSV with columns y_true, y_pred, y_prob (optional), model.")
}

predictions <- dplyr::bind_rows(lapply(prediction_files, read_prediction_file)) %>%
  mutate(
    y_true = as.integer(y_true),
    y_pred = as.integer(y_pred),
    y_prob = suppressWarnings(as.numeric(y_prob)),
    model = as.character(model)
  )

## Helper: compute classification metrics
compute_metrics <- function(df) {
  tp <- sum(df$y_true == 1 & df$y_pred == 1, na.rm = TRUE)
  tn <- sum(df$y_true == 0 & df$y_pred == 0, na.rm = TRUE)
  fp <- sum(df$y_true == 0 & df$y_pred == 1, na.rm = TRUE)
  fn <- sum(df$y_true == 1 & df$y_pred == 0, na.rm = TRUE)

  accuracy  <- (tp + tn) / (tp + tn + fp + fn)
  precision <- if ((tp + fp) == 0) NA_real_ else tp / (tp + fp)
  recall    <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
  f1        <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) NA_real_ else 2 * precision * recall / (precision + recall)

  # ROC-AUC if probabilities available
  auc <- NA_real_
  if (!all(is.na(df$y_prob))) {
    # Ensure valid 0..1 probabilities
    valid <- !is.na(df$y_prob) & is.finite(df$y_prob)
    if (sum(valid) > 0 && length(unique(df$y_true[valid])) > 1) {
      roc_obj <- tryCatch({
        pROC::roc(df$y_true[valid], df$y_prob[valid], quiet = TRUE)
      }, error = function(e) NULL)
      if (!is.null(roc_obj)) auc <- as.numeric(pROC::auc(roc_obj))
    }
  }

  tibble(
    tp = tp, tn = tn, fp = fp, fn = fn,
    accuracy = accuracy,
    precision = precision,
    recall = recall,
    f1 = f1,
    roc_auc = auc
  )
}

## Compute per-model metrics
metrics_by_model <- predictions %>%
  group_by(model) %>%
  group_modify(~compute_metrics(.x)) %>%
  ungroup() %>%
  arrange(desc(accuracy))

readr::write_csv(metrics_by_model, file.path(assessment_outputs_dir, "model_performance_metrics.csv"))

## Confusion matrices per model (as CSV)
confusions <- predictions %>%
  group_by(model) %>%
  summarise(
    tp = sum(y_true == 1 & y_pred == 1, na.rm = TRUE),
    tn = sum(y_true == 0 & y_pred == 0, na.rm = TRUE),
    fp = sum(y_true == 0 & y_pred == 1, na.rm = TRUE),
    fn = sum(y_true == 1 & y_pred == 0, na.rm = TRUE),
    .groups = "drop"
  )
readr::write_csv(confusions, file.path(assessment_outputs_dir, "confusion_matrices.csv"))

## Plot ROC curves if probabilities exist for any model
has_probs <- predictions %>% filter(!is.na(y_prob) & is.finite(y_prob)) %>% nrow() > 0
if (has_probs) {
  # Compute ROC per model (where available)
  roc_data <- predictions %>%
    filter(!is.na(y_prob) & is.finite(y_prob)) %>%
    group_by(model) %>%
    group_modify(function(.x, .y) {
      if (length(unique(.x$y_true)) < 2) return(tibble(tpr = numeric(0), fpr = numeric(0)))
      roc_obj <- pROC::roc(.x$y_true, .x$y_prob, quiet = TRUE)
      coords <- pROC::coords(roc_obj, x = "all", ret = c("specificity", "sensitivity"))
      tibble(fpr = 1 - coords[["specificity"]], tpr = coords[["sensitivity"]])
    }) %>%
    ungroup()

  p_roc <- ggplot(roc_data, aes(x = fpr, y = tpr, color = model)) +
    geom_line(size = 1) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
    labs(title = "ROC Curves by Model", x = "False Positive Rate", y = "True Positive Rate", color = "Model") +
    theme_minimal()

  ggsave(filename = file.path(assessment_outputs_dir, "roc_curves.png"), plot = p_roc, width = 8, height = 6, dpi = 300)
}

## Bar chart: Accuracy / F1 / ROC-AUC per model
metrics_long <- metrics_by_model %>%
  select(model, accuracy, f1, roc_auc) %>%
  pivot_longer(-model, names_to = "metric", values_to = "value")

p_perf <- ggplot(metrics_long, aes(x = model, y = value, fill = metric)) +
  geom_col(position = position_dodge(width = 0.75)) +
  scale_y_continuous(limits = c(0, 1)) +
  labs(title = "Model Performance Comparison", x = "Model", y = "Score (0-1)") +
  theme_minimal()

ggsave(filename = file.path(assessment_outputs_dir, "model_performance_comparison.png"), plot = p_perf, width = 9, height = 6, dpi = 300)

message("Assessment complete. Outputs written to: ", assessment_outputs_dir)


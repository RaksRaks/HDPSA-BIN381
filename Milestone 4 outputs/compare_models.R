# =====================================================================
# BIN381 – Milestone 4
# Person 2 – Approved Model(s) & Justification
# Author :person1 did it Petrus Human 577842
# Purpose: Compare candidate model metrics & produce Go/No-Go summary
# =====================================================================

library(dplyr)
library(knitr)

# Read model metrics exported by Person 1
metrics <- read.csv("Milestone 4 outputs/assessment/model_performance_summary.csv")

# Define business thresholds
acc_target <- 0.70
auc_target <- 0.75

# Determine approval status
approval_summary <- metrics %>%
  mutate(
    Decision = case_when(
      Accuracy >= acc_target | ROC_AUC >= auc_target ~ "Go",
      TRUE ~ "No-Go"
    ),
    Rationale = case_when(
      grepl("Logistic", Model, ignore.case = TRUE) ~
        "Transparent coefficients – ideal for policy communication",
      grepl("Tree", Model, ignore.case = TRUE) ~
        "Visual if–then logic supports decision explanation",
      grepl("Forest", Model, ignore.case = TRUE) ~
        "Opaque ensemble model – interpretability issues",
      grepl("Na", Model, ignore.case = TRUE) ~
        "Independence assumption violated – unreliable probabilities",
      TRUE ~ "Reviewed"
    )
  )

# Save table to Outputs folder
dir.create("Milestone 4 outputs/approved_models", recursive = TRUE, showWarnings = FALSE)
write.csv(approval_summary,
          "Milestone 4 outputs/approved_models/model_approval_summary.csv",
          row.names = FALSE)

# Display summary table
kable(approval_summary,
      caption = "Model Approval Summary – Go/No-Go Decisions (Person 2)")

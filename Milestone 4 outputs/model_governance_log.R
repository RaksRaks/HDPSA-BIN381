# =====================================================================
# Model Governance Log – Versioning and Audit Trail
# =====================================================================

governance <- data.frame(
  Model = c("Logistic Regression", "Decision Tree"),
  Version = c("v2025-10-LogReg", "v2025-10-Tree"),
  Parameters = c("link = logit", "minsplit = 20, cp = 0.01"),
  Last_Trained = Sys.Date(),
  Accuracy = c(0.5227, 0.5000),
  Decision = c("Go", "Go")
)

dir.create("Milestone 4 outputs/governance", recursive = TRUE, showWarnings = FALSE)
write.csv(governance,
          "Milestone 4 outputs/governance/model_governance_log.csv",
          row.names = FALSE)

print(governance)

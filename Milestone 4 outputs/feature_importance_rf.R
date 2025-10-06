library(randomForest)
library(dplyr)

setwd("C:/Users/modir/Desktop/HDPSA-BIN381-main")

df <- read.csv("Cleaned Datasets/final_cleaned_dataset.csv")

# Encode SurveyYear as factor (target)
df$SurveyYear <- as.factor(df$SurveyYear)

# Convert Indicator into numeric codes
df$IndicatorCode <- as.numeric(as.factor(df$Indicator))

# Train Random Forest using numeric encoding
rf_model <- randomForest(SurveyYear ~ IndicatorCode + Value,
                         data = df,
                         ntree = 100,
                         mtry = 2,
                         importance = TRUE,
                         na.action = na.omit)

# Create output folder if missing
dir.create("Model Outputs", showWarnings = FALSE, recursive = TRUE)

# Save model
saveRDS(rf_model, "Model Outputs/random_forest_model.rds")

cat("✅ Random Forest model trained and saved successfully!\n")
cat("File path: Model Outputs/random_forest_model.rds\n")


# Extract and visualize feature importance
library(randomForest)
library(ggplot2)

# Load saved Random Forest model (from Milestone 3)
rf_model <- readRDS("Model Outputs/random_forest_model.rds")

# Extract importance
importance_df <- data.frame(
  Feature = rownames(importance(rf_model)),
  MeanDecreaseGini = importance(rf_model)[, "MeanDecreaseGini"]
) %>%
  arrange(desc(MeanDecreaseGini)) %>%
  head(10)

# Visualize
ggplot(importance_df, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_col(fill = "#00BA38", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Top 10 Predictive Features - Random Forest",
    subtitle = "Mean Decrease in Gini Impurity",
    x = "Feature",
    y = "Importance Score"
  ) +
  theme_minimal()

ggsave("Milestone 4 outputs/assessment/feature_importance_rf.png", width = 10, height = 6, dpi = 300)


# Create charts for Milestone 1 Member 3 Report
library(readr)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(RColorBrewer)

# Set up paths
input_dir <- "Project Datasets"
output_dir <- "outputs"
charts_dir <- "charts"

# Create charts directory
dir.create(charts_dir, showWarnings = FALSE, recursive = TRUE)

# Read summary data
structure_summary <- read_csv(file.path(output_dir, "structure_summary.csv"))
missingness_summary <- read_csv(file.path(output_dir, "missingness_summary.csv"))
numeric_summary <- read_csv(file.path(output_dir, "numeric_summary.csv"))

# 1. Dataset Size Comparison Chart
p1 <- ggplot(structure_summary, aes(x = reorder(dataset, n_rows), y = n_rows)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "Dataset Size Comparison",
       subtitle = "Number of observations per dataset",
       x = "Dataset",
       y = "Number of Rows") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(charts_dir, "dataset_sizes.png"), p1, width = 10, height = 8, dpi = 300)

# 2. Missing Data Percentage Chart
p2 <- ggplot(missingness_summary, aes(x = reorder(dataset, pct_missing), y = pct_missing)) +
  geom_col(fill = "coral", alpha = 0.7) +
  coord_flip() +
  labs(title = "Missing Data Percentage by Dataset",
       subtitle = "Percentage of missing values across all datasets",
       x = "Dataset",
       y = "Missing Data (%)") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  geom_hline(yintercept = mean(missingness_summary$pct_missing), 
             linetype = "dashed", color = "red", size = 1)

ggsave(file.path(charts_dir, "missing_data_percentage.png"), p2, width = 10, height = 8, dpi = 300)

# 3. Data Completeness Heatmap
completeness_data <- missingness_summary %>%
  mutate(completeness = 100 - pct_missing) %>%
  select(dataset, completeness)

p3 <- ggplot(completeness_data, aes(x = 1, y = reorder(dataset, completeness), fill = completeness)) +
  geom_tile() +
  scale_fill_gradient(low = "red", high = "green", name = "Completeness %") +
  labs(title = "Data Completeness Heatmap",
       subtitle = "Green = High completeness, Red = Low completeness",
       x = "",
       y = "Dataset") +
  theme_minimal() +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.text.y = element_text(size = 8))

ggsave(file.path(charts_dir, "completeness_heatmap.png"), p3, width = 8, height = 10, dpi = 300)

# 4. Temporal Coverage Chart
# Extract survey years from numeric summary
temporal_data <- numeric_summary %>%
  select(dataset, contains("SurveyYearLabel")) %>%
  mutate(avg_year = SurveyYearLabel.mean) %>%
  select(dataset, avg_year)

p4 <- ggplot(temporal_data, aes(x = reorder(dataset, avg_year), y = avg_year)) +
  geom_point(size = 3, color = "darkblue") +
  coord_flip() +
  labs(title = "Average Survey Year by Dataset",
       subtitle = "Temporal distribution of data collection",
       x = "Dataset",
       y = "Average Survey Year") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  scale_y_continuous(breaks = seq(1998, 2016, 2))

ggsave(file.path(charts_dir, "temporal_coverage.png"), p4, width = 10, height = 8, dpi = 300)

# 5. Data Quality Summary Chart
quality_summary <- structure_summary %>%
  left_join(missingness_summary, by = "dataset") %>%
  mutate(completeness = 100 - pct_missing,
         quality_score = completeness * (n_rows / max(n_rows))) %>%
  arrange(desc(quality_score))

p5 <- ggplot(quality_summary, aes(x = reorder(dataset, quality_score), y = quality_score)) +
  geom_col(fill = "darkgreen", alpha = 0.7) +
  coord_flip() +
  labs(title = "Data Quality Score by Dataset",
       subtitle = "Combined completeness and size score",
       x = "Dataset",
       y = "Quality Score") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(charts_dir, "quality_scores.png"), p5, width = 10, height = 8, dpi = 300)

# 6. Missing Data Distribution
p6 <- ggplot(missingness_summary, aes(x = pct_missing)) +
  geom_histogram(bins = 10, fill = "orange", alpha = 0.7, color = "black") +
  labs(title = "Distribution of Missing Data Percentages",
       subtitle = "Histogram of missing data across all datasets",
       x = "Missing Data Percentage",
       y = "Number of Datasets") +
  theme_minimal() +
  geom_vline(xintercept = mean(missingness_summary$pct_missing), 
             linetype = "dashed", color = "red", size = 1) +
  annotate("text", x = mean(missingness_summary$pct_missing) + 1, 
           y = 3, label = paste("Mean:", round(mean(missingness_summary$pct_missing), 1), "%"),
           color = "red")

ggsave(file.path(charts_dir, "missing_data_distribution.png"), p6, width = 8, height = 6, dpi = 300)

# 7. Dataset Categories Overview
category_data <- data.frame(
  category = c("Health Access", "Child Health", "Maternal Health", "Infectious Diseases", 
               "Infrastructure", "Education", "Demographics"),
  count = c(1, 3, 1, 2, 2, 1, 2),
  avg_completeness = c(85.02, 82.5, 76.33, 80.0, 81.5, 79.97, 85.0)
)

p7 <- ggplot(category_data, aes(x = reorder(category, avg_completeness), y = avg_completeness)) +
  geom_col(fill = "purple", alpha = 0.7) +
  coord_flip() +
  labs(title = "Data Completeness by Category",
       subtitle = "Average completeness across indicator categories",
       x = "Category",
       y = "Average Completeness (%)") +
  theme_minimal()

ggsave(file.path(charts_dir, "category_completeness.png"), p7, width = 10, height = 6, dpi = 300)

# 8. Sample Size Distribution
sample_size_data <- numeric_summary %>%
  select(dataset, contains("DenominatorWeighted")) %>%
  mutate(avg_sample_size = DenominatorWeighted.mean) %>%
  select(dataset, avg_sample_size)

p8 <- ggplot(sample_size_data, aes(x = reorder(dataset, avg_sample_size), y = avg_sample_size)) +
  geom_col(fill = "darkred", alpha = 0.7) +
  coord_flip() +
  labs(title = "Average Sample Size by Dataset",
       subtitle = "Weighted denominator sizes across datasets",
       x = "Dataset",
       y = "Average Sample Size") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  scale_y_continuous(labels = scales::comma_format())

ggsave(file.path(charts_dir, "sample_sizes.png"), p8, width = 10, height = 8, dpi = 300)

print("All charts created successfully!")
print(paste("Charts saved in:", charts_dir))

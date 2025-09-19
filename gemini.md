# HDPSA Project - Data Processing Overview (Milestone 2)

This document provides a high-level overview of the data processing pipeline implemented for the Health & Demographic Patterns in South Africa (HDPSA) project, specifically covering the data preparation phase for Milestone 2.

## Project Goal
The primary goal of this project is to analyze health and demographic data to identify patterns, trends, and relationships that can inform policy decisions and improve public health outcomes in South Africa.

## Data Processing Pipeline (R Scripts)

The following R scripts have been developed and executed to transform raw, disparate datasets into a clean, preprocessed, and feature-selected format:

### 1. `Milestone_2_combine_datasets.R`
*   **Purpose:** Combines all individual raw CSV files from the `Raw Datasets` folder into a single `combined_dataset.csv`.
*   **Key Action:** Handles multiple header rows in source files by extracting the true header from the first file and skipping subsequent header/metadata rows.
*   **Output:** `Cleaned Datasets/combined_dataset.csv`

### 2. `Milestone_2_data_cleaning.R`
*   **Purpose:** Cleans and preprocesses the `combined_dataset.csv` to address data quality issues.
*   **Key Actions:**
    *   Removes duplicate rows.
    *   Imputes missing numerical values with group-wise mean (by Indicator and SurveyYear).
    *   Imputes missing categorical values with group-wise mode (by Indicator and SurveyYear).
    *   Caps outliers in numerical columns using group-wise IQR method (by Indicator and SurveyYear).
*   **Output:** `Cleaned Datasets/cleaned_combined_dataset.csv`

### 3. `Milestone_2_feature_selection.R`
*   **Purpose:** Selects relevant features and filters data based on predefined criteria.
*   **Key Actions:**
    *   Filters rows to keep only those where `IsPreferred` is `1`.
    *   Selects only `Indicator`, `Value`, and `SurveyYear` columns for the final dataset.
*   **Output:** `Cleaned Datasets/feature_selected_cleaned_combined_dataset.csv`

## Key Data Characteristics & Considerations

*   **Final Data Columns:** The processed data for modeling primarily consists of `Indicator`, `Value`, and `SurveyYear`. This selection was made to focus on core measurements and temporal trends, while removing redundant country identifiers and irrelevant metadata.
*   **Data Scaling:** The `Value` column is already in percentages or thousands, making explicit data scaling generally unnecessary.
*   **Train-Test Split:** Due to only two `SurveyYear` values, a time-series validation approach (training on earlier year, testing on later year) is recommended for predictive modeling, rather than a traditional random split.

## Further Documentation
For a more detailed explanation of the R scripts, their functionalities, and the rationale behind data preparation decisions, please refer to `Milestone 2 Docs/R_Scripts_Documentation.md`.

# HDPSA Project - Data Processing Overview (Milestone 2)

This document provides a high-level overview of the data processing pipeline implemented for the Health & Demographic Patterns in South Africa (HDPSA) project, specifically covering the data preparation phase for Milestone 2.

## Project Goal
The primary goal of this project is to analyze health and demographic data to identify patterns, trends, and relationships that can inform policy decisions and improve public health outcomes in South Africa.

## Data Processing Pipeline (R Scripts)

The following R scripts have been developed and executed to transform raw, disparate datasets into a clean, analysis-ready format:

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

### 4. `final_cleaning.R`
*   **Purpose:** Performs the final data cleaning by resolving duplicate indicators and ensuring data consistency across years.
*   **Key Actions:**
    *   Filters out any rows where the `Indicator` contains "Total".
    *   Identifies conflicting duplicates (e.g., weighted vs. unweighted, or different values for the same indicator/year). Saves these to `conflicting_duplicates.csv` for review.
    *   Resolves conflicts by preferring weighted over unweighted indicators, and then choosing the higher value.
    *   Ensures data integrity by removing any indicators that do not appear in both survey years.
*   **Output:** `Cleaned Datasets/final_cleaned_dataset.csv`

### 5. `rotate_final_dataset.R`
*   **Purpose:** Transforms the final cleaned dataset into a wide "rotated" format suitable for specific types of analysis.
*   **Key Actions:** Pivots the data so that `SurveyYear`s are rows and each unique `Indicator` becomes a column.
*   **Output:** `Cleaned Datasets/rotated_final_dataset.csv`

## Key Data Characteristics & Considerations

*   **Final Modeling Data:** The primary dataset ready for modeling is `rotated_final_dataset.csv`. This file is in a wide format with one row per `SurveyYear` and one column for each indicator.
*   **Intermediate Files:** The pipeline produces several intermediate files, with `final_cleaned_dataset.csv` representing the cleaned data in a long format before rotation.
*   **Data Integrity:** The final dataset contains only indicators that are present in both survey years, with duplicates, "(unweighted)", and "Total" rows removed or resolved.
*   **Data Scaling:** The `Value` column is already in percentages or thousands, making explicit data scaling generally unnecessary.
*   **Train-Test Split:** Due to only two `SurveyYear` values, a time-series validation approach (training on earlier year, testing on later year) is recommended for predictive modeling, rather than a traditional random split.

## Further Documentation
For a more detailed explanation of the R scripts, their functionalities, and the rationale behind data preparation decisions, please refer to `Milestone 2 Docs/R_Scripts_Documentation.md`.
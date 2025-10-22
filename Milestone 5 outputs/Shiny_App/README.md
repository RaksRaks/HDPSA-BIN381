# HDPSA R Shiny App - Installation and Setup Guide

## Prerequisites
Before running the R Shiny application, ensure you have the following R packages installed:

```r
# Install required packages
install.packages(c(
  "shiny",
  "shinydashboard", 
  "DT",
  "plotly",
  "ggplot2",
  "dplyr",
  "randomForest",
  "caret",
  "ROCR",
  "RColorBrewer"
))
```

## Running the Application

### Method 1: From R Console
```r
# Set working directory to the Shiny_App folder
setwd("HDPSA-BIN381/Milestone 5 outputs/Shiny_App")

# Run the application
shiny::runApp("app.R")
```

### Method 2: From RStudio
1. Open RStudio
2. Navigate to File > Open File
3. Select the `app.R` file
4. Click "Run App" button in the top-right corner of the script editor

## Application Features

### Dashboard Tab
- Project overview and key metrics
- KPI cards showing model accuracies
- Performance summary table

### Model Performance Tab
- Detailed model metrics table
- Confusion matrices for Random Forest and Logistic Regression
- ROC curves comparison for all models

### Data Explorer Tab
- Interactive filters for survey year and health indicators
- Data summary statistics
- Interactive data table with search and pagination
- Trend analysis visualization

### Predictions Tab
- Real-time prediction using Random Forest model
- Input form for health indicator values
- Probability outputs and visualization
- What-if scenario testing

## Data Requirements
The application expects the following files to be present:
- `../../Milestone 3 outputs/assessment/model_performance_metrics.csv`
- `../../Cleaned Datasets/final_cleaned_dataset.csv`
- `../../Cleaned Datasets/training_data.csv`
- `../../Cleaned Datasets/testing_data.csv`
- `../../Model Outputs/random_forest_model.rds`
- `../../Model Outputs/*_predictions.csv` (all prediction files)

## Troubleshooting

### Common Issues:
1. **Package not found**: Install missing packages using `install.packages()`
2. **File not found**: Ensure all data files are in the correct relative paths
3. **Model loading error**: Verify the Random Forest model file exists and is readable

### Performance Notes:
- The application loads all data at startup for optimal performance
- Large datasets may take a few seconds to load initially
- Interactive features update in real-time as filters are applied

## Browser Compatibility
- Chrome (recommended)
- Firefox
- Safari
- Edge

## Contact
For technical support or questions about the HDPSA R Shiny application, refer to the project documentation or contact the development team.



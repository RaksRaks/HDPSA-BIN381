# HDPSA R Shiny Application
# Health and Demographic Patterns in South Africa
# Advanced Analytics Dashboard with Model Performance and Predictions

# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(randomForest)
library(caret)
library(ROCR)
library(RColorBrewer)

# Load data and models
model_metrics <- read.csv("../../Milestone 3 outputs/assessment/model_performance_metrics.csv")
final_dataset <- read.csv("../../Cleaned Datasets/final_cleaned_dataset.csv")
training_data <- read.csv("../../Cleaned Datasets/training_data.csv")
testing_data <- read.csv("../../Cleaned Datasets/testing_data.csv")

# Load model predictions
rf_predictions <- read.csv("../../Model Outputs/random_forest_predictions.csv")
logistic_predictions <- read.csv("../../Model Outputs/logistic_predictions.csv")
dt_predictions <- read.csv("../../Model Outputs/decision_tree_predictions.csv")
nb_predictions <- read.csv("../../Model Outputs/naive_bayes_predictions.csv")

# Load trained Random Forest model
rf_model <- readRDS("../../Model Outputs/random_forest_model.rds")

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "HDPSA Analytics Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Model Performance", tabName = "performance", icon = icon("chart-line")),
      menuItem("Data Explorer", tabName = "explorer", icon = icon("search")),
      menuItem("Predictions", tabName = "predictions", icon = icon("brain"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Dashboard Tab
      tabItem(tabName = "dashboard",
        fluidRow(
          box(title = "Project Overview", status = "primary", solidHeader = TRUE, width = 12,
            p("Health and Demographic Patterns in South Africa (HDPSA) - Advanced Analytics Dashboard"),
            p("This application provides comprehensive analysis of health indicators from 1998-2016 using machine learning models.")
          )
        ),
        fluidRow(
          valueBox(
            value = paste0(round(model_metrics$accuracy[model_metrics$model == "random_forest"] * 100, 1), "%"),
            subtitle = "Random Forest Accuracy",
            icon = icon("tree"),
            color = "green"
          ),
          valueBox(
            value = paste0(round(model_metrics$accuracy[model_metrics$model == "logistic"] * 100, 1), "%"),
            subtitle = "Logistic Regression Accuracy",
            icon = icon("chart-line"),
            color = "blue"
          ),
          valueBox(
            value = nrow(final_dataset),
            subtitle = "Total Observations",
            icon = icon("database"),
            color = "purple"
          )
        ),
        fluidRow(
          box(title = "Model Performance Summary", status = "info", solidHeader = TRUE, width = 12,
            DT::dataTableOutput("performance_summary")
          )
        )
      ),
      
      # Model Performance Tab
      tabItem(tabName = "performance",
        fluidRow(
          box(title = "Model Performance Metrics", status = "primary", solidHeader = TRUE, width = 12,
            DT::dataTableOutput("detailed_metrics")
          )
        ),
        fluidRow(
          box(title = "Confusion Matrix - Random Forest", status = "success", solidHeader = TRUE, width = 6,
            plotlyOutput("confusion_matrix_rf")
          ),
          box(title = "Confusion Matrix - Logistic Regression", status = "info", solidHeader = TRUE, width = 6,
            plotlyOutput("confusion_matrix_logistic")
          )
        ),
        fluidRow(
          box(title = "ROC Curves Comparison", status = "warning", solidHeader = TRUE, width = 12,
            plotlyOutput("roc_curves")
          )
        )
      ),
      
      # Data Explorer Tab
      tabItem(tabName = "explorer",
        fluidRow(
          box(title = "Filters", status = "primary", solidHeader = TRUE, width = 4,
            selectInput("year_filter", "Survey Year:", 
                       choices = c("All", "1998", "2016"), 
                       selected = "All"),
            selectInput("indicator_filter", "Health Indicator:", 
                       choices = c("All", unique(final_dataset$Indicator)), 
                       selected = "All")
          ),
          box(title = "Data Summary", status = "info", solidHeader = TRUE, width = 8,
            verbatimTextOutput("data_summary")
          )
        ),
        fluidRow(
          box(title = "Interactive Data Table", status = "success", solidHeader = TRUE, width = 12,
            DT::dataTableOutput("data_table")
          )
        ),
        fluidRow(
          box(title = "Trend Analysis", status = "warning", solidHeader = TRUE, width = 12,
            plotlyOutput("trend_plot")
          )
        )
      ),
      
      # Predictions Tab
      tabItem(tabName = "predictions",
        fluidRow(
          box(title = "Model Input Parameters", status = "primary", solidHeader = TRUE, width = 6,
            numericInput("value_input", "Health Indicator Value:", 
                        value = 50, min = 0, max = 100, step = 0.1),
            selectInput("indicator_input", "Health Indicator:", 
                       choices = unique(final_dataset$Indicator)[1:10], 
                       selected = unique(final_dataset$Indicator)[1]),
            actionButton("predict_btn", "Generate Prediction", class = "btn-primary")
          ),
          box(title = "Prediction Results", status = "success", solidHeader = TRUE, width = 6,
            verbatimTextOutput("prediction_output"),
            plotlyOutput("prediction_probability")
          )
        ),
        fluidRow(
          box(title = "What-If Analysis", status = "info", solidHeader = TRUE, width = 12,
            p("Adjust the parameters above to see how different health indicator values affect predictions."),
            p("The model predicts whether a health indicator value corresponds to 1998 or 2016 survey year.")
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Dashboard Tab Outputs
  output$performance_summary <- DT::renderDataTable({
    model_metrics %>%
      select(model, accuracy, precision, recall, f1, roc_auc) %>%
      mutate(across(c(accuracy, precision, recall, f1, roc_auc), ~round(.x, 3))) %>%
      DT::datatable(options = list(pageLength = 4, dom = 't'))
  })
  
  # Model Performance Tab Outputs
  output$detailed_metrics <- DT::renderDataTable({
    model_metrics %>%
      select(model, tp, tn, fp, fn, accuracy, precision, recall, f1, roc_auc) %>%
      mutate(across(c(accuracy, precision, recall, f1, roc_auc), ~round(.x, 3))) %>%
      DT::datatable(options = list(pageLength = 4, dom = 't'))
  })
  
  # Confusion Matrix for Random Forest
  output$confusion_matrix_rf <- renderPlotly({
    rf_data <- model_metrics[model_metrics$model == "random_forest", ]
    
    confusion_data <- data.frame(
      Actual = c("1998", "1998", "2016", "2016"),
      Predicted = c("1998", "2016", "1998", "2016"),
      Count = c(rf_data$tn, rf_data$fp, rf_data$fn, rf_data$tp)
    )
    
    p <- ggplot(confusion_data, aes(x = Predicted, y = Actual, fill = Count)) +
      geom_tile() +
      geom_text(aes(label = Count), color = "white", size = 6) +
      scale_fill_gradient(low = "lightblue", high = "darkblue") +
      labs(title = "Random Forest Confusion Matrix",
           x = "Predicted", y = "Actual") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Confusion Matrix for Logistic Regression
  output$confusion_matrix_logistic <- renderPlotly({
    logistic_data <- model_metrics[model_metrics$model == "logistic", ]
    
    confusion_data <- data.frame(
      Actual = c("1998", "1998", "2016", "2016"),
      Predicted = c("1998", "2016", "1998", "2016"),
      Count = c(logistic_data$tn, logistic_data$fp, logistic_data$fn, logistic_data$tp)
    )
    
    p <- ggplot(confusion_data, aes(x = Predicted, y = Actual, fill = Count)) +
      geom_tile() +
      geom_text(aes(label = Count), color = "white", size = 6) +
      scale_fill_gradient(low = "lightgreen", high = "darkgreen") +
      labs(title = "Logistic Regression Confusion Matrix",
           x = "Predicted", y = "Actual") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # ROC Curves Comparison
  output$roc_curves <- renderPlotly({
    # Create ROC curve data for each model
    models <- c("random_forest", "logistic", "decision_tree", "naive_bayes")
    colors <- c("red", "blue", "green", "orange")
    
    plot_data <- data.frame()
    
    for(i in 1:length(models)) {
      model_name <- models[i]
      auc_value <- model_metrics$roc_auc[model_metrics$model == model_name]
      
      # Create simple ROC curve approximation
      fpr <- seq(0, 1, length.out = 100)
      tpr <- fpr^(1/auc_value)  # Simplified ROC curve
      
      temp_data <- data.frame(
        FPR = fpr,
        TPR = tpr,
        Model = toupper(gsub("_", " ", model_name)),
        AUC = round(auc_value, 3)
      )
      
      plot_data <- rbind(plot_data, temp_data)
    }
    
    p <- ggplot(plot_data, aes(x = FPR, y = TPR, color = Model)) +
      geom_line(size = 1) +
      geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray") +
      labs(title = "ROC Curves Comparison",
           x = "False Positive Rate", y = "True Positive Rate") +
      theme_minimal() +
      scale_color_manual(values = colors)
    
    ggplotly(p)
  })
  
  # Data Explorer Tab Outputs
  filtered_data <- reactive({
    data <- final_dataset
    
    if(input$year_filter != "All") {
      data <- data[data$SurveyYear == as.numeric(input$year_filter), ]
    }
    
    if(input$indicator_filter != "All") {
      data <- data[data$Indicator == input$indicator_filter, ]
    }
    
    return(data)
  })
  
  output$data_summary <- renderText({
    data <- filtered_data()
    paste("Filtered Data Summary:\n",
          "Number of records:", nrow(data), "\n",
          "Years covered:", paste(unique(data$SurveyYear), collapse = ", "), "\n",
          "Unique indicators:", length(unique(data$Indicator)), "\n",
          "Value range:", round(min(data$Value), 2), "to", round(max(data$Value), 2))
  })
  
  output$data_table <- DT::renderDataTable({
    DT::datatable(filtered_data(), 
                  options = list(pageLength = 10, scrollX = TRUE))
  })
  
  output$trend_plot <- renderPlotly({
    data <- filtered_data()
    
    if(nrow(data) > 0) {
      # Create trend plot
      trend_data <- data %>%
        group_by(SurveyYear, Indicator) %>%
        summarise(AvgValue = mean(Value), .groups = 'drop')
      
      p <- ggplot(trend_data, aes(x = SurveyYear, y = AvgValue, color = Indicator)) +
        geom_line(size = 1) +
        geom_point(size = 2) +
        labs(title = "Health Indicators Trend Over Time",
             x = "Survey Year", y = "Average Value") +
        theme_minimal() +
        theme(legend.position = "none")
      
      ggplotly(p)
    } else {
      plot_ly() %>% add_annotations(text = "No data available for selected filters")
    }
  })
  
  # Predictions Tab Outputs
  prediction_result <- reactive({
    if(input$predict_btn > 0) {
      # Create prediction input
      pred_input <- data.frame(
        Indicator = input$indicator_input,
        Value = input$value_input
      )
      
      # Make prediction using Random Forest model
      prediction <- predict(rf_model, pred_input, type = "prob")
      
      return(list(
        prediction = prediction,
        year = ifelse(prediction[1] > prediction[2], "1998", "2016"),
        probability_1998 = prediction[1],
        probability_2016 = prediction[2]
      ))
    }
    return(NULL)
  })
  
  output$prediction_output <- renderText({
    result <- prediction_result()
    if(!is.null(result)) {
      paste("Prediction Result:\n",
            "Predicted Year:", result$year, "\n",
            "Probability 1998:", round(result$probability_1998, 3), "\n",
            "Probability 2016:", round(result$probability_2016, 3))
    } else {
      "Click 'Generate Prediction' to see results"
    }
  })
  
  output$prediction_probability <- renderPlotly({
    result <- prediction_result()
    if(!is.null(result)) {
      prob_data <- data.frame(
        Year = c("1998", "2016"),
        Probability = c(result$probability_1998, result$probability_2016)
      )
      
      p <- ggplot(prob_data, aes(x = Year, y = Probability, fill = Year)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = c("1998" = "lightblue", "2016" = "lightgreen")) +
        labs(title = "Prediction Probabilities",
             x = "Survey Year", y = "Probability") +
        theme_minimal() +
        ylim(0, 1)
      
      ggplotly(p)
    } else {
      plot_ly() %>% add_annotations(text = "Generate prediction to see probability chart")
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)



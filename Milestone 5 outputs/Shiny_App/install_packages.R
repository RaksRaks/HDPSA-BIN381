# HDPSA R Shiny App - Package Installation Script
# Run this script to install all required packages

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install required packages
required_packages <- c(
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
)

# Function to install packages if not already installed
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    cat("Installing", package, "...\n")
    install.packages(package, dependencies = TRUE, repos = "https://cran.rstudio.com/")
    library(package, character.only = TRUE)
  } else {
    cat(package, "already installed\n")
  }
}

# Install all packages
cat("Installing required packages for HDPSA R Shiny App...\n")
for (package in required_packages) {
  cat("Installing", package, "...\n")
  install_if_missing(package)
}

cat("\nAll packages installed successfully!\n")
cat("You can now run the R Shiny app using: shiny::runApp('app.R')\n")

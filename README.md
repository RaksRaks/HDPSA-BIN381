# HDPSA BIN381

This repository contains Milestone 1 (Member 3) work: Data Understanding (EDA & Quality).

## Repository Structure
- R scripts and Rmd in `R/` and `scripts/`
- Datasets in `Project Datasets/`
- Outputs (tables/plots) in `outputs/`
- Docs in `docs/`

## Milestone 1: Deliverables (All roles)
- Project Scoping and Data Exploration Report (PDF/Doc) in `docs/`
  - Business understanding, objectives, success criteria, stakeholders
  - Data description, exploration visuals/insights, data quality assessment
- Code (R / R Markdown)
  - `scripts/eda_quality.R` (batch EDA summaries)
  - `R/milestone1_member3_eda.Rmd` (narrative EDA & quality)
- Power BI project file (optional in this phase) in `docs/` if used

## What’s included (Member 3 scope)
- Loads all 12 datasets from `Project Datasets/`
- Produces summaries saved to `outputs/`:
  - `structure_summary.csv` (rows/cols per dataset)
  - `column_types.csv` (variable types)
  - `missingness_summary.csv`
  - `duplicates_summary.csv`
  - `numeric_summary.csv` (descriptives)
  - `outliers_summary.csv` (IQR counts)

## How to run locally
1) Requirements: R with packages `readr dplyr purrr stringr tibble` (and `rmarkdown` if knitting)
2) Run automated EDA summaries:
   - `Rscript scripts/eda_quality.R`
3) Optional: knit the R Markdown report:
   - Open `R/milestone1_member3_eda.Rmd` in RStudio and Knit to HTML
   - Or run: `R -e "rmarkdown::render('R/milestone1_member3_eda.Rmd')"`
4) Outputs are written to `outputs/` (already committed for grading visibility)

## Notes
- This repo is focused on Milestone 1. Later milestones (prep, modeling, evaluation, deployment) will build on these outputs.
- Member mapping (suggested):
  - Member 1: Business understanding
  - Member 2: Research & KPIs
  - Member 3: Data understanding (EDA & quality) — this repo covers this
  - Member 4: Visualizations & data dictionary

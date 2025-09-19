#Packages
packages <- c("tidyverse","skimr","janitor","naniar","Hmisc","psych","corrplot",
              "broom","caret","mice","missMDA","FactoMineR","factoextra","car")
install.packages(setdiff(packages, rownames(installed.packages())), dependencies = TRUE)
lapply(packages, library, character.only = TRUE)

#loading of datasets
files <- list.files("C:\\Users\\shait\\OneDrive\\Documents\\BINDatasets", pattern = "\\.csv$", full.names = TRUE)
all_results <- list()

# Iterate through each dataset
for (f in files) {
  dataset_name <- tools::file_path_sans_ext(basename(f))
  out_dir <- file.path("outputs", dataset_name)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  
#missingness
  skimr::skim(df)
  missing_summary <- df %>% summarise(across(everything(), ~mean(is.na(.))*100)) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "pct_missing")
  write_csv(missing_summary, file.path(out_dir, "variable_summary.csv"))

  vars_df <- tibble(variable = names(df)) %>%
    mutate(class = map_chr(variable, ~class(df[[.x]])[1]),
           pct_missing = map_dbl(variable, ~mean(is.na(df[[.x]]))*100),
           n_unique = map_int(variable, ~n_distinct(df[[.x]])))
  
  nzv <- caret::nearZeroVar(df, saveMetrics = TRUE)
  nzv_tbl <- tibble(variable = rownames(nzv), nzv = nzv$nzv)
  vars_df <- left_join(vars_df, nzv_tbl, by = "variable")
  
  exclusion_log <- vars_df %>%
    mutate(decision = case_when(
      pct_missing > 30 ~ "Excluded",
      n_unique <= 1 ~ "Excluded",
      nzv ~ "Excluded",
      TRUE ~ "Kept"))
  write_csv(exclusion_log, file.path(out_dir, "exclusion_log.csv"))
  
#correlation and significance testing
  num_df <- df %>% select(where(is.numeric))
  if(ncol(num_df) > 1){
    res <- Hmisc::rcorr(as.matrix(num_df), type="pearson")
    R <- res$r; P <- res$P
    flattenCorrMatrix <- function(cmat, pmat){
      ut <- upper.tri(cmat)
      tibble(var1 = rownames(cmat)[row(cmat)[ut]],
             var2 = rownames(cmat)[col(cmat)[ut]],
             cor = cmat[ut],
             p = pmat[ut])
    }
    corr_long <- flattenCorrMatrix(R, P) %>% mutate(p_adj = p.adjust(p, method="fdr"))
    write_csv(corr_long, file.path(out_dir, "correlation_results.csv"))
    png(file.path(out_dir, "correlation_heatmap.png"))
    corrplot::corrplot(R, method="color")
    dev.off()
  }
  
  cat_vars <- df %>% select(where(~ is.character(.) | is.factor(.))) %>% names()
  if(length(cat_vars) > 1){
    test_results <- list()
    for(i in seq_along(cat_vars)){
      for(j in (i+1):length(cat_vars)){
        tbl <- table(df[[cat_vars[i]]], df[[cat_vars[j]]])
        pval <- if(any(tbl < 5)) fisher.test(tbl)$p.value else chisq.test(tbl)$p.value
        test_results[[paste(cat_vars[i], cat_vars[j], sep="__")]] <-
          tibble(var1 = cat_vars[i], var2 = cat_vars[j], p = pval)
      }
    }
    cat_tests <- bind_rows(test_results) %>% mutate(p_adj = p.adjust(p, method="fdr"))
    write_csv(cat_tests, file.path(out_dir, "categorical_tests.csv"))
  }
  
#feature scores
  features <- vars_df %>% mutate(
    relevance = NA_real_,
    quality = case_when(pct_missing <= 5 ~ 5,
                        pct_missing <= 20 ~ 4,
                        pct_missing <= 30 ~ 3,
                        TRUE ~ 1),
    variance_score = case_when(n_unique <= 1 ~ 0,
                               n_unique <= 5 ~ 1,
                               TRUE ~ 4)) %>%
    mutate(overall = 0.5*relevance + 0.3*quality + 0.2*variance_score)
  write_csv(features, file.path(out_dir, "feature_scores.csv"))
  
#imputation
  df_imputed <- df %>% mutate(across(where(is.numeric),
                                     ~ifelse(is.na(.), median(., na.rm=TRUE), .)))
  
#dimensionality reduction
  num_for_pca <- df_imputed %>% select(where(is.numeric))
  if(ncol(num_for_pca) > 1){
    pca <- prcomp(num_for_pca, center=TRUE, scale.=TRUE)
    sink(file.path(out_dir, "pca_summary.txt"))
    print(summary(pca))
    sink()
    png(file.path(out_dir, "pca_screeplot.png"))
    factoextra::fviz_eig(pca)
   
  }

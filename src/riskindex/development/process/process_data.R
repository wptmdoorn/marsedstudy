#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/deveopme/process/process_data.R #
#                                           #
# final data processing of separate datasets#
#############################################

# imports
library(slider)
library(dplyr)
library(purrr)
#library(tidyverse)
library(stringr)

source("riskindex/development/process/process_utils.R")

# directories
m_out <- "riskindex/data/processed/"
m_in <- "riskindex/data/preprocessed/split/"

process_train <- function(csv_file, out_name) {
  df <- read.csv(csv_file,
    sep = ";"
  )

  # Remove time >120 min
  df <- df %>%
    group_by(Patientnummer) %>%
    mutate(t_diff = as.numeric(difftime(Datum_Tijd,
      min(Datum_Tijd),
      units = "mins"
    ))) %>%
    filter(t_diff < 120) %>%
    summarise_all(., .funs = last) %>%
    mutate(mortality = ifelse(
      is.na(Overleden),
      0,
      difftime(Overleden,
        Datum_Tijd,
        units = "days"
      ) < 31
    )) %>%
    mutate(age = as.numeric(difftime(Sys.Date(),
      Geboortedatum,
      units = "weeks"
    )) / 52.25) %>%
    select(-c(Overleden, Geboortedatum, Datum_Tijd, Patientnummer, t_diff))

  # Data processing
  df <- df %>%
    select(which(colMeans(is.na(.)) < 0.990)) %>%
    filter(rowSums(!is.na(.)) > 8) %>%
    mutate(n_lab = rowSums(!is.na(.)))

  # Save cat list
  saveRDS(
    names(df %>% select_if(is_cat)),
    paste0(
      m_out,
      "train_cat_vars.RDS"
    )
  )

  for (col in colnames(df)) {
    if (col != "n_lab") {
      df[, paste0("presence_", col)] <- !is.na(df[, col])
    }
  }

  df <- df %>%
    rename_if(is_cat, ~ str_c("cat_", .)) %>%
    one_hot_encoding(columns = c("Geslacht", names(select(., starts_with("cat_"))))) %>%
    mutate_at(vars(!contains("cat_")), as.numeric)


  # Save variable list
  saveRDS(names(df), paste0(
    m_out,
    "train_vars.RDS"
  ))

  write.table(df,
    paste0(m_out, out_name),
    row.names = FALSE,
    sep = ";"
  )
}

process_other <- function(csv_file, out_name) {
  df <- read.csv(csv_file,
    sep = ";"
  )

  # Remove time >120 min
  df <- df %>%
    group_by(Patientnummer) %>%
    mutate(t_diff = as.numeric(difftime(Datum_Tijd,
      min(Datum_Tijd),
      units = "mins"
    ))) %>%
    filter(t_diff < 120) %>%
    summarise_all(., .funs = last) %>%
    mutate(mortality = ifelse(
      is.na(Overleden),
      0,
      difftime(Overleden,
        Datum_Tijd,
        units = "days"
      ) < 31
    )) %>%
    mutate(age = as.numeric(difftime(Sys.Date(),
      Geboortedatum,
      units = "weeks"
    )) / 52.25) %>%
    select(-c(Overleden, Geboortedatum, Datum_Tijd, Patientnummer, t_diff))

  # Data processing
  df <- df %>%
    select(which(colMeans(is.na(.)) < 0.990)) %>%
    filter(rowSums(!is.na(.)) > 8) %>%
    mutate(n_lab = rowSums(!is.na(.)))

  for (col in colnames(df)) {
    if (col != "n_lab") {
      df[, paste0("presence_", col)] <- !is.na(df[, col])
    }
  }

  # Data processing using train set information
  cat_vars <- readRDS(paste0(m_out, "train_cat_vars.RDS"))
  total_vars <- readRDS(paste0(m_out, "train_vars.RDS"))

  df <- df %>%
    rename_at(cat_vars, ~ str_c("cat_", .)) %>%
    one_hot_encoding(columns = c("Geslacht", names(select(., starts_with("cat_"))))) %>%
    (function(.df) {
      .df[total_vars[!(total_vars %in% colnames(.df))]] <- NA
      return(.df)
    }) %>%
    select(total_vars) %>%
    mutate_at(vars(!contains("cat_")), as.numeric)

  write.table(df,
    paste0(m_out, out_name),
    row.names = FALSE,
    sep = ";"
  )
}

process_train(paste0(m_in, "_train.csv"), "_train.csv")

for (d in list.files(path = m_in, pattern = "*.csv")) {
  if (!grepl("train", d)) {
    process_other(paste0(m_in, d), d)
  }
}
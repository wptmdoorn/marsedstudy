#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/process.R                       #
#                                           #
# (1) preprocessing on unknown patient      #
# (2) processing on unknown patient         #
#############################################

# imports
library(dplyr)
library(reshape2)

source("riskindex/constants.R")
source("riskindex/development/process/process_utils.R")

# directories
mod_info <- "riskindex/data/processed/"

preprocess <- function(data) {
  data %>%
    select(-ir_cols_realtime) %>%
    mutate(Datum_Tijd = as.POSIXct(paste(VerzamelDatum, VerzamelTijd),
      format = "%d-%m-%Y %H:%M"
    )) %>%
    mutate(Overleden = as.POSIXct(Overleden, format = "%d-%m-%Y")) %>%
    mutate(Geboortedatum = as.POSIXct(Geboortedatum, format = "%d-%m-%Y")) %>%
    select(-c("VerzamelDatum", "VerzamelTijd", "Afdeling")) %>%
    dcast(
      .,
      Patientnummer + Geboortedatum + Geslacht + Overleden + Datum_Tijd ~ Testcode,
      fun = first,
      value.var = "Resultaat"
    ) %>%
    select(-c("ORGEENH", "AANMELDS")[c("ORGEENH", "AANMELDS") %in% colnames(.)])
}

process <- function(data) {
  last_nna <- function(x) {
    last(na.omit(x))
  }

  data <- data %>%
    group_by(Patientnummer) %>%
    mutate(t_diff = as.numeric(difftime(Datum_Tijd,
      min(Datum_Tijd),
      units = "mins"
    ))) %>%
    filter(t_diff < 120) %>%
    summarise_all(., .funs = last_nna) %>%
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
  data <- data %>%
    select(which(colMeans(is.na(.)) < 0.990)) %>%
    filter(rowSums(!is.na(.)) > 6) %>%
    mutate(n_lab = rowSums(!is.na(.)))

  if (nrow(data) == 0) {
    return(list(FALSE, "Patient heeft niet >=4 laboratorium aanvragen gehad."))
  }

  for (col in colnames(data)) {
    if (col != "n_lab") {
      data[, paste0("presence_", col)] <- !is.na(data[, col])
    }
  }

  # Data processing using train set information
  cat_vars <- readRDS(paste0(mod_info, "train_cat_vars.RDS"))
  cat_vars <- cat_vars[cat_vars %in% colnames(data)]

  if (length(cat_vars) > 0) {
    data <- data %>%
      rename_at(cat_vars, ~ str_c("cat_", .)) %>%
      one_hot_encoding(columns = c("Geslacht", names(select(., starts_with("cat_")))))
  } else {
    data <- data %>%
      one_hot_encoding(columns = c("Geslacht"))
  }

  total_vars <- readRDS(paste0(mod_info, "train_vars.RDS"))

  data <- data %>%
    (function(.df) {
      .df[total_vars[!(total_vars %in% colnames(.df))]] <- NA
      return(.df)
    }) %>%
    select(total_vars) %>%
    mutate_at(vars(!contains("cat_")), as.numeric)

  if (nrow(data) == 0) {
    return(list(FALSE, "Patient heeft niet >=4 laboratorium aanvragen gehad."))
  } else {
    return(list(TRUE, data))
  }
}

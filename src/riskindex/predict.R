#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/predict.R                       #
#                                           #
# performs a prediction on unknown patient  #
#############################################

# imports
library(lightgbm)
source("riskindex/process.R", local = riskindex.process <- new.env())
source("riskindex/constants.R", local = riskindex.constants <- new.env())
source("prt/query.R", local = prt.query <- new.env())

calculate <- function(data) {
  rsn(n = 1, xi = 5, omega = 4, alpha = 1)
}

calculate_riskindex <- function(sap_id) {
  # check for character
  if (is.character(sap_id)) {
    sap_id <- as.numeric(sap_id)
  }

  # obtain data
  data <- prt.query$get_seh_data_individual(sprintf("%010d", sap_id))

  if (!data[[1]]) {
    return(data)
  }

  # preprocess
  data <- riskindex.process$preprocess(data[[2]])

  if (ncol(data) < 9) {
    return(c(
      FALSE,
      "Patient heeft niet >=4 laboratorium aanvragen gehad."
    ))
  }

  # process
  data <- riskindex.process$process(data)

  if (!data[[1]]) {
    return(data)
  }

  test_x <- as.matrix(data[[2]] %>% select(-mortality))

  # load model
  mod_in <- "riskindex/models/"
  model <- lightgbm::lgb.load(paste0(mod_in, "20220913_riskindex.model"))
  calibration <- readRDS("riskindex/models/20220913_calibration.model")

  raw_pred <- predict(model, test_x)

  calib_pred <- plogis(predict(calibration, data.frame(score = raw_pred)))

  # predictions
  list(TRUE, calib_pred[[1]] * 100, calculate_baseline(round(data[[2]]$age, 0),
                                          data[[2]]$Geslacht.V))
}

calculate_baseline <- function(age, GeslachtV) {
  baseline_data <- read.csv("riskindex/baseline.csv")

  # Filter predictions based on age and sex
  filtered_predictions <- baseline_data[baseline_data$Geslacht.V == GeslachtV & baseline_data$age_group == age, ]

  if (nrow(filtered_predictions) > 0) {
    return(round(filtered_predictions$prediction, 1))
  } else {
    return(-1) # Return -1 if no baseline data is available
  }
}

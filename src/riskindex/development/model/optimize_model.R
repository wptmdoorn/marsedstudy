#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/development/model/train_model.R #
#                                           #
# trains a LightGBM model                   #
#############################################

# imports
library(ParBayesianOptimization)
library(Matrix)
library(caret)
library(lightgbm)
library(dplyr)

source("riskindex/development/model/constants_model.R")

# set seed
set.seed(42)

# ensure everything is deleted
lgb.unloader(wipe = T)

m_in <- "riskindex/data/processed/"
mod_out <- "riskindex/models/"

train_data <- read.csv(paste0(m_in, "_train.csv"), sep = ";")
val_data <- read.csv(paste0(m_in, "_validation.csv"), sep = ";")

train_x <- as.matrix(train_data %>% select(-mortality))
train_y <- as.matrix(train_data %>% select(mortality))
categoricals.vec <- colnames(train_x)[c(grep("cat", colnames(train_x)))]

val_x <- as.matrix(val_data %>% select(-mortality))
val_y <- as.matrix(val_data %>% select(mortality))


lgb.train <- lgb.Dataset(
  data = train_x,
  label = train_y,
  categorical_feature = categoricals.vec
)

lgb.val <- lgb.Dataset.create.valid(lgb.train, val_x, label = val_y)

bounds <- list(
  n_leaves = c(5L, 2000L),
  b_fraction = c(0.25, 1),
  f_fraction = c(0.25, 1),
  learning_rate = c(0.001, 0.1),
  lambda_l1 = c(0.1, 100),
  lambda_l2 = c(0.1, 100),
  scale_pos_weight = c(0.01, 1.0),
  min_gain_to_split = c(1L, 100L)
)


scoringFunction <- function(n_leaves, b_fraction, f_fraction, learning_rate,
                            lambda_l1, lambda_l2, scale_pos_weight,
                            min_gain_to_split) {
  pars <- list(
    objective = "binary",
    metric = "binary_logloss",
    learning_rate = learning_rate,
    num_leaves = n_leaves,
    max_depth = -1,
    feature_fraction = f_fraction,
    bagging_fraction = b_fraction,
    lambda_l1 = lambda_l1,
    lambda_l2 = lambda_l2,
    scale_pos_weight = scale_pos_weight,
    min_gain_to_split = min_gain_to_split,
    early_stopping_round = 10
  )


  lgbmcv <- lgb.cv(
    params = pars,
    data = lgb.train,
    nrounds = 1000,
    nfold = 5,
  )

  return(list(
    Score = -lgbmcv$best_score,
    nrounds = lgbmcv$best_iter
  ))
}

optimization_object <- bayesOpt(
  FUN = scoringFunction,
  bounds = bounds,
  initPoints = 20,
  iters.n = 50,
  iters.k = 1,
  plotProgress = TRUE,
  verbose = 2
)

optimization_object <- addIterations(optimization_object, 10, bounds = bounds, verbose = TRUE)
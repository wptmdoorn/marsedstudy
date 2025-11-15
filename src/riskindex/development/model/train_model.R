#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/development/model/train_model.R #
#                                           #
# trains a LightGBM model                   #
#############################################

# imports
library(lightgbm)
library(dplyr)

# ensure everything is deleted
lightgbm::lgb.unloader(wipe = TRUE)

m_in <- "riskindex/data/processed/"
mod_out <- "riskindex/models/"

train_data <- read.csv(paste0(m_in, "_train.csv"), sep = ";")
val_data <- read.csv(paste0(m_in, "_validation.csv"), sep = ";")

train_x <- as.matrix(train_data %>% select(-mortality))
train_y <- as.matrix(train_data %>% select(mortality))
categoricals_vec <- colnames(train_x)[c(grep("cat", colnames(train_x)))]

val_x <- as.matrix(val_data %>% select(-mortality))
val_y <- as.matrix(val_data %>% select(mortality))

lgb_train <- lightgbm::lgb.Dataset(
  data = train_x,
  label = train_y,
  categorical_feature = categoricals.vec
)

lgb_val <- lightgbm::lgb.Dataset.create.valid(lgb_train, val_x, label = val_y)

params <- getBestPars(readRDS("riskindex/models/20220922 optimized model hyperparams v2.RDS"))
params$objective <- "binary"
params$metric <- "binary_logloss"

# initialize model
lgb_model <- lightgbm::lgb.train(
  params = params,
  data = lgb.train,
  nrounds = 500L,
  valids = list(val = lgb.val),
  early_stopping_rounds = 10,
)


lightgbm::lgb.save(lgb_model, paste0(mod_out, "20220922_riskindex v2.model"))
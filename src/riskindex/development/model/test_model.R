#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/development/model/test_model.R  #
#                                           #
# tests a LightGBM model                    #
#############################################

# imports
library(lightgbm)
library(pROC)
library(dplyr)

# ensure everything is deleted
lgb.unloader(wipe = T)

# directories
m_in <- "riskindex/data/processed/"
mod_in <- "riskindex/models/"

# load model
model <- lgb.load(paste0(mod_in, "20220922_riskindex.model"))

# load test data
test_data <- read.csv(paste0(m_in, "_test.csv"), sep = ";")

test_x <- as.matrix(test_data %>% select(-mortality))
test_y <- as.matrix(test_data %>% select(mortality))

# make predictions
pred_y <- predict(model, test_x)

# plot histogram and make title AUC
hist(pred_y * 100, main = sprintf("AUC: %.3f", auc(test_y, pred_y)))
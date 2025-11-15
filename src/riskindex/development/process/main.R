#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/development/process/main.R      #
#                                           #
# entry point to run full process pipeline  #
#############################################

# Preprocess Data
source('riskindex/development/process/preprocess_data.R')

# Split data
source('riskindex/development/process/split_data.R')

# Process data
source('riskindex/development/process/process_data.R')

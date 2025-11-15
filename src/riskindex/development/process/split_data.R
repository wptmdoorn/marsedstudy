#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/development/process/constants.R #
#                                           #
# file splitting data into seperate sets    #
#############################################

# imports
source("riskindex/development/process/constants.R")

# directories
m_in <- "riskindex/data/preprocessed/"

df <- read.csv(paste0(m_in, "preprocessed.csv"),
  sep = ";"
)

spec <- c(
  train = TRAIN_SIZE,
  test = TEST_SIZE,
  validation = VALIDATION_SIZE,
  calibration = CALIBRATION_SIZE
)

g <- sample(cut(seq(nrow(df)),
  nrow(df) * cumsum(c(0, spec)),
  labels = names(spec)
))

res <- split(df, g)

print("Results: ")
print(sapply(res, nrow) / nrow(df))

write.table(
  res$train,
  paste0(m_in, "split/", "_train.csv"),
  sep = ";",
  row.names = FALSE
)
write.table(
  res$test,
  paste0(m_in, "split/", "_test.csv"),
  sep = ";",
  row.names = FALSE
)
write.table(
  res$validation,
  paste0(m_in, "split/", "_validation.csv"),
  sep = ";",
  row.names = FALSE
)
write.table(
  res$calibration,
  paste0(m_in, "split/", "_calibration.csv"),
  sep = ";",
  row.names = FALSE
)
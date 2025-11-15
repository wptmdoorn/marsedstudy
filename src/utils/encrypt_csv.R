library(cyphr)
library(stringr)

data_path = 'data/'

files <- list.files(data_path, pattern="*.csv", full.names=FALSE)

for (f in files) {
  dat <- read.csv(paste0(data_path, f),
                  sep=",")
  cyphr::encrypt(write.csv(dat,
                           paste0(data_path, str_replace(f, '.csv', '.eCSV')),
                           row.names=FALSE), key=cyphr::key_sodium(readRDS('.key')))
}

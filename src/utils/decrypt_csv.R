library(cyphr)
library(stringr)

data_path = 'data/'

files <- list.files(data_path, pattern="*.eCSV", full.names=FALSE)

for (f in files) {
  dat <- cyphr::decrypt(read.csv(paste0(data_path, f)),
                        key=cyphr::key_sodium(readRDS('.key')))

  print(dat)

  write.csv(dat, paste0(data_path, str_replace(f, '.eCSV', '.csv')),
            row.names=FALSE)
}

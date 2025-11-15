library(tibble)
library(dplyr)

load.encrypted.users <- function(encrypt = TRUE) { # nolint
  .users <- cyphr::decrypt(read.csv("data/users.eCSV"),
    key = cyphr::key_sodium(readRDS(".key"))
  )

  if (encrypt) {
    .users <- .users %>%
      mutate(password = sapply(password, sodium::password_store)) %>%
      as_tibble()
  }

  .users
}

save.encrypted.users <- function(user_df) { # nolint
  cyphr::encrypt(write.csv(user_df, "data/users.eCSV", row.names = FALSE),
    key = cyphr::key_sodium(readRDS(".key"))
  )
}
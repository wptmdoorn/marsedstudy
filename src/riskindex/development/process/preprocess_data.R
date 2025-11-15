library(lightgbm)
library(dplyr)
library(reshape2)
library(readr)

ir_cols <- c(
  "Naam",
  "Labnummer",
  "UniekLabnummer",
  "Artsnaam",
  "Artscode",
  "Opmerkingrapport"
)

f_out <- "riskindex/data/preprocessed/%s"
f_raw <- "riskindex/data/raw/"

list.files(path = f_raw, pattern = "*.csv", full.names = TRUE) %>%
  purrr::map_df(
    ~ read.csv(
      .,
      sep = ";",
      header = TRUE,
      stringsAsFactors = FALSE
    ) %>%
      mutate(Labnummer = as.character(Labnummer))
  ) %>%
  bind_rows() %>%
  select(-ir_cols) %>%
  filter(Afdeling == "PEHU") %>%
  mutate(Datum_Tijd = as.POSIXct(paste(VerzamelDatum, VerzamelTijd),
    format = "%d-%m-%Y %H:%M"
  )) %>%
  mutate(Overleden = as.POSIXct(Overleden, format = "%d-%m-%Y")) %>%
  mutate(Geboortedatum = as.POSIXct(Geboortedatum, format = "%d-%m-%Y")) %>%
  select(-c("VerzamelDatum", "VerzamelTijd", "Afdeling")) %>%
  dcast(
    .,
    Patientnummer + Geboortedatum + Geslacht + Overleden + Datum_Tijd ~ Testcode,
    fun = last,
    value.var = "Resultaat"
  ) %>%
  select(-c("ORGEENH", "AANMELDS")[c("ORGEENH", "AANMELDS") %in% colnames(.)]) %>%
  write.table(., sprintf(f_out, "preprocessed.csv"), sep = ";", row.names = FALSE)
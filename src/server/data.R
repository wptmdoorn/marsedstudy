# library(tidyverse)

# helper functions
# epoch time (voor registratie enquetes + inclusie)
epochTime <- function() {
  return(as.integer(Sys.time()))
}

#####################
# INCLUSIE PAGINA   #
#####################

getAllocation <- function(i) {
  read.csv("static/block_randoms.csv")[i, ]$treatment
}

saveInclusieData <- function(df, enq, user_info) {
  .newdata <- data.frame(
    ID = enq[1],
    Naam = enq[2],
    SAP = enq[4],
    Geboortedatum = as.integer(as.POSIXct(enq[3][[1]])),
    Gezien = enq[6],
    Behandelaar = enq[7],
    InclusieDoor = user_info()$user,
    InclusieType = enq[5],
    InclusieTijd = enq[9],
    Opmerkingen = enq[8],
    Stadium = 1,
    Randomisatie = getAllocation(nrow(df) + 1),
    RISK_INDEX = ifelse(
      getAllocation(nrow(df) + 1) == "Treatment",
      "Nog niet berekend",
      "N.v.t."
    )
  )

  names(.newdata) <- names(df)

  df <- rbind(
    df,
    .newdata
  )

  write.encrypted.csv(df, "data/main.eCSV")

  df
}

#####################
# PRE-ENQ PAGINA    #
#####################

savePreData <- function(df, enq) {
  df <- rbind(
    df,
    data.frame(
      ID = enq[1],
      Pre_1 = enq[2],
      Pre_2 = enq[3],
      Pre_3 = enq[4],
      Pre_4 = enq[5],
      Pre_5 = enq[6],
      EnqueteTijd = enq[7]
    )
  )

  write.encrypted.csv(df, "data/pre.eCSV")

  df
}

#####################
# POST-ENQ PAGINA   #
#####################

savePostData <- function(df, enq) {
  if (!("Post_4" %in% colnames(df))) {
    df$Post_4 <- -1
  }

  df <- rbind(
    df,
    data.frame(
      ID = enq[[1]],
      Post_1 = enq[[2]],
      Post_2 = enq[[3]],  
      Post_4 = enq[[4]],
      Post_2a = ifelse(is.null(enq[[5]]), "", paste(enq[[5]], collapse = "|")),
      Post_2b = enq[[6]],
      Post_3 = enq[[7]],
      EnqueteTijd = enq[[8]]
    )
  )

  write.encrypted.csv(df, "data/post.eCSV")

  df
}

#####################
# SEH DATA          #
#####################

seh_data <- function(table = "patient") {
  source("prt/query.R")
  d <- get_seh_data()

  d
}

perc_digits_str <- function(s) {
  (str_count(s, "[0-9.><-]") / nchar(s)) * 100
}

process_seh_data <- function(df, table = "patient") { # nolint
  tryCatch(
    {
      if (table == "patient") {
        df <- df %>%
          group_by(Patientnummer) %>% # per patient
          mutate(AantalLab = ifelse(n() < 3, 0, n() - 3)) %>%
          arrange(Tijd) %>% # meest recente labafname ter info
          dplyr::slice(c(1, n())) %>%
          summarise(
            Eerst = min(Tijd),
            Laatst = max(Tijd),
            Naam = Naam,
            Geboorte_datum = Geboorte_datum,
            Specialisme = sub("^([[:alpha:]]*).*", "\\1", Artscode),
            AantalLab = AantalLab
          ) %>%
          dplyr::slice(1) %>%
          ungroup() %>%
          select(Patientnummer, Naam, Geboorte_datum, Eerst, Laatst, Specialisme, AantalLab) %>%
          arrange(desc(Laatst))
      } else if (table == "lab") {
        df <- df %>%
          filter(Materiaal != "Geen/n.v.t.") %>%
          mutate(Resultaat = ifelse(perc_digits_str(resultaat) > 90,
            paste0(resultaat, " ", LEenhRes),
            resultaat
          )) %>%
          select(
            "Patientnummer", "Naam", "Geboorte_datum", "Tijd", "Testomschrijving",
            "Resultaat"
          ) %>%
          arrange(desc(Tijd))
      }

      return(df)
    },
    error = function(e) {
      print(e)
      return(data.frame())
    },
    warning = function(w) {
      print(w)
      return(data.frame())
    }
  )
}

read.encrypted.csv <- function(file, ...) {
  cyphr::decrypt(read.csv(file = file),
    key = cyphr::key_sodium(readRDS(".key"))
  )
}

write.encrypted.csv <- function(df, file, ...) {
  cyphr::encrypt(write.csv(x = df, file = file, row.names = FALSE),
    key = cyphr::key_sodium(readRDS(".key"))
  )
}

get_baseline_sterfte <- function(patient) {
  bs_risk <- -1

  if (is.character(patient$Opmerkingen)) {
    bs_risk <- ifelse(grepl("baseline_risk", patient$Opmerkingen),
                      unlist(strsplit(patient$Opmerkingen, split='baseline_risk ', fixed=TRUE))[2],
                      -1)
  }

  if (bs_risk == -1) {
    return("<i>Er zijn geen baseline sterfte gegevens bekend van deze patient. </i> <br> <br>")
  } else {
    bs_risk <- as.numeric(bs_risk)
    risk_index <- as.numeric(patient$RISK_INDEX)

    if (risk_index > bs_risk) {
      relative <- sprintf("%s keer hoger dan", round(risk_index / bs_risk, 2))
    } else {
      relative <- sprintf("%s keer lager dan", round(bs_risk / risk_index, 2))
    }

    return(sprintf("<i>Deze RISK-INDEX is <b>%s</b> een gemiddelde patient met dezelfde leeftijd
              en geslacht. De baseline 31-daags sterfte in deze groep is %s%%. </i> <br> <br>",
        relative,
        bs_risk))
  }
}

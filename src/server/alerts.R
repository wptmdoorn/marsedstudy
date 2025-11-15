getRiskIndexAlert <- function(patient) { # nolint
  bs_risk <- -1

  if (is.character(patient$Opmerkingen)) {
    bs_risk <- ifelse(grepl("baseline_risk", patient$Opmerkingen),
                    unlist(strsplit(patient$Opmerkingen, split='baseline_risk ', fixed=TRUE))[2],
                    -1)
  }

  if (bs_risk == -1) {
        # no baseline data found
        shinyalert(
            html = TRUE,
            sprintf(
                "<h3> De RISK-INDEX van deze patient is %s.</h3> <br>",
                patient$RISK_INDEX
            ),
            type = "success"
        )
  } else {
    bs_risk <- as.numeric(bs_risk)
    risk_index <- as.numeric(patient$RISK_INDEX)

    if (risk_index > bs_risk) {
          relative <- sprintf("%s keer hoger dan", round(risk_index / bs_risk, 2))
    } else {
          relative <- sprintf("%s keer lager dan", round(bs_risk / risk_index, 2))
    }

    shinyalert(
          html = TRUE,
          sprintf(
              "<h2>De RISK-INDEX van deze patient is %s.</h2> <br>
              <h4>Deze RISK-INDEX is <b>%s</b> een gemiddelde patient met dezelfde leeftijd
              en geslacht. De baseline 31-daags sterfte in deze groep is %s%%.</h4>",
              patient$RISK_INDEX,
              relative,
              bs_risk
          ),
          type = "success"
      )
  }
}

noRiskIndexAlert <- function(error) {
  shinyalert(
    html = TRUE,
    sprintf(
      "<h3> De RISK-INDEX kon niet berekend worden. </h3> <br>
                 %s",
      error
    ),
    type = "error"
  )
}

noRiskIndexControl <- function() {
  shinyalert(
    html = TRUE,
    "In de controle groep berekenen we geen RISK-INDEX. <br>
                 Zie ook het studie protocol hier.",
    type = "error"
  )
}

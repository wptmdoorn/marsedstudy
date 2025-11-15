# inclusie velden
incl_fieldsAll <-
  c(
    "incl_studyid",
    "naam",
    "dateofbirth",
    "patid",
    "ictype",
    "artsgezien",
    "behandelaar",
    "opmerkingen"
  )
incl_fieldsMandatory <-
  c("incl_studyid",
    "naam",
    "dateofbirth",
    "patid",
    "ictype",
    "artsgezien",
    "behandelaar")

# pre-enq velden
pre_fieldsAll <-
  c("studyid", "pre_1", "pre_2", "pre_3", "pre_4", "pre_5")
pre_fieldsMandatory <- pre_fieldsAll

# post-enq velden
post_fieldsAll <-
  c("studyid", "post_1", "post_2", "post_4", "post_2a", "post_2b", "post_3")
post_fieldsMandatory <- c("studyid", "post_1", "post_2", "post_4")

# epoch time (voor registratie enquetes + inclusie)
epochTime <- function() {
  return(as.integer(Sys.time()))
}

kleurCodes <-
  c('#d3c8b2',
    '#aaa5a6',
    '#717a6c',
    '#628f98',
    '#FF9595')

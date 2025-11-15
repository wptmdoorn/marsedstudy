#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# riskindex/constants.R                     #
#                                           #
# contains constants for real-time predict  #
#############################################

# irrelevant columns
ir_cols_realtime <- c(
    "Naam",
    "Labnummer",
    "UniekLabnummer",
    "Artscode",
    "Artsnaam", "Opmerkingrapport",
    "Naam", "Testomschrijving", "ResInput", "LEenhRes"
)

# models directory
mod_in <- "riskindex/models/"
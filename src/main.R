library(utils)
library(shiny)

list_of_packages <-
  c(
    "tidyverse",
    "shiny",
    "shinyjs",
    "shinyalert",
    "dplyr",
    "odbc",
    "DT",
    "htmlwidgets",
    "markdown",
    "rvest",
    "shiny",
    "shinyauthr",
    "shinyjs",
    "tidyverse",
    "shinyauthr",
    "shinycssloaders",
    "shinydashboard",
    "shinyjs",
    "sodium",
    "tibble",
    "lightgbm",
    "reshape2",
    "lubridate",
    "cyphr",
    "stats",
    "leaflet.extras",
    "ParBayesianOptimization"
  )

new_packages <-
  list_of_packages[!(list_of_packages %in% utils::installed.packages()[, "Package"])]
if (length(new_packages)) {
  utils::install.packages(new.packages, repos = "http://cran.us.r-project.org")
}

print(getwd())
shiny::runApp("src", launch.browser = TRUE, port = 1234)

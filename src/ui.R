##################################
# MARS-ED STUDY INTERFACE        #
# by William van Doorn           #
# ui.R file                      #
##################################

# TO DO : CHECK IF LIBRARY EXIST AND OTHERWISE INSTALL

library(shinydashboard)
library(shinycssloaders)
library(DT)
library(shinyauthr)

###########
# LOAD UI #
###########

shinyUI(fluidPage(
  # load custom stylesheet
  includeCSS("www/style.css"),

  # load google analytics script
  tags$head(includeScript("www/google-analytics-bioNPS.js")),

  # remove shiny "red" warning messages on GUI
  tags$style(
    type = "text/css",
    ".shiny-output-error { visibility: hidden; }",
    ".shiny-output-error:before { visibility: hidden; }"
  ),

  # load page layout
  dashboardPage(
    skin = "green",
    dashboardHeader(
      title = "MARS-ED Studie Dashboard", titleWidth = 300,
      tags$li(
        class = "dropdown", style = "padding: 8px;",
        shinyauthr::logoutUI("logout")
      )
    ),
    dashboardSidebar(
      width = 300,
      uiOutput("sidebarpanel")
    ),
    dashboardBody(
      # load custom stylesheet
      includeCSS("www/style.css"),

      # load google analytics script
      tags$head(includeScript("www/google-analytics-bioNPS.js")),

      # remove shiny "red" warning messages on GUI
      tags$style(
        type = "text/css",
        ".shiny-output-error { visibility: hidden; }",
        ".shiny-output-error:before { visibility: hidden; }"
      ),
      shinyjs::useShinyjs(),
      shinyauthr::loginUI("login", title = "Login op het MARS-ED portaal"),
      tabItems(
        tabItem(
          tabName = "home",
          fluidRow(
            # Frontpage - boxes - start -----------------------------------------------
            valueBoxOutput(
              outputId = "huidige_studie_vandaag"
            ),
            valueBoxOutput(
              outputId = "huidige_studie"
            ),
            valueBoxOutput(
              outputId = "huidige_seh"
            )
          ),
          # home section
          uiOutput("homemd")
        ),
        tabItem(
          tabName = "sehOverzicht",
          uiOutput("sehMD"),
          tabBox(
            width = NULL,
            tabPanel(
              h5("Patienten"),
              dataTableOutput("sehTabel")
            ),
            tabPanel(
              h5("Lab resultaten"),
              dataTableOutput("sehLabTabel")
            )
          )
        ),
        tabItem(
          # species data section
          tabName = "studieOverzicht",
          uiOutput("studieOverzichtMD"),
          dataTableOutput("patientDataTable")
        ),
        tabItem(
          tabName = "nieuweInclusie",

          # markdown file ter introductie
          uiOutput("inclusieMD"),

          # enquete zelf
          uiOutput("inclusiePag")
        ),
        tabItem(
          tabName = "enquete",
          uiOutput("enquetemd"),
          uiOutput("enquetePag")
        ),
        tabItem(
          tabName = "adminPage",
        ),
        tabItem(
          tabName = "subAdminMenu_DB",
          uiOutput("adminDatabaseMD"),
          tabBox(
            width = NULL,
            tabPanel(
              h5("Studie"),
              dataTableOutput("adminStudieTable")
            ),
            tabPanel(
              h5("Exclusies"),
              dataTableOutput("adminExclusieTable")
            ),
            tabPanel(
              h5("Pre-Enquete"),
              dataTableOutput("adminPreTable")
            ),
            tabPanel(
              h5("Post-Enquete"),
              dataTableOutput("adminPostTable")
            )
          )
        ),
        tabItem(
          tabName = "subAdminMenu_CALC",
          uiOutput("adminCalcMD"),
          uiOutput("adminCalcPag"),
          dataTableOutput("adminCalcTable")
        ),
        tabItem(
          tabName = "subAdminMenu_INST"
        ),
        tabItem(
          tabName = "subAdminMenu_USER",
          uiOutput("adminUserMD"),
          dataTableOutput("adminUsersTable")
        ),
        tabItem(
          tabName = "subAdminMenu_EXPORT",
          uiOutput("adminExportMD"),
          uiOutput("adminExportPag")
        ),
        tabItem(
          tabName = "releases",
          uiOutput("releasesMD")
        )
      )
    ) # end dashboardBody
  ) # end dashboardPage
))
#############################################
# MARS-ED STUDY INTERFACE                   #
# by William van Doorn                      #
# ui/static.R                               #
#                                           #
# contains all static ui code, this includes#
# the static rendering of e.g. MD pages     #
#############################################

library(shiny)
library(shinydashboard)

render.sidebar <- function(cred, user_info) {
  renderUI({
    req(cred()$user_auth)
    div(
      sidebarMenu(
        id = "tabs",
        HTML(
          paste0(
            "<br>",
            "<img style = 'display: block; margin-left: auto; margin-right: auto; background-color: white' src='logo.png' width='280'>",
            "<br>"
          )
        ),
        menuItem("Home", tabName = "home", icon = icon("home")),
        if (user_info()$permissions != "monitor") {
          menuItem("SEH",
            tabName = "sehOverzicht",
            icon = icon("thumbtack")
          )
        },
        menuItem(
          "Studie overzicht",
          tabName = "studieOverzicht",
          icon = icon("table")
        ),
        menuItem(
          "Nieuwe inclusie",
          tabName = "nieuweInclusie",
          icon = icon("random", lib = "glyphicon")
        ),
        menuItem(
          "Enquete",
          tabName = "enquete",
          icon = icon("stats", lib = "glyphicon")
        ),
        if (grepl("admin", user_info()$permissions) || grepl("monitor", user_info()$permissions)) {
          menuItem(
            "Administrator",
            tabName = "adminPage",
            icon = icon("lock"),
            startExpanded = TRUE,
            menuSubItem("Database",
              tabName = "subAdminMenu_DB"
            ),
            menuSubItem("Manuele berekening",
              tabName = "subAdminMenu_CALC"
            ),
            menuSubItem("Instellingen",
              tabName = "subAdminMenu_INST"
            ),
            menuSubItem("Gebruikers",
              tabName = "subAdminMenu_USER"
            ),
            menuSubItem("Exporteer",
              tabName = "subAdminMenu_EXPORT"
            )
          )
        },
        menuItem(
          "Versies",
          tabName = "releases",
          icon = icon("stats", lib = "glyphicon")
        ),
        HTML("<br/> <br/> <br/>"),
        uiOutput("online"),
        HTML("<br/> "),
        HTML(sprintf(
          "<p style = 'text-align: center;'> <i> %s <br/> %s </i> </p>",
          user_info()$name, user_info()$permissions
        )),
        HTML(
          paste0(
            "<p style = 'text-align: center;'><small>&copy; - MARS-ED </small></p>"
          )
        )
      )
    )
  })
}

render.home.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/home.md", stylesheet = "www/style.css"))
  })
}

render.seh.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/seh.md", stylesheet = "www/style.css"))
  })
}

render.inclusie.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("forms/inclusie.md", stylesheet = "www/style.css"))
  })
}

render.studieOverzicht.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/overzicht.md", stylesheet = "www/style.css"))
  })
}

render.admin.calc.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/admincalc.md", stylesheet = "www/style.css"))
  })
}


render.admin.database.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/admindb.md", stylesheet = "www/style.css"))
  })
}

render.admin.user.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/adminuser.md", stylesheet = "www/style.css"))
  })
}

render.admin.export.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/adminexport.md", stylesheet = "www/style.css"))
  })
}

render.releases.MD <- function(cred) {
  renderUI({
    req(cred()$user_auth)
    HTML(markdown::markdownToHTML("www/releases.md", stylesheet = "www/style.css"))
  })
}
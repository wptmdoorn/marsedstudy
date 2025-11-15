##################################
# MARS-ED STUDY INTERFACE        #
# by William van Doorn           #
# server.R file                  #
##################################

# imports

library(shiny)
library(shinyauthr)
library(shinyalert)
library(lubridate)
library(tidyverse)
library(rvest)

source("ui/constants.R")
source("ui/static.R")
source("server/users.R") # users
source("server/data.R") # data
source("server/datatables.R")
source("server/js.R")
source("server/alerts.R")
source("prt/query.R")
source("riskindex/predict.R")
source("castor/export_lab.R")


################
# SERVER LOGIC #
################

shinyServer(function(input, output, session) {
  ################
  # MAIN OBSERVE #
  ################

  observe({
    incl_mandatoryFilled <-
      vapply(
        incl_fieldsMandatory,
        function(x) {
          !is.null(input[[x]]) && input[[x]] != ""
        },
        logical(1)
      )

    incl_mandatoryFilled <- all(incl_mandatoryFilled)
    shinyjs::toggleState(id = "incl_submit", condition = incl_mandatoryFilled)

    pre_mandatory_filled <-
      vapply(
        pre_fieldsMandatory,
        function(x) {
          !is.null(input[[x]]) && input[[x]] != ""
        },
        logical(1)
      )

    pre_mandatory_filled <- all(pre_mandatory_filled)
    shinyjs::toggleState(id = "pre_submit", condition = pre_mandatory_filled)
  })

  observe({
    huidig_studie <-
      reactive_main_df()

    output$huidige_studie <- renderValueBox({
      req(credentials()$user_auth)
      valueBox(
        huidig_studie %>% nrow(),
        subtitle = "Totale inclusies van MARS-ED",
        color = "blue",
        icon = icon("heart"),
      )
    })

    output$huidige_studie_vandaag <- renderValueBox({
      req(credentials()$user_auth)
      valueBox(
        huidig_studie %>%
          mutate(InclusieTijd = as.Date(
            as.POSIXlt(as.integer(InclusieTijd),
              origin = "1970-01-01"
            ),
            format = "%d-%m-%Y %H:%M"
          )) %>%
          filter(InclusieTijd == lubridate::today()) %>%
          nrow(),
        subtitle = "inclusies vandaag",
        color = "light-blue",
        icon = icon("heart"),
      )
    })
  })

  observe({
    huidig_seh <-
      seh.data.poll() %>%
      process_seh_data(table = "patient") %>%
      nrow()

    output$huidige_seh <- renderValueBox({
      req(credentials()$user_auth)
      valueBox(
        huidig_seh,
        subtitle = "Aantal patienten op de SEH",
        color = "green",
        icon = icon("list"),
      )
    })
  })

  #################
  # REACTIVE WORK #
  #################

  reactive_main_df <-
    reactiveVal(read.encrypted.csv("data/main.eCSV"))
  reactive_pre_df <-
    reactiveVal(read.encrypted.csv("data/pre.eCSV"))
  reactive_post_df <-
    reactiveVal(read.encrypted.csv("data/post.eCSV"))
  reactive_excl_df <-
    reactiveVal(read.encrypted.csv("data/excl.eCSV"))
  reactive_manual_df <-
    reactiveVal(data.frame())
  reactive_user_df <- reactiveVal(load.encrypted.users(FALSE))
  huidigePt <-
    reactiveVal(nrow(read.encrypted.csv("data/main.eCSV")))

  seh.data.poll <- reactivePoll(
    60000,
    session,
    checkFunc = function() {
      Sys.time()
    },
    valueFunc = function() {
      tryCatch(
        {
          seh_data()
        },
        error = function(e) {
          print(e)
          data.frame()
        },
        warning = function(w) {
          print(w)
          data.frame()
        }
      )
    }
  )

  status <- reactivePoll(
    60000,
    session,
    checkFunc = function() {
      print("checking DB")
      . <- NULL
    },
    valueFunc = function() {
      check_db_connection()
    }
  )

  ################
  # USER INFO    #
  ################

  credentials <- shinyauthr::loginServer(
    id = "login",
    data = load.encrypted.users(),
    # coming from users.R
    user_col = user,
    pwd_col = password,
    sodium_hashed = TRUE,
    log_out = reactive(logout_init())
  )

  # user information
  user_info <- reactive({
    credentials()$info
  })

  logout_init <- shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )

  observeEvent(credentials()$user_auth, {
    updateTabItems(session, "tabs", "home")
  })

  ################
  # Render all   #
  # static MD    #
  ################

  output$homemd <- render.home.MD(credentials)
  output$sehMD <- render.seh.MD(credentials)
  output$inclusieMD <- render.inclusie.MD(credentials)
  output$studieOverzichtMD <- render.studieOverzicht.MD(credentials)
  output$adminDatabaseMD <- render.admin.database.MD(credentials)
  output$adminCalcMD <- render.admin.calc.MD(credentials)
  output$adminUserMD <- render.admin.user.MD(credentials)
  output$adminExportMD <- render.admin.export.MD(credentials)
  output$releasesMD <- render.releases.MD(credentials)

  ################
  # SIDE BAR     #
  ################

  output$sidebarpanel <- render.sidebar(credentials, user_info)
  output$online <- renderUI({
    HTML(status())
  })

  #####################
  # SEH PAGINA        #
  #####################

  output$sehTabel <-
    DT::renderDataTable({
      req(credentials()$user_auth)
      req(user_info()$permissions != "monitor")

      tryCatch(
        {
          seh_data <- process_seh_data(seh.data.poll(), table = "patient") %>%
            mutate(Patientnummer = as.numeric(Patientnummer))
          excl_data <- reactive_excl_df() %>% rename("Patientnummer" = "SAP")
          main_data <- reactive_main_df() %>% rename("Patientnummer" = "SAP")

          seh_data <- left_join(seh_data,
                    excl_data %>% select("Patientnummer", "InclusieTijd")) %>%
            mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                        as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
            # check for at least 2 days
            mutate(color = ifelse(time_diff < 2, 1, 0)) %>%
            mutate(color = ifelse(is.na(color), 0, color)) %>%
            select(-c("InclusieTijd")) %>% left_join(.,
                                main_data %>% select("Patientnummer", "InclusieTijd")) %>%
            mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                        as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
            # check for at least 31 days
            mutate(color = ifelse(!is.na(time_diff) & time_diff < 31, 2, color)) %>%
            select(-c('time_diff', 'InclusieTijd'))

          render.seh.tabel(seh_data)
        },
        error = function(e) {
          print(e)
          DT::datatable(data.frame())
        },
        warning = function(w) {
          print(w)
          DT::datatable(data.frame())
        }
      )
    })

  output$sehLabTabel <-
    DT::renderDataTable({
      req(credentials()$user_auth)

      tryCatch(
        {
          render.seh.lab.tabel(process_seh_data(seh.data.poll(), table = "lab"))
        },
        error = function(e) {
          print(e)
          DT::datatable(data.frame())
        },
        warning = function(w) {
          print(w)
          DT::datatable(data.frame())
        }
      )
    })

  inclusieVelden <- reactiveValues()

  observeEvent(input$btn_press_incl, {
    if (is.null(input$sehTabel_cell_clicked$row)) {
      shinyalert("Selecteer eerst een patient!", type = "error")
      return()
    }

    seh_data <- process_seh_data(seh.data.poll(), table = "patient") %>%
      mutate(Patientnummer = as.numeric(Patientnummer))
    excl_data <- reactive_excl_df() %>% rename("Patientnummer" = "SAP")
    main_data <- reactive_main_df() %>% rename("Patientnummer" = "SAP")

    pat <- left_join(seh_data,
                          excl_data %>% select("Patientnummer", "InclusieTijd")) %>%
      mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                  as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
      # check for at least 2 days
      mutate(color = ifelse(time_diff < 2, 1, 0)) %>%
      mutate(color = ifelse(is.na(color), 0, color)) %>%
      select(-c("InclusieTijd")) %>% left_join(.,
                                               main_data %>% select("Patientnummer", "InclusieTijd")) %>%
      mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                  as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
      # check for at least 31 days
      mutate(color = ifelse(!is.na(time_diff) & time_diff < 31, 2, color)) %>%
      select(-c('time_diff', 'InclusieTijd'))

    pat <- pat[input$sehTabel_cell_clicked$row, ]

    if (!is.null(pat) & pat$color == 1) {
      shinyalert("Patient is al geexcludeerd!", type = "error")
    } else if (!is.null(pat) & pat$color == 2) {
      shinyalert("Patient is al geincludeerd in de studie!", type = "error")
    } else {
      inclusieVelden$pat <- pat$Naam
      inclusieVelden$dob <- as.character(as.Date(pat$Geboorte_datum, "%d-%m-%Y"))
      inclusieVelden$sap <- pat$Patientnummer

      updateTextInput(session, "naam", value = pat$Naam)
      updateTabItems(session, "tabs", "nieuweInclusie")
    }
  })

  observeEvent(input$btn_press_excl, {
    if (is.null(input$sehTabel_cell_clicked$row)) {
      shinyalert("Selecteer eerst een patient!", type = "error")
      return()
    }

    seh_data <- process_seh_data(seh.data.poll(), table = "patient") %>%
      mutate(Patientnummer = as.numeric(Patientnummer))
    excl_data <- reactive_excl_df() %>% rename("Patientnummer" = "SAP")
    main_data <- reactive_main_df() %>% rename("Patientnummer" = "SAP")

    pat <- left_join(seh_data,
                     excl_data %>% select("Patientnummer", "InclusieTijd")) %>%
      mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                  as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
      # check for at least 2 days
      mutate(color = ifelse(time_diff < 2, 1, 0)) %>%
      mutate(color = ifelse(is.na(color), 0, color)) %>%
      select(-c("InclusieTijd")) %>% left_join(.,
                                               main_data %>% select("Patientnummer", "InclusieTijd")) %>%
      mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                  as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
      # check for at least 31 days
      mutate(color = ifelse(!is.na(time_diff) & time_diff < 31, 2, color)) %>%
      select(-c('time_diff', 'InclusieTijd'))

    pat <- pat[input$sehTabel_cell_clicked$row, ]

    if (!is.null(pat) & pat$color == 1) {
      shinyalert("Patient is al geexcludeerd!", type = "error")
    } else if (!is.null(pat) & pat$color == 2) {
      shinyalert("Patient is al geincludeerd in de studie!", type = "error")
    } else {
      # Create 'fake' study PT
      alert <- shinyalert(
        title = "Wat is de reden van exclusie?",
        type = "input",
        callbackR = function(value) {
          # create excl pt
          if (value == "") {
            return()
          }

          excl_pt <- data.frame(
            SAP = as.numeric(pat$Patientnummer),
            InclusieTijd = epochTime(),
            ExclDoor = user_info()$user,
            Opmerkingen = paste0("Reden van exclusie: ", value)
          )

          # update excl data frame
          excl_df <- rbind(reactive_excl_df(), excl_pt)
          reactive_excl_df(excl_df)
          write.encrypted.csv(excl_df, "data/excl.eCSV")

          # sleep for a second and update
          Sys.sleep(0.1)
          updateTabItems(session, "tabs", "sehOverzicht")
        }
      )
    }
  })


  #####################
  # INCLUSIE PAGINA   #
  #####################

  output$inclusiePag <-
    renderUI({
      req(credentials()$user_auth)
      source("forms/inclusie.R")

      inclusie_formulier(nrow(reactive_main_df()) + 1, inclusieVelden)
    })


  incl_formData <- reactive({
    data <- sapply(incl_fieldsAll, function(x) {
      input[[x]]
    }, simplify = FALSE)
    data <- c(data, timestamp = epochTime())
    data <- t(data)
    data
  })

  # When the Submit button is clicked, submit the response
  observeEvent(input$incl_submit, {
    # FORM VALIDATION
    form <- incl_formData()
    main_df <- reactive_main_df()

    seh_data <- process_seh_data(seh.data.poll(), table = "patient") %>%
      mutate(Patientnummer = as.numeric(Patientnummer))
    excl_data <- reactive_excl_df() %>% rename("Patientnummer" = "SAP")
    main_data <- reactive_main_df() %>% rename("Patientnummer" = "SAP")

    pat <- left_join(seh_data,
                     excl_data %>% select("Patientnummer", "InclusieTijd")) %>%
      mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                  as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
      # check for at least 2 days
      mutate(color = ifelse(time_diff < 2, 1, 0)) %>%
      mutate(color = ifelse(is.na(color), 0, color)) %>%
      select(-c("InclusieTijd")) %>% left_join(.,
                                               main_data %>% select("Patientnummer", "InclusieTijd")) %>%
      mutate(time_diff = difftime(as.POSIXct(epochTime(), origin = "1970-01-01"),
                                  as.POSIXct(InclusieTijd, origin = "1970-01-01"), units='days')) %>%
      # check for at least 31 days
      mutate(color = ifelse(!is.na(time_diff) & time_diff < 31, 2, color)) %>%
      select(-c('time_diff', 'InclusieTijd'))

    pat <- pat[pat$Patientnummer == as.numeric(form[4]), ]

    if (!is.null(pat) & pat$color == 1) {
      shinyalert("Patient is al geexcludeerd!", type = "error")
    } else if (!is.null(pat) & pat$color == 2) {
      shinyalert("Patient is al geincludeerd in de studie!", type = "error")
    } else {
      shinyjs::disable("incl_submit")
      shinyjs::show("submit_msg")
      shinyjs::hide("error")
      # Save the data (show an error message in case of error)
      tryCatch(
        {
          # update FORM
          saveInclusieData(main_df, form, user_info)
          reactive_main_df(read.encrypted.csv("data/main.eCSV"))

          # update current pt
          huidigePt(nrow(main_df) + 1)
          updateTextInput(session, "studyid",
            value = paste0("MARS-ED-", sprintf("%04d", huidigePt()))
          )

          # shinyjs::reset("incl_form")
          shinyjs::hide("incl_form")
          shinyjs::show("thankyou_msg")
          updateTabItems(session, "tabs", "studieOverzicht")
        },
        error = function(err) {
          shinyjs::html("error_msg", err$message)
          shinyjs::show(
            id = "error",
            anim = TRUE,
            animType = "fade"
          )
        },
        finally = {
          updateTextInput(session, "incl_studyid",
            value = paste0("MARS-ED-", sprintf(
              "%04d", nrow(reactive_main_df()) + 1
            ))
          )

          shinyjs::enable("incl_submit")
          shinyjs::show("incl_form")
          shinyjs::hide("submit_msg")
          shinyjs::hide("thankyou_msg")

          inclusieVelden$pat <- ""
          inclusieVelden$dob <- ""
          inclusieVelden$sap <- ""
        }
      )
    }
  })

  #####################
  # MARS-ED STUDIE    #
  #####################

  output$patientDataTable <- renderDataTable({
    req(credentials()$user_auth)

    df <- reactive_main_df() %>%
      mutate(
        LabAanw = ifelse(
          sprintf("%010d", SAP) %in% sprintf("%010s", seh.data.poll()$Patientnummer),
          "Ja",
          "Nee"
        ),
        InclusieDatum = strftime(
          as.POSIXlt(as.integer(InclusieTijd),
            origin =
              "1970-01-01"
          ),
          format = "%d-%m-%Y %H:%M"
        )
      ) %>%
      select(
        ID,
        Naam,
        InclusieDatum,
        Randomisatie,
        LabAanw,
        RISK_INDEX,
        Stadium
      )

    render.studie.tabel(df)
  })


  observeEvent(input$btn_press_pat, {
    huidigePt(ifelse(
      is.null(input$patientDataTable_cell_clicked$row),
      nrow(reactive_main_df()),
      input$patientDataTable_cell_clicked$row
    ))

    huidige_pat <- reactive_main_df()[huidigePt(), ]

    if (huidige_pat$Stadium == 2) {
      shinyalert("Bereken eerst de RISK-INDEX voor deze patient.", type = "error")
    } else if (huidige_pat$Stadium == 4) {
      shinyalert("Alle enquetes voor deze patiënt zijn ingevuld.", type = "success")
    } else if (huidige_pat$Stadium == 5) {
      shinyalert("Deze patient is geexcludeerd van de studie.", type = "error")
    } else {
      updateTextInput(session, "studyid",
        value = paste0("MARS-ED-", sprintf("%04d", huidigePt()))
      )
      updateTabItems(session, "tabs", "enquete")
    }
  })

  calculateRiskIndex <- function(seh_data) {
    main_df <- reactive_main_df()

    risk_index <- calculate_riskindex(seh_data)

    if (risk_index[[1]]) {
      huidige_pat <- main_df[huidigePt(), ]

      huidige_pat$Stadium <- 3
      huidige_pat$RISK_INDEX <- sprintf("%0.1f", risk_index[[2]])
      huidige_pat$Opmerkingen <- sprintf("baseline_risk %0.1f", risk_index[[3]])
      main_df[main_df$ID == huidige_pat$ID, ] <- huidige_pat

      reactive_main_df(main_df)
      write.encrypted.csv(main_df, "data/main.eCSV")

      getRiskIndexAlert(reactive_main_df()[huidigePt(), ])

    } else {
      noRiskIndexAlert(risk_index[[2]])
    }
  }

  observeEvent(input$btn_press_riskindex, {
    huidigePt(ifelse(
      is.null(input$patientDataTable_cell_clicked$row),
      nrow(reactive_main_df()),
      input$patientDataTable_cell_clicked$row
    ))

    huidige_pat <- reactive_main_df()[huidigePt(), ]

    seh_data <-
      get_seh_data_individual(sprintf("%010d", huidige_pat$SAP))

    if (huidige_pat$Randomisatie == "Control") {
      noRiskIndexControl()
    } else if (huidige_pat$Stadium == 1) {
      shinyalert("Vul eerst de pre-enquete in voordat u de RISK-INDEX berekend.",
        type = "error"
      )
    } else if (huidige_pat$Stadium >= 3) {
      getRiskIndexAlert(huidige_pat)
      # shinyalert("De RISK-INDEX van deze patient is al berekend.", type = "success")
    } else if (huidige_pat$Stadium == 5) {
      shinyalert("Deze patient is geexcludeerd van de studie.", type = "error")
    } else if (huidige_pat$Stadium == 2) {
      if (is.null(seh_data)) {
        shinyalert(
          html = TRUE,
          "Deze patient is niet gevonden in de SEH database. <br>
                  Controleer of de patient is opgenomen in de studie.",
          type = "error"
        )
      } else {
        tijden <-
          seh_data[[2]] %>%
          dplyr::arrange(VerzamelTijd) %>%
          dplyr::slice(c(1, n())) %>%
          select(VerzamelTijd)

        shinyalert(
          html = TRUE,
          inputId = "alertRISK",
          confirmButtonText = "Bereken",
          confirmButtonCol = "green",
          cancelButtonText = "Annuleer",
          showCancelButton = TRUE,
          callbackR = function(x) {
            if (x == TRUE) {
              calculateRiskIndex(seh_data[[2]]$Patientnummer[[1]])
            }
          },
          text = tagList(
            HTML("<h4><b> Berekenen van de RISK-INDEX </b> </h4> <br/>"),
            HTML(
              sprintf(
                "Het eerste lab van deze patient is aangevraagd op <b>%s</b>
                      en het laatste lab op <b>%s</b>. <br>
                      In totaal zijn er <b>%d</b> aanvragen geweest.",
                tijden[1, 1],
                tijden[2, 1],
                nrow(seh_data[[2]]) - 4
              )
            ),
          )
        )
      }
    }
  })

  observeEvent(input$btn_press_excl_studie, {
    huidigePt(ifelse(
      is.null(input$patientDataTable_cell_clicked$row),
      nrow(reactive_main_df()),
      input$patientDataTable_cell_clicked$row
    ))

    huidige_pat <- reactive_main_df()[huidigePt(), ]

    if (huidige_pat$Stadium == 5) {
      shinyalert("Deze patient is al geexcludeerd van de studie.", type = "error")
      return()
    } else {
      shinyalert(
        html = TRUE,
        inputId = "excludeerPat",
        confirmButtonText = "Excludeer",
        confirmButtonCol = "red",
        cancelButtonText = "Annuleer",
        showCancelButton = TRUE,
        callbackR = function(x) {
          if (x == TRUE) {
            # update patient
            huidige_pat$Stadium <- 5
            huidige_pat$Opmerkingen <-
              paste0(
                huidige_pat$Opmerkingen,
                "\n",
                "Reden van exclusie: ",
                input$exclReden
              )

            # update dataframe
            main_df <- reactive_main_df()
            main_df[main_df$ID == huidige_pat$ID, ] <- huidige_pat
            reactive_main_df(main_df)
            write.encrypted.csv(main_df, "data/main.eCSV")
          }
        },
        text = tagList(
          HTML(
            "<h4><b> Excluderen van een studie patient. </b> </h4> <br/>"
          ),
          HTML(
            sprintf(
              'Je staat op het punt een patient uit de studie te verwijderen.
               Het betreft patient <b>%s</b> met SAP nummer <b>%s</b>. <br/>
               <b><p style="color: red"><b>Let op: dit kan niet meer terug gedraaid
               worden! </b></p> <br/> ',
              huidige_pat$Naam,
              huidige_pat$SAP
            )
          ),
          textInput("exclReden", "Wat is de reden van exclusie?", "")
        )
      )
    }
  })

  #####################
  # ENQUETE PAGINA    #
  #####################

  output$enquetemd <- renderUI({
    req(credentials()$user_auth)

    huidige_pat <- reactive_main_df()[huidigePt(), ]

    print(huidige_pat)

    if (huidige_pat$Stadium == 1) {
      HTML(
        markdown::markdownToHTML("forms/pre_enquete.md", stylesheet = "www/style.css")
      )
    } else if (huidige_pat$Stadium == 3) {
      HTML(
        markdown::markdownToHTML("forms/post_enquete.md", stylesheet = "www/style.css")
      )
    }
  })

  output$enquetePag <-
    renderUI({
      req(credentials()$user_auth)

      huidige_pat <- reactive_main_df()[huidigePt(), ]

      if (huidige_pat$Stadium == 1) {
        source("forms/pre_enquete.R")
        pre_formulier(huidigePt())
      } else if (huidige_pat$Stadium == 3) {
        source("forms/post_enquete.R")
        post_formulier(huidigePt(),
                       huidige_pat$RISK_INDEX,
                       get_baseline_sterfte(huidige_pat))
      }
    })

  pre_formData <- reactive({
    data <- sapply(pre_fieldsAll, function(x) {
      input[[x]]
    })
    data <- c(data, timestamp = epochTime())
    data <- t(data)
    data
  })

  # When the Submit button is clicked, submit the response
  observeEvent(input$pre_submit, {
    # User-experience stuff
    shinyjs::disable("pre_submit")
    shinyjs::show("submit_msg")
    shinyjs::hide("error")

    pre_df <- reactive_pre_df()
    pre_form <- pre_formData()

    # Save the data (show an error message in case of error)
    tryCatch(
      {
        # Save enquete data
        savePreData(pre_df, pre_form)
        reactive_pre_df(read.encrypted.csv("data/pre.eCSV"))

        # Update stadium in main table
        main_df <- reactive_main_df()
        huidige_pat <- reactive_main_df()[huidigePt(), ]

        if (huidige_pat$Randomisatie == "Control") {
          # controle groep, direct klaar
          huidige_pat$Stadium <- 4
          huidige_pat$RISK_INDEX <- "N.v.t."
        } else {
          huidige_pat$Stadium <- 2
        }

        main_df[main_df$ID == huidige_pat$ID, ] <- huidige_pat

        reactive_main_df(main_df)
        write.encrypted.csv(main_df, "data/main.eCSV")

        # shinyjs::reset("incl_form")
        shinyjs::hide("pre_form")
        shinyjs::show("thankyou_msg")

        updateTabItems(session, "tabs", "studieOverzicht")
      },
      error = function(err) {
        shinyjs::html("error_msg", err$message)
        shinyjs::show(
          id = "error",
          anim = TRUE,
          animType = "fade"
        )
      },
      finally = {
        # updateTextInput(session, 'studyid',
        #                value = paste0("MARS-ED-", sprintf("%04d", nrow(
        #                  reactive_main_df()
        #                ) + 1)))

        shinyjs::enable("incl_submit")
        shinyjs::show("incl_form")
        shinyjs::hide("submit_msg")
        shinyjs::hide("thankyou_msg")
      }
    )
  })

  post_formData <- reactive({
    data <- sapply(post_fieldsAll, function(x) {
      input[[x]]
    })
    data <- c(data, timestamp = epochTime())
    data <- t(data)
    data
  })

  # When the Submit button is clicked, submit the response
  observeEvent(input$post_submit, {
    # User-experience stuff
    shinyjs::disable("post_submit")
    shinyjs::show("submit_msg")
    shinyjs::hide("error")

    # Save the data (show an error message in case of error)
    tryCatch(
      {
        # Save enquete data
        savePostData(reactive_post_df(), post_formData())
        reactive_post_df(read.encrypted.csv("data/post.eCSV"))

        # Update stadium in main table
        main_df <- reactive_main_df()

        huidige_pat <- reactive_main_df()[huidigePt(), ]
        huidige_pat$Stadium <- 4 # for now while risk-index is here
        main_df[main_df$ID == huidige_pat$ID, ] <- huidige_pat

        reactive_main_df(main_df)
        write.encrypted.csv(main_df, "data/main.eCSV")

        # shinyjs::reset("incl_form")
        shinyjs::hide("post_form")
        shinyjs::show("thankyou_msg")

        updateTabItems(session, "tabs", "studieOverzicht")
      },
      error = function(err) {
        shinyjs::html("error_msg", err$message)
        shinyjs::show(
          id = "error",
          anim = TRUE,
          animType = "fade"
        )
      },
      finally = {
        shinyjs::enable("post_submit")
        shinyjs::show("incl_form")
        shinyjs::hide("submit_msg")
        shinyjs::hide("thankyou_msg")
      }
    )
  })

  #####################
  # ADMIN PAGE        #
  #####################

  output$adminStudieTable <-
    renderDataTable({
      req(credentials()$user_auth)

      render.admin.studie.tabel(reactive_main_df())
    })

  observeEvent(input$adminStudieTable_cell_edit, {
    .cell <- input$adminStudieTable_cell_edit
    .df <- reactive_main_df()

    .df[.cell$row, .cell$col + 1] <- .cell$value

    reactive_main_df(.df)
    write.encrypted.csv(.df, "data/main.eCSV")
  })

  output$adminExclusieTable <-
    renderDataTable({
      req(credentials()$user_auth)

      render.admin.exclusie.tabel(reactive_excl_df())
    })

  observeEvent(input$adminExclusieTable_cell_edit, {
    .cell <- input$adminExclusieTable_cell_edit
    .df <- reactive_excl_df()

    .df[.cell$row, .cell$col + 1] <- .cell$value

    reactive_excl_df(.df)
    write.encrypted.csv(.df, "data/excl.eCSV")
  })

  output$adminPreTable <-
    renderDataTable({
      req(credentials()$user_auth)

      render.admin.pre.tabel(reactive_pre_df())
    })

  observeEvent(input$adminPreTable_cell_edit, {
    .cell <- input$adminPreTable_cell_edit
    .df <- reactive_pre_df()

    .df[.cell$row, .cell$col + 1] <- .cell$value

    reactive_pre_df(.df)
    write.encrypted.csv(.df, "data/pre.csv")
  })

  output$adminPostTable <-
    renderDataTable({
      req(credentials()$user_auth)

      render.admin.post.tabel(reactive_post_df())
    })

  observeEvent(input$adminPostTable_cell_edit, {
    .cell <- input$adminPostTable_cell_edit
    .df <- reactive_post_df()

    .df[.cell$row, .cell$col + 1] <- .cell$value

    reactive_post_df(.df)
    write.encrypted.csv(.df, "data/post.eCSV")
  })

  output$adminCalcPag <-
    renderUI({
      req(grepl("admin", user_info()$permissions))
      textInput("adminCalcSAP", "SAP nummer", value = "")
    })

  observeEvent(input$adminCalcSAP, {
    if (nchar(input$adminCalcSAP) >= 6 &&
      nchar(input$adminCalcSAP) == str_count(input$adminCalcSAP, "[0-9]")) {
      # SAP number is atleast 6 numbers so we can now query labosys
      .q <- get_data_individual(input$adminCalcSAP)

      if (.q[[1]]) {
        reactive_manual_df(.q[[2]])
      }
    }
  })

  observeEvent(input$btn_press_admincalc, {
    if (dim(reactive_manual_df())[1] > 0) {
      risk_index <- calculate_riskindex(input$adminCalcSAP)

      if (risk_index[[1]]) {
        shinyalert(
          html = TRUE,
          sprintf(
            "<h3> De RISK-INDEX van deze patiënt is %0.1f. </h3> <br>",
            risk_index[[2]]
          ),
          type = "success"
        )
      } else {
        shinyalert(
          html = TRUE,
          sprintf(
            "<h3> De RISK-INDEX kon niet berekend worden. </h3> <br>
                 %s",
            risk_index[[2]]
          ),
          type = "error"
        )
      }
    }
  })

  output$adminCalcTable <-
    renderDataTable({
      req(credentials()$user_auth)
      req(grepl("admin", user_info()$permissions))
      if (dim(reactive_manual_df())[1] > 0) {
        render.admin.calc.tabel(process_seh_data(reactive_manual_df(),
          table = "lab"
        ))
      }
    })

  output$adminUsersTable <-
    renderDataTable({
      req(credentials()$user_auth)
      req(user_info()$permissions == "superadmin" || user_info()$permissions == "admin")

      render.admin.users.tabel(
        user_info()$permissions,
        reactive_user_df()
      )
    })

  observeEvent(input$btn_press_user_toev, {
    shinyalert(
      html = TRUE,
      inputId = "toevUserAlert",
      confirmButtonText = "Toevoegen",
      confirmButtonCol = "green",
      cancelButtonText = "Annuleer",
      showCancelButton = TRUE,
      callbackR = function(x) {
        if (x == TRUE) {
          # update patient
          if (!("" %in% c(input$userToevGebr, input$userToevPass))) {
            if (input$userToevGebr %in% reactive_user_df()$user) {
              shinyalert("Gebruikersnaam bestaat al, kies een andere.",
                type = "error"
              )
              return()
            }

            .user_df <- rbind(
              reactive_user_df(),
              data.frame(
                user = input$userToevGebr,
                password = input$userToevPass,
                permissions = input$userToevRechten,
                name = input$userToevNaam
              )
            )

            # storage
            reactive_user_df(.user_df)
            save.encrypted.users(.user_df)

            # TODO: refresh in current session?
          }
        }
      },
      text = tagList(
        HTML("<h2><b> Toevoegen van een gebruiker </b> </h2> <br/>"),
        textInput("userToevGebr", "Gebruikersnaam", ""),
        textInput("userToevPass", "Wachtwoord", ""),
        selectInput("userToevRechten", "Rechten", c("superadmin", "admin", "user", "monitor")),
        textInput("userToevNaam", "Naam", "")
      )
    )
  })

  observeEvent(input$btn_press_user_verw, {
    if (is.null(input$adminUsersTable_cell_clicked$row)) {
      shinyalert("Selecteer eerst een gebruiker!", type = "error")
      return()
    }

    huidige_user <-
      reactive_user_df()[input$adminUsersTable_cell_clicked$row, ]

    shinyalert(
      html = TRUE,
      inputId = "verUserAlert",
      confirmButtonText = "Verwijderen",
      confirmButtonCol = "red",
      cancelButtonText = "Annuleer",
      showCancelButton = TRUE,
      callbackR = function(x) {
        if (x == TRUE) {
          # update patient
          .user_df <- reactive_user_df() %>%
            filter(user != huidige_user$user)

          reactive_user_df(.user_df)
          save.encrypted.users(.user_df)
        }
      },
      text = tagList(
        HTML("<h2><b> Verwijderen van een gebruiker </b> </h2> <br/>"),
        HTML(
          sprintf(
            "Weet je zeker dat je gebruiker <b>%s</b> wil verwijderen?",
            huidige_user$user
          )
        )
      )
    )
  })

  observeEvent(input$adminUsersTable_cell_edit, {
    .cell <- input$adminUsersTable_cell_edit
    .df <- reactive_user_df()

    .df[.cell$row, .cell$col + 1] <- .cell$value

    reactive_user_df(.df)
    save.encrypted.users(.df)
  })

  output$adminExportPag <-
    renderUI({
      req(grepl("admin", user_info()$permissions))

      tagList(
        downloadButton("btn_export_castor_lab", "Exporteer labdata voor CASTOR"),
        actionButton("btn_export_castor_enquete", "Exporteer enquete-data voor CASTOR")
      )
    })

  output$btn_export_castor_lab <- downloadHandler(
    filename = function(file) {
      "exported_data.csv"
    },
    content = function(file) {
      huidig_studie <- reactive_main_df()
      withProgress(message = "Starten met exporteren!", value = 0, {
        write.csv(export.lab(huidig_studie), file)
      })
    }
  )

  observeEvent(input$btn_export_castor_enquete, {
    print("btn castor - data enquete")
  })
})
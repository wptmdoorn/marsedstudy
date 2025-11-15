##################################
# MARS-ED STUDY INTERFACE        #
# by William van Doorn           #
# server/datatables.R file       #
##################################

source("server/js.R")
source("ui/constants.R", local = ui.constants <- new.env())

render.seh.tabel <- function(df) {
  DT::datatable(
    df,
    colnames = c(
      "SAP",
      "Naam",
      "Geb. datum",
      "Eerste labafname",
      "Laatste labafname",
      "Specialisme",
      "Aantal labaanvragen",
      ""
    ),
    selection = "single",
    extensions = "Buttons",
    callback = sehTabel_JS,
    options = list(
      dom = 'l<"sep">Bfrtip',
      scrollX = TRUE,
      pageLength = 20,
      lengthMenu = list(c(10, 20, -1), c("10", "20", "All")),
      columnDefs = list(
        list(targets = c(0, 8), visible = F),
        list(targets = "_all", className = "dt-center")
      ),
      buttons = list(
        list(
          extend = "collection",
          text = "Includeer",
          className = "incSEH",
          action = incSEH_JS
        ),
        list(
          extend = "collection",
          text = "Excludeer",
          className = "exclSEH",
          action = exclSEH_JS
        )
      )
    )
  ) %>% formatStyle(
    0,
    target = "row",
    valueColumns = "color",
    backgroundColor = styleEqual(c(0, 1, 2), c("white", "#FF9595", "grey"))
  )
}

render.seh.lab.tabel <- function(df) {
  DT::datatable(
    df,
    colnames = c(
      "",
      "SAP",
      "Naam",
      "Geboortedatum",
      "Tijd",
      "Test",
      "Resultaat"
    ),
    selection = "single",
    extensions = "Buttons",
    options = list(
      dom = 'l<"sep">Bfrtip',
      scrollX = TRUE,
      pageLength = 20,
      lengthMenu = list(c(10, 20, -1), c("10", "20", "All")),
      columnDefs = list(
        list(targets = c(0), visible = F),
        list(targets = "_all", className = "dt-center")
      )
    )
  )
}

render.studie.tabel <- function(df) {
  DT::datatable(
    df,
    colnames = c(
      "ID",
      "Naam",
      "Datum inclusie",
      "Randomisatie",
      "Lab aanwezig?",
      "RISK-INDEX",
      ""
    ),
    selection = "single",
    extensions = "Buttons",
    callback = studieTabel_JS,
    options = list(
      dom = 'l<"sep">Bfrtip',
      order = list(list(1, "desc")),
      scrollX = TRUE,
      columnDefs = list(
        list(targets = c(0, 7), visible = F),
        list(targets = "_all", className = "dt-center")
      ),
      pageLength = 20,
      lengthMenu = list(c(10, 20, -1), c("10", "20", "All")),
      buttons = list(
        list(
          extend = "collection",
          text = "Enquete",
          className = "enqStudie",
          action = enqStudie_JS
        ),
        list(
          extend = "collection",
          text = "Bereken RISK-INDEX",
          className = "riskStudie",
          action = riskStudie_JS
        ),
        list(
          extend = "collection",
          text = "Excludeer",
          className = "exclStudie",
          action = exclStudie_JS
        )
      )
    )
  ) %>% formatStyle(
    names(.),
    target = "row",
    valueColumns = "Stadium",
    backgroundColor = styleEqual(
      c(1, 2, 3, 4, 5),
      ui.constants$kleurCodes
    )
  )
}

render.admin.studie.tabel <- function(df) {
  DT::datatable(
    df %>% mutate(InclusieTijd = as.Date(
      as.POSIXlt(as.integer(InclusieTijd),
        origin = "1970-01-01"
      ),
      format = "%d-%m-%Y %H:%M"
    )) %>%
      mutate(Geboortedatum = as.Date(
        as.POSIXlt(as.integer(Geboortedatum),
          origin = "1970-01-01"
        ),
        format = "%d-%m-%Y %H:%M"
      )),
    rownames = FALSE,
    selection = "single",
    extensions = c("Buttons", "KeyTable"),
    editable = TRUE,
    callback = JS(adminJS),
    fillContainer = TRUE,
    options = list(
      dom = 'l<"sep">Bfrtip',
      keys = TRUE,
      order = list(list(0, "desc")),
      scrollY = "500px",
      columnDefs = list(list(
        targets = "_all", className = "dt-center"
      )),
      lengthMenu = list(c(5, 10, 20, -1), c("5", "10", "20", "All")),
      buttons = list(
        c("print", "excel"),
        list(
          extend = "collection",
          text = "Enquete",
          className = "enqStudie",
          action = enqStudie_JS
        ),
        list(
          extend = "collection",
          text = "Bereken RISK-INDEX",
          className = "riskStudie",
          action = riskStudie_JS
        ),
        list(
          extend = "collection",
          text = "Excludeer",
          className = "exclStudie",
          action = exclStudie_JS
        )
      )
    )
  ) %>% formatStyle(
    names(.),
    target = "row",
    valueColumns = "Stadium",
    backgroundColor = styleEqual(
      c(1, 2, 3, 4, 5),
      ui.constants$kleurCodes
    )
  )
}

render.admin.exclusie.tabel <- function(df) {
  DT::datatable(
    df %>% mutate(InclusieTijd = as.Date(
      as.POSIXlt(as.integer(InclusieTijd),
        origin = "1970-01-01"
      ),
      format = "%d-%m-%Y %H:%M"
    )) %>%
      rename(ExclusieTijd = InclusieTijd),
    rownames = FALSE,
    selection = "single",
    extensions = c("Buttons", "KeyTable"),
    editable = TRUE,
    callback = JS(adminJS),
    fillContainer = TRUE,
    options = list(
      dom = 'l<"sep">Bfrtip',
      keys = TRUE,
      order = list(list(0, "desc")),
      scrollY = "500px",
      columnDefs = list(list(
        targets = "_all", className = "dt-center"
      )),
      lengthMenu = list(c(5, 10, 20, -1), c("5", "10", "20", "All")),
      buttons = c("print", "excel")
    )
  )
}

render.admin.pre.tabel <- function(df) {
  DT::datatable(
    df %>%
      mutate(EnqueteTijd = as.Date(
        as.POSIXlt(as.integer(EnqueteTijd),
          origin = "1970-01-01"
        ),
        format = "%d-%m-%Y %H:%M"
      )),
    rownames = FALSE,
    selection = "single",
    extensions = c("Buttons", "KeyTable"),
    editable = TRUE,
    callback = JS(adminJS),
    fillContainer = TRUE,
    options = list(
      dom = 'l<"sep">Bfrtip',
      keys = TRUE,
      order = list(list(0, "desc")),
      scrollY = "500px",
      columnDefs = list(list(
        targets = "_all", className = "dt-center"
      )),
      lengthMenu = list(c(10, 20, -1), c("10", "20", "All")),
      buttons = c("print", "excel")
    )
  )
}

render.admin.post.tabel <- function(df) {
  DT::datatable(
    df %>%
      mutate(EnqueteTijd = as.Date(
        as.POSIXlt(as.integer(EnqueteTijd),
          origin = "1970-01-01"
        ),
        format = "%d-%m-%Y %H:%M"
      )),
    rownames = FALSE,
    selection = "single",
    extensions = c("Buttons", "KeyTable"),
    editable = TRUE,
    callback = JS(adminJS),
    fillContainer = TRUE,
    options = list(
      dom = 'l<"sep">Bfrtip',
      keys = TRUE,
      order = list(list(0, "desc")),
      scrollY = "500px",
      columnDefs = list(list(
        targets = "_all", className = "dt-center"
      )),
      lengthMenu = list(c(10, 20, -1), c("10", "20", "All")),
      buttons = c("print", "excel")
    )
  )
}

render.admin.calc.tabel <- function(df) {
  DT::datatable(
    df,
    colnames = c(
      "",
      "SAP",
      "Naam",
      "Geboortedatum",
      "Tijd",
      "Test",
      "Resultaat"
    ),
    selection = "single",
    extensions = "Buttons",
    options = list(
      dom = 'l<"sep">Bfrtip',
      scrollX = TRUE,
      pageLength = 20,
      lengthMenu = list(c(10, 20, -1), c("10", "20", "All")),
      columnDefs = list(
        list(targets = c(0), visible = F),
        list(targets = "_all", className = "dt-center")
      ),
      buttons = list(
        list(
          extend = "collection",
          text = "Bereken RISK-INDEX",
          className = "riskStudie",
          action = riskAdmin_JS
        )
      )
    )
  )
}

render.admin.users.tabel <- function(permission, df) {
  # replace each string in password column with asterisks
  if (permission != "superadmin") {
    df$password <- "********"
  }

  DT::datatable(
    df,
    rownames = FALSE,
    selection = "single",
    extensions = c("Buttons", "KeyTable"),
    editable = TRUE,
    callback = JS(adminUserJS),
    fillContainer = TRUE,
    options = list(
      dom = 'l<"sep">Bfrtip',
      keys = TRUE,
      order = list(list(0, "desc")),
      scrollY = "500px",
      columnDefs = list(list(
        targets = "_all", className = "dt-center"
      )),
      lengthMenu = list(c(10, 20, -1), c("10", "20", "All")),
      buttons = list(
        list(
          extend = "collection",
          text = "Toevoegen",
          className = "admToevUser",
          action = admToevUser_JS
        ),
        list(
          extend = "collection",
          text = "Verwijderen",
          className = "admVerUser",
          action = admVerUser_JS
        )
      )
    )
  )
}

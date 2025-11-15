##################################
# MARS-ED STUDY INTERFACE        #
# by William van Doorn           #
# server/js.R file               #
# serverside javascript          #
##################################

adminJS <-
  c(
    "table.on('key', function(e, datatable, key, cell, originalEvent){",
    "  console.log(key); ",
    "  console.log(originalEvent.target.localName);",
    "  var targetName = originalEvent.target.localName;",
    "  if(key == 13 && targetName == 'div'){",
    "    $(cell.node()).trigger('dblclick.dt');",
    "  }",
    "});",
    "table.on('keydown', function(e){",
    "  console.log('hello');",
    "  var keys = [9,13,37,38,39,40];",
    "  if(e.target.localName == 'input' && keys.indexOf(e.keyCode) > -1){",
    "    $(e.target).trigger('blur');",
    "  }",
    "});",
    "table.on('key-focus', function(e, datatable, cell, originalEvent){",
    "  var targetName = originalEvent.target.localName;",
    "  var type = originalEvent.type;",
    "  if(type == 'keydown' && targetName == 'input'){",
    "    if([9,37,38,39,40].indexOf(originalEvent.keyCode) > -1){",
    "      $(cell.node()).trigger('dblclick.dt');",
    "    }",
    "  }",
    "});",
    'document.getElementsByClassName("enqStudie")[0].style.backgroundColor = "green";
     document.getElementsByClassName("riskStudie")[0].style.backgroundColor = "yellow";
     document.getElementsByClassName("exclStudie")[0].style.backgroundColor = "red";
     return table;'
  )

adminUserJS <-
  c(
    "table.on('key', function(e, datatable, key, cell, originalEvent){",
    "  console.log(key); ",
    "  console.log(originalEvent.target.localName);",
    "  var targetName = originalEvent.target.localName;",
    "  if(key == 13 && targetName == 'div'){",
    "    $(cell.node()).trigger('dblclick.dt');",
    "  }",
    "});",
    "table.on('keydown', function(e){",
    "  console.log('hello');",
    "  var keys = [9,13,37,38,39,40];",
    "  if(e.target.localName == 'input' && keys.indexOf(e.keyCode) > -1){",
    "    $(e.target).trigger('blur');",
    "  }",
    "});",
    "table.on('key-focus', function(e, datatable, cell, originalEvent){",
    "  var targetName = originalEvent.target.localName;",
    "  var type = originalEvent.type;",
    "  if(type == 'keydown' && targetName == 'input'){",
    "    if([9,37,38,39,40].indexOf(originalEvent.keyCode) > -1){",
    "      $(cell.node()).trigger('dblclick.dt');",
    "    }",
    "  }",
    "});",
    'document.getElementsByClassName("admToevUser")[0].style.backgroundColor = "green";
     document.getElementsByClassName("admVerUser")[0].style.backgroundColor = "red";
     return table;'
  )

# SEH TABEL
sehTabel_JS <-
  JS(
    'document.getElementsByClassName("incSEH")[0].style.backgroundColor = "green";
             document.getElementsByClassName("exclSEH")[0].style.backgroundColor = "red";
             return table;'
  )
incSEH_JS <-
  DT::JS(
    "function() {
                                  console.log('hello');
                                  Shiny.setInputValue('btn_press_incl', true, {priority: 'event'});
                                }"
  )

exclSEH_JS <-
  DT::JS(
    "function() {
                                  console.log('hello');
                                  Shiny.setInputValue('btn_press_excl', true, {priority: 'event'});
                                }"
  )

# Studie Tabel
studieTabel_JS <-
  JS(
    'document.getElementsByClassName("enqStudie")[0].style.backgroundColor = "green";
         document.getElementsByClassName("riskStudie")[0].style.backgroundColor = "yellow";
         document.getElementsByClassName("exclStudie")[0].style.backgroundColor = "red";
         return table;'
  )

enqStudie_JS <-
  DT::JS(
    "function() {
                           console.log('hello');
                           Shiny.setInputValue('btn_press_pat', true, {priority: 'event'});
                          }"
  )

riskStudie_JS <-
  DT::JS(
    "function() {
                           console.log('hello');
                           Shiny.setInputValue('btn_press_riskindex', true, {priority: 'event'});
                          }"
  )

exclStudie_JS <-
  DT::JS(
    "function() {
                           console.log('hello');
                           Shiny.setInputValue('btn_press_excl_studie', true, {priority: 'event'});
                          }"
  )


# Users tabel (admin)
admToevUser_JS <-
  DT::JS(
    "function() {
                           console.log('hello');
                           Shiny.setInputValue('btn_press_user_toev', true, {priority: 'event'});
                }"
  )

admVerUser_JS <-
  DT::JS(
    "function() {
                           console.log('hello');
                           Shiny.setInputValue('btn_press_user_verw', true, {priority: 'event'});
                  }"
  )

riskAdmin_JS <-
  DT::JS(
    "function() {
                           console.log('hello');
                           Shiny.setInputValue('btn_press_admincalc', true, {priority: 'event'});
                          }"
  )

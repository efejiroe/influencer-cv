## Environment ----
YT_DATA_API_KEY <- "AIzaSyBotXZPlvDrgRcrlBpvmxq1ad64nNckIDI"

## Library ---- 
if(!require('pacman')){install.packages('pacman')}

pacman::p_load(
  # Utility
  'renv'
  ,'jsonlite'
  ,'httr'
  ,'httr2'
  ,'plumber'

  # Data transformation
  ,'data.table'
  ,'tidyverse'
  ,'janitor'
  ,'skimr'

  # Machine learning and AI
  ,'gemini.R'
  ,'mlr3'
  ,'mlr3learners'

  # Graphing
  ,'plotly'
)

## Functions ----

# Get upload notification

# S1. Verification handshake:
# YouTube sends GET request
# Respond with "Hub Challenge" parameter

function(
    res,
    `hub.mode` = "",
    `hub.topic` = "",
    `hub.challenge` = "",
    `hub.lease_seconds` = ""){
  if (`hub.challenge` != "") {
    res$status <- 200
    return(as.character(`hub.challenge`))
  }
}

# S2. Receive Video notification
# Video ID is in the XML payload
# Response confirms receipt

function(req) {
  print("New video notification received!")
  return(response(status = 204))
}

cat('Dependencies Loaded.\n')
d <- search()
print(d)
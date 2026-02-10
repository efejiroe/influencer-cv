## Environment ----
API_KEY <- Sys.getenv("YT_DATA_API_KEY")

## Library ---- 
if(!require('pacman')){install.packages('pacman')}

pacman::p_load(
  # Utility
  'renv'
  ,'jsonlite'
  ,'httr'
  ,'httr2'
  ,'plumber'
  ,'xml2'
  ,'gitcreds'
  ,'usethis'
  ,'rsconnect'

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

cat('Dependencies Loaded.\n')
d <- search()
print(d)
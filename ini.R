## Environment ----
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

cat('Dependencies Loaded.\n')
d <- search()
print(d)
## Environment ----
API_KEY <- Sys.getenv("YT_DATA_API_KEY")

## Library ---- 
if(!require('pacman', quietly = TRUE)){install.packages('pacman')}

if(devMode){
  print('Development mode')
  pacman::p_load(
    'renv'
    ,'gitcreds'
    ,'usethis'
    ,'rsconnect'
    ,'janitor'
    ,'skimr'
  )
} else {
  print('Server mode: Loading only essential dependencies')
}

# Essential production dependencies
pacman::p_load(
  'jsonlite'
  ,'httr2'
  ,'xml2'
  ,'data.table'
  ,'syuzhet'
)

cat('Dependencies Loaded.\n')
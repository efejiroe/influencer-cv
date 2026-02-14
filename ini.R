## Environment ----
API_KEY <- Sys.getenv("YT_DATA_API_KEY")

devMode <- TRUE

## Library ---- 
if(!require('pacman', quietly = TRUE)){install.packages('pacman')}

if(devMode){
  print('Development mode')
  pacman::p_load(
    'renv'
    ,'plumber'
    ,'gitcreds'
    ,'usethis'
    ,'rsconnect'
    ,'data.table'
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
)

cat('Dependencies Loaded.\n')
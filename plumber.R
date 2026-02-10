source('ini.R')

#* @apiTitle YouTube Webhook for Influencer CV

# 1. VERIFICATION HANDSHAKE
#* @get /webhook
function(hub.challenge = "") {
  as.character(hub.challenge)
}

# 2. DATA RECEIVER
#* @post /webhook
function(req) {
  xml_data <- read_xml(req$postBody)
  v_id <- xml_text(xml_find_first(xml_data, ".//yt:videoId"))
  c_id <- xml_text(xml_find_first(xml_data, ".//yt:channelId"))
  
  new_entry <- data.frame(
    video_id = v_id,
    start_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    channel_id = c_id
  )
  
  # Ensure the file exists before appending to avoid deployment errors
  file_path <- "data/active_tracking.csv"
  
  write.table(
    new_entry, 
    file_path,
    append = TRUE, 
    sep = ",",
    row.names = FALSE, 
    col.names = !file.exists(file_path)
  )
  
  # LOGGING: Helps you debug in the Posit Connect logs
  message(paste("Logged new video:", v_id, "from channel:", c_id))
  
  res$status <- 204
}
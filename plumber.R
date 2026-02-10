source('ini.R')

#* @apiTitle YouTube Webhook for Influencer CV

# 1. VERIFICATION HANDSHAKE: GET endpoint for YouTube's verification handshake

#* @get /webhook

function(hub.challenge = "") {
  as.character(hub.challenge) # Sent to show server is alive
}


# 2. DATA RECEIVER: POST endpoint to receive video notifications

#* @post /webhook

function(req) {
  xml_data <- read_xml(req$postBody) # Payload
  v_id <- xml_text(xml_find_first(xml_data, ".//yt:videoId")) # Video ID
  c_id <- xml_text(xml_find_first(xml_data, ".//yt:channelId")) # Channel ID
  
  new_entry <- data.frame(
    video_id = v_id,
    start_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    channel_id = c_id
  )
  
  # APPEND to your tracking file so tracker.R sees it
  write.table(
    new_entry, 
    "active_tracking.csv",
    append = TRUE, 
    sep = ",",
    row.names = FALSE, 
    col.names = !file.exists("active_tracking.csv")
    )
  
  res$status <- 204 # Confirm receipt
}
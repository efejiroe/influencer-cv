#* @apiTitle YouTube Webhook for Influencer CV

#* GET endpoint for YouTube's verification handshake

#* @get /webhook

function(hub.challenge = "") {
  as.character(hub.challenge) # Sent to show server is alive
}

#* POST endpoint to receive video notifications

#* @post /webhook

function(req) {
  
  xml_data <- read_xml(req$postBody)
  
  # Extract Video ID and Channel ID
  video_id <- xml_text(xml_find_first(xml_data, ".//yt:videoId"))
  channel_id <- xml_text(xml_find_first(xml_data, ".//yt:channelId"))
  
  message(paste("New video detected!", video_id, "from", channel_id)) # Print test
  
  # TODO: Trigger your 48-hour tracking script here
  
  res$status <- 204 # Response confirms receipt
}
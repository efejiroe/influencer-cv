source('ini.R')

# 1. Get list of influencers
influencers <- read.csv("data/influencers.csv") # Manually sourced from Social Blade
channel_ids <- influencers$Channel.ID

# 2. Update the list of videos
get_latest_vid <- function(cid) {
  rss_url <- paste0("https://www.youtube.com/feeds/videos.xml?channel_id=", cid)
  
  resp <- request(rss_url) %>%
    req_perform()
  
  xml_data <- resp_body_xml(resp)
  
  video_id <- xml_data %>%
    xml_find_first(".//yt:videoId", xml_ns(xml_data)) %>%
    xml_text()
  
  return(video_id)
}

# 3. Get current tracking list and update
current_list <- read.csv("data/active_tracking.csv")
current_list$start_time <- as.POSIXct(current_list$start_time)


vids <- sapply(channel_ids, get_latest_vid)

new_vids <- data.frame(video_id = vids, start_time = Sys.time())

new_vids$channel_id <- rownames(new_vids)
rownames(new_vids) <- NULL


updated_list <- rbind(current_list, new_vids)
updated_list <- updated_list[!duplicated(updated_list$video_id), ]

write.csv(updated_list, "data/active_tracking.csv", row.names = FALSE)

# Track metrics in batches
track_metrics <- function() {
  tracking <- read.csv("data/active_tracking.csv")
  tracking$age <- as.numeric(difftime(Sys.time(), tracking$start_time, units = "hours"))
  
  # Filter: < 48h OR (Day 3-7 AND Hour is 12)
  to_track <- tracking[tracking$age <= 48 | (tracking$age > 48 & tracking$age <= 168 & as.POSIXlt(Sys.time())$hour == 12), ]
  
  if (nrow(to_track) > 0) {
    # Batch request (up to 50 IDs at once)
    ids_string <- paste(to_track$video_id, collapse = ",")
    
    res <- request("https://www.googleapis.com/youtube/v3/videos") %>%
      req_url_query(part = "statistics", id = ids_string, key = API_KEY) %>%
      req_perform() %>% resp_body_json()
    
    for (item in res$items) {
      out <- data.frame(time = Sys.time(), id = item$id, v = item$statistics$viewCount, l = item$statistics$likeCount, c = item$statistics$commentCount)
      write.table(out, "data/tracking_data.csv", append = TRUE, sep = ",", row.names = FALSE, col.names = !file.exists("data/tracking_data.csv"))
    }
  }
}

track_metrics()

# 4. Clean up redundancies
# Remove videos older than 7 days (168 hours) from the 'active' list
tracking <- read.csv("data/active_tracking.csv")
tracking$age <- as.numeric(difftime(Sys.time(), tracking$start_time, units = "hours"))

# Overwrite with only the recent ones
final_list <- tracking[tracking$age <= 168, c("video_id", "start_time", "channel_id")]
write.csv(final_list, "data/active_tracking.csv", row.names = FALSE)
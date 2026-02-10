source('ini.R')

# 1. Update the list of videos
channel_ids <- c(
  "UCEYKSLqhk9HsOd68T2jKbbQ", # Rebecca Joy
  "UCHl5BfkeoaXp8Yzne1TDYZg" # Me
  )

get_latest_vid <- function(cid) {
  req <- request("https://www.googleapis.com/youtube/v3/search")%>%
    req_url_query(
      part = "snippet",
      channelId = cid,
      order = "date",
      maxResults = 1,
      type = "video",
      key = API_KEY
      )%>%
    req_perform()%>%
    resp_body_json()
  
  req$items[[1]]$id$videoId
}

# 2. Get current tracking list and update
if (file.exists("data/active_tracking.csv")) {
  current_list <- read.csv("data/active_tracking.csv")
} else {
  current_list <- data.frame(video_id = character(), start_time = character())
}

vids <- sapply(channel_ids, get_latest_vid)

new_vids <- data.frame(video_id = vids, start_time = Sys.time())

updated_list <- rbind(current_list, new_vids)
updated_list <- updated_list[!duplicated(updated_list$video_id), ]

write.csv(updated_list, "data/active_tracking.csv", row.names = FALSE)

# 2. Track metrics in batches
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
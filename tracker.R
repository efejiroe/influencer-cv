
# 1. SETUP: Get API key and Define Channels
source('ini.R')

channel_ids <- c(
  "UCEYKSLqhk9HsOd68T2jKbbQ", # Rebecca
  "UCHl5BfkeoaXp8Yzne1TDYZg" # Me
  )

# 2. LISTENER: Get latest video ID

get_latest_vid <- function(cid) {
  req <- request("https://www.googleapis.com/youtube/v3/search")%>%
    req_url_query(
      part = "snippet",
      channelId = cid,
      order = "date",
      maxResults = 1,
      type = "video",
      key = API_KEY
      ) %>%
    req_perform()%>%
    resp_body_json()
  return(req$items[[1]]$id$videoId)
}

# Run once to populate your tracking file
vids <- sapply(channel_ids, get_latest_vid)

active_tracking <- data.frame(video_id = vids, start_time = Sys.time())

write.csv(active_tracking, "data/active_tracking.csv", row.names = FALSE)


# 3. TRACKER: Run this on an hourly schedule
track_metrics <- function() {
  tracking <- read.csv("data/active_tracking.csv")
  
  for (i in 1:nrow(tracking)) {
    # Calculate time elapsed
    hours_since_post <- as.numeric(difftime(Sys.time(), tracking$start_time[i], units = "hours"))
    
    is_early <- hours_since_post <= 48 # Hourly for 48 hours
    is_daily <- hours_since_post > 48 && hours_since_post <= 168 && as.POSIXlt(Sys.time())$hour == 12 # Daily, at hour 12 for days 3-7
    
    if (is_early || is_daily) {
      stats_req <- request("https://www.googleapis.com/youtube/v3/videos")%>%
        req_url_query(
          part = "statistics",
          id = tracking$video_id[i],
          key = API_KEY
          )%>%
        req_perform()%>% 
        resp_body_json()
      
      stats <- stats_req$items[[1]]$statistics
      
      result <- data.frame(
        time = Sys.time(),
        id = tracking$video_id[i],
        v = stats$viewCount,
        l = stats$likeCount,
        c = stats$commentCount
        )
      
      write.table(result, "data/tracking_data.csv", append = TRUE, sep = ",", row.names = FALSE, col.names = !file.exists("results.csv"))
    }
  }
}

track_metrics()

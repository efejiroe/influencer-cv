

# 1. Load your list of videos being tracked
# We assume a file named 'active_tracking.csv' exists with columns: 
# video_id, start_time, channel_name
if (file.exists("active_tracking.csv")) {
  tracking_list <- read.csv("active_tracking.csv")
  
  # 2. Define the metrics collection function
  get_stats <- function(v_id) {
    req <- request("https://www.googleapis.com/youtube/v3/videos") %>%
      req_url_query(part = "statistics,snippet", id = v_id, key = YT_DATA_API_KEY) %>%
      req_perform() %>%
      resp_body_json()
    
    item <- req$items[[1]]
    
    data.frame(
      timestamp = Sys.time(),
      video_id = v_id,
      title = item$snippet$title,
      views = as.numeric(item$statistics$viewCount),
      likes = as.numeric(item$statistics$likeCount),
      comments = as.numeric(item$statistics$commentCount)
    )
  }
  
  # 3. Loop through videos and decide whether to track
  for (i in 1:nrow(tracking_list)) {
    video_age_hours <- as.numeric(difftime(Sys.time(), tracking_list$start_time[i], units = "hours"))
    
    # LOGIC: Track hourly if < 48h, or once a day if > 48h (at the 12th hour)
    should_track <- video_age_hours < 48 || (as.POSIXlt(Sys.time())$hour == 12)
    
    if (should_track) {
      new_stats <- get_stats(tracking_list$video_id[i])
      write.table(new_stats, "tracking_results.csv", append = TRUE, sep = ",", row.names = FALSE, col.names = !file.exists("tracking_results.csv"))
    }
  }
}
devMode <- FALSE

source('ini.R')
library(httr2)
library(jsonlite)

# 1. Load influencers
influencers <- read.csv("data/influencers.csv", stringsAsFactors = FALSE)
channel_ids <- influencers$Channel.ID

# 2. Check who is already seeded
baseline_file <- "data/form_baselines.csv"
if (file.exists(baseline_file)) {
    seeded <- read.csv(baseline_file, stringsAsFactors = FALSE)
    unseeded_ids <- setdiff(channel_ids, seeded$channel_id)
} else {
    unseeded_ids <- channel_ids
}

if (length(unseeded_ids) == 0) {
    message("All currently tracked influencers have existing Form baselines. Nothing to seed.")
    quit(save = "no")
}

message(paste("Found", length(unseeded_ids), "unseeded channels. Seeding Form..."))

# Helper: Parse ISO 8601 duration (e.g. PT1M30S) safely for > 60s check
is_long_form <- function(duration_str) {
  if (is.null(duration_str) || is.na(duration_str)) return(FALSE)
  
  dur <- gsub("PT", "", duration_str)
  
  if (grepl("H", dur)) return(TRUE)
  
  mins <- 0
  if (grepl("M", dur)) {
    mins <- as.numeric(sub("M.*", "", dur))
  }
  
  secs <- 0
  if (grepl("S", dur)) {
    secs_str <- sub(".*M", "", dur) 
    secs_str <- sub("S", "", secs_str)
    secs <- as.numeric(secs_str)
  }
  
  total_secs <- (mins * 60) + secs
  return(total_secs > 60)
}

# 3. Process each unseeded channel
for (cid in unseeded_ids) {
    message(paste("Processing Channel:", cid))
    
    # A. Get Uploads Playlist ID
    req_channel <- request("https://www.googleapis.com/youtube/v3/channels") %>%
        req_url_query(part = "contentDetails", id = cid, key = API_KEY) %>%
        req_error(is_error = function(resp) FALSE)
    
    resp_c <- req_perform(req_channel)
    if (resp_status(resp_c) != 200) { message("Skipping due to API error on channels."); next }
    res_c <- resp_body_json(resp_c)
    
    if (length(res_c$items) == 0) { message("No channel found."); next }
    uploads_playlist_id <- res_c$items[[1]]$contentDetails$relatedPlaylists$uploads
    
    # B. Get recent videos from that playlist
    req_pl <- request("https://www.googleapis.com/youtube/v3/playlistItems") %>%
        req_url_query(part = "snippet", playlistId = uploads_playlist_id, maxResults = 15, key = API_KEY) %>%
        req_error(is_error = function(resp) FALSE)
    
    resp_pl <- req_perform(req_pl)
    if (resp_status(resp_pl) != 200) { message("Skipping due to API error on playlistItems."); next }
    res_pl <- resp_body_json(resp_pl)
    
    if (length(res_pl$items) == 0) { message("No videos found."); next }
    video_ids <- sapply(res_pl$items, function(x) x$snippet$resourceId$videoId)
    
    if (length(video_ids) == 0) next
    
    # C. Fetch Statistics and duration
    ids_string <- paste(video_ids, collapse = ",")
    req_vids <- request("https://www.googleapis.com/youtube/v3/videos") %>%
        req_url_query(part = "statistics,contentDetails,snippet", id = ids_string, key = API_KEY) %>%
        req_error(is_error = function(resp) FALSE)
    
    resp_vids <- req_perform(req_vids)
    if (resp_status(resp_vids) != 200) { message("Skipping due to API error on videos."); next }
    res_vids <- resp_body_json(resp_vids)
    
    # D. Filter for Long-form and calculate metrics
    valid_vmax <- numeric()
    valid_intent <- numeric()
    
    for (item in res_vids$items) {
        duration <- item$contentDetails$duration
        if (is_long_form(duration)) {
            
            views <- as.numeric(item$statistics$viewCount)
            likes <- as.numeric(item$statistics$likeCount)
            comments <- as.numeric(item$statistics$commentCount)
            
            if (is.null(views) || is.na(views)) views <- 0
            if (is.null(likes) || is.na(likes)) likes <- 0
            if (is.null(comments) || is.na(comments)) comments <- 0
            
            pub_date <- as.POSIXct(item$snippet$publishedAt, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC")
            now_utc <- as.POSIXct(format(Sys.time(), tz="UTC"), tz="UTC")
            hours_alive <- as.numeric(difftime(now_utc, pub_date, units = "hours"))
            
            if (hours_alive <= 0) hours_alive <- 1 
            
            vmax_proxy <- views / hours_alive
            
            intent_ratio <- 0
            if (views > 0) {
                intent_ratio <- (likes + (2 * comments)) / views
            }
            
            valid_vmax <- c(valid_vmax, vmax_proxy)
            valid_intent <- c(valid_intent, intent_ratio)
            
            if (length(valid_vmax) == 5) break 
        }
    }
    
    # E. Calculate Form and Append
    if (length(valid_vmax) > 0) {
        form_vmax <- mean(valid_vmax)
        form_intent <- mean(valid_intent)
        
        out <- data.frame(
            channel_id = cid,
            seed_date = as.Date(Sys.time()),
            baseline_vmax_proxy = form_vmax,
            baseline_intent_ratio = form_intent,
            videos_seeded = length(valid_vmax),
            stringsAsFactors = FALSE
        )
        
        write.table(
            out, 
            baseline_file, 
            append = TRUE, 
            sep = ",", 
            row.names = FALSE, 
            col.names = !file.exists(baseline_file)
        )
        message(paste("Successfully seeded baseline for", cid, "[ Videos:", length(valid_vmax), "]"))
    } else {
        message(paste("No valid long-form videos found for", cid))
    }
}

message("Seeding complete.")

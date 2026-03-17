## Tracking Code ----

# 1. Get list of influencers
influencers <- read.csv("data/influencers.csv") 
channel_ids <- influencers$Channel.ID

# 2. Update the list of videos
get_latest_vid <- function(cid) {
  rss_url <- paste0("https://www.youtube.com/feeds/videos.xml?channel_id=", cid)
  
  resp <- tryCatch({
    request(rss_url) %>% req_perform()
  }, error = function(e) {
    if (grepl("403", e$message)) {
      message("Quota potentially exhausted at RSS gateway. Skipping...")
    }
    return(NULL) 
  })
  
  if (is.null(resp)) return(NULL)
  
  xml_data <- resp_body_xml(resp)
  video_id <- xml_data %>%
    xml_find_first(".//yt:videoId", xml_ns(xml_data)) %>%
    xml_text()
  
  return(video_id)
}

# 3. Get current tracking list and update
current_list <- read.csv("data/active_tracking.csv")
if (!"sentiment_pulled" %in% names(current_list)) current_list$sentiment_pulled <- FALSE
current_list$start_time <- as.POSIXct(current_list$start_time)

# Get latest IDs
vids <- sapply(channel_ids, get_latest_vid, simplify = FALSE)

# REMOVE NULLS: Prevents "NULL" strings from entering your CSV
vids <- vids[!sapply(vids, is.null)]

if (length(vids) > 0) {
  new_vids <- data.frame(
    video_id = unlist(vids), 
    start_time = Sys.time(),
    channel_id = names(vids), # Use names from sapply
    sentiment_pulled = FALSE,
    stringsAsFactors = FALSE
  )
  
  updated_list <- rbind(current_list, new_vids)
  # Remove duplicates and ensure "NULL" didn't slip in
  updated_list <- updated_list[!duplicated(updated_list$video_id) & !is.na(updated_list$video_id), ]
  write.csv(updated_list, "data/active_tracking.csv", row.names = FALSE)
}

# Track metrics in batches
track_metrics <- function() {
  tracking <- read.csv("data/active_tracking.csv")
  if (nrow(tracking) == 0) return(NULL)
  
  if (!"sentiment_pulled" %in% names(tracking)) tracking$sentiment_pulled <- FALSE
  
  tracking$age <- as.numeric(difftime(Sys.time(), tracking$start_time, units = "hours"))
  to_track <- tracking[tracking$age <= 48 | (tracking$age > 48 & tracking$age <= 168 & as.POSIXlt(Sys.time())$hour == 12), ]
  
  if (nrow(to_track) > 0) {
    ids_string <- paste(to_track$video_id, collapse = ",")
    
    # 1. Prepare the request
    req <- request("https://www.googleapis.com/youtube/v3/videos") %>%
      req_url_query(part = "statistics", id = ids_string, key = API_KEY) %>%
      req_error(is_error = function(resp) FALSE) 
    
    # 2. Perform and check status
    resp <- req_perform(req)
    status <- resp_status(resp)
    
    if (status == 403) {
      message("Quota exhausted. No changes made to the data.")
      return(NULL) 
    }
    
    if (status != 200) {
      message(paste("API Error:", status, "- Skipping metrics update."))
      return(NULL)
    }
    
    res <- resp_body_json(resp)
    
    # Identify and remove missing IDs
    returned_ids <- sapply(res$items, function(x) x$id)
    missing_ids <- setdiff(to_track$video_id, returned_ids)
    
    if (length(missing_ids) > 0) {
      message("Removing deleted/missing videos: ", paste(missing_ids, collapse = ", "))
      # Note: Ensure 'tracking' exists in this scope or is updated globally
      tracking <- tracking[!tracking$video_id %in% missing_ids, ]
      write.csv(tracking, "data/active_tracking.csv", row.names = FALSE)
    }
    
    # Returns NA if the value is missing/NULL so the data.frame remains valid
    # Influencers disabling engagement can cause this.
    get_stat <- function(stat_item) {
      if (is.null(stat_item)) return(NA) else return(stat_item)
    }
    
    # 3. Save statistics
    for (item in res$items) {
      # Extract stats safely
      stats <- item$statistics
      
      # Default sentiment metrics
      s_pos <- NA; s_neu <- NA; s_neg <- NA
      target_row_idx <- which(tracking$video_id == item$id)
      
      if (length(target_row_idx) > 0) {
        v_age <- tracking$age[target_row_idx[1]]
        s_pulled <- tracking$sentiment_pulled[target_row_idx[1]]
        
        # 24-Hour Sentiment Snapshot Trigger
        if (v_age >= 23 && v_age <= 25 && !s_pulled) {
          req_comments <- request("https://www.googleapis.com/youtube/v3/commentThreads") %>%
            req_url_query(part = "snippet", videoId = item$id, maxResults = 100, textFormat = "plainText", key = API_KEY) %>%
            req_error(is_error = function(resp) FALSE)
          
          resp_c <- tryCatch(req_perform(req_comments), error = function(e) NULL)
          
          if (!is.null(resp_c) && resp_status(resp_c) == 200) {
            res_c <- resp_body_json(resp_c)
            # Extract comment text
            comments_text <- sapply(res_c$items, function(x) x$snippet$topLevelComment$snippet$textDisplay)
            
            if (length(comments_text) > 0) {
              # Clean URLs and Basic HTML
              comments_text <- gsub("http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+", "", comments_text)
              comments_text <- gsub("<.*?>", "", comments_text)
              
              # Calculate bing sentiment scores
              scores <- tryCatch({
                syuzhet::get_sentiment(comments_text, method = "bing")
              }, error = function(e) { NULL })
              
              if (!is.null(scores)) {
                s_pos <- round(mean(scores > 0, na.rm=TRUE), 4)
                s_neg <- round(mean(scores < 0, na.rm=TRUE), 4)
                s_neu <- round(mean(scores == 0, na.rm=TRUE), 4)
              }
            }
            # Update state so we don't pull again
            tracking$sentiment_pulled[target_row_idx] <- TRUE
          }
        }
      }
      
      out <- data.frame(
        time = Sys.time(), 
        id   = item$id, 
        v    = get_stat(stats$viewCount), 
        l    = get_stat(stats$likeCount), 
        c    = get_stat(stats$commentCount),
        sentiment_pos = s_pos,
        sentiment_neu = s_neu,
        sentiment_neg = s_neg,
        stringsAsFactors = FALSE
      )
      
      write.table(
        out, 
        "data/tracking_data.csv", 
        append = TRUE, 
        sep = ",", 
        row.names = FALSE, 
        col.names = !file.exists("data/tracking_data.csv")
      )
    }
    
    # Save the updated trailing state (sentiment_pulled)
    write.csv(tracking, "data/active_tracking.csv", row.names = FALSE)
  }
}

track_metrics()

# 4. Final Clean up
tracking <- read.csv("data/active_tracking.csv")
if (!"sentiment_pulled" %in% names(tracking)) tracking$sentiment_pulled <- FALSE
tracking$age <- as.numeric(difftime(Sys.time(), tracking$start_time, units = "hours"))
final_list <- tracking[tracking$age <= 168, c("video_id", "start_time", "channel_id", "sentiment_pulled")]
write.csv(final_list, "data/active_tracking.csv", row.names = FALSE)

# 5, Channel video Look up
tracking$start_date <- as.Date(tracking$start_time)
tracking$age <- NULL
tracking$start_time <- NULL
tracking$sentiment_pulled <- NULL

lookup <- read.csv("data/channel-video-lookup.csv")
lookup <- rbind(tracking, lookup)

setDT(lookup)
lookup[order(channel_id,start_date)]
lookup <- unique(lookup, by = 'video_id')

write.csv(lookup, "data/channel-video-lookup.csv", row.names = FALSE)

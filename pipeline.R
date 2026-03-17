devMode <- TRUE

library('ini.R')

# --- ANALYSIS PHASE (from pipeline.R) ---

# 1. Read tracking data
d <- read.csv('data/tracking_data.csv', header = FALSE) |> setDT()
names(d) <- c('date_time', 'video_id', 'views', 'likes', 'comments', 'sentiment_pos', 'sentiment_neu', 'sentiment_neg')

d[, date_time := as.POSIXct(date_time)]
setorder(d, video_id, views, date_time)
d[, seq_no := 1:.N, by = video_id]

# Link channels IDs using the lookup table
lookup <- read.csv('data/channel-video-lookup.csv', header = TRUE) |> setDT()
d[lookup, channel_id := channel_id, on = .(video_id)]

# Filter to include only linkable channels
d <- d[!is.na(channel_id), ]

# Calculate base metrics
d[, `:=`(
  engagement = round((likes + (2 * comments)) / views, digits = 2), # Weighted comments heavier than likes
  launch_age = round(as.numeric(difftime(date_time, first(date_time), units = 'hours')), digits = 1),
  interval = round(as.numeric(difftime(date_time, shift(date_time, n = 1L, type = 'lag'), units = 'hours')), digits = 1),
  views_delta = views - shift(views, n = 1L, type = 'lag', fill = 0),
  likes_delta = likes - shift(likes, n = 1L, type = 'lag', fill = 0),
  comments_delta = comments - shift(comments, n = 1L, type = 'lag', fill = 0)
), by = video_id][is.na(interval), interval := 0][likes_delta < 0, likes_delta := 0]

# View velocity calculations
d[, `:=`(
  view_velocity_cumm = ifelse(launch_age > 0, round(views / launch_age, digits = 1), 0),
  view_velocity_inst = ifelse(interval > 0, round((views_delta / interval) * views_delta, digits = 0), 0),
  view_velocity_vph = ifelse(interval > 0, round(views_delta / interval, digits = 1), 0)
)]

# Peak Velocity (Max VPH)
d[, peak_velocity := max(view_velocity_vph, na.rm = TRUE), by = video_id]

# Bass Diffusion Model (Discrete Form)
d[, cum_views_lag := shift(views, n = 1L, type = 'lag', fill = 0), by = video_id]

# Calculate Bass parameters for each video with enough data points
bass_params <- d[, {
  if (.N > 3) {
    fit <- tryCatch(lm(views_delta ~ cum_views_lag + I(cum_views_lag^2)), error = function(e) return(NULL))
    
    if (!is.null(fit)) {
      coefs <- coef(fit)
      a_param <- coefs[1]
      b_param <- coefs[2]
      c_param <- coefs[3]
      
      discriminant <- b_param^2 - 4 * a_param * c_param
      if (!is.na(discriminant) && discriminant >= 0 && !is.na(c_param) && c_param < 0) {
        M1 <- (-b_param + sqrt(discriminant)) / (2 * c_param)
        M2 <- (-b_param - sqrt(discriminant)) / (2 * c_param)
        M <- max(M1, M2, na.rm = TRUE)
        p <- a_param / M
        q <- -M * c_param
      } else {
        M <- NA_real_; p <- NA_real_; q <- NA_real_
      }
    } else {
      M <- NA_real_; p <- NA_real_; q <- NA_real_
    }
    list(bass_M = M, bass_p = p, bass_q = q)
  } else {
    list(bass_M = NA_real_, bass_p = NA_real_, bass_q = NA_real_)
  }
}, by = video_id]

# Merge Bass parameters back to main dataset
d <- merge(d, bass_params, by = "video_id", all.x = TRUE)

# --- EXPORT PHASE (from pbi.R) ---

# Load influencer dimension data
influencers <- fread("data/influencers.csv")
setnames(influencers, c("Influencer", "Handle", "Channel ID"), c("influencer_name", "handle", "channel_id"))

# Merge with the main data table 'd'
pbi_data <- merge(d, influencers, by = "channel_id", all.x = TRUE)

# Organise columns for Power BI
setcolorder(pbi_data, c("date_time", "influencer_name", "handle", "video_id", "channel_id"))

# Export final flattened dataset
write.csv(pbi_data, "data/pbi_fact_polling.csv", row.names = FALSE)

cat("Consolidated processing and Power BI export completed: data/pbi_fact_polling.csv\n")
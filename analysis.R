library(data.table)

# 1. Read
d <- read.csv('data/tracking_data.csv', header = F)|>setDT()

names(d) <- c('date_time', 'video_id', 'views', 'likes', 'comments', 'sentiment_pos', 'sentiment_neu', 'sentiment_neg')

d[, date_time := as.POSIXct(date_time)]

setorder(d, video_id, views, date_time)

d[, seq_no := 1:.N, by = video_id]

# Link channels IDs
lookup <- read.csv('data/channel-video-lookup.csv', header = T)|>setDT()

d[lookup, channel_id :=  channel_id, on =.(video_id)]

# We want only those we can link back.
# Ideally, we should keep data on the last 5 videos for each channel to show form.

d <- d[!is.na(channel_id),] 

# Calculate base metrics
d[, `:=`(
  engagement = round((likes+(2*comments))/views, digits = 2), # Weighted comments heavier than likes
  launch_age = round(as.numeric(difftime(date_time, first(date_time), units = 'hours')), digits = 1),
  interval = round(as.numeric(difftime(date_time, shift(date_time, n = 1L, type = 'lag'), units = 'hours')), digits = 1),
  views_delta = views - shift(views, n = 1L, type = 'lag', fill = 0),
  likes_delta = likes - shift(likes, n = 1L, type = 'lag', fill = 0),
  comments_delta = comments - shift(comments, n = 1L, type = 'lag', fill = 0)
), by = video_id][is.na(interval), interval := 0][likes_delta < 0, likes_delta := 0]

# About Views velocity
# Top of funnel metric i.e."consideration stage"
# Ave. Velocity shows how fast awareness happens
# It Shows if follower notifications are on or off
# It also indicates trust levels/FOMO factor of followers.

# Instant velocity tells us if the videos gets "intermittent revs"
# Algorithm promote fast views in side bars and shares from big accounts delaying its decay

d[, `:=`(
  view_velocity_cumm = ifelse(launch_age > 0, round(views/launch_age, digits = 1), 0),
  view_velocity_inst = ifelse(interval > 0, round((views_delta/interval)*views_delta, digits = 0), 0),
  view_velocity_vph = ifelse(interval > 0, round(views_delta/interval, digits = 1), 0)
)]

# Peak Velocity (Max VPH)
d[, peak_velocity := max(view_velocity_vph, na.rm = TRUE), by = video_id]

# Bass Diffusion Model (Discrete Form)
# n(t) = a + b*N(t-1) + c*N(t-1)^2
d[, cum_views_lag := shift(views, n = 1L, type = 'lag', fill = 0), by = video_id]

# Calculate Bass parameters for each video with enough data points
bass_params <- d[, {
  if (.N > 3) {
    # Fit quadratic model: views_delta ~ cum_views_lag + cum_views_lag^2
    fit <- tryCatch(lm(views_delta ~ cum_views_lag + I(cum_views_lag^2)), error = function(e) return(NULL))
    
    if (!is.null(fit)) {
      coefs <- coef(fit)
      a_param <- coefs[1]
      b_param <- coefs[2]
      c_param <- coefs[3]
      
      discriminant <- b_param^2 - 4*a_param*c_param
      if (!is.na(discriminant) && discriminant >= 0 && !is.na(c_param) && c_param < 0) {
        M1 <- (-b_param + sqrt(discriminant)) / (2*c_param)
        M2 <- (-b_param - sqrt(discriminant)) / (2*c_param)
        M <- max(M1, M2, na.rm = TRUE)
        p <- a_param / M
        q <- -M * c_param # or b_param + p
      } else {
        M <- NA_real_
        p <- NA_real_
        q <- NA_real_
      }
    } else {
      M <- NA_real_
      p <- NA_real_
      q <- NA_real_
    }
    list(bass_M = M, bass_p = p, bass_q = q)
  } else {
    list(bass_M = NA_real_, bass_p = NA_real_, bass_q = NA_real_)
  }
}, by = video_id]

# Merge Bass parameters back to main data set
d <- merge(d, bass_params, by = "video_id", all.x = TRUE)

# I am measure dynamics which is my differentiation.
# The algorithm:
# Watch time > Comments > Likes > Views
# Hi comment volumes = hi engagement. This needs sentiment analysis to be useful.
# Hi Like/View > 4% trigger the algorithm i.e. viewer satisfaction
# Hi View velocity triggers the algorithm.
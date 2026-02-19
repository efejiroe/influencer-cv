# 1. Read
d <- read.csv('data/tracking_data.csv', header = F)|>setDT()

names(d) <- c('date_time', 'video_id', 'views', 'likes', 'comments')

d[, date_time := as.POSIXct(date_time)]

setorder(d, video_id, views, date_time)

d[, seq_no := 1:.N, by = video_id]

# Calculate base metrics
d[, `:=`(
  engagement = round((likes+(2*comments))/views, digits = 2), # Weighted comments heavier thank likes
  launch_age = round(as.numeric(difftime(date_time, first(date_time), units = 'hours')), digits = 1),
  interval = round(as.numeric(difftime(date_time, shift(date_time, n = 1L, type = 'lag'), units = 'hours')), digits = 1),
  views_delta = views - shift(views, n = 1L, type = 'lag', fill = 0),
  likes_delta = likes - shift(likes, n = 1L, type = 'lag', fill = 0),
  comments_delta = comments - shift(comments, n = 1L, type = 'lag', fill = 0)
), by = video_id][is.na(interval), interval := 0][likes_delta < 0, likes_delta := 0]

# Views velocity and power
# Top of funnel metric i.e."consideration stage"
# Velocity shows how fast awareness happens
# Shows if follower notifications are on or off
# Aligned with engagement velocity it shows trust levels/FOMO factor
# Power shows how consistent awareness is
# Also tells us if the videos gets intermittent revs (algorithm promotion in side bars or shares from big accounts).
# This is good for delaying the decay.

d[, `:=`(
  view_velocity_cumm = ifelse(launch_age > 0, round(views/launch_age, digits = 1), 0),
  view_velocity_inst = ifelse(interval > 0, round(views_delta/interval, digits = 1), 0),
  view_power_inst = ifelse(interval > 0, round((views_delta/interval)*views_delta, digits = 0), 0)
  )]

# Engagement velocity and power
# Bottom of funnel metric i.e. predicts CTR
# Velocity shows how fast engagement (potentially CTR) happens - indicates FOMO factor
# Power shows how consistent engagement is - penalizes slow burn, indicates hot/cold converters.
d[, engagement_delta := round(ifelse(views_delta > 0, (likes_delta+comments_delta)/views_delta, 0), digits = 1)]
d[, `:=`(
  engagement_velocity_cumm = ifelse(launch_age > 0, round(engagement/launch_age, digits = 1), 0),
  engagement_velocity_inst = ifelse(interval > 0, round(engagement_delta/interval, digits = 1), 0),
  engagement_power_inst = ifelse(interval > 0, round((engagement_delta/interval)*engagement_delta, digits = 0), 0)
  )]

# Intent measures the quality of engagement velocity
# Hi Power, Hi intent = Maximum CTR
# Hi Power, Lo intent = High CTR
# Hi Power, Lo intent = Low CTR (revs would not resurrect this one!)
d[, intent := round(ifelse(views_delta > 0, comments_delta/views_delta, 0), digits = 2)]

# My metrics are dynamic which differentiates this.

# The algorithm:
# Watch time > Comments > Likes > Views
# Hi comment volumes = hi engagement.
# Hi Like/View > 4% trigger the algorithm i.e. viewer satisfaction
# Hi View velocity triggers the algorithm.
# Power BI Export Script
# This script processes the influencer tracking data and exports it for Power BI.

source('analysis.R')

# Load influencer dimension data
influencers <- fread("data/influencers.csv")
setnames(influencers, c("Influencer", "Handle", "Channel ID"), c("influencer_name", "handle", "channel_id"))

# Merge with the main data table 'd' from analysis.R
# 'd' contains granular polling data with calculated metrics
pbi_data <- merge(d, influencers, by = "channel_id", all.x = TRUE)

# Ensure columns are well-named and ordered for Power BI
# We keep it granular as requested
setcolorder(pbi_data, c("date_time", "influencer_name", "handle", "video_id", "channel_id"))

# Export to CSV
write.csv(pbi_data, "data/pbi_fact_polling.csv", row.names = FALSE)

cat("Power BI export completed: data/pbi_fact_polling.csv\n")

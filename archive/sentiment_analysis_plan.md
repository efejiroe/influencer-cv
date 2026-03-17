# Technical Roadmap: 24-Hour Comment Sentiment Analysis

This plan outlines how to modify the tracking pipeline to sustainably gather comments within the crucial first 24 hours of a video's launch and process them for sentiment, giving us the "Quality of Intent."

## The Challenge

Currently, `tracker.R` pulls the *aggregate* `commentCount`. It does not pull the actual text. Pulling text via the `CommentThreads` endpoint of the YouTube API is quota-heavy and can be computationally expensive. 

## Proposed Solution: The 24-Hour Snapshot

Instead of pulling comments every hour (which drains API quota rapidly), we will trigger a **Single Sentiment Snapshot** exactly at the 24-hour mark (or as close to it as the cron job allows).

### Step 1: Database Modification

We need to store sentiment scores alongside the raw numbers. In `tracking_data.csv` (or a new relational table like `comments_data.csv`), add new columns:
*   `sentiment_pos` (Percentage of positive comments)
*   `sentiment_net` (Percentage of neutral comments)
*   `sentiment_neg` (Percentage of negative comments)
*   `top_keywords` (e.g., "love, bought, code, fake, sponsor")

### Step 2: Modifying `tracker.R`

We will add a conditional scraper inside the main tracking loop.

```R
# Pseudocode implementation concept inside track_metrics()

if (tracking$age >= 23 && tracking$age <= 25 && !tracking$sentiment_pulled) {
    # 1. Hit the CommentThreads API Endpoint for this specific video_id
    # 2. Pull the "Top" 100 comments (or latest 100). Do not paginate deeply to save quota.
    # 3. Pass the vector of text strings to the Sentiment Engine.
    # 4. Save the aggregate score back to the tracking data.
    # 5. Mark tracking$sentiment_pulled = TRUE so it doesn't trigger again.
}
```

### Step 3: The Sentiment Engine (R Implementation)

To keep this lightweight and contained within the R ecosystem, we will use the `syuzhet` or `tidytext` packages. 

1.  **Text Clean-up:** Strip emojis (or convert them to text equivalents if possible, as emojis are heavily used in beauty), remove URLs, and lowercase.
2.  **Lexicon Scoring:** 
    *   We will start with the generic Bing or Afinn lexicons to score words as positive or negative.
    *   *Future Iteration:* We should build a custom "Beauty & Influencer Lexicon" (e.g., "obsessed", "need this", "dupe", "bought it" = highly positive / intent; "sponsored", "ad", "fake", "breakout" = negative/skeptical).
3.  **Aggregation:** Calculate the mean sentiment score for the 100 comments and append it to our metric row.

### Step 4: System Sustainability & Quota

*   **API Cost:** `commentThreads.list` costs 1 quota point per request. If we track 50 active videos, that's only 50 extra points per day (highly sustainable against the 10,000 daily limit).
*   **Processing Cost:** Sentiment analysis of 100 short text strings per video in R takes milliseconds. It will not slow down the hourly GitHub Action runner.

## The Output Insight

Once implemented, our pitch framework upgrades significantly:
Instead of just saying: *"Creator D generates 500 comments."*
We can say: *"Creator D generated 500 comments in the first 24 hours, and 85% of them were High-Intent Positive, specifically utilizing keywords like 'buying' and 'link'."*

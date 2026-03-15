# Influencer Expansion Plan: Beauty Micro-Influencers

This plan details the strategy to identify, vet, and ingest beauty micro-influencers (10,000 - 100,000 subscribers) who post regularly on YouTube.

## Phase 1: Discovery & Sourcing

We cannot rely purely on manual YouTube searches because the algorithm biases towards massive creators. We must use targeted tools to find the "middle layer" of creators.

1.  **Modash / HypeAuditor Queries:**
    *   **Filters:** "Beauty & Makeup" category.
    *   **Audience Size:** strictly bounded between 10k and 100k subscribers.
    *   **Platform:** YouTube primarily.
    *   **Activity Level:** Filter for creators who have published at least one video in the last 14 days to ensure they have an active posting "form" we can track.
2.  **Affiliate Network Scraping:** Look at platforms like MagicLinks or RewardStyle (LTK). Creators succeeding on these platforms often have high *Intent Ratios*, making them perfect candidates for our tracking pipeline.
3.  **The "Suggested Loophole":** Take 10 well-known beauty micro-influencers. Scrape the "Suggested Channels" sidebar on their channels to discover adjacent, similar-sized creators.

## Phase 2: Vetting (The "Eye Test" before the Math)

Before committing API quota to track them, perform a quick manual or bulk audit:
*   **Format Check:** What format dominates their channel: Long-form videos or only Shorts? 
    *   *Brand Preference:* Brands typically prefer **Long-form videos** for driving deep intent, trust, and high Conversion Rates (CTR). Shorts are treated as cheap, fleeting top-of-funnel reach that rarely convert sales.
    *   *Our Tracker:* Because Shorts have erratic algorithm spikes that break normal adoption curves, we are **strictly filtering for Long-form creators** to run our Bass diffusion and Velocity models accurately.
*   **Engagement Baseline:** Do they regularly get comments? If they average 0 comments, they are useless for our Intent/Sentiment metrics.

## Phase 3: Ingestion Pipeline

To sustainably add these to the Influencer CV tracker:

1.  **Batch Appending:** Maintain the `data/influencers.csv` master list. 
2.  **Initial Seeding:** When a new channel ID is added, the script currently waits for their *next* upload to start pulling data. 
    *   *Improvement Idea:* Write a one-off "seed script" that pulls the historical stats of their *last 5 videos* immediately upon ingestion. This establishes their baseline "Form" instantly, rather than waiting weeks for them to upload 5 new videos naturally.
    *   *What is "Form"?* Instead of tracking generic "30-day reach", Form is defined as the **Rolling Average of Peak Velocity ($V_{max}$) and Intent Ratio** across their last 5 videos. This proves if their engagement is trending up or dying out before a brand sponsors them.
3.  **API Quota Management:** 100 micro-influencers uploading weekly can consume quota fast if we poll hourly. Ensure the batching logic (`ids_string <- paste(to_track$video_id, collapse = ",")`) in `tracker.R` is strictly enforced to pull up to 50 videos in a single API call.

## Phase 4: Pilot Test Portfolio

Select an initial batch of 30 creators representing different sub-niches:
*   10 Skincare focused (Typically high $p$, high trust)
*   10 Makeup / Trend focused (Typically high $q$, high virality)
*   10 Product Review / Dupe focused (Typically high Intent/CTR)

*Implementation Details:* We must add a `sub_niche` column to our `data/influencers.csv` ingestion file. Tagging creators early ensures we can perform sub-group analysis later (e.g., proving to stakeholders that "Skincare creators have a 40% higher baseline Intent Ratio than trend-chasers").

Let them run through the `tracker.R` 48-hour cycle to see if the Bass diffusion model holds up across these different content types.

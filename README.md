# YouTube Influencer Tracker - Automated

This repository contains an automated R\-based pipeline that tracks the performance of YouTube videos for a curated list of influencers\. The system uses GitHub Actions to poll the YouTube Data API v3 and log metrics into a persistent dataset\.

## How It Works

The system operates on a "Discovery and Track" model, running once every hour via GitHub Actions\.

### 1\. Discovery & Update Phase

The script iterates through the `channel_ids` defined in `tracker.R`.

- __API Call:__ It uses the search endpoint to find the most recent video for each channel.
- __Merge Logic:__ It compares the latest video ID with the existing list in `data/active_tracking.csv`.
- __Persistence:__ If a new video is found, it is added with the current timestamp as its start\_time\. Existing videos remain untouched to preserve their original launch timer\.

### 2\. Metric Collection - The 48/7 Logic

The tracker determines collection frequency based on the video's age:

- __0–48 Hours Launch Window:__ Metrics (views, likes, comments) are collected __hourly__.
- __2–7 Days Maturity Window:__ Metrics are collected __daily__ (triggered during the 12:00 PM UTC run).
- __Post 7 Days:__ The video is removed from the active tracking list to save API quota and keep the system scalable.

### 3\. Efficient Batching

To scale beyond 100 influencers, the script utilizes __batched requests__. Instead of making one request per video, it combines up to 50 video IDs into a single API call, reducing quota consumption by up to 98%.

## Tech Stack

- __Language:__ R (using httr2, jsonlite, and pacman)
- __Automation:__ GitHub Actions (Cron: 0 * * * *)
- __API:__ YouTube Data API v3
- __Data Storage:__ Flat-file CSV (`data/tracking_data.csv`)

## Repository Structure

- `tracker.R`: Core logic for API interaction, filtering, and data logging.
- `ini.R`: Environment setup, API key retrieval, and dependency management.
- `.github/workflows/hourly_tracker.yml`: The automation roadmap for GitHub.
- `data/`: Contains the datasets (Ensure this folder has a `.gitkeep` file to be tracked by Git).

## How to Add a New Influencer

1. Open `tracker.R`.
2. Find the `channel_ids` vector at the top of the script.
3. Add the new Channel ID (usually starts with UC) to `data/influencers.csv` sourced from Modash and Social Blade:
4. Commit and push the changes to GitHub\. The next hourly run will automatically begin tracking the new influencer.

## Configuration

The system requires a `YT_DATA_API_KEY` to function.

- __Local:__ Store the key in your `.Renviron file`.
- __Server (GitHub):__ Add the key to __Settings > Secrets and variables > Actions__ as a secret named `YT_DATA_API_KEY`.

## Maintenance

The script automatically cleans the `data/active_tracking.csv` file by removing videos older than 168 hours (7 days), ensuring the "active" list remains focused on relevant, high-growth content.



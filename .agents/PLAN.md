# Execution Roadmap (PLAN.md)

## Phase 1: Housekeeping & Deprecation
**Objective:** Remove legacy reporting infrastructure to establish `etl.R` and Power BI as the sole analytical outputs.
* **Task 1.1:** Delete `archive/report.Rmd`, `archive/generate_report.R`, and `archive/report.html`.
* **Task 1.2:** Audit `README.md` and remove any references to the deleted R Markdown reporting pipeline.
* **Task 1.3:** Ensure `etl.R` has no remaining dependencies on the deprecated `analysis.R` logic.

## Phase 2: Metric Expansion & Data Transformation
**Objective:** Update `etl.R` to calculate the advanced metrics promised in the commercial pitch.
* **Task 2.1 (Sentiment Integration):** Modify the weighted engagement calculation in `etl.R` to ingest and weight the `sentiment_pos`, `sentiment_neu`, and `sentiment_neg` columns currently captured by `tracker.R`.
* **Task 2.2 (Velocity Decay Rate):** Implement logic in `etl.R` to calculate the percentage drop in Views Per Hour (VPH) after a video reaches its Peak Velocity ($V_{max}$).
* **Task 2.3 (Form Consistency):** Implement a rolling average calculation for the last 5 videos per `channel_id` to determine current algorithmic momentum versus baseline performance.
* **Task 2.4 (Export Validation):** Verify that `data/pbi_fact_polling.csv` accurately flattens and exports these new metrics for Business Intelligence ingestion.

## Phase 3: Automation & Benchmarking Repair
**Objective:** Restore the historical benchmarking pipeline and automate its execution.
* **Task 3.1 (Fetch Action):** Debug and repair `.github/workflows/fetch.yml` so it successfully triggers the `benchmarker.R` script on designated events.
* **Task 3.2 (Data Integration):** Route the output CSV files from `benchmarker.R` into the sequestered `/data` directory.
* **Task 3.3 (Schema Alignment):** Ensure the historical benchmarking data schema aligns with the daily polling data for seamless Power BI integration.

## Phase 4: Business Intelligence Construction
**Objective:** Visualise the mathematical backend into actionable business value.
* **Task 4.1:** Build the Power BI dashboard using `data/pbi_fact_polling.csv`.
* **Task 4.2:** Create visualisations categorising the creator roster into "Loyalists" (high Bass $p$), "Viral Engines" (high Bass $q$), and "Dead Weight".
* **Task 4.3:** Develop the "Peak Velocity Timeline" and "Creator CV Portfolio" views.
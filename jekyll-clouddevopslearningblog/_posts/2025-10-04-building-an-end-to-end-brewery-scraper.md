---
layout: post
title: "Building an End-to-End Brewery Scraper for Australian Data for OpenBreweryDB"
date: 2025-10-04
categories: devops data-engineering python scraping
description: A technical deep dive into how I built a robust, multi-source brewery scraper to power Australian data for OpenBreweryDB — including scraping, enrichment, retries, and lessons learned.
---

## Introduction

I recently tried to get one of my old projects, [BreweriesNearMe](https://github.com/simonmackinnon/breweriesnearme) working again. After multiple issues getting the site running again (details will be in another post soon), I realised the API that I was using, brewerydb.com, no longer exists. I found OpenBreweryDB pretty soon, and had it hooked up and running. However, I found that there was no local data for Australia (it's an open/crowd sourced data source). I then thought, "How hard can that be to get?" 

When I started this task, my goal was deceptively simple: **collect a comprehensive list of breweries in Australia** and format them for ingestion into the [OpenBreweryDB](https://www.openbrewerydb.org/) schema. The catch? There’s no single authoritative source — and every source that *does* exist presents its own challenges.

This post is a deep dive into how I designed and built a fully automated data pipeline to tackle that problem. It’s not a tutorial, but a breakdown of the engineering decisions, mistakes, and solutions that got us from *“let’s scrape some websites”* to *“production-ready, enriched, validated data.”*

---

## Architecture Overview

At a high level, the scraper evolved into a modular system with three major components:

1. **Data Extraction Layer** – Scrape and parse multiple upstream sources.  
2. **Normalization & Cleaning Layer** – Standardize the fields into a unified schema.  
3. **Enrichment & Post-Processing Layer** – Use the Google Places API to add structured location data, validate results, and filter noise.

The guiding principle was **“merge many imperfect sources into one high-quality dataset.”**

---

## 1. Data Extraction Layer

The first major step was building scrapers for four key sources:

- **Craft Cartel:** A long-form page with a single block of comma-separated brewery names.  
- **Independent Brewers Association (IBA):** Paginated cards with names and rough locations.  
- **Wikipedia:** Tables split into “major company owned” and “microbreweries.”  
- **Untappd:** Initially attempted, but abandoned due to authentication requirements and closed API.

Each of these posed different challenges.

### Craft Cartel: Parsing Unstructured Text

The simplest-looking source turned out to be tricky. The brewery names weren’t in HTML tables or lists — they were buried inside a block of text. Once extracted, each needed to be split and cleaned. That got us names, but no addresses, phones, or coordinates — we’d deal with that later.

### IBA: Paginated and Noisy Data

IBA was the richest source but introduced pagination (`/page/2/`, `/page/3/`, etc.). Handling this meant writing a loop that crawled until no more pages existed. I also had to filter out non-brewery blocks like “Brewery Members” and “Want to be a member?” that appeared on each page.

### Wikipedia: Tables That Weren’t Really Tables

Wikipedia’s structure was the most brittle. The tables I needed were buried after specific `<h2>` headings, but weren’t direct siblings. My first attempt returned nothing. The fix was to walk forward through the DOM until the next `<table class="wikitable">` appeared, then flatten it — accounting for rowspan and column misalignment.

In the end, Wikipedia provided high-value signals: ownership classification and historical data that wasn’t available elsewhere.

---

## 2. Normalization & Cleaning

With data now flowing from three sources, the next challenge was making it **consistent**. OpenBreweryDB expects a schema like:

```
id, name, brewery_type, address_1, address_2, city, state_province, postal_code, country, phone, website_url, longitude, latitude
```

This meant handling dozens of edge cases:

- Splitting free-form location strings like `"340 Melton Rd, Northgate QLD 4013, Australia"` into structured fields.  
- Dropping breweries with no Australian presence.  
- Deduplicating records by normalizing names and fuzzy matching city/state combinations.  
- Removing metadata rows from Wikipedia that weren’t breweries at all.

Normalization turned out to be where most of the real engineering time went — 70% of the work was spent here.

---

## 3. Enrichment with Google Places API

The raw scraped data was still thin — we had names and maybe a rough suburb. The next step was to **enrich it**.

For each brewery, I constructed a text query like:

```
<name> brewery Australia
```

and passed it to the [Google Places API](https://developers.google.com/maps/documentation/places/web-service/overview). From the response, I extracted:

- ✅ Full structured address  
- ✅ Phone number  
- ✅ Official website  
- ✅ Latitude & longitude  

The enrichment step transformed the dataset from *“interesting”* to *“useful.”*

### Filtering Non-Australian Results

Many names overlapped with breweries overseas. Adding a strict `"country: Australia"` filter and rejecting any result not geocoded inside Australia cleaned up the data dramatically.

---

## 4. Reliability, Error Handling & Backoff

The first full run failed halfway through: `ConnectionResetError: [Errno 54] Connection reset by peer`. That turned out to be a **network-level reset during Places API calls** — likely due to too many requests too quickly.

The solution was threefold:

- ✅ **Exponential backoff + jitter** on all API calls.  
- ✅ A global `requests.Session` adapter with automatic retries and respect for `Retry-After`.  
- ✅ A configurable `--places-rate` flag to control throughput (e.g. `1.5s` between calls).

With these improvements, I could run enrichment across 500+ breweries without a single crash.

---

## 5. Lessons Learned & Future Work

This project ended up being far more complex than a “simple web scraper.” Along the way, I learned a few key lessons:

- **Scraping is the easy part.** Normalization and enrichment are where the real complexity lies.  
- **DOM structures are fragile.** Wikipedia’s layout changes broke three early attempts — defensive parsing is essential.  
- **Error handling isn’t optional.** A 500-request enrichment job *will* hit transient network issues. Plan for them.  
- **Multiple imperfect sources > one perfect one.** The final dataset was only possible by merging three sources and using Places data to fill gaps.

Future improvements include:

- Adding brewery size classification (micro, regional, large) automatically.  
- Building a scheduling layer to re-run the scraper periodically.  
- Adding CI tests to validate schema integrity and geolocation coverage.

---

## Conclusion

What started as a simple scraper evolved into a production-ready data pipeline — one that fetches, normalizes, enriches, and validates hundreds of Australian breweries. The final result is a clean, geocoded dataset that can slot directly into OpenBreweryDB, providing far richer data than any single source on its own.

If you’re building something similar, my advice is simple: treat scraping as just the **first step**. The real value lies in how you clean, enrich, and harden that data for downstream use.

Final note: If you want, check out the source of the scraper here: https://github.com/simonmackinnon/breweriesnearme/blob/master/data/scrape_au_breweries.py

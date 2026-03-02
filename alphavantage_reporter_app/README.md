# Alpha Vantage Reporter App

Combined R application: **API query** (Gold & Silver + Stock Daily), **Shiny UI**, and **AI report** (Alpha Vantage data → Ollama → HTML). Ready to upload to GitHub.

---

## Folder structure

| File | Description |
|------|-------------|
| **app.R** | Main Shiny application (two tabs: Gold & Silver, AI Report). |
| **run_app.R** | Optional launcher: run from this folder to start the app. |
| **api_helpers.R** | API query logic: Gold/Silver history + daily time series (stocks). |
| **ai_report_helpers.R** | AI pipeline: fetch → process → prompt → Ollama → HTML. |
| **04_alphavantage_query.R** | Standalone script: Alpha Vantage TIME_SERIES_DAILY (no Shiny). |
| **06_ai_report_script.R** | Standalone script: full AI report (fetch + Ollama + save HTML). |
| **install_packages.R** | One-time install of R dependencies. |
| **.env.example** | Template for API keys; copy to `.env`. |
| **.gitignore** | Excludes `.env`, generated `.html`, etc. |

---

## Setup

1. **R** (4.0+).
2. **Install packages** (once):

```r
setwd("alphavantage_reporter_app")   # or your path to this folder
source("install_packages.R")
```

3. **API keys:** Copy `.env.example` to `.env` and add your [Alpha Vantage](https://www.alphavantage.co/support/#api-key) key:

```env
API_KEY=your_alpha_vantage_key_here
OLLAMA_API_KEY=   # optional; for Ollama Cloud; leave blank for local Ollama
```

---

## How to run

### Shiny app (main application)

From **project root** (parent of `alphavantage_reporter_app`):

```r
shiny::runApp("alphavantage_reporter_app")
```

Or from **inside** the app folder:

```r
setwd("alphavantage_reporter_app")
shiny::runApp(".")   # or source("run_app.R")
```

- **Gold & Silver tab:** Choose commodity and interval, click *Run query* to fetch and view data + chart.
- **AI Report tab:** Enter stock symbol (e.g. IBM), click *Generate AI Report* to run the pipeline and view or download the HTML report.

### Standalone scripts (no Shiny)

- **API query only:**

```bash
cd alphavantage_reporter_app
Rscript 04_alphavantage_query.R
```

- **AI report only** (fetch + Ollama + save HTML):

```bash
cd alphavantage_reporter_app
Rscript 06_ai_report_script.R
```

Requires Ollama running locally (or set `OLLAMA_API_KEY` in `.env` for cloud).

---

## GitHub

1. Do **not** commit `.env` (it is in `.gitignore`).
2. Commit and push this folder as a repo or as part of a larger repo.
3. In the repo README, point users to this README and to copy `.env.example` to `.env` and add `API_KEY`.

---

## Requirements summary

| Item | Purpose |
|------|--------|
| `API_KEY` | Alpha Vantage (required for both tabs and standalone scripts). |
| `OLLAMA_API_KEY` | Optional; if set, AI report uses Ollama Cloud; else local Ollama. |
| Local Ollama | For AI report without cloud key: install and run [Ollama](https://ollama.com), model e.g. `gemma3:latest`. |

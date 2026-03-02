# 06_ai_report_script.R
# Standalone AI report script: fetch Alpha Vantage -> process -> Ollama -> save HTML.
# Run from this folder: Rscript 06_ai_report_script.R
# Requires: .env with API_KEY; for cloud AI set OLLAMA_API_KEY in .env.

library(httr2)
library(jsonlite)
library(dplyr)

# Load .env from app folder
if (file.exists(".env")) readRenviron(".env")
api_key = Sys.getenv("API_KEY")
if (!nzchar(api_key)) {
  stop("API_KEY not set. Add API_KEY=... to .env in this folder.")
}
ollama_key = Sys.getenv("OLLAMA_API_KEY")

# Source helpers (same directory)
source("api_helpers.R", local = TRUE)
source("ai_report_helpers.R", local = TRUE)

cat("Running AI report pipeline (Alpha Vantage + Ollama)...\n")
res = run_ai_report(api_key, symbol = "IBM", ollama_api_key = ollama_key)
if (!isTRUE(res$success)) {
  stop(res$message)
}
out_file = "alphavantage_ai_report.html"
writeLines(res$html_content, out_file, useBytes = TRUE)
cat("Saved:", normalizePath(out_file, mustWork = FALSE), "\n")
cat("Done.\n")

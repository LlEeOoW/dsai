# 04_alphavantage_query.R
# Standalone API query script: Alpha Vantage TIME_SERIES_DAILY (e.g. IBM).
# Run from this folder: Rscript 04_alphavantage_query.R

library(httr2)
library(jsonlite)

# Load .env from app folder
if (file.exists(".env")) readRenviron(".env")
api_key = Sys.getenv("API_KEY")
if (!nzchar(api_key)) api_key = "demo"

url = "https://www.alphavantage.co/query"
req = request(url) |>
  req_url_query(
    `function` = "TIME_SERIES_DAILY",
    symbol = "IBM",
    apikey = api_key
  ) |>
  req_method("GET")
resp = req_perform(req)
status = resp_status(resp)
cat("Status Code:", status, "\n")
if (status == 200) {
  data = resp_body_json(resp)
  ts = data[["Time Series (Daily)"]]
  if (!is.null(ts)) {
    cat("Time Series (Daily):", length(ts), "days\n")
    cat(toJSON(list(meta = data[["Meta Data"]], sample = head(ts, 2)), pretty = TRUE, auto_unbox = TRUE))
  }
} else {
  cat("Request failed.\n")
  cat(resp_body_string(resp))
}

#' api_helpers.R
#' Alpha Vantage API helpers: Gold/Silver history and daily time series (for AI report).
#' Used by app.R and by 04_alphavantage_query.R / 06_ai_report_script.R.

# ---- Gold & Silver History (GOLD_SILVER_HISTORY) ----

fetch_gold_silver_history = function(api_key, symbol = "SILVER", interval = "daily") {
  if (!nzchar(api_key)) {
    return(list(success = FALSE, data = NULL, message = "API key is missing. Add API_KEY to .env or enter in app."))
  }
  url = "https://www.alphavantage.co/query"
  req = httr2::request(url) |>
    httr2::req_url_query(
      `function` = "GOLD_SILVER_HISTORY",
      symbol = symbol,
      interval = interval,
      apikey = api_key
    ) |>
    httr2::req_method("GET") |>
    httr2::req_timeout(25)
  resp = tryCatch(httr2::req_perform(req), error = function(e) e)
  if (inherits(resp, "error")) {
    return(list(success = FALSE, data = NULL, message = paste0("Request failed: ", resp$message)))
  }
  if (httr2::resp_status(resp) != 200) {
    return(list(success = FALSE, data = NULL, message = paste0("HTTP ", httr2::resp_status(resp))))
  }
  data = tryCatch(httr2::resp_body_json(resp), error = function(e) e)
  if (inherits(data, "error")) {
    return(list(success = FALSE, data = NULL, message = paste0("Invalid JSON: ", data$message)))
  }
  if (!is.null(data[["Error Message"]])) {
    return(list(success = FALSE, data = NULL, message = data[["Error Message"]]))
  }
  ts = data[["data"]]
  if (is.null(ts)) ts = data[[names(data)[2]]]
  if (is.null(ts) || length(ts) == 0) {
    return(list(success = FALSE, data = NULL, message = "No time series data in response."))
  }
  bind_err = NULL
  out = tryCatch(dplyr::bind_rows(ts), error = function(e) { bind_err <<- e; NULL })
  if (is.null(out)) {
    msg = if (!is.null(bind_err)) conditionMessage(bind_err) else "Unknown parse error."
    return(list(success = FALSE, data = NULL, message = paste0("Could not parse API response. ", msg)))
  }
  if (length(ts) == nrow(out) && !is.null(names(ts)) && all(nzchar(names(ts)))) {
    out$date = names(ts)
  }
  for (col in names(out)) {
    if (is.character(out[[col]])) {
      num = suppressWarnings(as.numeric(out[[col]]))
      if (!all(is.na(num))) out[[col]] = num
    }
  }
  list(success = TRUE, data = out, message = paste0("Retrieved ", nrow(out), " records."))
}

# ---- Daily Time Series (TIME_SERIES_DAILY) for stocks ----

#' Fetch daily time series (e.g. IBM). Returns list(success, data = df, message).
#' data has columns: date, open, high, low, close, volume.
fetch_time_series_daily = function(api_key, symbol = "IBM") {
  if (!nzchar(api_key)) {
    return(list(success = FALSE, data = NULL, message = "API key is missing."))
  }
  url = "https://www.alphavantage.co/query"
  req = httr2::request(url) |>
    httr2::req_url_query(
      `function` = "TIME_SERIES_DAILY",
      symbol = symbol,
      apikey = api_key
    ) |>
    httr2::req_method("GET") |>
    httr2::req_timeout(25)
  resp = tryCatch(httr2::req_perform(req), error = function(e) e)
  if (inherits(resp, "error")) {
    return(list(success = FALSE, data = NULL, message = paste0("Request failed: ", resp$message)))
  }
  if (httr2::resp_status(resp) != 200) {
    return(list(success = FALSE, data = NULL, message = paste0("HTTP ", httr2::resp_status(resp))))
  }
  data = tryCatch(httr2::resp_body_json(resp), error = function(e) e)
  if (inherits(data, "error")) {
    return(list(success = FALSE, data = NULL, message = paste0("Invalid JSON: ", data$message)))
  }
  if (!is.null(data[["Error Message"]])) {
    return(list(success = FALSE, data = NULL, message = data[["Error Message"]]))
  }
  ts = data[["Time Series (Daily)"]]
  if (is.null(ts) || length(ts) == 0) {
    return(list(success = FALSE, data = NULL, message = "No Time Series (Daily) in response."))
  }
  dates = names(ts)
  n = length(dates)
  out = vector("list", n)
  for (i in seq_len(n)) {
    d = ts[[i]]
    out[[i]] = data.frame(
      date = dates[i],
      open = as.numeric(d[["1. open"]]),
      high = as.numeric(d[["2. high"]]),
      low = as.numeric(d[["3. low"]]),
      close = as.numeric(d[["4. close"]]),
      volume = as.numeric(d[["5. volume"]]),
      stringsAsFactors = FALSE
    )
  }
  df = do.call(rbind, out)
  df$date = as.character(df$date)
  list(success = TRUE, data = df, message = paste0("Retrieved ", nrow(df), " days for ", symbol, "."))
}

#' ai_report_helpers.R
#' Alpha Vantage data -> process -> prompt -> Ollama -> HTML report.
#' Used by app.R (AI Report tab) and by 06_ai_report_script.R.

# Requires: api_helpers.R (fetch_time_series_daily), httr2, jsonlite

#' Run full AI report pipeline: fetch stock data, summarize, call LLM, build HTML.
#' @param api_key Alpha Vantage API key
#' @param symbol Stock symbol (e.g. IBM)
#' @param ollama_api_key Optional; if set, use Ollama Cloud; else use local Ollama
#' @return list(success, html_content, message, summary_stats)
run_ai_report = function(api_key, symbol = "IBM", ollama_api_key = NULL) {
  # 1. Fetch
  fetch_res = fetch_time_series_daily(api_key, symbol)
  if (!isTRUE(fetch_res$success)) {
    return(list(success = FALSE, html_content = NULL, message = fetch_res$message, summary_stats = NULL))
  }
  df = fetch_res$data

  # 2. Process: last 30 days, aggregate stats
  df = df[order(df$date, decreasing = TRUE), ]
  df = df[seq_len(min(30L, nrow(df))), ]
  df = df[order(df$date), ]

  summary_stats = list(
    symbol = symbol,
    n_days = nrow(df),
    date_range = paste(df$date[1], "to", df$date[nrow(df)]),
    close_min = min(df$close),
    close_max = max(df$close),
    close_mean = round(mean(df$close), 2),
    close_latest = df$close[nrow(df)],
    volume_mean = round(mean(df$volume), 0)
  )
  last5 = tail(df$close, 5)
  prev5 = tail(head(df$close, nrow(df) - 5), 5)
  if (length(prev5) >= 1) {
    summary_stats$close_avg_last5 = round(mean(last5), 2)
    summary_stats$close_avg_prev5 = round(mean(prev5), 2)
    summary_stats$trend_note = if (mean(last5) > mean(prev5)) "recent 5 days higher than previous 5" else "recent 5 days lower than previous 5"
  } else {
    summary_stats$close_avg_last5 = round(mean(last5), 2)
    summary_stats$close_avg_prev5 = NA
    summary_stats$trend_note = "insufficient data for trend"
  }

  summary_text = paste0(
    "Summary statistics:\n",
    "  Symbol: ", summary_stats$symbol, "\n",
    "  Days: ", summary_stats$n_days, " (", summary_stats$date_range, ")\n",
    "  Close price: min ", summary_stats$close_min, ", max ", summary_stats$close_max, ", mean ", summary_stats$close_mean, ", latest ", summary_stats$close_latest, "\n",
    "  Volume (avg): ", summary_stats$volume_mean, "\n",
    "  Trend: ", summary_stats$trend_note, "\n"
  )
  recent = tail(df, 5)
  rows = sprintf("  %s  open=%.2f high=%.2f low=%.2f close=%.2f vol=%.0f",
    recent$date, recent$open, recent$high, recent$low, recent$close, recent$volume)
  table_text = paste0("Last 5 days (date, open, high, low, close, volume):\n", paste(rows, collapse = "\n"))
  data_for_ai = paste0(summary_text, "\n", table_text)

  # 3. Prompt
  prompt = paste0(
    "You are a concise financial data analyst. Below is processed daily stock data from Alpha Vantage.\n\n",
    "--- DATA ---\n", data_for_ai, "\n--- END DATA ---\n\n",
    "Please respond in this exact format:\n",
    "1. Summary (2-3 sentences): key statistics and what they mean.\n",
    "2. Trends: brief note on recent price/volume pattern.\n",
    "3. Recommendations: 2-3 bullet points (actionable, short).\n",
    "Use plain language and keep the total response under 150 words."
  )

  # 4. Call Ollama (cloud or local)
  use_cloud = nzchar(ollama_api_key)
  output = NULL
  err_msg = NULL
  tryCatch({
    if (use_cloud) {
      url_llm = "https://ollama.com/api/chat"
      body = list(
        model = "gpt-oss:20b-cloud",
        messages = list(list(role = "user", content = prompt)),
        stream = FALSE
      )
      res = httr2::request(url_llm) |>
        httr2::req_headers(
          "Authorization" = paste0("Bearer ", ollama_api_key),
          "Content-Type" = "application/json"
        ) |>
        httr2::req_body_json(body) |>
        httr2::req_method("POST") |>
        httr2::req_perform()
    } else {
      url_llm = "http://localhost:11434/api/chat"
      body = list(
        model = "gemma3:latest",
        messages = list(list(role = "user", content = prompt)),
        stream = FALSE
      )
      res = httr2::request(url_llm) |>
        httr2::req_body_json(body) |>
        httr2::req_method("POST") |>
        httr2::req_perform()
    }
    resp_llm = httr2::resp_body_json(res)
    output = resp_llm$message$content
  }, error = function(e) {
    err_msg <<- conditionMessage(e)
  })
  if (is.null(output) || !nzchar(output)) {
    return(list(
      success = FALSE,
      html_content = NULL,
      message = if (nzchar(err_msg)) err_msg else "Ollama returned no content. Is Ollama running (local) or is OLLAMA_API_KEY set (cloud)?",
      summary_stats = summary_stats
    ))
  }

  # 5. Build HTML
  output_escaped = gsub("&", "&amp;", output, fixed = TRUE)
  output_escaped = gsub("<", "&lt;", output_escaped, fixed = TRUE)
  output_escaped = gsub(">", "&gt;", output_escaped, fixed = TRUE)
  output_escaped = gsub("\n", "<br>\n", output_escaped, fixed = TRUE)
  html_content = paste0(
    "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n",
    "  <meta charset=\"UTF-8\">\n  <title>Alpha Vantage AI Report</title>\n",
    "  <style>\n",
    "    body { font-family: system-ui, sans-serif; max-width: 640px; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }\n",
    "    h1 { font-size: 1.25rem; color: #333; }\n",
    "    .report { background: #f8f9fa; padding: 1rem; border-radius: 8px; white-space: pre-wrap; }\n",
    "    .meta { color: #666; font-size: 0.875rem; margin-top: 1rem; }\n",
    "  </style>\n</head>\n<body>\n",
    "  <h1>Alpha Vantage AI Report (", summary_stats$symbol, ")</h1>\n",
    "  <p class=\"meta\">", summary_stats$date_range, " &middot; ", summary_stats$n_days, " days</p>\n",
    "  <div class=\"report\">", output_escaped, "</div>\n",
    "</body>\n</html>\n"
  )
  list(success = TRUE, html_content = html_content, message = paste0("Report generated for ", symbol, "."), summary_stats = summary_stats)
}

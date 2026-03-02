#' app.R
#' @title Alpha Vantage Reporter — Shiny App
#' @description Combined app: (1) Gold & Silver History API query, (2) AI Stock Report (Alpha Vantage + Ollama).
#' Requires API_KEY in .env; optional OLLAMA_API_KEY for cloud AI.

# 0. SETUP ###################################

library(shiny)
library(httr2)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(bslib)
library(DT)

# Helpers: must be in same folder as app.R. Run app with runApp("alphavantage_reporter_app") or runApp(".")
if (!file.exists("api_helpers.R")) stop("api_helpers.R not found. Run app with runApp('alphavantage_reporter_app') from project root, or runApp('.') from inside alphavantage_reporter_app.")
source("api_helpers.R", local = TRUE)
source("ai_report_helpers.R", local = TRUE)

# .env
env_paths = c(".env", "../.env")
for (p in env_paths) {
  if (file.exists(p)) { readRenviron(p); break }
}
default_api_key = Sys.getenv("API_KEY")
default_ollama_key = Sys.getenv("OLLAMA_API_KEY")

# 1. UI ######################################

ui = fluidPage(
  theme = bs_theme(bootswatch = "flatly", primary = "#2c3e50"),
  titlePanel("Alpha Vantage Reporter"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h5("API key", class = "text-muted"),
      textInput("api_key_override", "API key (optional)", value = "", placeholder = "Leave blank to use .env"),
      hr(),
      tabsetPanel(
        id = "main_tabs",
        tabPanel(
          "Gold & Silver",
          h5("Query parameters", class = "text-muted"),
          selectInput("symbol", "Commodity", choices = c(Silver = "SILVER", Gold = "GOLD"), selected = "SILVER"),
          selectInput("interval", "Interval", choices = c(Daily = "daily", Weekly = "weekly", Monthly = "monthly"), selected = "daily"),
          actionButton("run_query", "Run query", class = "btn-primary", icon = icon("play"))
        ),
        tabPanel(
          "AI Report",
          h5("AI Stock Report", class = "text-muted"),
          textInput("report_symbol", "Stock symbol", value = "IBM", placeholder = "e.g. IBM, AAPL"),
          textInput("ollama_key_override", "Ollama API key (optional)", value = "", placeholder = "For cloud; blank = local"),
          helpText("Local: start Ollama. Cloud: set key above or in .env."),
          actionButton("run_report", "Generate AI Report", class = "btn-primary", icon = icon("file-alt"))
        )
      )
    ),
    mainPanel(
      width = 9,
      tabsetPanel(
        id = "result_tabs",
        tabPanel(
          "Gold & Silver",
          p("Click \"Run query\" to fetch data.", class = "text-muted"),
          verbatimTextOutput("status_text"),
          uiOutput("summary_ui"),
          plotOutput("line_chart", height = "340px"),
          DT::dataTableOutput("table_out")
        ),
        tabPanel(
          "AI Report",
          p("Click \"Generate AI Report\" to fetch stock data and get AI analysis.", class = "text-muted"),
          verbatimTextOutput("report_status"),
          uiOutput("report_ui"),
          downloadButton("download_report", "Download report (.html)", class = "btn-secondary")
        )
      )
    )
  )
)

# 2. SERVER ###################################

server = function(input, output, session) {
  result = reactiveVal(NULL)
  report_result = reactiveVal(NULL)

  api_key = reactive({
    key = trimws(input$api_key_override)
    if (nzchar(key)) key else default_api_key
  })

  # ---- Gold & Silver ----
  observeEvent(input$run_query, {
    result(NULL)
    key = api_key()
    if (!nzchar(key)) {
      result(list(success = FALSE, data = NULL, message = "API key is required."))
      showNotification("API key missing.", type = "error", duration = 3)
      return()
    }
    result(list(success = NA, data = NULL, message = "Querying API..."))
    res = tryCatch(
      fetch_gold_silver_history(key, symbol = input$symbol, interval = input$interval),
      error = function(e) list(success = FALSE, data = NULL, message = paste0("Error: ", conditionMessage(e)))
    )
    result(res)
    if (isTRUE(res$success)) showNotification(res$message, type = "message", duration = 2)
    if (identical(res$success, FALSE)) showNotification(res$message, type = "error", duration = 5)
  })

  output$status_text = renderText({
    res = result()
    if (is.null(res)) return("(No query run yet.)")
    res$message
  })

  output$summary_ui = renderUI({
    res = result()
    if (is.null(res) || !isTRUE(res$success) || is.null(res$data)) return(NULL)
    n = nrow(res$data)
    cols = paste(names(res$data), collapse = ", ")
    div(
      p(strong("Records:"), n),
      p(strong("Fields:"), cols, class = "small text-muted"),
      hr()
    )
  })

  output$line_chart = renderPlot({
    res = result()
    if (is.null(res) || !isTRUE(res$success) || is.null(res$data)) return(NULL)
    d = res$data
    if (nrow(d) == 0) return(NULL)
    tryCatch({
      date_col = NULL
      for (c in c("date", "timestamp", "datetime")) {
        if (c %in% names(d)) { date_col = c; break }
      }
      if (is.null(date_col)) date_col = names(d)[1]
      num_col = NULL
      for (c in c("4. close", "close", "1. open", "open", "value", "price")) {
        if (c %in% names(d) && is.numeric(d[[c]])) { num_col = c; break }
      }
      if (is.null(num_col)) {
        for (c in names(d)) {
          if (is.numeric(d[[c]])) { num_col = c; break }
        }
      }
      if (is.null(num_col)) {
        plot(1, type = "n", xlab = "", ylab = "", main = "No numeric column for chart.")
        return(invisible(NULL))
      }
      d = dplyr::mutate(d, .x = as.Date(as.character(.data[[date_col]]), optional = TRUE))
      if (all(is.na(d$.x))) d$.x = seq_len(nrow(d))
      d = dplyr::arrange(d, .x)
      p = ggplot(d, aes(x = .x, y = .data[[num_col]])) +
        geom_line(size = 0.8, colour = "#2c3e50") +
        geom_point(size = 1.2, colour = "#2c3e50", alpha = 0.6) +
        labs(x = "Date", y = num_col, title = paste("History:", num_col)) +
        theme_minimal(base_size = 12) + theme(plot.title = element_text(hjust = 0.5))
      print(p)
    }, error = function(e) {
      plot(1, type = "n", xlab = "", ylab = "", main = paste("Chart error:", conditionMessage(e)))
    })
  })

  output$table_out = DT::renderDataTable({
    res = result()
    if (is.null(res) || !isTRUE(res$success) || is.null(res$data)) return(NULL)
    DT::datatable(res$data, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
  })

  # ---- AI Report ----
  observeEvent(input$run_report, {
    report_result(NULL)
    key = api_key()
    if (!nzchar(key)) {
      report_result(list(success = FALSE, html_content = NULL, message = "API key is required."))
      showNotification("API key missing.", type = "error", duration = 3)
      return()
    }
    ollama_key = trimws(input$ollama_key_override)
    if (!nzchar(ollama_key)) ollama_key = default_ollama_key
    showNotification("Generating report (fetch + AI)...", duration = 2, type = "message")
    report_result(list(success = NA, html_content = NULL, message = "Running..."))
    sym = trimws(input$report_symbol)
    if (!nzchar(sym)) sym = "IBM"
    res = tryCatch(
      run_ai_report(key, symbol = sym, ollama_api_key = ollama_key),
      error = function(e) list(success = FALSE, html_content = NULL, message = paste0("Error: ", conditionMessage(e)))
    )
    report_result(res)
    if (isTRUE(res$success)) showNotification(res$message, type = "message", duration = 2)
    if (identical(res$success, FALSE)) showNotification(res$message, type = "error", duration = 5)
  })

  output$report_status = renderText({
    r = report_result()
    if (is.null(r)) return("(No report generated yet.)")
    r$message
  })

  output$report_ui = renderUI({
    r = report_result()
    if (is.null(r) || !isTRUE(r$success) || is.null(r$html_content)) return(NULL)
    HTML(r$html_content)
  })

  output$download_report = downloadHandler(
    filename = function() "alphavantage_ai_report.html",
    content = function(file) {
      r = report_result()
      if (!is.null(r) && isTRUE(r$success) && nzchar(r$html_content)) {
        writeLines(r$html_content, file, useBytes = TRUE)
      }
    }
  )
}

# 3. RUN ######################################

shinyApp(ui, server)

# Generate DOCUMENTATION.docx for Alpha Vantage Reporter App
# Run from alphavantage_reporter_app folder: source("generate_documentation_docx.R")

if (!requireNamespace("officer", quietly = TRUE)) {
  install.packages("officer", repos = "https://cloud.r-project.org")
}
library(officer)

doc = read_docx()

# Title
doc = body_add_par(doc, "Alpha Vantage Reporter App — Documentation", style = "heading 1")
doc = body_add_par(doc, "")

# 1. Brief documentation
doc = body_add_par(doc, "1. Brief Documentation", style = "heading 2")
doc = body_add_par(doc, "This tool is a combined R application that does two things. First, it lets you query Gold and Silver historical prices from the Alpha Vantage API: you choose the commodity (Silver or Gold) and the interval (daily, weekly, or monthly), then click Run query to see the data in a table and a line chart. Second, it can generate an AI-written report for a stock (e.g. IBM): it fetches the stock's daily time series from Alpha Vantage, summarizes the last 30 days, sends that summary to an LLM (Ollama, local or cloud), and displays or downloads the AI analysis as an HTML report with summary, trends, and recommendations. All of this is available in one Shiny app with two tabs, and the same logic can be run from the command line via standalone scripts.", style = "Normal")
doc = body_add_par(doc, "")

# 2. Data Summary
doc = body_add_par(doc, "2. Data Summary — API Data Columns", style = "heading 2")

doc = body_add_par(doc, "Gold & Silver History (GOLD_SILVER_HISTORY)", style = "heading 3")
t1 = data.frame(
  Column_name = c("date", "value", "(other fields)"),
  Data_type = c("character", "numeric", "varies"),
  Description = c(
    "Date of the observation (added from API response keys).",
    "Price or value for the commodity on that date.",
    "Additional columns may appear depending on API response (e.g. open, high, low, close)."
  ),
  stringsAsFactors = FALSE
)
doc = body_add_table(doc, t1, header = TRUE, style = "Normal Table")
doc = body_add_par(doc, "")

doc = body_add_par(doc, "Daily Time Series — Stocks (TIME_SERIES_DAILY)", style = "heading 3")
t2 = data.frame(
  Column_name = c("date", "open", "high", "low", "close", "volume"),
  Data_type = c("character", "numeric", "numeric", "numeric", "numeric", "numeric"),
  Description = c(
    "Trading date (YYYY-MM-DD).",
    "Opening price for the day.",
    "Highest price for the day.",
    "Lowest price for the day.",
    "Closing price for the day.",
    "Trading volume (number of shares)."
  ),
  stringsAsFactors = FALSE
)
doc = body_add_table(doc, t2, header = TRUE, style = "Normal Table")
doc = body_add_par(doc, "")

# 3. Technical Details
doc = body_add_par(doc, "3. Technical Details", style = "heading 2")
doc = body_add_par(doc, "API keys", style = "heading 3")
doc = body_add_par(doc, "API_KEY (required): Your Alpha Vantage API key. Get a free key at https://www.alphavantage.co/support/#api-key. Used for both Gold/Silver and Stock Daily queries.", style = "Normal")
doc = body_add_par(doc, "OLLAMA_API_KEY (optional): If set, the AI report uses Ollama Cloud. If left blank, the app uses local Ollama (http://localhost:11434).", style = "Normal")
doc = body_add_par(doc, "")
doc = body_add_par(doc, "API endpoints", style = "heading 3")
doc = body_add_par(doc, "Alpha Vantage: https://www.alphavantage.co/query — GET with query parameters function, symbol, interval (or symbol for daily), apikey.", style = "Normal")
doc = body_add_par(doc, "Ollama local: http://localhost:11434/api/chat — POST, JSON body with model and messages.", style = "Normal")
doc = body_add_par(doc, "Ollama Cloud: https://ollama.com/api/chat — POST with Bearer token in Authorization header.", style = "Normal")
doc = body_add_par(doc, "")
doc = body_add_par(doc, "R packages", style = "heading 3")
doc = body_add_par(doc, "shiny, httr2, jsonlite, dplyr, ggplot2, bslib, DT. Install once via install_packages.R.", style = "Normal")
doc = body_add_par(doc, "")
doc = body_add_par(doc, "File structure", style = "heading 3")
doc = body_add_par(doc, "app.R — Main Shiny app (two tabs). run_app.R — Launcher. api_helpers.R — API logic (Gold/Silver + daily stock). ai_report_helpers.R — AI pipeline (fetch, process, prompt, Ollama, HTML). 04_alphavantage_query.R — Standalone API script. 06_ai_report_script.R — Standalone AI report script. install_packages.R — Dependency installer. .env.example — Copy to .env and add keys.", style = "Normal")
doc = body_add_par(doc, "")

# 4. Usage Instructions
doc = body_add_par(doc, "4. Usage Instructions", style = "heading 2")
doc = body_add_par(doc, "Step 1 — Install dependencies (once)", style = "heading 3")
doc = body_add_par(doc, "Open R or RStudio. Set the working directory to the alphavantage_reporter_app folder. Run: source(\"install_packages.R\")", style = "Normal")
doc = body_add_par(doc, "")
doc = body_add_par(doc, "Step 2 — Set up API keys", style = "heading 3")
doc = body_add_par(doc, "Copy the file .env.example to a new file named .env (in the same folder). Open .env in a text editor. Replace your_alpha_vantage_key_here with your real Alpha Vantage API key. Save the file. Do not share or commit .env.", style = "Normal")
doc = body_add_par(doc, "")
doc = body_add_par(doc, "Step 3 — Run the Shiny app", style = "heading 3")
doc = body_add_par(doc, "Option A: From the folder that contains alphavantage_reporter_app, run in R: shiny::runApp(\"alphavantage_reporter_app\")", style = "Normal")
doc = body_add_par(doc, "Option B: In R, set the working directory to alphavantage_reporter_app, then run: shiny::runApp(\".\") or source(\"run_app.R\")", style = "Normal")
doc = body_add_par(doc, "The app will open in your browser. Use the Gold & Silver tab to query commodities; use the AI Report tab to enter a stock symbol and generate the AI report.", style = "Normal")
doc = body_add_par(doc, "")
doc = body_add_par(doc, "For the AI report to work without a cloud key, install and start Ollama on your computer (https://ollama.com) and pull a model (e.g. gemma3:latest).", style = "Normal")

out_file = "DOCUMENTATION.docx"
print(doc, target = out_file)
message("Saved: ", normalizePath(out_file, mustWork = FALSE))

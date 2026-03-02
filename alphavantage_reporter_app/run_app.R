# run_app.R — Launch the Shiny app.
# From app folder:  source("run_app.R")
# From project root:  shiny::runApp("alphavantage_reporter_app")

if (file.exists("app.R")) {
  shiny::runApp(".", launch.browser = TRUE)
} else if (file.exists("alphavantage_reporter_app/app.R")) {
  shiny::runApp("alphavantage_reporter_app", launch.browser = TRUE)
} else {
  stop("app.R not found. Run from alphavantage_reporter_app or project root.")
}

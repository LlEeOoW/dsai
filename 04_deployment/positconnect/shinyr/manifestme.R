#' manifestme.R
#' @title Generate manifest.json for Shiny R App (Posit Connect)
#' @description
#' Builds manifest.json in the target app directory so Posit Connect knows
#' dependencies and package/software versions from your development environment.
#' Run from project root or from this folder; pass the app path as first argument.
#'
#' Usage (from project root):
#'   Rscript 04_deployment/positconnect/shinyr/manifestme.R alphavantage_reporter_app
#' Or from R:
#'   source("04_deployment/positconnect/shinyr/manifestme.R")
#'   manifestme("alphavantage_reporter_app")

# 0. SETUP ###################################

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}
library(rsconnect)

# 1. RESOLVE APP DIR ###################################

# First CLI arg, or env MANIFEST_APP_DIR, or current directory
app_dir = commandArgs(trailingOnly = TRUE)[1]
if (is.na(app_dir) || !nzchar(app_dir)) {
  app_dir = Sys.getenv("MANIFEST_APP_DIR", unset = "")
}
if (!nzchar(app_dir)) {
  app_dir = getwd()
}
# Resolve to absolute path so we can setwd into it and write manifest there
app_dir = normalizePath(app_dir, mustWork = TRUE)

# 2. WRITE MANIFEST ###################################

message("Writing manifest.json for app: ", app_dir)
old_wd = setwd(app_dir)
on.exit(setwd(old_wd), add = TRUE)

writeManifest(
  appDir = ".",
  appPrimaryDoc = "app.R",
  appMode = "shiny",
  verbose = TRUE
)

manifest_path = file.path(app_dir, "manifest.json")
if (file.exists(manifest_path)) {
  message("Done. manifest.json written to: ", manifest_path)
} else {
  stop("manifest.json was not created. Check that appDir contains a valid Shiny app (e.g. app.R).")
}

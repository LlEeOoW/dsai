# install_packages.R — Install dependencies for Alpha Vantage Reporter app.
# Run once from this folder: source("install_packages.R")

pkgs = c("shiny", "httr2", "jsonlite", "dplyr", "ggplot2", "bslib", "DT")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}
message("Done. Required packages: ", paste(pkgs, collapse = ", "))

# 02_example_r.R

# This script can be run in R to demonstrate 
# how to make an API request

# Install if you haven’t yet
# install.packages(c(“httr2”, “jsonlite”)) 

# Execute query and save response as object
library(httr2)
library(jsonlite)

# Load environment variables from .env (optional)
if (file.exists(".env")) readRenviron(".env")
TEST_API_KEY = Sys.getenv("TEST_API_KEY")

# Create request (JSONPlaceholder: no Cloudflare, works in all networks)
req = request("https://jsonplaceholder.typicode.com/users/1") |>
  req_headers("User-Agent" = "Mozilla/5.0 (compatible; R-httr2/1.0)")
if (nzchar(TEST_API_KEY)) req = req_headers(req, `x-api-key` = TEST_API_KEY)
req = req_method(req, "GET")

# Execute request and print response
resp = req_perform(req)
cat("Status Code:", resp_status(resp), "\n")
data = resp_body_json(resp)
print(data)

# Clear environment
rm(list = ls())

# Exit
# q(save = "no")
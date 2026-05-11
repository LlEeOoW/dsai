# 02_example_python.py
# Simple example of making an API request in Python
# Pairs with 02_example.R
# Tim Fraser

# This script shows how to:
# - Load an API key from a .env file
# - Make a GET request to an example API
# - Inspect the HTTP status code and JSON response

# 0. Setup #################################

## 0.1 Load Packages ############################

# !pip install requests python-dotenv  # run this once in your environment

import os  # for reading environment variables
import requests  # for making HTTP requests
from dotenv import load_dotenv  # for loading variables from .env

## 0.2 Load Environment Variables ################

# Load environment variables from the .env file in the project root
# This matches the behavior of readRenviron(".env") in 02_example.R
load_dotenv(".env")

# Get the API key from the environment
TEST_API_KEY = os.getenv("TEST_API_KEY")

## 1. Make API Request ###########################

# Execute query (JSONPlaceholder: no Cloudflare, works in all networks)
url = "https://jsonplaceholder.typicode.com/users/1"
headers = {"Accept": "application/json"}
if os.getenv("TEST_API_KEY"):
    headers["x-api-key"] = os.getenv("TEST_API_KEY")
response = requests.get(url, headers=headers)

## 2. Inspect Response ###########################

# View response status code (200 = success)
print(response.status_code)

# Only parse JSON when response is OK and looks like JSON (avoid crash when server returns HTML)
if response.status_code == 200 and response.text.strip() and not response.text.strip().startswith("<"):
    print(response.json())
else:
    print("API returned HTML or error.")
    print("Response preview:", (response.text[:120] + "...") if len(response.text) > 120 else response.text)


# Clear environment (optional in short scripts, but shown for parity
# with the R example that clears its workspace)
globals().clear()
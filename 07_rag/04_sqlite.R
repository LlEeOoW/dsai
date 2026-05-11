# 04_sqlite.R
# Example RAG workflow using SQLite database

# Load libraries
# install.packages(c("DBI", "RSQLite", "dbplyr", "dplyr", "httr2", "jsonlite", "ollamar"), repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))
if (!requireNamespace("DBI", quietly = TRUE)) install.packages("DBI", repos = "https://cloud.r-project.org")
if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages("RSQLite", repos = "https://cloud.r-project.org")
if (!requireNamespace("dbplyr", quietly = TRUE)) install.packages("dbplyr", repos = "https://cloud.r-project.org")
library(DBI) # for database connection
library(RSQLite) # for SQLite database
library(dbplyr) # for extending dplyr to database operations
library(dplyr) # for data wrangling
library(httr2) # for HTTP requests
library(jsonlite) # for JSON operations
library(ollamar) # for interacting with the LLM
source("07_rag/functions.R")

MODEL = "smollm2:135m" # use this small model (no function calling, < 200 MB)
PORT = 11434 # use this default port
OLLAMA_HOST = paste0("http://localhost:", PORT) # use this default host
DB_PATH = "07_rag/data/rag_example.db" # path to the SQLite database

# Create the SQLite database if it doesn't exist
if (!file.exists(DB_PATH)) {
    source("07_rag/data/papers_create.R")
}

# Connect to database
con <- dbConnect(RSQLite::SQLite(), DB_PATH)

# Define a search function for the database
search_documents = function(query, db_connection, limit = 5) {
    # Search in title, content, and tags
    sql_query = "
        SELECT id, title, content, category, author, tags
        FROM documents
        WHERE title LIKE ? 
           OR content LIKE ?
           OR tags LIKE ?
        LIMIT ?
    "
    
    search_pattern = paste0("%", query, "%")
    
    results = dbGetQuery(
        db_connection, 
        sql_query,
        params = list(search_pattern, search_pattern, search_pattern, limit)
    )
    
    return(results)
}

# Test search function
search_documents("machine learning", con)

# Example: Search for documents about a specific topic
input = list(topic = "database")

# Task 1: Data Retrieval - keep it small for faster LLM calls
result1 = search_documents(input$topic, con, limit = 1)

# Truncate long document content to keep the prompt short and fast.
if ("content" %in% names(result1)) {
    result1$content = substr(result1$content, 1, 400)
}

# Convert results to JSON for the LLM
result1_json = result1 %>%
    as.list() %>%
    jsonlite::toJSON(auto_unbox = TRUE)

# Task 2: Generation augmented with the retrieved data
# Generate a summary of the retrieved documents
role = "Output a concise summary (max 120 words) of the retrieved document(s). Use markdown with a short title and 5 bullet points. No extra commentary."

# Using our custom agent_run function, which wraps ollamar::chat
result2 = agent_run(
    role = role, 
    task = result1_json, 
    model = MODEL, 
    output = "text"
)

# View result
cat(result2)

# Alternative: Manual chat approach, using ollamar::chat
result2b = chat(
    model = MODEL,
    messages = list(
        list(role = "system", content = role),
        list(role = "user", content = result1_json)
    ), 
    output = "text", 
    stream = FALSE
)

# View result
cat(result2b)

# Close database connection
dbDisconnect(con)

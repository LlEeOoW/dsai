# 02_function_calling.R

# This script demonstrates how to use the ollamar package in R to interact with an LLM that supports function calling.

# Further reading: https://cran.r-project.org/web/packages/ollamar/vignettes/ollamar.html

# Load packages (quiet: no startup messages or version-built-under warnings)
suppressWarnings(suppressPackageStartupMessages({
    library(ollamar)
    library(dplyr)
    library(stringr)
    # jsonlite: parse tool$arguments when API sends JSON text
    library(jsonlite)
}))

# Select model of interest
MODEL = "smollm2:1.7b"

# Define a function to be used as a tool
add_two_numbers = function(x, y){
    return(x + y)
}

# Second tool: multiply (same pattern — function in global env, name matches metadata)
multiply_numbers = function(x, y){
    return(x * y)
}

# Define the tool metadata as a list
tool_add_two_numbers = list(
    type = "function",
    "function" = list(
        name = "add_two_numbers",
        description = "Add two numbers",
        parameters = list(
            type = "object",
            required = list("x", "y"),
            properties = list(
                x = list(type = "numeric", description = "first number"),
                y = list(type = "numeric", description = "second number")
            )
        )
    )
)

tool_multiply_numbers = list(
    type = "function",
    "function" = list(
        name = "multiply_numbers",
        description = "Multiply two numbers",
        parameters = list(
            type = "object",
            required = list("x", "y"),
            properties = list(
                x = list(type = "numeric", description = "first number"),
                y = list(type = "numeric", description = "second number")
            )
        )
    )
)

# Parse tool arguments: sometimes "arguments" is a JSON string, sometimes already a list
parse_tool_arguments = function(args) {
    if (is.null(args)) {
        stop("Tool call has no arguments.")
    }
    if (is.character(args) && length(args) == 1L) {
        args = jsonlite::fromJSON(args, simplifyVector = TRUE)
    }
    if (!is.list(args)) {
        args = as.list(args)
    }
    args
}

# Create a simple chat history with a user question that will require the tool
messages = create_message(role = "user", content = "What is 3 times 4?")
resp = chat(
    model = MODEL,
    messages = messages,
    tools = list(tool_add_two_numbers, tool_multiply_numbers),
    output = "tools",
    stream = FALSE
)

# Receive back the tool call (empty if the model did not request a tool)
if (length(resp) == 0L) {
    stop(
        "No tool calls returned. Check that Ollama is running, model ",
        MODEL,
        " is installed (e.g. ollama pull ",
        MODEL,
        "), and the model supports tools."
    )
}
tool = resp[[1]]
# Execute the tool call
do.call(tool$name, parse_tool_arguments(tool$arguments))

# Clean up shop
rm(list = ls())

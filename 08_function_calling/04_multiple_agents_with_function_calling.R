# 04_multiple_agents_with_function_calling.R
# Run from repo root: Rscript 08_function_calling/04_multiple_agents_with_function_calling.R
# Or set working directory to 08_function_calling first.

args = commandArgs(trailingOnly = FALSE)
match = grep("^--file=", args)
if (length(match) > 0) {
  script_path = sub("^--file=", "", args[match])
  if (nzchar(script_path) && file.exists(script_path)) {
    setwd(dirname(normalizePath(script_path)))
  }
}

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(httr2)
  library(jsonlite)
  library(ollamar)
  library(purrr)
  library(lubridate)
})

MODEL = "smollm2:1.7b"
source("functions.R")

# In this script, we will build a graph of agents and their interactions,
# to query data, perform analysis, and interpret it.

# We will use the FDA Drug Shortages API to get data on drug shortages.
# https://open.fda.gov/apis/drug/drugshortages/

get_shortages = function(category = "Psychiatry", limit = 500){
  # Testing values
  # category = "Psychiatry"

  # Create request object
  req = request("https://api.fda.gov/drug/shortages.json") |>
      req_headers(Accept = "application/json")  |>
      req_method("GET") |>
      # Sort by initial posting date, most recent first
      req_url_query(sort="initial_posting_date:desc") |>
      # Search for capsule medications, Psychiatric medications, and current shortages
      req_url_query(search = paste0('dosage_form:"Capsule"+status:"Current"+therapeutic_category:"', category, '"')) |>
      # Limit to N results
      req_url_query(limit = limit) 


    # Perform the request
    resp = req |> req_perform()
    # Parse the response as JSON
    data = resp_body_json(resp)

    res = data$results
    if (is.null(res) || length(res) == 0L) {
      return(tibble(
        therapeutic_category = character(),
        generic_name = character(),
        update_type = character(),
        update_date = as.Date(character()),
        availability = character(),
        related_info = character()
      ))
    }

    # Process the data into a tidy dataframe
    processed_data = res |>
      map_dfr(~tibble(
        therapeutic_category = paste0(.x$therapeutic_category, collapse = ", "),
        generic_name = .x$generic_name,
        update_type = .x$update_type,
        update_date = .x$update_date,
        availability = .x$availability,
        related_info = .x$related_info,
          )
      )  %>%
      mutate(update_date = lubridate::mdy(update_date))
      return(processed_data)
}

# Context the tool needs to know
categories = c(
  "Analgesia/Addiction",
  "Anesthesia",
  "Anti-Infective",   
  "Antiviral",
  "Cardiovascular",
  "Dental",
  "Dermatology",
  "Endocrinology/Metabolism",
  "Gastroenterology",
  "Hematology",
  "Inborn Errors",
  "Medical Imaging",
  "Musculoskeletal",
  "Neurology",
  "Oncology",
  "Ophthalmology",
  "Other",
  "Pediatric",
  "Psychiatry",
  "Pulmonary/Allergy",
  "Renal",
  "Reproductive",
  "Rheumatology",
  "Total Parenteral Nutrition",
  "Transplant",
  "Urology"
)

# Define the tool metadata as a list
tool_get_shortages = list(
    type = "function",
    "function" = list(
        name = "get_shortages",
        description = "Get data on drug shortages",
        parameters = list(
            type = "object",
            required = list("category", "limit"),
            properties = list(
                category = list(type = "string", description = paste0("the therapeutic category of the drug. Options are: ", paste(categories, collapse = ", "), ".")),
                limit = list(type = "numeric", description = "the max number of results to return. Default is 500.")
            )
        )
    )
)



# Get data from an API
# data = get_shortages("Psychiatry")



# Let's create an agentic workflow.
task = "Get data on drug shortages for the category Psychiatry"
role1 = "I fetch information from the FDA Drug Shortages API"
result1 = agent_run(role = role1, task = task, model = MODEL, output = "tools", tools = list(tool_get_shortages))

cat("\n--- Agent 1 (tool) -> tabular result (head) ---\n")
print(head(result1, 10L))

role2 = paste(
  "You are a data analyst. The user lists FDA drug shortage lines (drug | update | availability).",
  "Reply with 3-6 bullet points summarizing patterns (which drugs, mostly revised or reverified, availability).",
  sep = " "
)
r1 = head(result1, 25)
lines = with(r1, paste(generic_name, update_type, availability, sep = " | "))
task2 = paste0(
  "Records:\n",
  paste(lines, collapse = "\n")
)
result2 = agent_run(role = role2, task = task2, model = MODEL, output = "text", tools = NULL)

cat("\n--- Agent 2 (analysis) ---\n")
cat(result2, sep = "\n")

role3 = paste(
  "You are a communications writer. Write a short press release (3-5 sentences)",
  "based only on the analysis paragraph you receive. Do not add facts not in the analysis.",
  sep = " "
)
result3 = agent_run(role = role3, task = result2, model = MODEL, output = "text", tools = NULL)

cat("\n--- Agent 3 (press release) ---\n")
cat(result3, sep = "\n")


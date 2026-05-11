# 04_agent_query.R
# Agent with REST Tool Call
# Tim Fraser
# Run from repo root OR via Code Runner on this file:
#   Rscript 12_end/04_agent_query.R
# If API_PUBLIC_URL is localhost and nothing is listening, install.packages("processx")
# once; this script will auto-start Plumber and stop it when finished.

# 0. SETUP ###################################

library(httr2)
library(jsonlite)

# 1. CONFIG ###################################

script_dir = {
  ca = commandArgs(trailingOnly = FALSE)
  fa = sub("^--file=", "", ca[grepl("^--file=", ca)][1])
  if (!is.na(fa) && nzchar(fa)) {
    normalizePath(dirname(fa), winslash = "/", mustWork = FALSE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  }
}
root_dir = if (basename(script_dir) == "12_end") {
  dirname(script_dir)
} else {
  script_dir
}
for (envf in c(
  file.path(root_dir, "12_end", ".env"),
  file.path(root_dir, ".env"),
  file.path(script_dir, ".env")
)) {
  if (file.exists(envf)) readRenviron(envf)
}

ENDPOINT_URL = trimws(Sys.getenv("API_PUBLIC_URL", unset = "http://localhost:8000"))
ENDPOINT_URL = sub("/$", "", ENDPOINT_URL)
OLLAMA_HOST = Sys.getenv("OLLAMA_HOST", unset = "https://ollama.com")
OLLAMA_API_KEY = Sys.getenv("OLLAMA_API_KEY", unset = "")
OLLAMA_MODEL = Sys.getenv("OLLAMA_MODEL", unset = "smollm2:1.7b")

# Local Ollama app (http://127.0.0.1:11434) does not use Bearer auth.
is_local_ollama_host = function(host) {
  grepl(
    "^https?://(localhost|127\\.0\\.0\\.1)(:|/|$)",
    tolower(trimws(host))
  )
}

is_local_api_url = function(url) {
  grepl("^https?://(localhost|127\\.0\\.0\\.1)(:|/|$)", url, ignore.case = TRUE)
}

ping_validation = function() {
  tryCatch(
    resp_status(
      request(ENDPOINT_URL) |>
        req_url_path_append("validation") |>
        req_timeout(2) |>
        req_perform()
    ),
    error = function(e) NA_integer_
  )
}

start_local_plumber_if_needed = function() {
  if (!is_local_api_url(ENDPOINT_URL)) {
    return(NULL)
  }
  if (isTRUE(ping_validation() == 200L)) {
    cat("Using existing API at", ENDPOINT_URL, "\n")
    return(NULL)
  }
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "No Plumber process at ", ENDPOINT_URL, ". Either:\n",
      "  install.packages('processx')  # then re-run to auto-start the API, or\n",
      "  Rscript ", file.path(root_dir, "12_end", "03_plumber", "runme.R"),
      "  # in a separate terminal first."
    )
  }
  runme = normalizePath(
    file.path(root_dir, "12_end", "03_plumber", "runme.R"),
    winslash = "/",
    mustWork = TRUE
  )
  proc = processx::process$new(
    "Rscript",
    args = c(runme),
    wd = root_dir,
    stdout = "|",
    stderr = "|"
  )
  for (i in seq_len(60)) {
    if (isTRUE(ping_validation() == 200L)) {
      cat("Started local Plumber at", ENDPOINT_URL, "\n")
      return(proc)
    }
    if (!proc$is_alive()) {
      err = proc$read_error()
      stop("Plumber exited early. stderr:\n", err)
    }
    Sys.sleep(0.5)
  }
  proc$kill()
  stop("Plumber did not respond on ", ENDPOINT_URL, " within 30s.")
}

plumber_proc = start_local_plumber_if_needed()
if (!is.null(plumber_proc)) {
  on.exit(
    {
      if (plumber_proc$is_alive()) try(plumber_proc$kill(), silent = TRUE)
    },
    add = TRUE
  )
}

if (!nzchar(trimws(OLLAMA_API_KEY)) && !is_local_ollama_host(OLLAMA_HOST)) {
  stop(
    "Missing OLLAMA_API_KEY for Ollama Cloud. Either:\n",
    "  1) Copy 12_end/.env.example to 12_end/.env and set OLLAMA_API_KEY=... (cloud), or\n",
    "  2) Install and run the Ollama desktop app, then in 12_end/.env set:\n",
    "       OLLAMA_HOST=http://127.0.0.1:11434\n",
    "       OLLAMA_API_KEY=\n",
    "     (leave key empty) and use a model you have pulled, e.g. OLLAMA_MODEL=smollm2:1.7b"
  )
}
if (is_local_ollama_host(OLLAMA_HOST) && !nzchar(trimws(OLLAMA_API_KEY))) {
  cat("Using local Ollama at", OLLAMA_HOST, "(no API key).\n")
}

# 2. DEFINE TOOL FUNCTION ###################################

predict_vehicle_count = function(day_of_week, hours_of_day) {
  hours = as.integer(hours_of_day)
  hours = hours[!is.na(hours) & hours >= 0 & hours <= 23]
  if (length(hours) == 0) stop("hours_of_day must contain at least one integer between 0 and 23.")

  preds = lapply(hours, function(h) {
    resp = request(ENDPOINT_URL) |>
      req_url_path_append("predict") |>
      req_url_query(
        day_of_week = day_of_week,
        hour_of_day = h
      ) |>
      req_perform() |>
      resp_body_json()
    list(
      hour_of_day = h,
      predicted_vehicle_count = as.numeric(unlist(resp$predicted_vehicle_count)[1])
    )
  })

  list(
    day_of_week = as.integer(day_of_week),
    unit = "vehicles_observed_in_one_minute",
    interval = "1m_t1",
    note = "Each prediction is for one representative minute within that hour and day of week.",
    predictions = preds
  )
}

# 3. OLLAMA /API/CHAT HELPERS ###################################

ollama_chat_once = function(base_url, api_key, model, messages, tools = NULL) {
  url = paste0(sub("/$", "", base_url), "/api/chat")
  body = list(model = model, messages = messages, stream = FALSE)
  if (!is.null(tools) && length(tools) > 0L) body$tools = tools

  req = httr2::request(url) |>
    httr2::req_headers("Content-Type" = "application/json")
  if (nzchar(trimws(api_key))) {
    req = req |> httr2::req_headers(Authorization = paste("Bearer", trimws(api_key)))
  }
  req = req |>
    httr2::req_body_json(body) |>
    httr2::req_timeout(120)

  resp = httr2::req_perform(req)
  data = httr2::resp_body_json(resp, simplifyVector = FALSE, simplifyDataFrame = FALSE)

  msg = if (is.null(data$message)) list() else data$message
  content = if (is.null(msg$content)) "" else as.character(msg$content)

  list(content = trimws(paste(content, collapse = "")), message = msg, raw = data)
}

parse_function_arguments = function(raw) {
  if (is.null(raw)) return(list())
  if (is.list(raw) && !is.character(raw)) return(raw)
  if (!is.character(raw)) return(list())

  s = trimws(raw)
  if (!nzchar(s)) return(list())

  parsed = tryCatch(jsonlite::fromJSON(s, simplifyVector = FALSE), error = function(e) list())
  if (is.list(parsed)) parsed else list()
}

build_tool_message = function(tool_call) {
  fn_obj = tool_call[["function"]]
  fn = if (is.null(fn_obj$name)) "" else fn_obj$name
  args = parse_function_arguments(fn_obj$arguments)
  day_of_week = as.integer(args$day_of_week)
  hours_of_day = as.integer(unlist(args$hours_of_day))

  if (identical(fn, "predict_vehicle_count") && !is.na(day_of_week) && length(hours_of_day) > 0L) {
    pred = predict_vehicle_count(day_of_week = day_of_week, hours_of_day = hours_of_day)
    tool_content = jsonlite::toJSON(
      pred,
      auto_unbox = TRUE
    )
  } else {
    tool_content = jsonlite::toJSON(list(error = "Invalid tool call or arguments"), auto_unbox = TRUE)
  }

  tool_message = list(role = "tool", content = tool_content)
  if (!is.null(tool_call$id)) tool_message$tool_call_id = tool_call$id
  if (nzchar(fn)) {
    tool_message$name = fn
    tool_message$tool_name = fn
  }
  tool_message
}

# 4. DEFINE TOOL METADATA ###################################

tool_predict_vehicle_count = list(
  type = "function",
  "function" = list(
    name        = "predict_vehicle_count",
    description = paste(
      "Predict Brussels vehicle count for a specific day of week and vector of hours.",
      "Returns one estimated vehicle count per requested hour.",
      "Each value is for one representative minute (1m/t1 interval) within that hour and day of week."
    ),
    parameters  = list(
      type     = "object",
      required = list("day_of_week", "hours_of_day"),
      properties = list(
        day_of_week = list(type = "integer", description = "Day of week (1=Monday, ..., 7=Sunday)"),
        hours_of_day = list(
          type = "array",
          description = "Vector of hours to predict (0-23), e.g. [0,1,2,...,23].",
          items = list(type = "integer")
        )
      )
    )
  )
)

# 5. RUN OLLAMA TOOL-CALLING LOOP ###################################

messages = list(
  list(
    role = "system",
    content = paste(
      "You are a Brussels traffic assistant.",
      "When prediction data is needed, call predict_vehicle_count with day_of_week and hours_of_day vector.",
      "Always state units clearly: vehicles observed in one representative minute (1m/t1 interval)",
      "within the requested hour and day of week."
    )
  ),
  list(role = "user", content = "Predict Brussels vehicle count for Monday at 8 AM.")
)

tools = list(tool_predict_vehicle_count)
ollama_result = ollama_chat_once(
  base_url = OLLAMA_HOST,
  api_key = OLLAMA_API_KEY,
  model = OLLAMA_MODEL,
  messages = messages,
  tools = tools
)

assistant_msg = ollama_result$message
messages[[length(messages) + 1L]] = list(
  role = "assistant",
  content = if (is.null(assistant_msg$content)) "" else assistant_msg$content,
  tool_calls = assistant_msg$tool_calls
)

tool_calls = if (is.null(assistant_msg$tool_calls)) list() else assistant_msg$tool_calls
if (length(tool_calls) > 0L) {
  # Keep this tutorial simple: execute the first requested tool call.
  messages[[length(messages) + 1L]] = build_tool_message(tool_calls[[1]])
}

final_result = ollama_chat_once(
  base_url = OLLAMA_HOST,
  api_key = OLLAMA_API_KEY,
  model = OLLAMA_MODEL,
  messages = messages,
  tools = tools
)

cat("\nAgent result:", final_result$content, "\n")

# 6. VERIFY ###################################

direct = predict_vehicle_count(day_of_week = 1, hours_of_day = 8)
cat(
  "Direct API call: predicted_vehicle_count =",
  direct$predictions[[1]]$predicted_vehicle_count,
  "(Monday 08:00, 1m/t1)\n"
)
cat("Tool calls used (agent round 1):", length(tool_calls), "\n")

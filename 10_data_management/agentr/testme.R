# testme.R
# Smoke-test the deployed agent (Posit Connect or any public base URL)
# Tim Fraser
#
# Same pattern as agentpy/testme.py. Set AGENT_PUBLIC_URL in .env (repository root or agentr/).
#
# 0. SETUP ###################################

library(httr2)

if (file.exists(".env")) {
  readRenviron(".env")
}
if (!nzchar(trimws(Sys.getenv("AGENT_PUBLIC_URL", ""))) &&
    file.exists("10_data_management/agentr/.env")) {
  readRenviron("10_data_management/agentr/.env")
}

viewer = trimws(Sys.getenv("CONNECT_VIEWER_KEY", unset = ""))
if (!nzchar(viewer)) {
  viewer = trimws(Sys.getenv("CONNECT_API_KEY", unset = ""))
}
# Posit Connect REST API uses "Key"; some hosts use "Bearer".
auth_prefix = toupper(trimws(Sys.getenv("CONNECT_VIEWER_AUTH", unset = "KEY")))
connect_authorization = function(secret) {
  if (!nzchar(secret)) {
    return(NULL)
  }
  if (identical(auth_prefix, "BEARER")) {
    paste("Bearer", secret)
  } else {
    paste("Key", secret)
  }
}

# 1. REQUESTS ################################################################

base = trimws(Sys.getenv("AGENT_PUBLIC_URL", unset = ""))
base = sub("/$", "", base)
if (!nzchar(base)) {
  stop("Set AGENT_PUBLIC_URL in .env to your deployed base, e.g. https://connect.example.com/content/abc")
}
# Or if local, try this:
# base = "http://localhost:8000"
# Or if trying the instructor's deployment, try this:
# base = "https://connect.systems-apps.com/autonomous_agent"

cat("# Smoke test at", base, "\n\n")

req_health = httr2::request(paste0(base, "/health"))
auth_h = connect_authorization(viewer)
if (!is.null(auth_h)) {
  req_health = req_health |>
    httr2::req_headers(Authorization = auth_h)
}
r1 = req_health |>
  httr2::req_timeout(30) |>
  httr2::req_perform()

cat("health:", httr2::resp_status(r1), "\n")
print(httr2::resp_body_json(r1, simplifyVector = TRUE))




body = list(
  task = paste0(
    "Training brief: incident 'Exercise Riverdale', River County, last 24h — ",
    "minimal situational sections; note if no live search."
  )
)

req_agent = httr2::request(paste0(base, "/hooks/agent")) |>
  httr2::req_method("POST") |>
  httr2::req_headers("Content-Type" = "application/json")
if (!is.null(auth_h)) {
  req_agent = req_agent |>
    httr2::req_headers(Authorization = auth_h)
}
r2 = req_agent |>
  httr2::req_body_json(body) |>
  httr2::req_timeout(120) |>
  httr2::req_perform()

txt = httr2::resp_body_string(r2)
cat("agent:", httr2::resp_status(r2), substr(txt, 1L, min(500L, nchar(txt))), "\n")

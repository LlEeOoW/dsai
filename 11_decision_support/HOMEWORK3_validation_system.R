#' @name HOMEWORK3_validation_system.R
#' @title Homework 3: AI Report Validation + Prompt Experiment
#' @author Prof. Tim Fraser
#' @description
#' Topic: Decision Support + Text Analysis
#'
#' This script builds a customized AI validation system for generated reports,
#' compares Prompt A/B/C performance, and runs statistical tests (t-test + ANOVA).
#' It is designed as a one-file Homework 3 deliverable you can run end-to-end.

# 0. SETUP ###################################

## 0.1 Load Packages #################################
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(httr2)
  library(jsonlite)
  library(broom)
  library(ggplot2)
  library(tidyr)
  library(purrr)
})

## 0.2 Resolve Project Root #################################
args = commandArgs(trailingOnly = FALSE)
match = grep("^--file=", args)
if (length(match) > 0) {
  script_path = sub("^--file=", "", args[match])
  if (nzchar(script_path) && file.exists(script_path)) {
    ROOT = dirname(dirname(normalizePath(script_path)))
    setwd(ROOT)
  }
}

cat("\n============================================================\n")
cat("HOMEWORK 3 | AI Report Validation System\n")
cat("Working directory:", getwd(), "\n")
cat("============================================================\n\n")

## 0.3 Config #################################
# AI setup
AI_PROVIDER = "ollama"   # "ollama" or "openai"
OLLAMA_HOST = "http://localhost:11434"
OLLAMA_MODEL = "gemma3:latest"
OPENAI_MODEL = "gpt-4o-mini"

if (file.exists(".env")) { readRenviron(".env") }
OPENAI_API_KEY = Sys.getenv("OPENAI_API_KEY")

# Homework workflow toggle
# TRUE  = run customized AI validator on reports and generate new score file
# FALSE = use existing module 9 scores for fast statistical outputs
RUN_CUSTOM_VALIDATION = TRUE

# Sample size per prompt when RUN_CUSTOM_VALIDATION = TRUE
REPORTS_PER_PROMPT = 10

# Input files
REPORTS_FILE = "09_text_analysis/data/prompt_comparison_reports.csv"
PRECOMPUTED_SCORES_FILE = "09_text_analysis/data/prompt_comparison_scores.csv"

# Output directory/files
OUT_DIR = "11_decision_support/output_homework3"
OUT_SCORES = file.path(OUT_DIR, "homework3_custom_scores.csv")
OUT_SUMMARY = file.path(OUT_DIR, "homework3_summary_stats.csv")
OUT_TESTS = file.path(OUT_DIR, "homework3_stat_tests.csv")
OUT_PLOT = file.path(OUT_DIR, "homework3_prompt_boxplot.png")

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# 1. CUSTOMIZED VALIDATION FRAMEWORK ###################################

## 1.1 Define customized rubric #################################
# We intentionally use a rubric different from the module's original Likert setup.
rubric_text = "
Customized Validation Rubric (1-5 scale):
1) evidence_use: Does the report cite concrete numbers or evidence from data?
2) decision_usefulness: Does the report support action or policy decisions?
3) constraint_awareness: Does it avoid over-claiming and respect uncertainty?
4) readability: Is it clear, concise, and easy for non-technical readers?
5) policy_alignment: Are recommendations aligned with stated findings?

Also return:
- pass_minimum_quality (boolean): TRUE if average score >= 3.5, else FALSE
- details (string): 0-40 words explanation
"

## 1.2 Build validation prompt #################################
build_custom_prompt = function(report_text) {
  paste0(
    "You are a strict report validator.\n",
    "Evaluate the report using the rubric below and return valid JSON only.\n\n",
    rubric_text, "\n",
    "Return JSON in this exact format:\n",
    "{\n",
    "  \"evidence_use\": 1-5,\n",
    "  \"decision_usefulness\": 1-5,\n",
    "  \"constraint_awareness\": 1-5,\n",
    "  \"readability\": 1-5,\n",
    "  \"policy_alignment\": 1-5,\n",
    "  \"pass_minimum_quality\": true/false,\n",
    "  \"details\": \"0-40 words\"\n",
    "}\n\n",
    "Report text:\n",
    report_text
  )
}

## 1.3 Query model #################################
query_validator = function(prompt, provider = AI_PROVIDER) {
  if (provider == "ollama") {
    body = list(
      model = OLLAMA_MODEL,
      messages = list(list(role = "user", content = prompt)),
      format = "json",
      stream = FALSE
    )

    res = request(paste0(OLLAMA_HOST, "/api/chat")) %>%
      req_method("POST") %>%
      req_body_json(body) %>%
      req_error(is_error = function(resp) FALSE) %>%
      req_perform()

    if (resp_status(res) >= 400) {
      body_txt = tryCatch(resp_body_string(res), error = function(e) "")
      stop(
        "Ollama request failed (HTTP ", resp_status(res), "). ",
        if (nzchar(body_txt)) paste0("Response: ", body_txt, " ") else "",
        "Check that Ollama is running and model exists: ", OLLAMA_MODEL,
        call. = FALSE
      )
    }

    response = resp_body_json(res)
    return(response$message$content)
  }

  if (provider == "openai") {
    if (!nzchar(OPENAI_API_KEY)) {
      stop("OPENAI_API_KEY missing in .env for OpenAI mode.", call. = FALSE)
    }

    body = list(
      model = OPENAI_MODEL,
      messages = list(
        list(role = "system", content = "You are a strict report validator. Return JSON only."),
        list(role = "user", content = prompt)
      ),
      response_format = list(type = "json_object"),
      temperature = 0.2
    )

    res = request("https://api.openai.com/v1/chat/completions") %>%
      req_method("POST") %>%
      req_headers(
        "Authorization" = paste0("Bearer ", OPENAI_API_KEY),
        "Content-Type" = "application/json"
      ) %>%
      req_body_json(body) %>%
      req_perform()

    response = resp_body_json(res)
    return(response$choices[[1]]$message$content)
  }

  stop("provider must be 'ollama' or 'openai'.", call. = FALSE)
}

## 1.4 Parse validation JSON #################################
parse_validation_json = function(json_text) {
  clean_json = str_extract(json_text, "\\{[\\s\\S]*\\}")
  if (is.na(clean_json)) { stop("No JSON object detected in model response.", call. = FALSE) }

  obj = fromJSON(clean_json)

  tibble(
    evidence_use = as.numeric(obj$evidence_use),
    decision_usefulness = as.numeric(obj$decision_usefulness),
    constraint_awareness = as.numeric(obj$constraint_awareness),
    readability = as.numeric(obj$readability),
    policy_alignment = as.numeric(obj$policy_alignment),
    pass_minimum_quality = as.logical(obj$pass_minimum_quality),
    details = as.character(obj$details)
  ) %>%
    mutate(
      custom_overall = rowMeans(across(c(
        evidence_use, decision_usefulness, constraint_awareness, readability, policy_alignment
      )), na.rm = TRUE)
    )
}

# 2. RUN VALIDATION ###################################

## 2.1 Load report dataset #################################
reports_df = read_csv(REPORTS_FILE, show_col_types = FALSE)
cat("Loaded reports:", nrow(reports_df), "rows\n")

## 2.2 Optional AI validation pass #################################
if (RUN_CUSTOM_VALIDATION) {
  cat("Running customized AI validation...\n")

  sampled_reports = reports_df %>%
    group_by(prompt_id) %>%
    slice_head(n = REPORTS_PER_PROMPT) %>%
    ungroup()

  scored_rows = list()
  for (i in seq_len(nrow(sampled_reports))) {
    row = sampled_reports[i, ]
    prompt = build_custom_prompt(row$report_text)

    cat("  - Validating", row$prompt_id, "report", row$report_id, "...\n")
    parsed = tryCatch({
      raw = query_validator(prompt, provider = AI_PROVIDER)
      parse_validation_json(raw)
    }, error = function(e) {
      warning("Validation failed for prompt_id=", row$prompt_id, ", report_id=", row$report_id, ": ", e$message)
      tibble(
        evidence_use = NA_real_,
        decision_usefulness = NA_real_,
        constraint_awareness = NA_real_,
        readability = NA_real_,
        policy_alignment = NA_real_,
        pass_minimum_quality = NA,
        details = paste("Validation error:", e$message),
        custom_overall = NA_real_
      )
    })

    scored_rows[[i]] = bind_cols(row %>% select(prompt_id, report_id), parsed)
    Sys.sleep(0.3)
  }

  scores = bind_rows(scored_rows)
  write_csv(scores, OUT_SCORES)
  cat("Saved customized scores to:", OUT_SCORES, "\n")
} else {
  cat("RUN_CUSTOM_VALIDATION = FALSE -> using existing precomputed scores for stats.\n")
  base_scores = read_csv(PRECOMPUTED_SCORES_FILE, show_col_types = FALSE)

  # Map module-9 dimensions into a "customized" structure for quick Homework 3 outputs.
  scores = base_scores %>%
    transmute(
      prompt_id = prompt_id,
      report_id = report_id,
      evidence_use = accuracy,
      decision_usefulness = relevance,
      constraint_awareness = faithfulness,
      readability = (clarity + succinctness) / 2,
      policy_alignment = formality,
      pass_minimum_quality = overall_score >= 3.5,
      details = "Quick mode derived from module-9 scores",
      custom_overall = rowMeans(across(c(
        evidence_use, decision_usefulness, constraint_awareness, readability, policy_alignment
      )), na.rm = TRUE)
    )
  write_csv(scores, OUT_SCORES)
}

# 3. STATISTICAL EXPERIMENT ###################################

## 3.1 Summary statistics #################################
summary_stats = scores %>%
  group_by(prompt_id) %>%
  reframe(
    mean_custom_overall = mean(custom_overall, na.rm = TRUE),
    sd_custom_overall = sd(custom_overall, na.rm = TRUE),
    pass_rate = mean(pass_minimum_quality, na.rm = TRUE),
    n = n()
  ) %>%
  arrange(desc(mean_custom_overall))

write_csv(summary_stats, OUT_SUMMARY)
cat("\nSummary stats by prompt:\n")
print(summary_stats)

## 3.2 T-test (A vs B) #################################
a_scores = scores %>% filter(prompt_id == "A") %>% pull(custom_overall)
b_scores = scores %>% filter(prompt_id == "B") %>% pull(custom_overall)
ttest_res = t.test(a_scores, b_scores)
ttest_tidy = broom::tidy(ttest_res) %>%
  mutate(test_name = "t_test_A_vs_B")

## 3.3 ANOVA (A vs B vs C) #################################
anova_res = oneway.test(custom_overall ~ prompt_id, data = scores, var.equal = FALSE)
anova_tidy = broom::tidy(anova_res) %>%
  mutate(test_name = "anova_A_B_C")

tests_out = bind_rows(ttest_tidy, anova_tidy)
write_csv(tests_out, OUT_TESTS)

cat("\nStatistical tests:\n")
print(tests_out)

# 4. VISUAL OUTPUT ###################################

plot_obj = ggplot(scores, aes(x = prompt_id, y = custom_overall, fill = prompt_id)) +
  geom_boxplot(alpha = 0.8) +
  labs(
    title = "Homework 3: Customized Validation Scores by Prompt",
    x = "Prompt",
    y = "Custom Overall Score"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(filename = OUT_PLOT, plot = plot_obj, width = 8, height = 5, dpi = 150)
cat("\nSaved plot:", OUT_PLOT, "\n")

# 5. CONCLUSION PRINT ###################################
best_prompt = summary_stats$prompt_id[1]
best_mean = round(summary_stats$mean_custom_overall[1], 3)

cat("\n============================================================\n")
cat("Homework 3 run complete.\n")
cat("Best prompt by mean customized score:", best_prompt, "(mean =", best_mean, ")\n")
cat("Artifacts saved in:", OUT_DIR, "\n")
cat("============================================================\n\n")

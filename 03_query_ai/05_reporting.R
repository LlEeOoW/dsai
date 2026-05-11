# 05_reporting.R
# Save AI Report as Word (.docx)
# Pairs with 05_reporting.py
# Tim Fraser

# This script saves AI-generated report text to a Word document using the officer package.

# 0. SETUP ###################################

## 0.1 Load Packages #################################

# If you haven't already, install required package:
# install.packages("officer", repos = "https://cloud.r-project.org")
library(officer)   # for creating Word documents

## 0.2 Mock LLM Output #########################

# Simulate an AI response object
# In a real script, this would come from your LLM API call
mock_llm_response = list(
  response = "# Data Analysis Report

## Summary
The dataset contains 150 records with 3 key metrics showing positive trends.

## Key Findings
- Metric A increased by 15% over the period
- Metric B remained stable at 42 units
- Metric C showed significant variation

## Recommendations
Consider further investigation into Metric C variations."
)

# Extract the text content
report_text = mock_llm_response$response

# 1. SAVE AS WORD DOCUMENT (.docx) ###################################

# Create a Word document using officer package
doc = read_docx()

# Split content by lines and add to document
# Handle markdown headers and formatting
lines = strsplit(report_text, "\n")[[1]]

for (line in lines) {
  if (startsWith(line, "# ")) {
    # Main heading
    doc = body_add_par(doc, substring(line, 3), style = "heading 1")
  } else if (startsWith(line, "## ")) {
    # Subheading
    doc = body_add_par(doc, substring(line, 4), style = "heading 2")
  } else if (startsWith(line, "- ")) {
    # Bullet point (use Normal; default template may not have "List Bullet")
    doc = body_add_par(doc, substring(line, 3), style = "Normal")
  } else if (nchar(trimws(line)) > 0) {
    # Regular paragraph
    doc = body_add_par(doc, line)
  }
}

out_file = "report.docx"
print(doc, target = out_file)
cat("✅ Saved report.docx\n")
cat("   Path:", normalizePath(out_file, mustWork = FALSE), "\n")

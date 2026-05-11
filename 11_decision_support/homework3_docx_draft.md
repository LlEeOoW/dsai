# Homework 3: AI Report Validation System

Student Name: [Your Name]  
Course: [Course Name]  
Date: [Submission Date]

---

## 1) Writing Component (Draft)

> Important: The assignment says this part must be written in your own words and NOT AI-generated.  
> Use this draft as a structure reference, then rewrite it in your own style before submitting.

In this homework, I built a customized AI validation system to evaluate report quality and compare prompt performance. The goal was not to reuse the exact Likert rubric from the lab, but to design a rubric that better supports decision-making use cases. I used three prompt families (A, B, C) and evaluated their generated reports with an AI validator. The validator returns structured JSON scores for each report, and then I ran statistical tests to compare prompt quality.

My validator focuses on five dimensions: evidence use, decision usefulness, constraint awareness, readability, and policy alignment. I selected these dimensions because this project is about decision support, so I wanted to evaluate not only writing quality but also whether the report is actionable and avoids over-claiming. I also added a boolean pass indicator (`pass_minimum_quality`) with a threshold of average score >= 3.5. This gives a practical pass/fail signal for deployment scenarios where a team needs to quickly decide whether a generated report is acceptable.

Implementation was done in a single integrated R script: `11_decision_support/HOMEWORK3_validation_system.R`. The script can run in two modes. In the full mode (`RUN_CUSTOM_VALIDATION = TRUE`), it calls an LLM validator for each report and saves custom scores. In quick mode (`FALSE`), it maps existing module data to the custom schema for faster testing. For this submission, I used full mode and validated 30 reports total (10 per prompt). This produced an output score file, summary table, statistical test table, and a boxplot image.

The final average custom scores were: Prompt C = 4.60, Prompt A = 4.54, Prompt B = 4.50. Based on mean scores, Prompt C performed best in this run. However, the A vs B t-test returned p = 0.626, so the difference between A and B was not statistically significant. Also, ANOVA output was unstable in this run because one group had near-zero variance, which is a useful methodological finding: model-based scoring pipelines can produce compressed scores, and this can weaken inferential power. To improve this, I would increase sample size, adjust validator strictness, and run repeated trials to reduce variance artifacts.

Overall, this homework shows how to build a practical quality-control loop for AI reports: define a rubric, score outputs consistently, compare prompts with statistics, and document evidence for model/prompt selection decisions.

---

## 2) Git Repository Links

- Validation system script: [HOMEWORK3_validation_system.R](https://github.com/your-username/your-repo/blob/main/11_decision_support/HOMEWORK3_validation_system.R)
- Custom score output: [homework3_custom_scores.csv](https://github.com/your-username/your-repo/blob/main/11_decision_support/output_homework3/homework3_custom_scores.csv)
- Summary statistics: [homework3_summary_stats.csv](https://github.com/your-username/your-repo/blob/main/11_decision_support/output_homework3/homework3_summary_stats.csv)
- Statistical tests: [homework3_stat_tests.csv](https://github.com/your-username/your-repo/blob/main/11_decision_support/output_homework3/homework3_stat_tests.csv)
- Source reports dataset: [prompt_comparison_reports.csv](https://github.com/your-username/your-repo/blob/main/09_text_analysis/data/prompt_comparison_reports.csv)

---

## 3) Screenshots / Outputs to Include

Please insert 4-5 screenshots in your `.docx`:

1. Script running in terminal (`Rscript 11_decision_support/HOMEWORK3_validation_system.R`)
2. Sample validation results (rows from `homework3_custom_scores.csv`)
3. Summary table by prompt (`homework3_summary_stats.csv`)
4. Statistical test output (`homework3_stat_tests.csv`)
5. Prompt comparison figure (`homework3_prompt_boxplot.png`)

---

## 4) Documentation

### 4.1 Validation Criteria Table

| Dimension | Type | Scale / Rule | Why It Matters |
|---|---|---|---|
| evidence_use | numeric | 1-5 | Checks whether the report uses concrete numbers and data evidence |
| decision_usefulness | numeric | 1-5 | Measures actionability for policy or management decisions |
| constraint_awareness | numeric | 1-5 | Penalizes over-claims or weak uncertainty handling |
| readability | numeric | 1-5 | Evaluates clarity and accessibility for non-technical readers |
| policy_alignment | numeric | 1-5 | Tests whether recommendations match reported findings |
| pass_minimum_quality | boolean | TRUE if average >= 3.5 | Fast deployment-ready pass/fail signal |
| custom_overall | numeric | mean of 5 dimensions | Overall quality metric used for statistical comparison |

### 4.2 Experimental Design

- Prompts compared: A, B, C
- Sample size: 10 reports per prompt (30 total) in full custom-validation run
- Validator: LLM-based JSON scorer using custom rubric
- Evaluation unit: one report per score row
- Main metric: `custom_overall`

### 4.3 Statistical Analysis

- **t-test (A vs B):**
  - Mean A = 4.54
  - Mean B = 4.50
  - Mean difference = 0.04
  - p-value = 0.626 (not statistically significant)

- **ANOVA (A/B/C):**
  - Run attempted with one-way test
  - This run produced unstable ANOVA output due to low within-group variance in one prompt group
  - Practical interpretation: prompt score separation exists in means, but inferential confidence is limited in this sample

### 4.4 System Design

The system follows this pipeline:

1. Load prompt-generated reports from CSV
2. Build custom validation prompt with strict JSON schema
3. Call model (`ollama` or `openai`) for each report
4. Parse JSON into structured score columns
5. Compute `custom_overall` and pass rate
6. Run statistical tests (t-test + ANOVA)
7. Save outputs and visualization for reporting

### 4.5 Technical Details

- Main script: `11_decision_support/HOMEWORK3_validation_system.R`
- Key packages: `dplyr`, `readr`, `httr2`, `jsonlite`, `broom`, `ggplot2`, `purrr`, `tidyr`, `stringr`
- AI mode options:
  - `AI_PROVIDER = "ollama"` (local)
  - `AI_PROVIDER = "openai"` (requires `OPENAI_API_KEY` in `.env`)
- Current setting used for submission run:
  - `RUN_CUSTOM_VALIDATION = TRUE`
  - `REPORTS_PER_PROMPT = 10`

### 4.6 Usage Instructions

1. Open terminal at repo root.
2. Ensure dependencies are installed in R.
3. Start Ollama (if using local mode) and confirm model exists.
4. Run:
   - `Rscript "11_decision_support/HOMEWORK3_validation_system.R"`
5. Collect output files from:
   - `11_decision_support/output_homework3`
6. Insert links + screenshots into final `.docx`.

---

## 5) Submission Checklist

- [ ] Writing section rewritten in my own words (NOT AI-generated)
- [ ] All repository links updated and clickable
- [ ] 4-5 screenshots inserted
- [ ] Validation criteria table included
- [ ] Experiment design and statistical results included
- [ ] Final file exported/submitted as a single `.docx`

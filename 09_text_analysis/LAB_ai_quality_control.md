# 📌 LAB

## Build an AI Text Quality Control System

🕒 *Estimated Time: 30-45 minutes*

---

## 📋 Lab Overview

Create an AI-powered text quality control system that automatically evaluates AI-generated reports on multiple quality criteria. Design quality control prompts, implement quality control functions using Ollama or OpenAI, and iterate to improve quality control accuracy. This lab teaches you to automate quality control for AI-generated content.

---

## ✅ Your Tasks

### Task 1: Set Up AI Quality Control Prompt

- [ ] Open [`02_ai_quality_control.R`](02_ai_quality_control.R) or [`02_ai_quality_control.py`](02_ai_quality_control.py) and review the quality control prompt structure
- [ ] Understand the quality control criteria from the script:
  - Boolean accuracy check (TRUE/FALSE)
  - Likert scales (1–5) for: accuracy, formality, faithfulness, clarity, succinctness, relevance
- [ ] Review how the prompt is structured to request JSON output
- [ ] Note how source data can be included for accuracy checking

### Task 2: Implement Quality Control Function

- [ ] Choose your AI provider: Ollama (local) or OpenAI (cloud)
  - [ ] Set the `AI_PROVIDER` variable in the script to `"ollama"` or `"openai"`
  - If using OpenAI, ensure your API key is set in your `.env` file in the **project root** (see [`ACTIVITY_openai_api_key.md`](../03_query_ai/ACTIVITY_openai_api_key.md))
  - If using Ollama, ensure Ollama is running locally (see [`ACTIVITY_ollama_local.md`](../03_query_ai/ACTIVITY_ollama_local.md))
- [ ] Review the `query_ai_quality_control()` function to understand how it queries the AI
- [ ] Review the `parse_quality_control_results()` function to understand how JSON responses are parsed

### Task 3: Run Quality Control and Compare Results

- [ ] From the **repository root** (`dsai`), run [`02_ai_quality_control.R`](02_ai_quality_control.R) or [`02_ai_quality_control.py`](02_ai_quality_control.py) so file paths to `09_text_analysis/data/` resolve correctly
- [ ] Review the quality control results: check the boolean accuracy, Likert scale scores, and overall quality score
- [ ] Compare AI quality control results with manual quality control from [`01_manual_quality_control.R`](01_manual_quality_control.R) or [`01_manual_quality_control.py`](01_manual_quality_control.py)
- Note any differences between manual and AI quality control approaches

### Task 4: Iterate on Quality Control Prompts

- [ ] Modify the quality control prompt in `create_quality_control_prompt()` to:
  - Add more specific instructions for a particular criterion
  - Adjust the format requirements
  - Include additional quality control checks
- [ ] Test your modified prompt on the sample report
- [ ] Compare results before and after your changes
- [ ] Briefly document what worked and what did not in your prompt design

---

## 💡 Tips and Resources

- **Prompt design**: Be specific about JSON format requirements. Some models work better with explicit format instructions.
- **Model selection**: For JSON output, use models that support structured output (for example `llama3.2:latest` for Ollama, `gpt-4o-mini` for OpenAI).
- **Error handling**: If JSON parsing fails, the script extracts JSON from text responses. You may need to adjust parsing logic for your specific model.
- **Quality criteria**: The script comments describe validation-style criteria (aligned with the ideas in `samplevalidation.tex` in the original course materials). You can adapt them for your own use case.
- **Batch quality control**: The script includes a function to check multiple reports. Uncomment the batch quality control section to test it.
- **Comparing prompts statistically** (optional extension): After you have scores from several prompts, see [`ACTIVITY_statistical_comparison.md`](ACTIVITY_statistical_comparison.md) and [`03_statistical_comparison.R`](03_statistical_comparison.R) / [`03_statistical_comparison.py`](03_statistical_comparison.py).
- **Reference files**:
  - [`01_manual_quality_control.R`](01_manual_quality_control.R), [`01_manual_quality_control.py`](01_manual_quality_control.py) — manual quality control for comparison
  - [`02_ai_quality_control.R`](02_ai_quality_control.R), [`02_ai_quality_control.py`](02_ai_quality_control.py) — AI quality control implementation
  - [`../03_query_ai/02_ollama.R`](../03_query_ai/02_ollama.R) — basic Ollama query pattern
  - [`../03_query_ai/04_openai.R`](../03_query_ai/04_openai.R) — basic OpenAI query pattern
- **Integration**: This lab builds on concepts from Module 3 (AI API calls) and Module 6 (system prompts and structured outputs).

---

## 📤 To Submit

- For credit, submit:
  1. Your complete quality control script (with any modifications you made)
  2. A screenshot showing the quality control results (boolean accuracy, Likert scales, overall score)
  3. A brief explanation (3–4 sentences) describing:
     - Your prompt design choices and any modifications you made
     - How AI quality control compares to manual quality control
     - What worked well and what you would improve

---

![](../docs/prep/icons.png)

---

← 🏠 [Back to Top](#LAB)

# 📌 HOMEWORK

## Homework 2: AI Agent System with RAG and Tools

🕒 *Estimated Time: 3-4 hours*

---

## 📋 Homework Overview

Compile your work from the last 3 weeks into a complete **AI agent system** that combines multi-agent orchestration, RAG, and function calling.

This homework compiles work from:
- [`LAB_prompt_design.md`](../06_agents/LAB_prompt_design.md) - Multi-agent prompt design
- [`LAB_custom_rag_query.md`](../07_rag/LAB_custom_rag_query.md) - RAG queries
- [`LAB_multi_agent_with_tools.md`](LAB_multi_agent_with_tools.md) - Multi-agent systems with tools

**Note**: This homework compiles work from 3 weekly LABS. Each LAB represents the next step of your project. Show us your individual progress by compiling your work into a complete AI agent system.

---

## 📝 Instructions

### Who?
Individual homework assignment - 1 per team member.

### What?
Compile your work from the last 3 weeks into a complete **AI agent system** that demonstrates multi-agent orchestration, RAG integration, and function calling. **Submit a single .docx file.**

### Why?
This homework demonstrates your cumulative learning by showcasing how you've integrated prompt engineering, RAG, and tool-based interactions into a working AI system.

---

## ✅ Your Deliverable

### AI Agent System with RAG and Tools [100 pts]

Your deliverable should be a complete system that demonstrates:
- **Multi-Agent Orchestration**: A workflow with 2-3 agents working together (from LAB 1)
- **RAG Integration**: Context-aware responses using retrieval from your data source (from LAB 2)
- **Function Calling**: Agents that use tools to interact with external APIs or data sources (from LAB 3)

**Requirements:**

- [ ] **📝 [25 pts] Writing Component**: Brief written explanation of your system (NOT AI-generated)
  - Explain what your system does
  - Describe how the components work together
  - Discuss any design choices or challenges you encountered
  - Written in your own words (3+ paragraphs)

- [ ] **🔗 [25 pts] Code, as Git Repository Links**: Working, valid links to relevant content in your git repository
  - Link to your multi-agent orchestration script
  - Link to your RAG implementation
  - Link to your function calling/tool definitions
  - Link to your main system file (if different)
  - Links must be functional and point to the correct files

- [ ] **📸 [25 pts] Screenshots/Outputs**: Screenshots and/or samples of outputs
  - Screenshot showing your multi-agent workflow in action
  - Screenshot demonstrating RAG retrieval and response
  - Screenshot showing function calling/tool usage
  - At least 3-4 screenshots total

- [ ] **📚 [25 pts] Documentation**: Brief documentation for your system
  - **System Architecture**: Description of your agent roles and workflow
  - **RAG Data Source**: Description of your data source and search function
  - **Tool Functions**: Table or list describing each tool: name, purpose, parameters, and what it returns
  - **Technical Details**: Any information needed to understand your software (e.g., API keys, endpoints, packages, file structure)
  - **Usage Instructions**: How to install dependencies, set up data sources, configure API keys, and run the system. Make it easy for me!

**Total: 100 pts**

---

## 📤 To Submit

- For credit: Submit all four required components listed in the **Requirements** section above (100 pts total). **Submit a single .docx file.**

Submit via Canvas by the due date specified in the course schedule.

---

## Appendix: Submission package for this repo (`LlEeOoW/dsai`)

*Copy the sections below into your single `.docx`. Replace screenshot placeholders with your own images. The **Writing** section must be **your own words** (course rule: not AI-generated); use the outline only as a guide.*

**Base URL for links:** `https://github.com/LlEeOoW/dsai/blob/main/`

### Writing component (3+ paragraphs) — outline only

Use this structure; write each paragraph yourself:

1. **What the system does** — You built three pieces: (a) a **multi-agent** stock workflow using Alpha Vantage daily prices, (b) a **CSV RAG** over [`custom_topics.csv`](../07_rag/data/custom_topics.csv) with token matching and an Ollama answer, (c) **function calling** via an in-process FDA shortage workflow and/or an **MCP** server exposing dataset tools.
2. **How components connect** — Data flows: fetched prices → Agent 1 → Agent 2 → Agent 3; RAG: query → `search()` JSON → LLM; tools: model chooses `get_shortages` or MCP `summarize_dataset` / `filter_cars_by_mpg` → JSON or text to the client.
3. **Design choices and challenges** — Examples you can mention: small Ollama models and grounding (plain-text lines vs tables), API keys in `.env`, running Plumber from repo root, MCP `MCP_SERVER` URL.

### Git repository links (paste into Word as hyperlinks)

| Component | Link |
|-----------|------|
| Multi-agent orchestration | [06_multi_agent_lab.R](https://github.com/LlEeOoW/dsai/blob/main/06_agents/06_multi_agent_lab.R) |
| RAG implementation | [05_custom_csv_rag.R](https://github.com/LlEeOoW/dsai/blob/main/07_rag/05_custom_csv_rag.R) |
| Function calling (agents + tools) | [04_multiple_agents_with_function_calling.R](https://github.com/LlEeOoW/dsai/blob/main/08_function_calling/04_multiple_agents_with_function_calling.R) |
| MCP / tool server (optional but strong) | [plumber.R](https://github.com/LlEeOoW/dsai/blob/main/08_function_calling/mcp_plumber/plumber.R) · [testme.R](https://github.com/LlEeOoW/dsai/blob/main/08_function_calling/mcp_plumber/testme.R) |
| Helper agents | [functions.R](https://github.com/LlEeOoW/dsai/blob/main/08_function_calling/functions.R) (used by function-calling scripts) |

### Screenshots checklist (3–4+)

| # | What to capture |
|---|------------------|
| 1 | Console or terminal: multi-agent run (e.g. `Rscript 06_agents/06_multi_agent_lab.R`) showing multiple agent stages / outputs. |
| 2 | RAG: search JSON or answer text from [`05_custom_csv_rag.R`](https://github.com/LlEeOoW/dsai/blob/main/07_rag/05_custom_csv_rag.R). |
| 3 | Function calling: e.g. `Tools called: get_shortages` and Agent 2 output from [`04_multiple_agents_with_function_calling.R`](https://github.com/LlEeOoW/dsai/blob/main/08_function_calling/04_multiple_agents_with_function_calling.R). |
| 4 | Optional: MCP client test — `tools/list`, direct `filter_cars_by_mpg`, or “LLM chose tool” from [`mcp_plumber/testme.R`](https://github.com/LlEeOoW/dsai/blob/main/08_function_calling/mcp_plumber/testme.R). |

### Documentation

#### System architecture

| Stage | Role (summary) | Script |
|-------|------------------|--------|
| Multi-agent | Three Ollama agents: interpret price data → analysis → daily + 30-day narrative | [`06_agents/06_multi_agent_lab.R`](../06_agents/06_multi_agent_lab.R) |
| RAG | `search()` returns top matching rows as JSON; system prompt restricts answers to retrieved context | [`07_rag/05_custom_csv_rag.R`](../07_rag/05_custom_csv_rag.R) |
| Tools | `get_shortages` (FDA API) via `agent_run` + tool metadata; optional MCP tools on HTTP `/mcp` | [`04_multiple_agents_with_function_calling.R`](04_multiple_agents_with_function_calling.R), [`mcp_plumber/plumber.R`](mcp_plumber/plumber.R) |

#### RAG data source

| File | Description |
|------|-------------|
| [`07_rag/data/custom_topics.csv`](../07_rag/data/custom_topics.csv) | Columns: `Name`, `Category`, `Content`, `Keywords`. Short topic notes (deployment, Ollama, APIs, RAG, etc.). |

**Search function:** tokenize query, OR-match tokens against a `haystack` built from those columns; return up to 5 rows (content truncated) as JSON for the LLM.

#### Tool functions

| Name | Purpose | Parameters | Returns |
|------|---------|------------|---------|
| `get_shortages` | FDA Drug Shortages API | `category` (therapeutic class), `limit` | `tibble` of shortage rows |
| `summarize_dataset` (MCP) | Numeric summary stats | `dataset_name`: `mtcars` or `iris` | JSON string of summary table |
| `filter_cars_by_mpg` (MCP) | Filter `mtcars` by mpg | `min_mpg` (number) | JSON (up to 15 rows) |

#### Technical details

- **Ollama:** local `http://localhost:11434`; models such as `smollm2:135m`, `smollm2:1.7b` (see each script’s `MODEL`).
- **Alpha Vantage:** `API_KEY` in [`06_agents/.env`](../06_agents/.env.example) (copy to `.env`).
- **MCP (Plumber):** default `http://127.0.0.1:8000/mcp`; optional `CONNECT_API_KEY` for Connect-style auth in [`testme.R`](mcp_plumber/testme.R).
- **R packages:** `ollamar`, `httr2`, `dplyr`, `jsonlite`, `plumber`, `readr`, `stringr`, etc., per script headers.
- **Repo layout:** agents under `06_agents/`, RAG under `07_rag/`, function calling + MCP under `08_function_calling/`.

#### Usage instructions

1. Install [Ollama](https://ollama.com/) and pull the models your scripts reference.
2. **Multi-agent lab:** `cd` to `06_agents`, add `.env` with `API_KEY`, run `Rscript 06_multi_agent_lab.R` (or run from repo root with path adjusted).
3. **RAG:** ensure `07_rag/data/custom_topics.csv` exists; from repo root, `Rscript 07_rag/05_custom_csv_rag.R` (or set working directory to `07_rag` per script).
4. **Function calling:** from repo root, `Rscript 08_function_calling/04_multiple_agents_with_function_calling.R`.
5. **MCP:** `Rscript 08_function_calling/mcp_plumber/runme.R` (or `plumb()$run` / `pr_run` as in [`plumber.R`](mcp_plumber/plumber.R) comments); then `Rscript 08_function_calling/mcp_plumber/testme.R` with `MCP_SERVER` if not on port 8000.

---

![](../../docs/images/homework.png)

---

← 🏠 [Back to Top](#HOMEWORK)

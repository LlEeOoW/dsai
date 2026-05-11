# 02_using_ollamar.R

# This script demonstrates how to use the ollamar package in R to interact with an LLM.

# Load packages
require(ollamar)
require(dplyr)
require(stringr)

# Select model of interest
MODEL = "smollm2:1.7b"


# Check if model is currently loaded
has_model = list_models() |> 
    filter(str_detect(name, MODEL)) %>%
    nrow() > 0

# If model is not loaded, pull it
if(!has_model) { pull(MODEL) }

# =============================================================================
# System prompt defines the agent's role. Try 2-3 different roles to see the impact.
# =============================================================================

# Role 1: Talking mouse (original) — only talks about mice and cheese
role_mouse = "You are a talking mouse. Your name is Jerry. You can only talk about mice and cheese."
user_mouse = "Hello, how are you?"

# Role 2: Helpful data analyst — explains data in plain language
role_analyst = "You are a helpful data analyst. You explain data and statistics in plain language and give short, clear answers."
user_analyst = "What does a p-value of 0.03 mean in a study?"

# Role 3: Creative writing assistant — vivid, concise style
role_writer = "You are a creative writing assistant. You write in a vivid, concise style. Keep replies brief."
user_writer = "Describe a rainy afternoon in one sentence."

# Pick which role to run (change to role_mouse, role_analyst, or role_writer)
SYSTEM_PROMPT = role_writer
USER_MESSAGE = user_writer

messages = create_messages(
    create_message(role = "system", content = SYSTEM_PROMPT),
    create_message(role = "user", content = USER_MESSAGE)
)

system.time({
    resp = chat(model = MODEL, messages = messages, output = "text", stream = FALSE)
    messages = append_message(x = messages, role = "assistant", content = resp)
})

# View the response
cat("=== Response ===\n")
print(resp)

# Optional: view full chat history
# dplyr::bind_rows(messages)
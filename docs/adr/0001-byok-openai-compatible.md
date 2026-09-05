# BYOK on-device via OpenAI-compatible chat

The MVP must accept any model the user can pay for or get free (Chinese hosts, OpenRouter, Ollama, etc.) without NutriMezzo subsidizing tokens. The app calls an OpenAI-compatible chat endpoint from the device with the user's base URL, API key, and model id. Each Renglón is one request; the client accepts only a strict JSON Propuesta (name, macros per 100 g, assumed grams when missing). A hosted proxy or per-vendor SDK would either pin the model or explode maintenance.

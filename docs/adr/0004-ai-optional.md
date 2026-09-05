# Logging must work without a model

A missing API key, a down provider, or a bad JSON response must not block a Comida. Local Patrón matches still resolve; unmatched Renglones fall back to creating an Alimento on the confirmation screen. Making the LLM mandatory would contradict BYOK and the regex catalog. The model is an accelerator, not a lock.

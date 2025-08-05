Supported in: {% new_in 3.11 %}

```json
curl http://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": "In the heart of the city, the rain whispered secrets to the streets.",
    "voice": "<VOICE_NAME>"
  }' \
  --output speech.mp3
```

{:.info}
> **Note:** Replace `<VOICE_NAME>` with a supported voice identifier (e.g., `serene`, `vibrant`). Available voices depend on the LLM model or provider. Check your provider's documentation for the list of supported voices.
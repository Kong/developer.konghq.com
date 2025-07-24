Supported in: {% new_in 3.11 %}

```json
curl http://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": "In the heart of the city, the rain whispered secrets to the streets.",
    "voice": "serene"
  }' \
  --output speech.mp3
```
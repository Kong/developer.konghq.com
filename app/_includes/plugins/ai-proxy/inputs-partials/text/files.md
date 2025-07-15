Supported in: {% new_in 3.11 %}

```json
curl http://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F purpose="batch" \
  -F file="@mydata.jsonl"
```
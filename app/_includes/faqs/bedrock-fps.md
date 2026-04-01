Use the `extra_body` feature when sending requests in OpenAI format:

```sh
    curl http://localhost:8000 \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "amazon.nova-reel-v1:0",
        "prompt": "A large red square that is rotating",
        "extra_body": {
        "fps": 24
        }
    }'
```
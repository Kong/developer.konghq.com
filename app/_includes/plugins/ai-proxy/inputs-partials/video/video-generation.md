Supported in {% new_in 3.13 %}

```json
curl http://localhost:8000 \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "model=sora-2" \
  -F "prompt=A large red square that is rotating"
```

{:.info}
> **Note**: The following additional parameters are supported when using OpenAI request format through the `extra_body` feature:
>
> * **Bedrock**: Set the `fps` parameter for video generation.
>
> Example with Bedrock provider:
> ```bash
> curl http://localhost:8000 \
>   -H "Authorization: Bearer $OPENAI_API_KEY" \
>   -H "Content-Type: application/json" \
>   -d '{
>     "model": "amazon.nova-reel-v1:0",
>     "prompt": "A large red square that is rotating",
>     "extra_body": {
>       "fps": 24
>     }
>   }'
> ```
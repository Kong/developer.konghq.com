Supported in: {% new_in 3.11 %}

{:.info}
> This is a RESTful endpoint that supports all CRUD operations, but this preview example demonstrates only a `POST` request.

```json
curl http://localhost:8000 \
  -F purpose="batch" \
  -F file="@mydata.jsonl"
```
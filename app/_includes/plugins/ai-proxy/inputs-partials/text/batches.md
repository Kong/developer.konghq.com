Supported in: {% new_in 3.11 %}

{:.info}
> This is a RESTful endpoint that supports all CRUD operations, but this preview example demonstrates only a `POST` request.

```json
{
    "input_file_id": "file-abc123",
    "endpoint": "/v1/chat/completions",
    "completion_window": "24h"
}
```
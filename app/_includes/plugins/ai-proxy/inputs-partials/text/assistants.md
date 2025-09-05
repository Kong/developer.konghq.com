Supported in: {% new_in 3.11 %}

{:.warning}
> For **OpenAI** and **Azure Assistant APIs**, include the header `OpenAI-Beta: assistants=v2`.
>
> This is a RESTful endpoint that supports all CRUD operations, but this preview example demonstrates only a `POST` request.

```json
{
  "instructions": "You are a frontend mentor. When asked a question, write and explain JavaScript code to help the user understand key concepts.",
  "name": "Frontend Mentor",
  "tools": [{"type": "code_interpreter"}],
  "model": "gpt-4o"
}
```
Send a request through {{site.ai_gateway}} so the budget has spend to track:

<!--vale off-->
{% validation request-check %}
url: /v1/chat/completions
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    model: budget-gpt-4o
    messages:
        - role: "user"
          content: "Say this is a test!"
{% endvalidation %}
<!--vale on-->

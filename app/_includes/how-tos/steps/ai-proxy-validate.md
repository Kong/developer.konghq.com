Send a request to the route to validate.

```sh
curl -X POST http://localhost:8000/anything \
 -H 'Content-Type: application/json' \
 --data-raw '{ "messages": [ { "role": "system", "content": "You are a mathematician" }, { "role": "user", "content": "What is 1+1?"} ] }'
```
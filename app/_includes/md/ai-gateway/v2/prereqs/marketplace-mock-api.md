This tutorial uses a mock Express-based API that simulates a marketplace with users and their orders. It exposes `/marketplace/users` and `/marketplace/{userId}/orders` endpoints.

Run the following to download and start the mock API:

```sh
curl -s -o api.js "https://gist.githubusercontent.com/subnetmarco/5ddb23876f9ce7165df17f9216f75cce/raw/a44a947d69e6f597465050cc595b6abf4db2fbea/api.js"
npm install express
node api.js
```

Verify it's running:

```sh
curl -X GET http://localhost:3000
```

```text
{"name":"Sample Users API"}%
```
{:.no-copy-code}

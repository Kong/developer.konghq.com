A `portalaccesstoken` is a cookie that gets generated when a developer authenticates to Dev Portal. 
It's used only by the [Dev Portal API](/api/konnect/dev-portal/).

Unlike the {{site.konnect_short_name}} PAT, it can't be generated or managed manually, but it can expire.
You can find the `portalaccesstoken` cookie value in an outgoing request to the API after you login, or in the cookie storage section of your browser's dev tools.
If the token expires, you need to re-authenticate with Dev Portal to generate a new cookie.

When using the Dev Portal API, you need to send the `portalaccesstoken` in a cookie header with requests access any resources that require authentication.
For example, the `POST /v3/applications` endpoint requires auth, so you would access it like this:

```sh
curl -X POST https://global.api.konghq.com/v3/applications \
-H 'Content-Type: application/json' \
-H 'Cookie: portalaccesstoken=$JWT_ACCESS_TOKEN_VALUE' \
```
## Generate a token for the client

The Gateway Service requires an access token from the client to access the Service. Generate a token for the client by making a call to the issuer URL:

<!--vale off-->
{% validation request-check %}
konnect_url: $ISSUER_URL
method: POST
headers:
  - 'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: client_credentials
  client_id: $CLIENT_ID
  client_secret: $CLIENT_SECRET
  scope: my-scope
extract_body:
  - name: access_token
    variable: ACCESS_TOKEN
capture:
  - variable: ACCESS_TOKEN
    jq: ".access_token"
status_code: 200
url: /oauth/token
{% endvalidation %}
<!--vale on-->
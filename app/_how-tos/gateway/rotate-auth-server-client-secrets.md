---
title: Rotate secrets for an authorization server client
permalink: /how-to/rotate-auth-server-client-secrets/
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/
  - text: Principals and directories
    url: /identity/principals/ 
  

description: Learn how to rotate the client secrets for an authorization server client with no downtime.
products:
  - identity

works_on:
    - konnect

min_version:
  gateway: '3.15'


tags:
    - authentication

tldr:
  q: How do I rotate the secrets for an authorization server client?
  a: |
    Create a second secret for the client, validate that it works, then delete the original secret.

prereqs:
  
  inline:
    - title: Kong Identity authorization server
      icon_url: /assets/icons/identity.svg
      content: |
        Create an authorization server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer), and save the `AUTH_SERVER_ID` and `ISSUER_URL` variables:

        <!--vale off-->
        {% konnect_api_request %}
        url: /v1/auth-servers
        status_code: 201
        method: POST
        headers:
          - 'Content-Type: application/json'
        body:
          name: "Auth server example"
          description: "Auth server example"
          audience: "api://default"
        capture:
          - variable: AUTH_SERVER_ID
            jq: ".id"
          - variable: ISSUER_URL
            jq: ".issuer"
        {% endkonnect_api_request %}
        <!--vale on-->
    - title: Kong Identity authorization server client
      icon_url: /assets/icons/identity.svg
      content: |
        Create a client in the authorization server using the [`/v1/auth-servers/{authServerId}/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient), and save the `CLIENT_ID` and `CLIENT_SECRET` variables:

        <!--vale off-->
        {% konnect_api_request %}
        url: /v1/auth-servers/$AUTH_SERVER_ID/clients
        status_code: 201
        method: POST
        headers:
          - 'Content-Type: application/json'
        body:
          name: "Client"
          grant_types:
            - client_credentials
          allow_all_scopes: true
          response_types:
            - token
          token_endpoint_auth_method: client_secret_post
        capture:
          - variable: CLIENT_ID
            jq: ".id"
          - variable: CLIENT_SECRET
            jq: ".client_secret"
        {% endkonnect_api_request %}
        <!--vale on-->
---

## Validate the current secret

Before rotating, confirm the client can authenticate with its current secret by requesting a token from the authorization server's token endpoint using the client credentials grant.
A successful response returns an `access_token`:

```sh
curl -s -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET"
```

## Get the ID of the current secret

The disable and delete operations identify a secret by its ID, not its value.
List the client's secrets and store the current secret's ID as `$OLD_SECRET_ID`.
Do this before you create the new secret, while the client still has only one secret:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients/$CLIENT_ID/secrets
method: GET
status_code: 200
capture:
  - variable: OLD_SECRET_ID
    jq: ".data[0].id"
{% endkonnect_api_request %}
<!--vale on-->

## Create a new secret

Send a POST request to the `/auth-servers/{authServerId}/clients/{clientId}/secrets` endpoint with the secret value you want to use. In this example, you:

Create a new client secret with the value `new-secret` and store the value as `$NEW_SECRET`:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients/$CLIENT_ID/secrets
method: POST
status_code: 201
body:
  secret: new-secret
  enabled: true
capture:
  - variable: NEW_SECRET
    jq: ".secret"
{% endkonnect_api_request %}
<!--vale on-->

This adds a new active secret along to the existing secret. The previous secret is still active.

## Validate the new secret

Send a request with the new secret (`$NEW_SECRET`) to confirm the rotated secret authenticates before you disable the old one.
A successful response returns an `access_token`:

```sh
curl -s -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$NEW_SECRET"
```

## Delete the old secret

After you've verified the new secret works as expected, you can delete the old secret in the API by sending a DELETE request: 

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients/$CLIENT_ID/secrets/$OLD_SECRET_ID
method: DELETE
status_code: 204
{% endkonnect_api_request %}
<!--vale on-->



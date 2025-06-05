---
title: Dynamic templates
content_type: reference
layout: reference

permalink: /kong-identity/dynamic-templates/
products:
    - konnect-platform
tech_preview: true
search_aliases:
  - Kong IDP
  - Dynamic templates
breadcrumbs:
  - /konnect/
works_on:
    - konnect
api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

related_resources:
- text: Kong Identity
  url: /kong-identity/
- text: How to configure Kong Identity
  url: /kong-identity/get-started/

description: |
  Insert Templating description here

faqs:
  - q: FAQ 1
    a: |
      In the authorization code flow:
      1. The **client application** displays the user consent page and authenticates the user (this part is handled outside Kong).
      2. When the user clicks "Authorize," the client app calls the `/authorize` endpoint created by attaching the OAuth2 plugin to a service.
      3. The request includes the client ID, secret, and scopes the user consented to.
      4. The **authorization server** (Kong Gateway with OAuth2 plugin) validates the client credentials and returns an **authorization code**.
      5. The client exchanges this code at the `/accesstoken` endpoint for access tokens.
      6. The access token is used to call protected APIs.
      7. When the API call is made, the **introspection plugin** validates the token with the Identity Provider (IdP), identifies the associated consumer, and adds `x-consumer-*` headers to the upstream request.

  - q: FAQ 2
    a: |
      To retrieve your client secret, you must access the credentials stored in the service or plugin configuration. 
      If the secret was not saved securely by the client application, you may need to generate a new secret through the Kong Admin API or relevant client management interface.



---


## Dynamic Claim Templating

JWT claim values can be rendered as multiple types: strings, integers, floats, booleans and JSON object or arrays. The type is inferred from the value.

Moreover, JWT claims values can be templated with contextual data and functions. Dynamic values must use the ${ opening and } closing symbols as templating boundaries.

Claims support templating via the context passed to the client during the authentication. The context is represented by the following format:

```json
{
	"AuthServer":{
	ID:               uuid.UUID
	CreatedAt:        DateTime
	UpdatedAt:        Datetime
	Name:             string
	Description:      string
	Audience:         string
	SigningAlgorithm: string
	Labels:           map[string]string
},
"Client":{
ID:             string
	CreatedAt:      Datetime
	UpdatedAt:      Datetime
	Name:           string
	Labels: 	   map[string]string
	GrantTypes:     []string
	RedirectURIs:   []string
	LoginURI:       string
	ResponseTypes:  []string
	AllowAllScopes: bool
	AllowScopeIDs:  []string

}
}
```
### Testing
To test the templating you can use this endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$authServerId/clients/$clientId/test-claim
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  test-something: "${ \"bar\" | upper }"
  test-something-else: "${ uuidv4 }"
  context-auth-server-id: "${ .Context.AuthServer.ID }"
{% endkonnect_api_request %}
<!--vale on-->

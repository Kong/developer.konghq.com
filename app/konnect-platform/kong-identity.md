---
title: "Kong Identity"
content_type: reference
layout: reference

products:
    - konnect

permalink: /kong-identity/
works_on:
    - konnect
search_aliases:
  - Kong IdP
  - Konnect IdP
breadcrumbs:
  - /konnect/

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

related_resources:
  - text: Configure the OIDC plugin with Kong Identity
    url: /how-to/configure-kong-identity-oidc/
  - text: Configure the Upstream OAuth plugin with Kong Identity
    url: /how-to/configure-kong-identity-upstream-oauth/
  - text: Configure the OAuth 2.0 Introspection plugin with Kong Identity
    url: /how-to/configure-kong-identity-oauth-introspection/
  - text: Automatically create Dev Portal applications in Kong Identity with Dynamic Client Registration
    url: /how-to/kong-identity-dcr/
  - text: Set up Kong Event Gateway with Kong Identity OAuth
    url: /how-to/event-gateway/kong-identity-oauth/

description: |
  Kong Identity enables you to use {{site.konnect_short_name}} to generate, authenticate and authorize API access. Kong Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. 

---

{:.success}
> **Get started:**
> * [Configure the OIDC plugin with Kong Identity](/how-to/configure-kong-identity-oidc/)
> * [Configure the Upstream OAuth plugin with Kong Identity](/how-to/configure-kong-identity-upstream-oauth/)
> * [Configure the OAuth 2.0 Introspection plugin with Kong Identity](/how-to/configure-kong-identity-oauth-introspection/)
> * [Automatically create Dev Portal applications in Kong Identity with Dynamic Client Registration](/how-to/kong-identity-dcr/)

Kong Identity enables you to use {{site.konnect_short_name}} to generate, authenticate, and authorize API access. 
Specifically, Kong Identity can be used for machine-to-machine authentication. 

You can use Kong Identity to:
* Create authorization servers per region
* Issue and validate access tokens
* Integrate secure authentication into your {{site.base_gateway}} APIs 

Kong Identity implements the OAuth2.0 standard with OpenID Connect for authentication and authorization. Kong Identity can be used with the following Kong plugins:
* [OpenID Connect plugin](/plugins/openid-connect/)
* [OAuth2.0 Introspection plugin](/plugins/oauth2-introspection/)
* [Upstream OAuth plugin](/plugins/upstream-oauth/)

## How Kong Identity works

Kong Identity allows you to create auth servers, claims, scopes, and clients in {{site.konnect_short_name}} using the [{{site.konnect_short_name}} API](/api/konnect/kong-identity/v1/#/). Each of these components plays a specific role in how access is managed:
* **Auth server:** Issue OAuth 2.0 and OpenID Connect tokens that you can use to authenticate a client (machine) with your Gateway Services. Each auth server is unique to your organization and [{{site.konnect_short_name}} region](/konnect-platform/geos/). We recommend creating different auth servers for different environments or subsidiaries.
* **Clients:** Represent machines that request tokens, such as microservices, mobile apps, or automation scripts.
* **Scopes:** Define what those clients are allowed to access. 
* **Claims:** Optional pieces of metadata, like user roles or environment tags, that can be included in tokens and forwarded to upstream services.

To use Kong Identity for authentication, you must configure one of the supported plugins (OpenID Connect, OAuth2.0 Introspection, or Upstream OAuth). These plugins determine how tokens are validated, introspected, or passed along to upstream services.

## Kong Identity client credential authentication flow

The following diagram shows how authentication works with Kong Identity:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client Application
    participant idsvc as Kong Identity Service
    participant gateway as Kong Gateway
    participant api as Customer API
    client->>idsvc: request access token<br>(Client ID, Client Secret, requested scope)
    idsvc->>idsvc: validate credentials
    idsvc-->>client: access token, granted scope, expiry time
    client->>gateway: /get_protected_resource<br>(access token, granted scope)
    gateway->>idsvc: validate access token
    idsvc-->>gateway: validate access token
    gateway->>api: get_resource
    api-->>gateway: resource
    gateway-->>client: resource
{% endmermaid %}
<!--vale on-->

## Kong Identity authorization code flow

In the authorization code flow:
1. (Optional) The client application displays the user consent page and authenticates the user (this part is handled outside {{site.base_gateway}}). When the user clicks **Authorize**, the client app calls the `/authorize` endpoint created by attaching the OAuth2 plugin to a service.

   {:.info}
   > If an app requires user authentication, the authorization step must happen outside of {{site.konnect_short_name}}.
   
3. The client makes a request that includes the client ID, secret, and scopes the user consented to.
4. The authorization server ({{site.base_gateway}} with OAuth2 plugin) validates the client credentials and returns an authorization code.
5. The client exchanges this code at the `/oauth/token` endpoint for access tokens.
6. The client uses the access token to call protected APIs.

## Kong Consumer Group claim authorization flow
When using plugins scoped to Consumer Groups:
1. In **{{site.konnect_short_name}} > API Gateway > Consumers**, the client creates the Consumer. Each user that needs access is represented as a Consumer.

   {:.info}
   > If using OIDC, you don’t need to manually map credentials. The OIDC plugin automatically maps clients to Consumers based on token claims.
2. The client defines the required Consumer Groups in {{site.konnect_short_name}}, and then applies the desired plugin at the Consumer Group scope.
3. The client assigns each Consumer to the appropriate Consumer Group. Once assigned, the plugin configuration at the group level automatically applies to the Consumer.

## Dynamic claim templates

Dynamic claim templates allow you to define custom JWT claims, where the claim value is determined at the time the access token is generated. 
The value is based on contextual data and specified functions.
For example, you can use a dynamic claim template so that {{site.konnect_short_name}} populates a random UUID for the client.

You can use dynamic claim templates for both the auth server and client. 

These JWT claim values can be rendered as any of the following types:
* Strings 
* Integers
* Floats
* Booleans
* JSON object or arrays

The type is inferred from the value. 

JWT claim values can be templated with contextual data and functions. Dynamic values must use `${}` as templating boundaries. For example:
* `${ uuidv4 }` creates a UUID every time a new token is created.
* `${ .Client.Name }` includes the client's name in the token.
* `${ now | date "2006-01-02T15:04:05Z07:00" }` generates the current timestamp in ISO 8601 format.
* `${ .AuthServer.Audience }-${ .Client.ID }` concatenates the auth server's audience with the client ID.
* `${ .Client.Labels.environment | default "production" }` uses the client's environment label, defaulting to "production" if it isn't set.
* `${ upper .Client.Name }` converts the client name to uppercase.
* `${ randAlphaNum 16 }` generates a random 16-character alphanumeric string for each token.

You can use `uuidParse` and `uuidValidate` in your dynamic claim templates to parse a string as a UUID and check for a valid UUID, respectively.

To test the templating, you can use the [`/v1/auth-servers/$authServerId/clients/$clientId/test-claim` endpoint](/api/konnect/kong-identity/v1/#/operations/testClaimForClient).

### Supported contexts

Dynamic claims can use the context passed to the client during authentication in the following format:

<!--vale off-->
{% table %}
item_title: JWT context variables
columns:
  - title: Variable Name
    key: variable
  - title: Description
    key: description
  - title: Format
    key: format

rows:
  - variable: AuthServer.ID
    description: A regionally unique UUID of the auth server
    format: uuid.UUID

  - variable: AuthServer.CreatedAt
    description: The timestamp when the auth server was created
    format: DateTime

  - variable: AuthServer.UpdatedAt
    description: The timestamp when the auth server was last updated
    format: DateTime

  - variable: AuthServer.Name
    description: The name of the auth server
    format: string

  - variable: AuthServer.Description
    description: A description of the auth server
    format: string

  - variable: AuthServer.Audience
    description: The intended audience for tokens issued by this auth server
    format: string

  - variable: AuthServer.SigningAlgorithm
    description: The algorithm used to sign the JWT (for example, RS256, HS256)
    format: string

  - variable: AuthServer.Labels.key
    description: A key/value label for metadata tagging
    format: string

  - variable: Client.ID
    description: The ID of the client
    format: string

  - variable: Client.CreatedAt
    description: The timestamp when the client was created
    format: DateTime

  - variable: Client.UpdatedAt
    description: The timestamp when the client was last updated
    format: DateTime

  - variable: Client.Name
    description: The name of the client
    format: string

  - variable: Client.Labels.key
    description: A key/value label for metadata tagging
    format: string

  - variable: Client.GrantTypes[]
    description: "The grant types supported by the client (for example, `client_credentials`)"
    format: string

  - variable: Client.RedirectURIs[]
    description: Allowed redirect URIs for the client
    format: string

  - variable: Client.LoginURI
    description: Login URI for interactive flows
    format: string

  - variable: Client.ResponseTypes[]
    description: Supported OAuth response types (for example, code, token)
    format: string

  - variable: Client.AllowAllScopes
    description: Indicates if all scopes are allowed by default
    format: boolean
{% endtable %}
<!--vale on-->

### Supported functions

Dynamic claim templates support all the following functions from [sprig](https://masterminds.github.io/sprig/) in the claim templating engine:

<!--vale off -->
{% table %}
columns:
  - title: Type
    key: type
  - title: Supported functions
    key: functions
rows:
  - type: Date functions
    functions: |
      * `ago`
      * `date`
      * `dateInZone`
      * `dateModify`
      * `duration`
      * `durationRound`
      * `htmlDate`
      * `htmlDateInZone`
      * `mustDateModify`
      * `mustToDate`
      * `now`
      * `toDate`
      * `unixEpoch`
  - type: Strings
    functions: |
      * `abbrev`
      * `abbrevboth`
      * `trunc`
      * `trim`
      * `upper`
      * `lower`
      * `title`
      * `untitle`
      * `substr`
      * `repeat`
      * `trimAll`
      * `trimSuffix`
      * `trimPrefix`
      * `nospace`
      * `initials`
      * `randAlphaNum`
      * `randAlpha`
      * `randAscii`
      * `randNumeric`
      * `swapcase`
      * `shuffle`
      * `snakecase`
      * `camelcase`
      * `kebabcase`
      * `wrap`
      * `wrapWith`
      * `contains`
      * `hasPrefix`
      * `hasSuffix`
      * `quote`
      * `squote`
      * `cat`
      * `indent`
      * `nindent`
      * `replace`
      * `plural`
      * `sha1sum`
      * `sha256sum`
      * `adler32sum`
      * `toString`
      * `atoi`
      * `int64`
      * `int`
      * `float64`
      * `seq`
      * `toDecimal`
      * `split`
      * `splitList`
      * `splitn`
      * `toStrings`
      * `until`
      * `untilStep`
      * `join`
      * `sortAlpha`
  - type: Math
    functions: |
      * `add1`
      * `add`
      * `sub`
      * `div`
      * `mod`
      * `mul`
      * `randInt`
      * `add1f`
      * `addf`
      * `subf`
      * `divf`
      * `mulf`
      * `biggest`
      * `max`
      * `min`
      * `maxf`
      * `minf`
      * `ceil`
      * `floor`
      * `round`
  - type: Defaults
    functions: |
      * `default`
      * `empty`
      * `coalesce`
      * `all`
      * `any`
      * `compact`
      * `mustCompact`
      * `fromJson`
      * `toJson`
      * `toPrettyJson`
      * `toRawJson`
      * `mustFromJson`
      * `mustToJson`
      * `mustToPrettyJson`
      * `mustToRawJson`
      * `ternary`
      * `deepCopy`
      * `mustDeepCopy`
  - type: Paths
    functions: |
      * `base`
      * `dir`
      * `clean`
      * `ext`
      * `isAbs`
  - type: Encoding
    functions: |
      * `b64enc`
      * `b64dec`
      * `b32enc`
      * `b32dec`
  - type: Data Structures
    functions: |
      * `tuple`
      * `list`
      * `dict`
      * `get`
      * `set`
      * `unset`
      * `hasKey`
      * `pluck`
      * `keys`
      * `pick`
      * `omit`
      * `merge`
      * `mergeOverwrite`
      * `mustMerge`
      * `mustMergeOverwrite`
      * `values`
      * `append`
      * `mustAppend`
      * `prepend`
      * `mustPrepend`
      * `first`
      * `mustFirst`
      * `rest`
      * `mustRest`
      * `last`
      * `mustLast`
      * `initial`
      * `mustInitial`
      * `reverse`
      * `mustReverse`
      * `uniq`
      * `mustUniq`
      * `without`
      * `mustWithout`
      * `has`
      * `mustHas`
      * `slice`
      * `mustSlice`
      * `concat`
      * `dig`
      * `chunk`
      * `mustChunk`
  - type: UUIDs
    functions: |
      * `uuidv4`
  - type: URLs
    functions: |
      * `urlParse`
      * `urlJoin`
{% endtable %}
<!--vale on -->


## Configure Kong Identity

To configure Kong Identity, do the following:

{% navtabs "api-version" %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, click [**Identity**](https://cloud.konghq.com/identity/).
1. Click **New authorization server**.
1. In the **Name** field, enter a name.
1. In the **Audience** field, enter the audience.
   
   {:.info}
   > **Note:** The value in the **Audience** field is the audience that the token is intended for, like a client ID or the upstream URL of the Gateway Service for the API resource. For example, `https://api.example.com/payments` and `http://myhttpbin.dev`. If you don't have an intended audience, you can put a placeholder value, like `orders-api`, in this field.
1. Click **Create**.
1. Click **New scope**.
1. In the **Name** field, enter a name for your scope.
1. Click **Create**.
1. Navigate back to your authorization server.
1. Click **New claim**.
1. In the **Name** field, enter a name for your claim.
1. In the **Value** field, enter the value for your claim. These can also be [dynamic](#dynamic-claim-templates).
1. From the **When to include this claim in tokens** dropdown menu, select an option.
1. Click **Create**.
1. Navigate back to your authorization server.
1. Click **New client**. 
1. In the **Name** field, enter a name for your client.
1. From the **Allowed scopes** dropdown menu, select an option.
1. Click **Create**.
1. Copy and save your client ID and secret. 
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
1. Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):
<!--vale off-->
{% capture auth-server %}
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Appointments Dev"
  audience: "http://myhttpbin.dev"
  description: "Auth server for the Appointment dev environment"
{% endkonnect_api_request %}
{% endcapture %}
{{ auth-server | indent: 3 }}
<!--vale on-->
1. Export the auth server ID and issuer URL:
   ```sh
   export AUTH_SERVER_ID='YOUR-AUTH-SERVER-ID'
   export ISSUER_URL='YOUR-ISSUER-URL'
   ```
1. Configure a scope in your auth server using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):
<!--vale off-->
{% capture scope %}
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes 
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "my-scope"
  description: "Scope to test Kong Identity"
  default: false
  include_in_metadata: false
  enabled: true
{% endkonnect_api_request %}
{% endcapture %}
{{ scope | indent: 3 }}
<!--vale on-->
1. Export your scope ID:
   ```sh
   export SCOPE_ID='YOUR-SCOPE-ID'
   ```
1. Configure a custom claim using the [`/v1/auth-servers/$AUTH_SERVER_ID/claims` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClaim):
<!--vale off-->
{% capture claim %}
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims 
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "test-claim"
  value: test
  include_in_token: true
  include_in_all_scopes: false
  include_in_scopes: 
  - $SCOPE_ID
  enabled: true
{% endkonnect_api_request %}
{% endcapture %}
{{ claim | indent: 3 }}

1. Configure the client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):
<!--vale off-->
{% capture client %}
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: Client
  grant_types:
    - client_credentials
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  access_token_duration: 3600
  id_token_duration: 3600
  response_types:
    - id_token
    - token
{% endkonnect_api_request %}
{% endcapture %}
{{ client | indent: 3 }}

1. Export your client secret and client ID:
   ```sh
   export CLIENT_SECRET='YOUR-CLIENT-SECRET'
   export CLIENT_ID='YOUR-CLIENT-ID'
   ```
{% endnavtab %}
{% endnavtabs %}

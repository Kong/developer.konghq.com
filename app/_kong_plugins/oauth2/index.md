---
title: 'OAuth 2.0 Authentication'
name: 'OAuth 2.0 Authentication'

content_type: plugin

publisher: kong-inc
description: 'Add OAuth 2.0 authentication to your Services and Routes'

tags:
  - authentication
  - oauth2
search_aliases:
  - OAuth 2.0
products:
    - gateway

works_on:
    - on-prem

topologies:
  on_prem:
    - traditional

icon: oauth2.png

categories:
  - authentication

related_resources:
  - text: Enable OAuth 2.0 authentication with {{site.base_gateway}}
    url: /how-to/enable-oauth2-authentication-with-kong-gateway/
  - text: Enable OAuth 2.0 authentication for WebSocket requests with {{site.base_gateway}}
    url: /how-to/enable-oauth2-authentication-for-websocket-requests/
  - text: Configure OIDC with Kong Oauth2 token authentication
    url: /how-to/configure-oidc-with-kong-oauth2/
  - text: "{{site.base_gateway}} authentication"
    url: /gateway/authentication/

notes: |
  This plugin can't be used in Konnect, hybrid, or DB-less modes. It needs to
  generate and delete tokens, and commit those changes to a database on the
  same node.

min_version:
  gateway: '1.0'
---

Add an [OAuth 2.0](https://oauth.net/2/) authentication layer with one of the following grant flows:
* [Authorization Code Grant](https://tools.ietf.org/html/rfc6749#section-4.1)
* [Client Credentials](https://tools.ietf.org/html/rfc6749#section-4.4)
* [Implicit Grant](https://tools.ietf.org/html/rfc6749#section-4.2)
* [Resource Owner Password Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.3) 

{:.warning}
> **Important**: 
* Once this plugin is applied, any user with a valid credential can access the Gateway Service.
  To restrict usage to only some of the authenticated users, also add the
  [ACL](/plugins/acl/) plugin (not covered here) and create allowed or
  denied groups of users.
* As per the OAuth2 specs, this plugin requires the
  underlying Service to be served over HTTPS. To avoid any
  confusion, we recommend that you configure the Route used to serve the
  underlying Service to only accept HTTPS traffic (using its `protocols`
  property).

## Upstream headers

{% include_cached /plugins/upstream-headers.md name=page.name %}

## OAuth 2.0 flows

The OAuth2 plugin can run in one of two flows: client credentials or authorization code.
### Client credentials

The [client credentials](https://tools.ietf.org/html/rfc6749#section-4.4) flow works out of the box, without building any authorization page.
The clients need to use the `/oauth2/token` endpoint to request an access token. For more details, see [Enable OAuth 2.0 authentication with {{site.base_gateway}}](/how-to/enable-oauth2-authentication-with-kong-gateway/).

### Authorization code

The authorization code flow requires a few extra setup steps. 
After provisioning Consumers and associating OAuth 2.0 credentials to them, you must also:
* Implement an authorization page on your web application.
* Provide internal documentation on how to consume your OAuth 2.0 protected services, so that developers accessing your Service know how to build their client implementations.

#### How the Authorization Code flow works

Building the authorization page is the primary task that the plugin itself can't do out of the box, because it requires checking that the user is properly logged in, and this operation is strongly tied with your authentication implementation.

The authorization page is made up of two parts:
* The frontend page that the user sees, and that allows them to authorize the client application to access their data.
* The backend that processes the HTML form displayed in the frontend. This backend connects with the OAuth 2.0 plugin in {{site.base_gateway}} and redirects the user to a third party URL.

You can see a sample implementation in [node.js + express.js](https://github.com/Kong/kong-oauth2-hello-world) on GitHub.

<!-- @TODO 
  add a mermaid diagram based on /assets/images/gateway/oauth2-authorization-code-flow.png, 
  maybe adapt this diagram: https://kongdeveloper.netlify.app/plugins/openid-connect/#kong-oauth-token-auth-flow and add the webapp -->

Here's how it works:

1. The client application redirects the end user to the authorization page on your web application, passing `client_id`, `response_type`, and `scope` (if required) as query string parameters.

1. The web application ensures that the user is logged in, then shows the authorization page.

1. The client application sends the `client_id` in the query string, from which the web application can retrieve both the OAuth 2.0 application name and developer name, by making the following request to {{site.base_gateway}}:
   ```bash
   curl localhost:8001/oauth2?client_id=$CLIENT_ID
   ```

1. If the end user authorizes the application, the form submits the data to your backend with a `POST` request, sending the `client_id`, `response_type`, and `scope` parameters that were placed in `<input type="hidden" .. />` fields.

1. The backend makes a `POST` request to {{site.base_gateway}} at your Service address, on the `/oauth2/authorize` endpoint, with the `provision_key`, `authenticated_userid`, `client_id`, `response_type`, and `scope` parameters. If an `Authorization` header was sent by the client, that must be added too. For example:
   ```bash
   curl https://$SERVICE.com/oauth2/authorize \
     --header "Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW" \
     --data "client_id=$CLIENT_ID" \
     --data "response_type=$RESPONSE_TYPE" \
     --data "scope=$SCOPE" \
     --data "provision_key=$PROVISION_KEY" \
     --data "authenticated_userid=$USER_ID"
   ```

   The `provision_key` is the key the plugin generates when it's added to the Service. `authenticated_userid` is the ID of the logged-in end user who grants the permission.

1. {{site.base_gateway}} responds with a JSON response:

   ```json
   {
     "redirect_uri": "http://some/url"
   }
   ```

   The response can be either a `200 OK` or `400 Bad Request`.
1. In both cases, {{site.base_gateway}} ignores the response status code and redirects the user to whatever URI is being returned in the `redirect_uri` property.

1. The client application takes it from here, and continues the flow with {{site.base_gateway}} with no other interaction with your web application. For example, if it's an Authorization Code Grant flow, the client app might exchange the authorization code for an access token.

1. After retrieving the access token,, the client application makes requests on behalf of the user to your upstream service.

1. Access tokens can expire, and when that happens the client application needs to renew the access token with {{site.base_gateway}} and retrieve a new one.

In this flow, the steps that you need to implement are:
* The login page (step 2)
* The Authorization page, with its backend that simply collects the values, makes a `POST` request to {{site.base_gateway}}, and redirects the user to whatever URL {{site.base_gateway}} has returned (steps 3 to 7)

## gRPC requests

OAuth2 access tokens can be used by gRPC applications:
```bash
grpcurl -H 'authorization: bearer $TOKEN' ...
```

The rest of the credentials flow uses HTTPS and not gRPC. Depending on your application, you may have to configure the `oauth2` plugin on two separate Routes: one under `protocols: ["https"]` and another under `protocols: ["grpcs"]`.

## WebSocket requests

This plugin can't issue new tokens from a WebSocket Route, because the request
will be rejected as an invalid WebSocket handshake. 
To use this plugin with WebSocket services, you must configure an additional, non-WebSocket Route to issue tokens. 
For more details, see [Enable OAuth 2.0 authentication for WebSocket requests with {{site.base_gateway}}](/how-to/enable-oauth2-authentication-for-websocket-requests/).

## Resource owner password credentials (legacy systems only)

{:.warning}
 > **Important**: The OAuth2 Security Best Practice explicitly mentions that Resource Owner Password Credentials
  ["MUST NOT BE USED"](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics-13#section-3.4).
  The following section is left here as a reference for supporting legacy systems.


The [Resource Owner Password Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.3) is a much simpler version of the Authorization Code flow, but it still requires to build an authorization backend (without the frontend) to make it work properly.

1. On the first request, the client application makes a request with some OAuth2 parameters to your web application.

2. The backend of your web application adds the `provision_key` and `grant_type` parameters to the parameters originally sent by the client, then makes a `POST` request to {{site.base_gateway}} using the `/oauth2/token` endpoint of the configured plugin. If an `Authorization` header is sent by the client, that must be added too. For example:

    ```bash
    curl https://$SERVICE.com/oauth2/token \
      --header "Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW" \
      --data "client_id=$CLIENT_ID" \
      --data "client_secret=$CLIENT_SECRET" \
      --data "grant_type=password" \
      --data "scope=$SCOPE" \
      --data "provision_key=$PROVISION_KEY" \
      --data "authenticated_userid=$USER_ID" \
      --data "username=$USERNAME" \
      --data "password=$PASSWORD"
    ```

    The `provision_key` is the key the plugin has generated when it has been added to the Service, while `authenticated_userid` is the ID of the end user whose `username` and `password` belong to.

3. {{site.base_gateway}} responds with a JSON response.

4. The JSON response sent by {{site.base_gateway}} must be sent back to the original client as it is. If the operation is successful, this response includes an access token, otherwise it returns an error.

In this flow, the step that you need to implement is the backend endpoint that processes the original request and authenticates the `username` and `password` values sent by the client.
If the authentication is successful, this endpoint makes the request to {{site.base_gateway}} and returns the response that {{site.base_gateway}} sends back to the client.


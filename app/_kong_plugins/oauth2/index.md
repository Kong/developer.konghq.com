---
title: 'OAuth 2.0 Authentication'
name: 'OAuth 2.0 Authentication'

content_type: plugin

publisher: kong-inc
description: 'Add OAuth 2.0 authentication to your Services and Routes'


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

When a client has been authenticated and authorized, the plugin will append some headers to the request before proxying it to the upstream Service, so that you can identify the Consumer and the end-user in your code:

* `X-Consumer-ID`: The ID of the Consumer in {{site.base_gateway}}.
* `X-Consumer-Custom-ID`: The `custom_id` of the Consumer (if set).
* `X-Consumer-Username`: The `username` of the Consumer (if set).
* `X-Credential-Identifier`, the `client_id` of the credential (if set), representing the client and the credential associated.
* `X-Authenticated-Scope`: The comma-separated list of scopes that the end user has authenticated, if available (only if the Consumer is not the 'anonymous' Consumer)
* `X-Authenticated-Userid`: The logged-in user ID who has granted permission to the client (only if the Consumer is not the 'anonymous' Consumer)
* `X-Anonymous-Consumer`: Is set to `true` if authentication fails, and the `anonymous` Consumer is set instead.

You can use this information on your side to implement additional logic.
You can use the `X-Consumer-ID` value to query the Admin API and retrieve
more information about the Consumer.

## OAuth 2.0 flows

### Client Credentials

The [Client Credentials](https://tools.ietf.org/html/rfc6749#section-4.4) flow works out of the box, without building any authorization page.
The clients need to use the `/oauth2/token` endpoint to request an access token. For more details, see [Enable OAuth 2.0 authentication with {{site.base_gateway}}](/how-to/enable-oauth2-authentication-with-kong-gateway/).

### Authorization Code

After provisioning Consumers and associating OAuth 2.0 credentials to them, it's' important to understand how the OAuth 2.0 authorization flow works. As opposed to most of the {{site.base_gateway}} plugins, the OAuth 2.0 plugin requires some additional work on your side to make everything work well:
* You **must** implement an authorization page on your web application.
* You may need to explain document how to consume your OAuth 2.0 protected services, so that developers accessing your Service know how to build their client implementations.

#### The flow explained

Building the authorization page is going to be the primary task that the plugin itself can't do out of the box, because it requires checking that the user is properly logged in, and this operation is strongly tied with your authentication implementation.

The authorization page is made of two parts:
* The frontend page that the user will see, and that will allow them to authorize the client application to access their data.
* The backend that will process the HTML form displayed in the frontend, that will talk with the OAuth 2.0 plugin on {{site.base_gateway}}, and that will redirect the user to a third party URL.

You can see a sample implementation in [node.js + express.js](https://github.com/Kong/kong-oauth2-hello-world) on GitHub.

![Diagram representing the Authorization Code flow](/assets/images/gateway/oauth2-authorization-code-flow.png)
<!-- @TODO replace this with a mermaid diagram -->

Here's how it works:

1. The client application redirects the end user to the authorization page on your web application, passing `client_id`, `response_type` and `scope` (if required) as query string parameters.

1. The web application ensures that the user is logged in, then shows the authorization page.

1. The client application sends the `client_id` in the query string, from which the web application can retrieve both the OAuth 2.0 application name and developer name, by making the following request to {{site.base_gateway}}:
   ```bash
   curl localhost:8001/oauth2?client_id=XXX
   ```

1. If the end user authorizes the application, the form submits the data to your backend with a `POST` request, sending the `client_id`, `response_type` and `scope` parameters that were placed in `<input type="hidden" .. />` fields.

1. The backend makes a `POST` request to {{site.base_gateway}} at your Service address, on the `/oauth2/authorize` endpoint, with the `provision_key`, `authenticated_userid`, `client_id`, `response_type`, and `scope` parameters. If an `Authorization` header was sent by the client, that must be added too. For example:
   ```bash
   curl https://your.service.com/oauth2/authorize \
     --header "Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW" \
     --data "client_id=XXX" \
     --data "response_type=XXX" \
     --data "scope=XXX" \
     --data "provision_key=XXX" \
     --data "authenticated_userid=XXX"
   ```

   The `provision_key` is the key the plugin generates when it's added to the Service. `authenticated_userid` is the ID of the logged-in end user who grants the permission.

1. {{site.base_gateway}} responds with a JSON response:

   ```json
   {
     "redirect_uri": "http://some/url"
   }
   ```

   The response can be either a `200 OK` or `400 Bad Request`.
1. In both cases, ignore the response status code and just redirect the user to whatever URI is being returned in the `redirect_uri` property.

1. The client application takes it from here, and continues the flow with {{site.base_gateway}} with no other interaction with your web application. Like exchanging the authorization code for an access token if it's an Authorization Code Grant flow.

1. Once the Access Token is retrieved, the client application makes requests on behalf of the user to your upstream service.

1. Access Tokens can expire, and when that happens the client application needs to renew the Access Token with {{site.base_gateway}} and retrieve a new one.

In this flow, the steps that you need to implement are:
* The login page (step 2)
* The Authorization page, with its backend that simply collects the values, makes a `POST` request to {{site.base_gateway}} and redirects the user to whatever URL {{site.base_gateway}} has returned (steps 3 to 7)

## gRPC requests

The same access tokens can be used by gRPC applications:
```bash
grpcurl -H 'authorization: bearer XXX' ...
```

Note that the rest of the credentials flow uses HTTPS and not gRPC. Depending on your application, you may have to configure the `oauth2` plugin on two separate Routes: one under `protocols: ["https"]` and another under `protocols: ["grpcs"]`.

## WebSocket requests

This plugin can't issue new tokens from a WebSocket Route, because the request
will be rejected as an invalid WebSocket handshake. Therefore, to use this
plugin with WebSocket services, an additional non-WebSocket Route must be used
to issue tokens. For more details, see [Enable OAuth 2.0 authentication for WebSocket requests with {{site.base_gateway}}](/how-to/enable-oauth2-authentication-for-websocket-requests/)

## Resource owner password credentials (legacy systems only)

{:.warning}
 > **Important**: The OAuth2 Security Best Practice explicitly mentions that Resource Owner Password Credentials
  ["MUST NOT BE USED"](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics-13#section-3.4).
  The following section is left here as a reference for supporting legacy systems.


The [Resource Owner Password Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.3) is a much simpler version of the Authorization Code flow, but it still requires to build an authorization backend (without the frontend) in order to make it work properly.

1. On the first request, the client application makes a request with some OAuth2 parameters to your web application.

2. The backend of your web application adds the `provision_key` and `grant_type` parameters to the parameters originally sent by the client, then makes a `POST` request to {{site.base_gateway}} using the `/oauth2/token` endpoint of the configured plugin. If an `Authorization` header is sent by the client, that must be added too. For example:

    ```bash
    curl https://your.service.com/oauth2/token \
      --header "Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW" \
      --data "client_id=XXX" \
      --data "client_secret=XXX" \
      --data "grant_type=password" \
      --data "scope=XXX" \
      --data "provision_key=XXX" \
      --data "authenticated_userid=XXX" \
      --data "username=XXX" \
      --data "password=XXX"
    ```

    The `provision_key` is the key the plugin has generated when it has been added to the Service, while `authenticated_userid` is the ID of the end user whose `username` and `password` belong to.

3. {{site.base_gateway}} will respond with a JSON response

4. The JSON response sent by {{site.base_gateway}} must be sent back to the original client as it is. If the operation is successful, this response will include an access token, otherwise it will include an error.

In this flow, the steps that you need to implement are:

* The backend endpoint that will process the original request and will authenticate the `username` and `password` values sent by the client, and if the authentication is successful, make the request to {{site.base_gateway}} and return back to the client whatever response {{site.base_gateway}} has sent back.


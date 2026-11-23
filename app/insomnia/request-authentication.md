---
title: Request authentication reference

content_type: reference
layout: reference
description: Learn what request authentication is and how to authenticate requests in {{ site.insomnia }}.

related_resources:
  - text: Authentication and authorization
    url: /insomnia/authentication-authorization/

tags:
    - test-apis
    - authentication

products:
    - insomnia

breadcrumbs:
  - /insomnia/
  - /insomnia/authentication-authorization/

faqs:
  - q: What should I do if I see SSL certificate errors in {{ site.insomnia }}?
    a: |
      If you encounter errors like:
      ```
      Error: unable to verify the first certificate
      ```
      or
      ```
      Error: Hostname/IP doesn't match certificate's altnames
      ```
      This likely means you're using an invalid or self-signed certificate, which is a common issue with local development servers.

      To bypass this, go to **Settings** and disable the **Validate SSL Certificates** option.

---

Some requests require authentication to ensure that the client requests access data securely. In {{ site.insomnia }}, you can configure different authentication types and parameters when you send a request so that it can authenticate. 

The {{ site.insomnia }} UI provides a simplified configuration for request authentication. It pre-populates the parameters when you select an auth type so you only have to fill in the values. 

## How do I configure authentication in my requests in {{ site.insomnia }}? 

Navigate to a request in a collection, click the **Auth** tab below your request, and select an authentication type from the dropdown menu.

![Image of all the available request auth types in {{ site.insomnia }}](/assets/images/insomnia/request-auth.png)

## How do I share settings across requests?

{% new_in 13.5 %} Set authentication, headers, and scripts once on the API Collection or on a folder, and every request inside uses them. On the API Collection screen, use the **Auth**, **Headers**, and **Scripts** tabs. For a folder, select it in the sidebar. To use inherited authentication, set the request's authentication type to **Inherit from parent**.

### How inheritance works

{{ site.insomnia }} applies settings from the API Collection, then from each folder (outermost first), then from the request:

* **Authentication:** The closest level that sets authentication wins. A request's own type, including **None**, overrides inheritance. Requests that inherit OAuth 2.0 share the token stored on the level that owns the configuration.
* **Headers:** {{ site.insomnia }} combines headers from every level. When several levels set the same header, it joins the values with a comma. The exception is single-value headers such as `Authorization`, `Content-Type`, and `Host`, where the closest level wins.
* **Scripts:** Pre-request and after-response scripts run in the same order: API Collection, then folders, then request.

## Which authentication types are supported?

The following authentication types are supported for request authentication in {{ site.insomnia }}:
* [Basic auth](https://datatracker.ietf.org/doc/html/rfc7617.html)
* [Digest auth](https://datatracker.ietf.org/doc/html/rfc7616)
* [OAuth 1.0](https://datatracker.ietf.org/doc/html/rfc5849)
* [OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749)
* [Microsoft NTLM](https://learn.microsoft.com/en-us/windows-server/security/kerberos/ntlm-overview)
* [AWS IAM v4](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html)
* [Bearer token](https://swagger.io/docs/specification/v3_0/authentication/bearer-authentication/)
* [HawK](https://github.com/mozilla/hawk)
* [Atlassian ASAP](https://s2sauth.bitbucket.io/spec/)
* [Netrc file](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html)

## How does request authentication work?

Request authentication requires the client to validate their identity in some way before they can access the resources from the server.

The following diagram shows how [basic auth](https://datatracker.ietf.org/doc/html/rfc7617.html) works when it's required as part of request authentication:
{% mermaid %}
sequenceDiagram
    participant Client
    participant Server
    Client->>Server: Requests a protected resource
    Server->>Client: Requests username and password
    alt If correct credentials sent
        Client->>Server: Sends username and password
        Server->>Client: Returns requested resource
    else If wrong credentials sent
        Client->>Server: Sends wrong username and password
        Server->>Client: Returns 401 Unauthorized status code
    end
{% endmermaid %}
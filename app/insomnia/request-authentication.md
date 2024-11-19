---
title: Request authentication reference

content_type: reference
layout: reference

related_resources:
  - text: Authentication & Authorization in Insomnia
    url: /insomnia/authentication-authorization

tags:
    - requests
    - testing
    - authentication
    - beginner

products:
    - insomnia

breadcrumbs:
  - /insomnia/
---

## What is request authentication in Insomnia?

Some requests require authentication to ensure that the client requests access data securely. In Insomnia, you can configure different authentication types and parameters when you send a request so that it can authenticate. 

The Insomnia UI provides a simplified configuration for request authentication. It prepopulates the parameters when you select an auth type so you only have to fill in the values. 

## How do I configure authentication in my requests in Insomnia? 

Navigate to a request in a collection, click the **Auth** tab below your request, and select an authentication type from the dropdown menu.

![Image of all the available request auth types in Insomnia](/assets/images/insomnia/request-auth.png)

## Which authentication types are supported?

The following authentication types are supported for request authentication in Insomnia:
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
    alt Correct credentials sent
        Client->>Server: Sends username and password
        Server->>Client: Returns requested resource
    else Wrong credentials sent
        Client->>Server: Sends wrong username and password
        Server->>Client: Returns 401 Unauthorized status code
    end
{% endmermaid %}
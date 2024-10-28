---
title: Request authentication reference

content_type: reference
layout: reference

related_resources:
  - text: Authentication & Authorization in Insomnia
    url: /insomnia/authentication-authorization
  - text: Testing in Insomnia
    url: /insomnia/test

tags:
    - requests
    - testing
    - authentication

products:
    - insomnia

breadcrumbs:
  - /insomnia/
---

## What is request authentication in Insomnia?

Some requests require authentication. In Insomnia, you can configure different authentication types and parameters when you send a request so that it can authenticate.

## How do I configure authentication in my requests in Insomnia? 

Navigate to a request in a collection, click the **Auth** tab below your request, and select an authentication type from the dropdown menu.

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
---
title: "{{site.base_gateway}}: Auth0 IDP returns invalid bearer token when using with consumer claim"
content_type: support
description: This happens specifically with Auth0 when there is no audience specified with the OIDC configuration.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Auth0 return an invalid bearer token that fails the OIDC plugin's consumer claim mapping?
  a: |
    Auth0 omits the expected claim (e.g. `azp`) from the token when no `audience` is specified in the OIDC configuration. Set the `audience` field in the OIDC plugin to the application's API identifier from Auth0 so the IdP issues a token with the claim needed for consumer mapping.
related_resources: []
---

## Problem

OIDC logs show this error:

```

2024/02/29 23:43:05 [notice] 2397#0: *128795 [lua] responses.lua:24: [openid-connect] kong consumer was not found (claim (azp) was not found for consumer mapping), client: 172.17.0.1, server: kong, request: "GET /new?code=fNoCoi60sMzlUGq6ISsavJoZzA0-QQUKlHPuYqzeQWgLk&state=vSCOSePIItmEK-qSdefWeMQ9 HTTP/1.1", host: "localhost:8000", request_id: "ed621d4370bad6319cf058330812184e"
```

The bearer token returned by the IDP is invalid when decoded:

```

eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIiwiaXNzIjoiaHR0cHM6Ly9kZXYtanhvZm9ydjdqY2FnMWt3by51cy5hdXRoMC5jb20vIn0..QvcoFJl3EGkMvAJr.x2mQPwSQHg7aJWRqYu8oydMKyfLaT0NZ6jKEGp8HIB0x0amIM4OqbNiviF_LR2MYX5e0uWYPtVyTs5THFP-8bvBRV98lUHNBqoTPNsMo3b9uLWOOzByr7_mrZHlXTEHY-tprio56igFtmHE_WJ0LnHlIfBx855Ro1ul6OvY5-LOSefYU8lTF9tcnIG49q6WWiUy65heZrX8tOOrGiejd2fdCv37-Pn4H2kynsLo-l_eWI19qIkd4y7vVoouxQU60VvD0urSHXw1VWXxv882k1NvHaELmm8tLsvl1OOUXshRIAAV7v3g5S5pyp2NAvD5pXCt13g.yo6tr-ftGFZlRjBjobLsew
```

Decoding the token

## Solution

This happens specifically with Auth0 when there is no audience specified with the OIDC configuration. Audience value is taken from the IDP.

Navigate to the application in the IDP and click on the API tab. We will find the identifier defined for this application. The identifier has to be added to the OIDC plugin under the `Audience` field.

IDP:

Kong OIDC Plugin config:

Once this is added, we can see that the IDP returns proper token as shown below and the error with consumer claims is resolved as well.

Valid token:

```

eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlFianJNOXhUa2NSLU9EMTdrdFhjRSJ9.eyJpc3MiOiJodHRwczovL2Rldi1qeG9mb3J2N2pjYWcxa3dvLnVzLmF1dGgwLmNvbS8iLCJzdWIiOiJhdXRoMHw2NWQzYmI4ZDFmNDk3OTNlYzlkMWViOGIiLCJhdWQiOlsiaHR0cDovL2tvbmcuZXhhbXBsZS5jb20iLCJodHRwczovL2Rldi1qeG9mb3J2N2pjYWcxa3dvLnVzLmF1dGgwLmNvbS91c2VyaW5mbyJdLCJpYXQiOjE3MDkyNTA0OTUsImV4cCI6MTcwOTMzNjg5NSwiYXpwIjoiRjZYU3dLa0RkaWtZamZuT1BQaWhieDA1dzdLYWkzWTEiLCJzY29wZSI6Im9wZW5pZCJ9.XmBE2G1tn9QBWR-Qan9POhznoBfI1U-BLDkOtbAKc7cEbYcAytd5WzMXnZcEZ15HOClf-mfG-oplo8E4Znfo0xSDCvj-t_KoinFQcaIHOq1vg0WEMnEm2ahwnc0oFsIsGEtyxcvYY7k6pmjD2LMnIW5pUuTZZg-srM30dNIaRpGoc6v7OIuRi1UqkA0VuFUXNtU8UqbXoLG2LD5mS9qyAerQVjE6vsvyLenWgJPRBg5b2oT3ReFnaRXFXUJqf8Rq63q9zGVPkmofEEn2JRTgwto4tJelfPpBEJWNSvm1mBSwht2oozV3fw3Y_cNAL0tj1g0mhMjwof0EJnVwGJ6wgg
```

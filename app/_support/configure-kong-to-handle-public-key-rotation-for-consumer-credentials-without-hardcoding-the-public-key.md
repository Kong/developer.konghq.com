---
title: Configure Kong to handle public key rotation for consumer credentials without hardcoding the public key
content_type: support
description: The JWT plugin in Kong requires the public key to be uploaded for JWT validation.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure Kong to handle public key rotation for consumer credentials without hardcoding the public key?
  a: |
    The JWT plugin requires the public key to be uploaded and does not support automatic key rotation. Use the OpenID Connect plugin instead: set `config.issuer` to your IdP's discovery endpoint so the plugin auto-configures from the JWKS URI and rotates keys automatically. Tune `config.rediscovery_lifetime` to control how often the JWKS is re-fetched.
related_resources: []
---

## Problem

The JWT plugin in Kong requires the public key to be uploaded for JWT validation, but this approach does not support automatic key rotation for consumer credentials.

## Solution

To handle key rotation without hardcoding the public key, you can use the OpenID Connect plugin, which supports JWKS URIs and can automatically handle key rotation.

Here are the steps to configure the OpenID Connect plugin to use JWKS URIs:

1. Configure the OpenID Connect plugin with the `config.issuer` parameter set to your Identity Provider's (IdP) discovery endpoint. This allows the plugin to auto-configure most settings and handle key rotation.

   ```json
   {
       "config.issuer": "https://<your-idp>/path/to/.well-known/openid-configuration"
   }
   ```

2. Set the `config.rediscovery_lifetime` to specify how often the plugin should re-discover the JWKS (in seconds). This is useful when the plugin cannot find a key for verifying the signature.

   ```json
   {
       "config.rediscovery_lifetime": 30
   }
   ```

3. Use `config.extra_jwks_uris` if you have additional JWKS URIs to specify.

   ```json
   {
       "config.extra_jwks_uris": ["https://<your-idp>/path/to/jwks.json"]
   }
   ```

4. Test the JWKS retrieval using the OpenID Connect plugin's JWKS retrieval API call to ensure that the JWKS URI is correctly set up.

5. Check for caching behavior. When using Kong with a database, the discovery information and the JWKS are cached in the Kong configuration database. The plugin will re-discover upon failure to find the key.

6. Monitor for any authentication issues such as 401 Unauthorized errors, which may indicate a problem with the JWKS URI or the token validation process.

7. Review the debug logs if you encounter issues. The logs can provide additional information about the failure, such as signature verification problems.

8. Ensure that the `config.issuers_allowed` parameter is correctly configured if you are using it to restrict which issuers are allowed.

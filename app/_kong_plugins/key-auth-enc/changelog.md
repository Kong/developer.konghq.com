---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.8.x
* Added WWW-Authenticate headers to all 401 responses.

### {{site.base_gateway}} 3.0.x
* The deprecated `X-Credential-Username` header has been removed.

### {{site.base_gateway}} 2.7.x
* If keyring encryption is enabled
and you are using key authentication, the `keyauth_credentials.key` field will
be encrypted.
---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.10.x
* Fixed an issue where binary string was truncated at the first null character.

### {{site.base_gateway}} 3.8.x
* This plugin now supports decoding an empty sequence or set represented in long form length.
* Added WWW-Authenticate headers to all 401 responses.

### {{site.base_gateway}} 3.7.x
* Fixed an issue where, if the credential was encoded with no username, {{site.base_gateway}} threw an error and returned a 500 code.
* Fixed an issue where an exception would be thrown when LDAP search failed.

### {{site.base_gateway}} 3.6.x
* Added support for consumer group scoping by using the PDK `kong.client.authenticate` function.
* Fixed some cache-related issues which caused `groups_required` to return unexpected codes after a non-200 response.

### {{site.base_gateway}} 3.0.x
* Added the `groups_required` parameter.
* The deprecated `X-Credential-Username` header has been removed.
* The character `.` is now allowed in group attributes.
* The character `:` is now allowed in the password field.

### {{site.base_gateway}} 2.8.x

* The `ldap_password` and `bind_dn` configuration fields are now marked as
referenceable, which means they can be securely stored as
[secrets](/gateway/secrets-management/)
in a Vault. References must follow a specific format.

### {{site.base_gateway}} 2.7.x

* Starting with {{site.base_gateway}} 2.7.0.0, if keyring encryption is enabled,
 the `config.ldap_password` parameter value will be encrypted.

### {{site.base_gateway}} 2.3.x

* Added the parameter `log_search_results`, which lets the plugin display all the LDAP search results received from the LDAP server.
* Added new debug log statements for authenticated groups.

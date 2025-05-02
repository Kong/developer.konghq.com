---
content_type: reference

---

## Changelog

### {{site.base_gateway}} 3.10.x

* Added support for sending messages to multiple topics with `topics_query_arg`, and enabled topic allowlisting with `allowed_topics`.
* Added support for message manipulation with the new configuration field `message_by_lua_functions`.

### {{site.base_gateway}} 2.8.x

* Added support for the `SCRAM-SHA-512` authentication mechanism.

* Added the `cluster_name` configuration parameter.

* The `authentication.user` and `authentication.password` configuration fields are now marked as
referenceable, which means they can be securely stored as
[secrets](/gateway/secrets-management/)
in a vault. References must follow a [specific format](/gateway/secrets-management/).

### {{site.base_gateway}} 2.7.x

* Starting with {{site.base_gateway}} 2.7.0.0, if keyring encryption is enabled,
 the `config.authentication.user` and `config.authentication.password` parameter
 values will be encrypted.

   {:.warning}
   > There's a bug in {{site.base_gateway}} that prevents keyring encryption
   from working on deeply nested fields. As a result, the `encrypted=true` setting has no effect in this plugin at this time.

### {{site.base_gateway}} 2.6.x
*  The Kafka Log plugin now supports TLS, mTLS, and SASL auth.
SASL auth includes support for PLAIN, SCRAM-SHA-256, and delegation tokens.
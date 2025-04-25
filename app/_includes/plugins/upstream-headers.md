<!--used in the following plugins: Header Cert Auth, HMAC Auth, LDAP Auth, Key Auth Encrypted-->
When a client has been authenticated, the plugin appends some headers to
the request before proxying it to the upstream service, so that you
can identify the Consumer in your code:

* `X-Consumer-ID`: The ID of the Consumer in {{site.base_gateway}}.
* `X-Consumer-Custom-ID`: The `custom_id` of the Consumer (if set).
* `X-Consumer-Username`: The `username` of the Consumer (if set).
* `X-Credential-Identifier`: The identifier of the credential (only if the Consumer is not the `anonymous` Consumer).
* `X-Anonymous-Consumer`: Is set to `true` if authentication fails, and the `anonymous` Consumer is set instead.
{% if include.name == "OAuth 2.0 Authentication" %}
* `X-Authenticated-Scope`: The comma-separated list of scopes that the end user has authenticated, if available (only if the Consumer is not the 'anonymous' Consumer).
* `X-Authenticated-Userid`: The logged-in user ID who has granted permission to the client (only if the Consumer is not the 'anonymous' Consumer).
{% endif %}

You can use this information on your side to implement additional logic.
You can use the `X-Consumer-ID` value to query the Admin API and retrieve
more information about the Consumer.


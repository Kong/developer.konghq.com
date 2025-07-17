Sometimes, you might not want to use automatic Consumer lookup, or you have certificates
that contain a field value not directly associated with Consumer objects. In those
situations, you can manually assign one or more subject names to the [Consumer entity](/gateway/entities/consumer/) for
identifying the correct Consumer.

{:.info}
> **Note**: Subject names refer to the certificate's Subject Alternative Names (SAN) or
Common Name (CN). CN is only used if the SAN extension does not exist.

{% if include.slug == "mtls-auth" %}
You can create a Consumer mapping with either of the following:
  * The [`/consumers/{consumer}/mtls-auth` Admin API endpoint](/plugins/mtls-auth/api/)
  * [decK](/gateway/entities/consumer/#set-up-a-consumer) by specifying `mtls_auth_credentials` in the configuration like the following:

    ```yaml
    consumers:
    - custom_id: my-consumer
      username: example-consumer
      mtls_auth_credentials:
      - id: bda09448-3b10-4da7-a83b-2a8ba6021f0c
        subject_name: test@example.com
    ```
{% elsif include.slug == "header-cert-auth" %}
You can create a Consumer mapping using the [`/consumers/{consumer}/header-cert-auth` Admin API endpoint](/plugins/header-cert-auth/api/).
{% endif %}

The following table describes how Consumer mapping parameters work for the {{include.name}} plugin:

{% table %}
columns:
  - title: Form Parameter
    key: parameter
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - parameter: "`id`<br>*required for declarative config*"
    default: none
    description: "UUID of the Consumer mapping. Required if adding mapping using declarative configuration, otherwise generated automatically by {{site.base_gateway}}'s Admin API."
  - parameter: "`subject_name`<br>*required*"
    default: none
    description: "The Subject Alternative Name (SAN) or Common Name (CN) that should be mapped to `consumer` (in order of lookup)."
  - parameter: "`ca_certificate`<br>*optional*"
    default: none
    description: |
      * **If using the Admin API:** UUID of the Certificate Authority (CA). 
      * **If using declarative configuration:** Full PEM-encoded CA certificate.
      <br><br>
      The provided CA UUID or full CA Certificate has to be verifiable by the issuing certificate authority for the mapping to succeed. 
      This is to help distinguish multiple certificates with the same subject name that are issued under different CAs. 
      <br><br>
      If empty, the subject name matches certificates issued by any CA under the corresponding `config.ca_certificates`."
{% endtable %}

### Matching behaviors

After a client certificate has been verified as valid, the Consumer object is determined in the following order, unless [`config.skip_consumer_lookup`](./reference/#schema--config-skip-consumer-lookup) is set to `true`:

1. Manual mappings with `subject_name` matching the certificate's SAN or CN (in that order) and `ca_certificate = {issuing authority of the client certificate}`.
2. Manual mappings with `subject_name` matching the certificate's SAN or CN (in that order) and `ca_certificate = NULL`.
3. If [`config.consumer_by`](./reference/#schema--config-consumer-by) is not null, Consumer with `username` and/or `id` matching the certificate's SAN or CN (in that order).
4. The [`config.anonymous`](./reference/#schema--config-anonymous) Consumer (if set).

{:.info}
> **Note**: Matching stops as soon as the first successful match is found.

### Upstream headers

{% include_cached /plugins/upstream-headers.md %}

When [`config.skip_consumer_lookup`](./reference/#schema--config-skip-consumer-lookup) is set to `true`, Consumer lookup is skipped and instead of appending aforementioned headers, the plugin appends the following two headers:

* `X-Client-Cert-Dn`: The distinguished name of the client certificate
* `X-Client-Cert-San`: The SAN of the client certificate

Once `config.skip_consumer_lookup` is applied, any client with a valid certificate can access the Service/API.
To restrict usage to only some of the authenticated users, also add the [ACL plugin](/plugins/acl/) and create
allowed or denied groups of users using the same
certificate property being set in [`config.authenticated_group_by`](./reference/#schema--config-authenticated-group-by).
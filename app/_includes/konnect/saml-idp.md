{% navtabs "Mappings" %}
{% navtab "Azure" %}


Attribute mapping for Azure configuration:
<!-- vale off -->
{% table %}
columns:
  - title: Azure
    key: azure
  - title: Konnect
    key: konnect
rows:
  - azure: Identifier (Entity ID)
    konnect: "`sp_entity_id`"
  - azure: Reply URL (Assertion Consumer Service URL)
    konnect: "`callback_url`"
  - azure: App Federation Metadata Url
    konnect: "`idp_metadata_url`"
  - azure: "`user.mail`"
    konnect: "`email`"
  - azure: "`user.givenname`"
    konnect: "`firstname`"
  - azure: "`user.surname`"
    konnect: "`lastname`"
  - azure: "`user.groups`"
    konnect: "`groups`"
  - azure: "`user.principalname`"
    konnect: Unique user identifier
{% endtable %}
<!-- vale on -->

**Notes and best practices**

* When adding an enterprise application, note that OIDC uses app registration.
* Remove the namespace from the claim name in Azure. You can do this by checking **Customize** on the group claim.
* Using groups maps to the Group ID by default.


{% endnavtab %}
{% navtab "Oracle Cloud" %}

Attribute mapping for Oracle Cloud configuration:
<!-- vale off -->
{% table %}
columns:
  - title: Oracle Cloud
    key: oracle
  - title: Konnect
    key: konnect
rows:
  - oracle: Entity ID
    konnect: "`sp_entity_id`"
  - oracle: Assertion consumer URL
    konnect: "`callback_url`"
  - oracle: App Federation Metadata Url
    konnect: "`idp_metadata_url`"
{% endtable %}
<!-- vale on -->

**Notes and best practices**

* When configuring the Name ID format in Oracle Cloud, make sure to set it to `transient`.
* You will need to manually upload the signing certificate from `sp_metadata_url`.
   - `cert.pem` must use the `X509Certificate` value for signing.


{% endnavtab %}
{% navtab "KeyCloak" %}

Attribute mapping for KeyCloak configuration:
<!-- vale off -->
{% table %}
columns:
  - title: KeyCloak
    key: keycloak
  - title: Konnect
    key: konnect
rows:
  - keycloak: Client ID
    konnect: "`sp_entity_id`"
  - keycloak: Valid redirect URI
    konnect: "`callback_url`"
  - keycloak: App Federation Metadata Url
    konnect: "`idp_metadata_url`"
{% endtable %}
<!-- vale on -->


**Notes and best practices**

* You will need to manually upload the signing certificate from `sp_metadata_url`.
   - `cert.pem` must use the `X509Certificate` value for signing.
* Go to **Realm Settings** in Keycloak to locate your metadata endpoint. The `sp_metadata_url` for {{site.konnect_short_name}} will be:`http://<keycloak-url>/realms/konnect/protocol/saml/descriptor`

{% endnavtab %}
{% endnavtabs %}

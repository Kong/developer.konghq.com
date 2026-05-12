When you link an API to a Gateway, you have two options:
* Link to a single Gateway Service with the {{site.konnect_short_name}} Application Auth (KAA) plugin
* Link to a control plane with the [Access Control Enforcement plugin](/plugins/ace/)

These plugins are responsible for applying authentication and authorization on the Service or control plane.
The [authentication strategy](/dev-portal/auth-strategies/) that you select for the API defines how clients authenticate.

The following table can help you decide which option to pick:

{% table %}
item_title: Option
columns:
  - title: KAA plugin
    key: kaa
  - title: ACE plugin
    key: ace
rows:
  - title: Plugin applied...
    kaa: "Automatically on the [Gateway Service linked to the API](/catalog/apis/#gateway-service-link)"
    ace: "Manually"
  - title: "Managed by..."
    kaa: "{{site.konnect_short_name}}. You can only modify it by configuring JSON in the advanced configuration for your [application auth strategy](/dev-portal/auth-strategies/)."
    ace: "You"
  - title: "{{site.base_gateway}} version"
    kaa: "3.6 or later"
    ace: "3.13 or later"
  - title: "Can be used with declarative configuration"
    kaa: "No, because the plugin is applied automatically"
    ace: "Yes, because you must configure the plugin"
  - title: "Can be used with API packages"
    kaa: "No"
    ace: "Yes"
{% endtable %}

{:.danger}
> **Do not** configure the KAA and ACE plugin on the same control plane because their overlapping interactions can be unpredictable. 
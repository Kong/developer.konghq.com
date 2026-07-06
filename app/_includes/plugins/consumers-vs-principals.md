The {{ include.name }} plugin supports two types of authenticating entities: [Consumers](/gateway/entities/consumer/) and [principals](/identity/principals/) {% new_in 3.15 %}.

The following table will help you decide which to use based on your use case:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Choose
    key: choose
rows:
  - usecase: You are running on-prem and need authentication plugins.
    choose: "[Consumers](/gateway/entities/consumer/)"
  - usecase: You have a highly performance-sensitive application that can't rely on connectivity between your Gateway data planes and {{site.konnect_short_name}}.
    choose: "[Consumers](/gateway/entities/consumer/)"
  - usecase: You are on {{site.konnect_short_name}} and need to share identity across multiple control planes in the same region without manually syncing credentials.
    choose: "[Principals](/identity/principals/)"
  - usecase: You have a large population of authenticating entities that would exceed [Consumer control plane limits](/gateway/control-plane-resource-limits/). {{site.konnect_short_name}} loads Consumers into data plane memory, but loads principals on demand and caches them in the data plane.
    choose: "[Principals](/identity/principals/)"
  - usecase: You need to attach metadata to an authenticating entity for [conditional plugin execution](/gateway/configure-conditional-plugin-execution/).
    choose: "[Principals](/identity/principals/)"
  - usecase: You need a single identity that works across {{site.base_gateway}}, {{site.event_gateway_short}}, and {{site.dev_portal}}.
    choose: "[Principals](/identity/principals/)"
{% endtable %}
<!--vale on-->

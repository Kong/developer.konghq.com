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
  - usecase: You are running on-prem or {{site.konnect_short_name}} and need authentication plugins other than Key Auth or Basic Auth.
    choose: "[Consumers](/gateway/entities/consumer/)"
  - usecase: You need to scope plugins directly to an authenticating entity.
    choose: "[Consumers](/gateway/entities/consumer/)"
  - usecase: You are on {{site.konnect_short_name}} and need to share identity across multiple control planes in the same region without manually syncing credentials.
    choose: "[Principals](/identity/principals/)"
  - usecase: You have a large population of authenticating entities that would exceed [Consumer control plane limits](/gateway/control-plane-resource-limits/). Consumers are loaded into data plane memory; principals are loaded on demand.
    choose: "[Principals](/identity/principals/)"
  - usecase: You need to attach metadata to an authenticating entity for [conditional plugin execution](/gateway/configure-conditional-plugin-execution/).
    choose: "[Principals](/identity/principals/)"
  - usecase: You need a single identity that works across {{site.base_gateway}}, {{site.event_gateway_short}}, and {{site.dev_portal}}.
    choose: "[Principals](/identity/principals/)"
{% endtable %}
<!--vale on-->

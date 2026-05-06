{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'provider' %}
The following creates a new AI Provider. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site.ai_gateway_name}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Providers**.
1. Click **New Provider**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Select a provider (for example: `{{ include.presenter.data['type'] }}`).
1. Configure authentication and connection settings for the selected provider type.
1. Click **Create**.
{% when 'policy' %}
The following creates a new AI Policy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site.ai_gateway_name}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Policies**.
1. Click **New Policy**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Select a policy **Type** (for example: `{{ include.presenter.data['type'] }}`).
1. Configure the policy `config` fields.
1. Click **Create**.
{% when 'consumer' %}
The following creates a new AI Consumer. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site.ai_gateway_name}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Consumers**.
1. Click **New Consumer**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Select an authentication **Type** (for example: `{{ include.presenter.data['type'] }}`).
1. Configure credentials and optional Consumer Group or Policy references.
1. Click **Create**.
{% when 'consumer-group' %}
The following creates a new AI Consumer Group. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site.ai_gateway_name}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Credentials**.
1. Select the **Groups** tab.
1. Click **New Group**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Optionally add policy references for group-level enforcement.
1. Click **Create**.
{% when 'model' %}
The following creates a new AI Model. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site.ai_gateway_name}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Models**.
1. Click **New Model**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Configure at least one target model and select the Provider reference.
1. Optionally add policies, ACLs, labels, and fallback/load-balancing settings.
1. Click **Create**.
{% when 'agent' %}
The following creates a new AI Agent. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site.ai_gateway_name}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Agents**.
1. Click **New Agent**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Configure the agent settings, model/tool references, and optional policies.
1. Click **Create**.
{% when 'mcp-server' %}
The following creates a new AI MCP Server. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site.ai_gateway_name}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **MCP Servers**.
1. Click **New MCP Server**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Configure endpoint/auth settings and optional policies.
1. Click **Create**.
{% else %}
UI instructions are not yet available for this {{site.ai_gateway}} entity type.
{% endcase %}
{% endif %}

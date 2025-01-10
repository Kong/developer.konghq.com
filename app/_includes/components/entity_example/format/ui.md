{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'consumer' %}
The following creates a new consumer called **{{ include.presenter.data['username'] }}**:

1. In Kong Manager or Gateway Manager, go to **Consumers**.
2. Click **New Consumer**.
3. Enter the **Username** `{{ include.presenter.data['username'] }}` and **Custom ID** `{{ include.presenter.data['custom_id'] }}`.
4. Click **Save**.
{% when 'consumer_group' %}
The following creates a new Consumer Group called **{{ include.presenter.data['name'] }}**:

1. In Kong Manager or Gateway Manager, go to **API Gateway** > **Consumers**.
2. Click **Consumer Group**.
3. Click **New Consumer Group**.
4. Enter the **Name** `{{ include.presenter.data['name'] }}`.
5. Click **Save**.
{% when 'route' %}
The following creates a new route called **{{ include.presenter.data['name'] }}** with basic configuration:

1. In Kong Manager or Gateway Manager, go to **Routes**.
2. Click **New Route**.
3. Enter a unique name and select a service to assign it to. In this example, the route is named `{{ include.presenter.data['name'] }}`.
4. Set a path or define routing rules. For example, the path can be `{{ include.presenter.data['paths']}}`.
5. Click **Save**.
{% when 'service' %}
The following creates a new service called **{{ include.presenter.data['name'] }}** with basic configuration:

1. In Kong Manager or Gateway Manager, go to **Gateway Services**.
2. Click **New Gateway Service**.
3. Enter a unique name for the service. In this example, it's `{{ include.presenter.data['name'] }}`.
4. Define the endpoint for this service by specifying the full URL or by its separate elements. In this example, the full upstream URL is `{{ include.presenter.data['url'] }}`.
5. Click **Save**.
{% when 'plugin' %}
1. In Kong Manager or Gateway Manager, go to **Plugins**.
2. Click **New Plugin**.
3. Choose a scope for the plugin:
    * **Global**, which applies the plugin to all services, routes, consumers, and consumer groups in the workspace (Kong Manager) or control plane (Gateway Manager).
    * **Scoped**, which lets you choose a specific Gateway service, route, consumer, or consumer group to apply the plugin to.
    The types of entities you have available here depend on the plugin you picked.

4. Configure your plugin. The configuration options will depend on which plugin you picked.
5. Click **Save**.
{% when 'target' %}
The following creates a new Upstream and a Target with basic configuration:

1. In Kong Manager or Gateway Manager, Navigate to **Workspaces** > **Upstreams**.
2. Click **New Upstream**.
3. Enter a unique name for the Upstream. For example: `example_upstream`.
4. Click **Save**.
5. From your Upstream, select the **Targets** tab.
6. Click **New Target**.
7. Enter an IP address/hostname and port in the **Target Address** field, for example: `{{ include.presenter.data['target'] }}`
8. Update the weight for example: `{{ include.presenter.data['weight'] }}`.
9. Click **Save**.
{% when 'upstream' %}
The following creates a new Upstream with basic configuration:

1. In Kong Manager or Gateway Manager, Navigate to **Workspaces** > **Upstreams**.
2. Click **New Upstream**.
3. Enter a unique name for the Upstream. For example: `{{ include.presenter.data['name'] }}`.
4. Click **Save**.
{% when workspace %}
{% when 'sni' %}
The following creates a new SNI with basic configuration:

1. In Kong Manager or Gateway Manager, go to **SNIs**.
2. On the SNIs tab, click **New SNI**.
3. In the **Name** field, enter a name for the SNI:
    ```
    {{ include.presenter.data['name'] }}
    ```
4. In the **SSL Certificate ID** field, enter the ID for an existing Certificate:
    ```
    {{ include.presenter.data['certificate']['id'] }}

{% when 'certificate' %}
The following creates a new Certificate with basic configuration:

1. In Kong Manager or Gateway Manager, go to **Certificates**.
2. On the Certificates tab, click **New Certificate**.
3. In the **Cert** field, enter the PEM-encoded public certificate:
    ```
    {{ include.presenter.data['cert'] }}
    ```
4. In the **Key** field, enter the PEM-encoded private key:
    ```
    {{ include.presenter.data['key'] }}
    ```
5. Click **Save**.
{% else %}
{% endcase %}
{% endif %}
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
{% when 'vault' %}
The following creates a new Vault with basic configuration:

1. In Kong Manager or Gateway Manager, navigate to a control plane and click **Vaults** in the sidebar.
2. Click **New Vault**.
3. Select a configuration for the Vault. For example: `{{ include.presenter.data['name'] }}`
1. Enter a prefix for the Vault. For example: `{{ include.presenter.data['prefix'] }}`
1. Enter a description for the Vault. For example: `{{ include.presenter.data['description'] }}`
4. Click **Save**.

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
{% when 'workspace' %}
The following creates a new Workspace:

1. From the Kong Manager Dashboard select **New Workspace**.
2. Add a name, then select **Create New Workspace**.

This will create a new Workspace, and from here you can start managing entities from Kong Manager.

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
{% when 'ca_certificate' %}
The following creates a new Certificate with basic configuration:

1. In Kong Manager or Gateway Manager, go to **Certificates**.
2. Click the **CA Certificates** tab.
3. Click **New CA Certificate**.
4. In the **Cert** field, enter the PEM-encoded public certificate of the CA:
    ```
    {{ include.presenter.data['cert'] }}
    ```
5. Click **Save**.
{% when 'rbac' %}
The following instructions create an RBAC user in Kong Manager. `kong.conf` must be configured to `ENFORCE_RBAC=on`.

1. In Kong Manager, go to **Teams**. 
2. Select the **RBAC Users** tab, 
4. Select the appropriate [Workspace](/gateway/entities/workspace/) then **Add new user**.
3. Create a **Name**, **User Token**, and press **Create**. 
{% when 'key' %}
The following creates a new JSON Web Key with basic configuration:

1. In Kong Manager or Gateway Manager, go to **Keys**.
2. Click the **Keys** tab.
3. Click **New Key**.
4. In the **Key ID** field, enter the key ID. It should match the `kid` field in the key:
    ```
    {{ include.presenter.data['kid'] }}
    ```
5. Enter a name for the key:
    ```
    {{ include.presenter.data['name'] }}
    ```
5. In the **JWK** field, enter the JSON Web Key:
    ```
    {{ include.presenter.data['jwk'] }}
    ```
6. Click **Save**.
{% else %}
{% endcase %}
{% endif %}



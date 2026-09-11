Run the [quickstart script]({{ include.config.script_url }}) to automatically provision a demo {{site.base_gateway}} control plane and data plane, and configure your environment:

```bash
{{ include.config.command }}
```

This sets up an {{site.base_gateway}} control plane named `{{ include.config.control_plane_name }}`, provisions a local data plane, and prints out the following environment variable export:

```bash
export {{ include.config.gateway_id_var }}=your-gateway-id
```
{% if include.no_copy_code %}{:.no-copy-code}
{% endif %}
Copy and paste the command with your Event Gateway ID into your terminal to configure your session.

{% include_cached /knep/quickstart-note.md %}

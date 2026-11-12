{% include_cached components/plugin_credential_example/lead_sentence.md plugin_name=include.presenter.plugin_name %}

Add the following to your Terraform configuration to create the Consumer and the credential:

```hcl
resource "{{ include.presenter.consumer_resource_name }}" "{{ include.presenter.consumer_local_name }}" {
{{ include.presenter.consumer_body }}
  control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
}

resource "{{ include.presenter.credential_resource_name }}" "{{ include.presenter.credential_local_name }}" {
{{ include.presenter.credential_body }}
  control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
}
```

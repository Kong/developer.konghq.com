{%- navtabs "policy-yaml" additional_classes heading_level -%}
{%- if show_kubernetes -%}
{%- navtab "Kubernetes" -%}
{%- if use_meshservice -%}
{%- if page.output_format != 'markdown' -%}
<div class="meshservice text-sm">
<label class="flex gap-2 py-0.5 w-full text-sm text-primary md:pl-1 items-center">
<input class="checkbox" type="checkbox"> I am using <a href="/mesh/networking/meshservice/">MeshService</a></label>
</div>
{%- endif -%}
{% if page.output_format == 'markdown' %}Using `kuma.io/service` tag-based naming:{% endif %}
{{kube_legacy | liquify}}
{% if page.output_format == 'markdown' %}Using `MeshService` Kubernetes resources:{% endif %}
{{kube | liquify}}
{%- else -%}
{{kube_legacy | liquify}}
{%- endif -%}
{%- endnavtab -%}
{%- endif -%}
{%- if show_universal -%}
{%- navtab "Universal" -%}
{%- if use_meshservice -%}
{%- if page.output_format != 'markdown' -%}
<div class="meshservice text-sm">
<label class="flex gap-2 py-0.5 w-full text-sm text-primary md:pl-1 items-center">
<input class="checkbox" type="checkbox"> I am using <a href="/mesh/networking/meshservice/">MeshService</a></label>
</div>
{%- endif -%}
{% if page.output_format == 'markdown' %}Using `kuma.io/service` tag-based naming:{% endif %}
{{uni_legacy | liquify}}
{% if page.output_format == 'markdown' %}Using `MeshService` Kubernetes resources:{% endif %}
{{uni | liquify}}
{%- else -%}
{{uni_legacy | liquify}}
{%- endif -%}
{%- endnavtab -%}
{%- endif -%}
{%- if show_tf -%}
{%- navtab "Terraform" %}
Adjust **konnect_mesh_control_plane.my_meshcontrolplane.id** and **konnect_mesh.my_mesh.name** according to your current configuration.
{: .text-sm}

{{ terraform_content | liquify }}
{%- endnavtab -%}
{%- endif -%}
{%- endnavtabs -%}

{%- assign vzc_zones = include.zones | default: 'zone-1' | split: ',' -%}
{%- if vzc_zones.size > 1 -%}
Confirm the zones are connected to your global control plane:
{%- else -%}
Confirm the zone is connected to your global control plane:
{%- endif %}

```sh
kongctl inspect mesh zones \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
  --pat "$KONNECT_TOKEN"
```

{% if vzc_zones.size > 1 %}Each zone should{% else %}The zone should{% endif %} report an `Online` status:

```text
NAME    STATUS
{%- for vzc_zone in vzc_zones %}
{{ vzc_zone | strip }}  Online
{%- endfor %}
```
{:.no-copy-code}

If a zone is missing or not `Online`, check:
* The zone's control plane logs
* Outbound access to the KDS address
* The control plane ID
* The system account's `Connector` role and token

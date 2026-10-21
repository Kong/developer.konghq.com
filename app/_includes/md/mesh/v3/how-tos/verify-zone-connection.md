{%- assign vzc_zones = include.zones | default: 'zone-1' | split: ',' -%}
{%- capture vzc_zone_list -%}
{%- for vzc_zone in vzc_zones -%}
{%- if forloop.index > 1 and forloop.last %} and {% elsif forloop.index > 1 %}, {% endif -%}
`{{ vzc_zone | strip }}`
{%- endfor -%}
{%- endcapture -%}
{%- if vzc_zones.size > 1 -%}
Confirm the zones are connected to your global control plane:
{%- else -%}
Confirm the zone is connected to your global control plane:
{%- endif %}

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Confirm that {{ vzc_zone_list }} {% if vzc_zones.size > 1 %}appear{% else %}appears{% endif %} in the list of zones with an **Online** status.

If a zone is missing or not **Online**, check:
* The zone's control plane logs
* Outbound access to the KDS address
* The control plane ID
* The system account's `Connector` role and token

In the logs, `Unauthenticated` means the KDS address or token is wrong, and `PermissionDenied` means the system account is missing the `Connector` role.

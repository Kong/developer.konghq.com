On first Sync, set the proxy URL for each Gateway Service:

1. From your {{ site.data.products.insomnia.name }} workspace, go to the {{ site.konnect_short_name }} tab
1. Select a Gateway Service to see the associated Collections
1. Open the **Base Environment** file
1. From {{ site.konnect_short_name }}, copy the proxy URLs for the selected Gateway Service
1. Paste each proxy URL into the **value** field, and add the port using this format: `<proxy-url>:<port>`

{:.info}
> The proxy URLs depend on the type of control plane you chose. See [Data Plane hosting options](/gateway/topology-hosting-options/) for details.

{{ site.data.products.insomnia.name }} never resets this setup when syncing. If you change the proxy URLs in {{ site.konnect_short_name }}, repeat this setup.
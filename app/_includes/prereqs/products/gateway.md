{% assign summary='{{site.base_gateway}} running' %}

{% capture details_content %}
{% if include.tier=='enterprise' %}

This tutorial requires {{site.ee_product_name}}.
If you don't have {{site.base_gateway}} set up yet, you can use the
[quickstart script](https://get.konghq.com/quickstart) with an enterprise license
to get an instance of {{site.base_gateway}} running almost instantly.

1. Export your license to an environment variable:

    ```
    export KONG_LICENSE_DATA='<license-contents-go-here>'
    ```

2. Run the quickstart script:

    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA
    ```

    Once {{site.base_gateway}} is ready, you will see the following message:
    ```bash
    Kong Gateway Ready
    ```
    {:.no-copy-code}

{% else %}

This tutorial requires {{site.base_gateway}}.
If you don't have it set up yet, you can use the [quickstart script](https://get.konghq.com/quickstart) to get an instance of {{site.base_gateway}} running almost instantly:

```bash
curl -Ls https://get.konghq.com/quickstart | bash -s
```
Once {{site.base_gateway}} is ready, you will see the following message:
```bash
Kong Gateway Ready
```
{:.no-copy-code}

{% endif %}
{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}
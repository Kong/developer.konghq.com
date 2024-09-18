{% assign summary='Kong Gateway running' %}

{% capture details_content %}
{% if include.tier=='enterprise' %}

This tutorial requires Kong Gateway Enterprise. 
If you don't have Kong Gateway set up yet, you can use the 
[quickstart script](https://get.konghq.com/quickstart) with an enterprise license
to get an instance of Kong Gateway running almost instantly.

1. Export your license to an environment variable:
  
    ```
    export KONG_LICENSE_DATA='<license-contents-go-here>'
    ```

2. Run the quickstart script:

    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA
    ```

    Once Kong Gateway is ready, you will see the following message:
    ```bash
    Kong Gateway Ready 
    ```
    {:.no-copy-code}

{% else %}

This tutorial requires Kong Gateway. 
If you don't have it set up yet, you can use the [quickstart script](https://get.konghq.com/quickstart) to get an instance of Kong Gateway running almost instantly:

```bash
curl -Ls https://get.konghq.com/quickstart | bash -s
```
Once Kong Gateway is ready, you will see the following message:
```bash
Kong Gateway Ready
```
{:.no-copy-code}

{% endif %}
{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content %}
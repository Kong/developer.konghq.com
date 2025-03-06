{% assign summary='{{site.base_gateway}} running' %}

{% capture details_content %}
{% if include.rbac %}
{% assign summary='{{site.base_gateway}} running with RBAC enabled' %}
This tutorial requires {{site.ee_product_name}}.
1. Export your license to an environment variable:

    ```
    export KONG_LICENSE_DATA='<license-contents-go-here>'
    ```

2. Run the quickstart script with RBAC enabled:

    ```bash
    curl -Ls get.konghq.com/quickstart | bash -s -- -e "KONG_LICENSE_DATA" \
         -e "KONG_ENFORCE_RBAC=on" \
         -e "KONG_ADMIN_GUI_AUTH=basic-auth" \
         -e "KONG_PASSWORD=kong" \
         -e 'KONG_ADMIN_GUI_SESSION_CONF={"secret":"kong", "cookie_lifetime":300000, "cookie_renew":200000, "cookie_name":"kong_cookie", "cookie_secure":false, "cookie_samesite": "off"}'
    ```
    For more information about the values see the [RBAC](/gateway/entities/rbac/) reference.
    Once {{site.base_gateway}} is ready, you will see the following message:
    ```bash
    Kong Gateway Ready
    ```
    {:.no-copy-code}


{% else %}

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
    curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA {% if include.env_variables %}\{% endif %}{% for variable in include.env_variables %}
         -e {{variable.name}}{% if variable.value %}={{variable.value}}{% endif %}{% unless forloop.last %} \{% endunless %}{% endfor %}
    ```

    Once {{site.base_gateway}} is ready, you will see the following message:
    ```bash
    Kong Gateway Ready
    ```
    {:.no-copy-code}

{% endif %}
{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}
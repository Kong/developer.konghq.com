{% assign summary='{{site.base_gateway}} running' %}

{% capture rbac_snippet %}
```bash
curl -Ls get.konghq.com/quickstart | bash -s -- -e "KONG_LICENSE_DATA" \
     -e "KONG_ENFORCE_RBAC=on" \
     -e "KONG_ADMIN_GUI_AUTH=basic-auth" \
     -e "KONG_PASSWORD=kong" \
     -e 'KONG_ADMIN_GUI_SESSION_CONF={"secret":"kong", "cookie_lifetime":300000, "cookie_renew":200000, "cookie_name":"kong_cookie", "cookie_secure":false, "cookie_samesite": "off"}'
```
{% endcapture %}

{% capture details_content %}
{% if include.rbac %}
{% assign summary='{{site.base_gateway}} running with RBAC enabled' %}
This tutorial requires {{site.ee_product_name}}.
1. Export your license to an environment variable:

   ```bash
   export KONG_LICENSE_DATA='LICENSE-CONTENTS-GO-HERE'
   ```

2. Run the quickstart script with RBAC enabled:

   {% if page.output_format == 'markdown' %}
   {{rbac_snippet | liquify | indent: 3}}
   {% else %}
   <div data-test-setup='{ "gateway": "{{page.min_version.gateway}}", "rbac": true }' markdown="1">
{{rbac_snippet | indent: 3}}
   </div>
   {% endif %}

   For more information about the values see the [RBAC](/gateway/entities/rbac/) reference.
   Once {{site.base_gateway}} is ready, you will see the following message:
   ```bash
   Kong Gateway Ready
   ```

{% else %}

{% capture vanilla_snippet %}
```bash
curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA {% if include.env_variables %}\{% endif %}{% for variable in include.env_variables %}
     -e {{variable.name}}{% if variable.value %}={{variable.value}}{% endif %}{% unless forloop.last %} \{% endunless %}{% endfor %}
```
{% endcapture %}
This tutorial requires {{site.ee_product_name}}.
If you don't have {{site.base_gateway}} set up yet, you can use the
[quickstart script](https://get.konghq.com/quickstart) with an enterprise license
to get an instance of {{site.base_gateway}} running almost instantly.

1. Export your license to an environment variable:

    ```bash
    export KONG_LICENSE_DATA='LICENSE-CONTENTS-GO-HERE'
    ```

2. Run the quickstart script:

   {% if page.output_format == 'markdown' %}
   {{vanilla_snippet | liquify | indent: 3}}
   {% else %}
   <div data-test-setup='{ "gateway": "{{page.min_version.gateway}}" }' markdown="1">
{{vanilla_snippet | indent: 3}}
   </div>

   {% endif %}

    Once {{site.base_gateway}} is ready, you will see the following message:
    ```bash
    Kong Gateway Ready
    ```
    {:.no-copy-code}

{% endif %}
{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}
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

    Once {{site.base_gateway}} is ready, you will see the following message:
    ```bash
    Kong Gateway Ready
    ```
    For more information about the values see the [Bootstrap RBAC](/how-to/bootstrap-rbac/) guide.
    {:.no-copy-code}





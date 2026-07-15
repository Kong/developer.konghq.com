{% assign product = page.products | first %}{% if product == 'ai-gateway' %}{% assign hardened_product_name = site.ai_gateway %}{% else %}{% assign hardened_product_name = site.base_gateway %}{% endif %}
{:.info}
> **Running in a hardened container**
>
> {{hardened_product_name}} needs writable volumes mounted at `/tmp` and at the `prefix` (`KONG_PREFIX`) directory, even in a read-only root filesystem. The prefix directory holds the PID file, Unix sockets, the LMDB cache, and the generated NGINX configuration. You can redirect logs, such as `proxy_error_log`, to a separate writable path or to stderr.
>
> To run as a non-root user, set `nginx_user` (or the `KONG_NGINX_USER` environment variable). A non-root user can't bind to privileged ports (1024 or lower), so configure the proxy and Admin API listeners on ports above 1024.

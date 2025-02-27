In general, the proxy ports are the *only* ports that should be made available to your clients. Upstream services are accessible via the proxy interface and ports, so make sure that these values only grant the access level you require. 

Your proxy will need rules added for any HTTP/HTTPS and TCP/TLS stream listeners that you configure. For example, if you want {{site.base_gateway}} to manage traffic on port `4242`, your firewall must allow traffic on that port.

The following are the default proxy ports:

| Port | Protocol | `kong.conf` setting | Description | 
|---------|---------|------------|------------|
| `8000` | HTTP     | [`proxy_listen`](/gateway/configuration/#proxy_listen) | Takes incoming HTTP traffic from [Consumers](/gateway/entities/consumer/), and forwards it to upstream services. | 
| `8443` | HTTPS    | [`proxy_listen`](/gateway/configuration/#proxy_listen) | Takes incoming HTTPS traffic from [Consumers](/gateway/entities/consumer/), and forwards it to upstream services. |

You can also proxy TCP/TLS streams, which is disabled by default. If you want to proxy this traffic, see [`stream_listen` in the Kong configuration reference](/gateway/configuration/) for more information about stream proxy listen options and how to enable it.
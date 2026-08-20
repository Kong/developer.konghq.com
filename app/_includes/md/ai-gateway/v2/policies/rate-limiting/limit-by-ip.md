If limiting by IP address, it's important to understand how {{site.ai_gateway}} determines the IP address of an incoming request.

The IP address is extracted from the request headers sent to {{site.ai_gateway}} by downstream clients. Typically, these headers are named `X-Real-IP` or `X-Forwarded-For`.

By default, {{site.ai_gateway}} uses the header name `X-Real-IP` to identify the client's IP address. If your environment requires a different header, you can specify this by setting the [`real_ip_header`](/ai-gateway/configuration/#real-ip-header) Nginx property. Depending on your network setup, you may also need to configure the [`trusted_ips`](/ai-gateway/configuration/#trusted-ips) Nginx property to include the load balancer IP address. This ensures that {{site.ai_gateway}} correctly interprets the client's IP address, even when the request passes through multiple network layers.

This Policy uses the [lua-resty-kafka](https://github.com/kong/lua-resty-kafka) client.
{% if include.forward_fields %}
Control which parts of the request are included in the message with [`config.forward_body`](./reference/#schema--config-forward-body) (enabled by default), [`config.forward_headers`](./reference/#schema--config-forward-headers), [`config.forward_method`](./reference/#schema--config-forward-method), and [`config.forward_uri`](./reference/#schema--config-forward-uri).
{% endif %}
When encoding request bodies, several things happen:

* For requests with a content-type header of `application/x-www-form-urlencoded`, `multipart/form-data`,
  or `application/json`, this Policy passes the raw request body in the `body` attribute, and tries
  to return a parsed version of those arguments in `body_args`.
  If this parsing fails, the Policy returns an error message and the message isn't sent.
* If the `content-type` is not `text/plain`, `text/html`, `application/xml`, `text/xml`, or `application/soap+xml`,
  then the body will be base64-encoded to ensure that the message can be sent as JSON. In that case,
  the message has an extra attribute called `body_base64` set to `true`.

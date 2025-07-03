The plugin supports the following modes of operation:
* `http-get`: Consume messages via an HTTP GET requests (default)
* `server-sent-events`: Stream messages using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
{% if include.slug == 'kafka-consume' %}
* `websocket` {% new_in 3.11 %}: Stream messages over a [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) connection
{% endif %}
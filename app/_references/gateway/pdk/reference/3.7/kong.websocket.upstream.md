---
title: kong.websocket.upstream
---

Upstream WebSocket PDK functions.

## kong.websocket.upstream.get_frame()

Retrieve the current frame.

This returns the payload, type, and status code (for close frames) of
the in-flight frame/message.

This function is useful in contexts like the pre-function or post-function plugins
where execution is sandboxed, and the caller has no access to these
variables in the plugin handler scope.


**Phases**

* `ws_upstream_frame`

**Returns**

*  `string`:  The frame payload.
*  `string`:  The frame type (one of "text", "binary", "ping", "pong", or "close")
*  `number`:  The frame status code (only returned for close frames)


**Usage**

```lua
local data, typ, status = kong.websocket.upstream.get_frame()
```



## kong.websocket.upstream.set_frame_data(data)

Set the current frame's payload.

This allows the caller to overwrite the contents of the in-flight
WebSocket frame before it is forwarded to the client.

Plugin handlers that execute _after_ this has been called will see the
updated version of the frame.


**Phases**

* `ws_upstream_frame`

**Parameters**

* **data** (`string`):  The desired frame payload

**Usage**

```lua
kong.websocket.upstream.set_frame_data("updated!")
```



## kong.websocket.upstream.set_status(status)

Set the status code for a close frame.

This allows the caller to overwrite the status code of close frame
before it is forwarded to the client.

See the [WebSocket RFC](https://datatracker.ietf.org/doc/html/rfc6455#section-7.4.1)
for a list of valid status codes.

Plugin handlers that execute _after_ this has been called will see the
updated version of the status code.

Calling this function when the in-flight frame is not a close frame
will result in an exception.


**Parameters**

* **status** (`number`):  The desired status code

**Usage**

```lua
-- overwrite the payload and status before forwarding
local data, typ, status = kong.websocket.upstream.get_frame()
if typ == "close" then
  kong.websocket.upstream.set_frame_data("goodbye!")
  kong.websocket.upstream.set_status(1000)
end
```



## kong.websocket.upstream.drop_frame()

Drop the current frame.

This causes the in-flight frame to be dropped, meaning it will not be
forwarded to the client.

Plugin handlers that are set to execute _after_ this one will be
skipped.

Close frames cannot be dropped. Calling this function for a close
frame will result in an exception.

**Usage**

```lua
kong.websocket.upstream.drop_frame()
```

## kong.websocket.upstream.close([status[, message[, client_status[, client_payload]]]])

Close the WebSocket connection.

Calling this function immediately sends a close frame to the client and
the upstream before terminating the connection.

The in-flight frame will not be forwarded to the client, and plugin
handlers that are set to execute _after_ the current one will not be
executed.


**Parameters**

* **status** (`number`, _optional_):  Status code of the upstream close frame
* **message** (`string`, _optional_):  Payload of the upstream close frame
* **client_status** (`number`, _optional_):  Status code of the client close frame
* **client_payload** (`string`, _optional_):  Payload of the client close frame

**Usage**

```lua
kong.websocket.upstream.close(1009, "Invalid message",
                              1001, "Upstream is going away")
```

## kong.set_max_payload_size

Set the maximum allowed payload size for upstream frames.

This limit is applied to all data frame types:
  * text
  * binary
  * continuation

The limit is also assessed during aggregation of frames. For example,
if the limit is 1024, and a upstream sends 3 continuation frames of size
500 each, the third frame will exceed the limit.

If a upstream sends a message that exceeds the limit, a close frame with
status code `1009` is sent to the upstream, and the connection is closed.

This limit does not apply to control frames (close/ping/pong).

* **size** (`integer`):  The limit (`0` resets to the default limit)

**Usage**

```lua
-- set a max payload size of 1KB
kong.websocket.upstream.set_max_payload_size(1024)
-- Restore the default limit
kong.websocket.upstream.set_max_payload_size(0)
```
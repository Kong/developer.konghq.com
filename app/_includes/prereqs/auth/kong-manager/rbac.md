{{site.base_gateway}} comes packaged with authentication plugins that can be used to secure Kong Manager. To enable `basic-auth` for only Kong Manager, you need to set the following properties in `kong.conf`:

* Set `enforce_rbac` to `on`
* Set `admin_gui_auth` to `basic-auth`
* Configure `admin_gui_session_conf` with a secret, for example: `example-secret`

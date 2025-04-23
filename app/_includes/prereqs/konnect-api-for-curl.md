To use the copy, paste, and run the instructions in this how-to, you must export these additional environmental variables:

```sh
export CONTROL_PLANE_ID=your-control-plane-uuid
```

* `CONTROL_PLANE_ID`: You can find your control plane UUID by navigating to the control plane in the {{site.konnect_short_name}} UI or by sending a `GET` request to the [`/control-planes` endpoint](/api/konnect/control-planes/v2/#/operations/list-control-planes).
